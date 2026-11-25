import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/settings_dao.dart';
import '../../../core/l10n/app_language.dart';
import '../../../core/network/tmdb_client.dart';
import '../../../core/settings/app_settings_providers.dart';
import '../../backup/data/backup_codec.dart';
import '../../backup/data/backup_service.dart';
import '../../backup/data/letterboxd_codec.dart';
import '../../backup/data/letterboxd_import_service.dart';
import '../../backup/data/zip_archive_reader.dart';

const String kTmdbAttributionText =
    'This product uses the TMDB API but is not endorsed or certified by TMDB.';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _keyController = TextEditingController();
  bool _obscure = true;
  bool _testing = false;
  bool _importingLetterboxd = false;
  bool _initializedFromStore = false;
  String? _keyFeedback;
  bool _keyFeedbackIsError = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey(AppLanguage lang) async {
    final trimmed = _keyController.text.trim();
    if (trimmed.isNotEmpty && !TmdbClient.isPlausibleKey(trimmed)) {
      setState(() {
        _keyFeedback = lang.pick(
          'Anahtar formatı geçersiz görünüyor.',
          'Key format looks invalid.',
        );
        _keyFeedbackIsError = true;
      });
      return;
    }
    await ref.read(settingsDaoProvider).write(
          SettingKeys.tmdbApiKey,
          trimmed.isEmpty ? null : trimmed,
        );
    if (!mounted) return;
    setState(() {
      _keyFeedback = trimmed.isEmpty
          ? lang.pick('Kayıtlı anahtar silindi.', 'Saved key deleted.')
          : lang.pick('Anahtar kaydedildi.', 'Key saved.');
      _keyFeedbackIsError = false;
    });
  }

  Future<void> _testAndSaveKey(AppLanguage lang) async {
    final trimmed = _keyController.text.trim();
    if (!TmdbClient.isPlausibleKey(trimmed)) {
      setState(() {
        _keyFeedback = lang.pick(
          'Lütfen geçerli bir TMDB API anahtarı girin.',
          'Please enter a valid TMDB API key.',
        );
        _keyFeedbackIsError = true;
      });
      return;
    }

    setState(() {
      _testing = true;
      _keyFeedback = null;
    });

    final client = TmdbClient(trimmed, language: lang.tmdbLocale);
    try {
      await client.validateKey();
      await ref
          .read(settingsDaoProvider)
          .write(SettingKeys.tmdbApiKey, trimmed);
      if (mounted) {
        setState(() {
          _keyFeedback = lang.pick(
            'Anahtar doğrulandı ve kaydedildi.',
            'Key verified and saved.',
          );
          _keyFeedbackIsError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _keyFeedback = userMessageFor(e, lang);
          _keyFeedbackIsError = true;
        });
      }
    } finally {
      client.close();
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _exportBackup(AppLanguage lang) async {
    final location = await getSaveLocation(
      suggestedName: 'movie_tracker_backup.json',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (location == null || !mounted) return;
    try {
      final count =
          await ref.read(backupServiceProvider).exportToFile(location.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.pick(
                '$count kayıt dışa aktarıldı.',
                '$count entries exported.',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.pick(
                'Dışa aktarma başarısız: $e',
                'Export failed: $e',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _importBackup(AppLanguage lang) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (file == null || !mounted) return;

    final lowerSelectedName = file.name.toLowerCase();
    if (lowerSelectedName.endsWith('.zip') ||
        lowerSelectedName.endsWith('.csv')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.pick(
              'Letterboxd dosyaları için alt kısımdaki "Letterboxd (.zip / .csv) İçe Aktar" butonunu kullanın.',
              'For Letterboxd files, please use the "Import Letterboxd (.zip / .csv)" button below.',
            ),
          ),
        ),
      );
      return;
    }

    try {
      final length = await file.length();
      if (length > kMaxBackupBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang.pick(
                  'Yedek dosyası çok büyük (>20 MB).',
                  'Backup file is too large (>20 MB).',
                ),
              ),
            ),
          );
        }
        return;
      }
      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes);
      final result =
          await ref.read(backupServiceProvider).importJson(content);
      if (mounted) {
        final skipped = result.errors.isEmpty
            ? ''
            : lang.pick(
                ' (${result.errors.length} hatalı kayıt atlandı)',
                ' (${result.errors.length} invalid entries skipped)',
              );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.pick(
                '${result.inserted} yeni eklendi, ${result.updated} güncellendi$skipped.',
                '${result.inserted} added, ${result.updated} updated$skipped.',
              ),
            ),
          ),
        );
      }
    } on BackupFormatException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.pick(
                'Dosya UTF-8 metin olarak okunamadı.',
                'File could not be read as UTF-8 text.',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.pick(
                'İçe aktarma başarısız: $e',
                'Import failed: $e',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _importLetterboxd(AppLanguage lang) async {
    if (_importingLetterboxd) return;

    if (!ref.read(apiKeyProvider).hasKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.pick(
              'Letterboxd verilerini afiş ve detaylarıyla eşleştirmek için önce yukarıdan geçerli bir TMDB API anahtarı kaydedin.',
              'Please save a valid TMDB API key above first to match Letterboxd entries with posters and details.',
            ),
          ),
        ),
      );
      return;
    }

    final selectedFiles = await openFiles(
      acceptedTypeGroups: [
        XTypeGroup(
          label: lang.pick(
            'Letterboxd Verisi (.zip, .csv)',
            'Letterboxd Data (.zip, .csv)',
          ),
          extensions: const ['zip', 'csv'],
        ),
      ],
    );
    if (selectedFiles.isEmpty || !mounted) return;

    final zipFiles = selectedFiles
        .where((f) => f.name.toLowerCase().endsWith('.zip'))
        .toList();
    if (zipFiles.isNotEmpty && selectedFiles.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.pick(
              'Lütfen tek bir Letterboxd .zip arşivi veya birden fazla .csv dosyası seçin.',
              'Please select either a single Letterboxd .zip archive or one or more .csv files.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _importingLetterboxd = true);
    final cancelToken = CancelToken();
    final progressNotifier = ValueNotifier<_LetterboxdProgressState>(
      const _LetterboxdProgressState(processed: 0, total: 0, currentTitle: ''),
    );
    BuildContext? dialogContext;
    var dialogShown = false;

    try {
      // Pre-validate sizes before opening the progress dialog.
      if (zipFiles.length == 1) {
        final len = await zipFiles.single.length();
        if (len > kMaxZipArchiveBytes) {
          throw const LetterboxdFormatException(
            'ZIP arşivi çok büyük (en fazla 50 MB).',
            'ZIP archive is too large (max 50 MB).',
          );
        }
      } else {
        for (final f in selectedFiles) {
          final len = await f.length();
          if (len > kMaxLetterboxdCsvBytes) {
            throw const LetterboxdFormatException(
              'CSV dosyası çok büyük (en fazla 20 MB).',
              'CSV file is too large (max 20 MB).',
            );
          }
        }
      }

      if (!mounted) return;
      dialogShown = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx;
          return _LetterboxdProgressDialog(
            lang: lang,
            progress: progressNotifier,
            onCancel: () {
              if (!cancelToken.isCancelled) {
                cancelToken.cancel();
              }
            },
          );
        },
      );

      final service = ref.read(letterboxdImportServiceProvider);
      void onProgress(int processed, int total, String title) {
        progressNotifier.value = _LetterboxdProgressState(
          processed: processed,
          total: total,
          currentTitle: title,
        );
      }

      final LetterboxdImportResult result;
      if (zipFiles.length == 1) {
        final bytes = await zipFiles.single.readAsBytes();
        result = await service.importZipBytes(
          bytes,
          cancelToken: cancelToken,
          onProgress: onProgress,
        );
      } else {
        final csvInputs = <({String fileName, String content})>[];
        for (final f in selectedFiles) {
          final bytes = await f.readAsBytes();
          csvInputs.add((fileName: f.name, content: utf8.decode(bytes)));
        }
        result = await service.importCsvFiles(
          csvInputs,
          cancelToken: cancelToken,
          onProgress: onProgress,
        );
      }

      if (dialogShown && dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
        dialogShown = false;
      }

      if (!mounted) return;
      await _presentLetterboxdResult(lang, result);
    } on LetterboxdFormatException catch (e) {
      if (dialogShown && dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
        dialogShown = false;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.messageFor(lang))),
        );
      }
    } on TmdbException catch (e) {
      if (dialogShown && dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
        dialogShown = false;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessageForLang(lang))),
        );
      }
    } on FormatException {
      if (dialogShown && dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
        dialogShown = false;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.pick(
                'CSV dosyası UTF-8 metin olarak okunamadı.',
                'CSV file could not be read as UTF-8 text.',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (dialogShown && dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
        dialogShown = false;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.pick(
                'Letterboxd içe aktarma başarısız: $e',
                'Letterboxd import failed: $e',
              ),
            ),
          ),
        );
      }
    } finally {
      if (dialogShown && dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }
      progressNotifier.dispose();
      if (mounted) {
        setState(() => _importingLetterboxd = false);
      }
    }
  }

  Future<void> _presentLetterboxdResult(
    AppLanguage lang,
    LetterboxdImportResult result,
  ) async {
    final unchangedSuffix = result.unchanged > 0
        ? lang.pick(
            ', ${result.unchanged} kayıt zaten güncel',
            ', ${result.unchanged} already up to date',
          )
        : '';
    final summary = lang.pick(
      '${result.inserted} yeni eklendi, ${result.updated} güncellendi$unchangedSuffix.',
      '${result.inserted} added, ${result.updated} updated$unchangedSuffix.',
    );

    if (result.unmatchedTitles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(summary)),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          lang.pick(
            'Letterboxd İçe Aktarma Tamamlandı',
            'Letterboxd Import Completed',
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(summary),
              const SizedBox(height: 12),
              Text(
                lang.pick(
                  'TMDB\'de eşleşmeyen başlıklar (${result.unmatchedTitles.length}):',
                  'Titles not matched on TMDB (${result.unmatchedTitles.length}):',
                ),
                style: Theme.of(ctx).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      result.unmatchedTitles.map((t) => '• $t').join('\n'),
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(lang.pick('Tamam', 'OK')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storedKeyAsync = ref.watch(storedApiKeyProvider);
    final apiKeyState = ref.watch(apiKeyProvider);
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final lang = ref.watch(currentLanguageProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!_initializedFromStore && storedKeyAsync.hasValue) {
      _initializedFromStore = true;
      _keyController.text = storedKeyAsync.value ?? '';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.pick('TMDB API Anahtarı', 'TMDB API Key'),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lang.pick(
                          'Anahtar yalnızca yerel veritabanında saklanır; JSON yedeklerine ve loglara dahil edilmez.',
                          'Your key is stored only in the local database; it is never included in JSON backups or logs.',
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (apiKeyState.source == ApiKeySource.environment) ...[
                        const SizedBox(height: 8),
                        Text(
                          lang.pick(
                            'Şu anda --dart-define ile verilen geliştirici anahtarı kullanılıyor.',
                            'Currently using the developer key provided via --dart-define.',
                          ),
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        controller: _keyController,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: lang.pick(
                            'TMDB API Anahtarı (v3 veya v4 Okuma Jetonu)',
                            'TMDB API Key (v3 or v4 Read Access Token)',
                          ),
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? lang.pick('Göster', 'Show')
                                : lang.pick('Gizle', 'Hide'),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      if (_keyFeedback != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _keyFeedback!,
                          style: TextStyle(
                            color: _keyFeedbackIsError
                                ? scheme.error
                                : scheme.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed:
                                _testing ? null : () => _testAndSaveKey(lang),
                            icon: _testing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.verified_outlined),
                            label: Text(
                              lang.pick(
                                'Doğrula ve Kaydet',
                                'Verify & Save',
                              ),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: _testing ? null : () => _saveKey(lang),
                            child: Text(
                              lang.pick(
                                'Doğrulamadan Kaydet',
                                'Save Without Verifying',
                              ),
                            ),
                          ),
                          if ((storedKeyAsync.value ?? '').isNotEmpty)
                            TextButton(
                              onPressed: _testing
                                  ? null
                                  : () {
                                      _keyController.clear();
                                      _saveKey(lang);
                                    },
                              child: Text(
                                lang.pick('Anahtarı Sil', 'Delete Key'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.pick('Dil ve Görünüm', 'Language & Appearance'),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        lang.pick('Uygulama Dili', 'App Language'),
                        style: textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<AppLanguage>(
                        segments: [
                          for (final item in AppLanguage.values)
                            ButtonSegment<AppLanguage>(
                              value: item,
                              icon: const Icon(Icons.language_outlined),
                              label: Text(item.displayName),
                            ),
                        ],
                        selected: {lang},
                        onSelectionChanged: (selection) {
                          ref.read(settingsDaoProvider).write(
                                SettingKeys.language,
                                selection.first.name,
                              );
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(
                        lang.pick('Tema', 'Theme'),
                        style: textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<ThemeMode>(
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: const Icon(Icons.brightness_auto_outlined),
                            label: Text(lang.pick('Sistem', 'System')),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: const Icon(Icons.light_mode_outlined),
                            label: Text(lang.pick('Açık', 'Light')),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: const Icon(Icons.dark_mode_outlined),
                            label: Text(lang.pick('Koyu', 'Dark')),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (selection) {
                          ref.read(settingsDaoProvider).write(
                                SettingKeys.themeMode,
                                selection.first.name,
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.pick(
                          'Yedekleme ve Veri Aktarımı',
                          'Backup & Data Transfer',
                        ),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lang.pick(
                          'Kütüphaneni, puanlarını, notlarını ve bölüm ilerlemeni JSON dosyası olarak dışa veya içe aktarabilirsin.',
                          'Export or import your library, ratings, notes, and episode progress as a JSON file.',
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => _exportBackup(lang),
                            icon: const Icon(Icons.upload_file_outlined),
                            label: Text(
                              lang.pick('JSON Dışa Aktar', 'Export JSON'),
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _importBackup(lang),
                            icon: const Icon(Icons.download_outlined),
                            label: Text(
                              lang.pick('JSON İçe Aktar', 'Import JSON'),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1),
                      ),
                      Text(
                        lang.pick(
                          'Letterboxd\'dan İçe Aktar',
                          'Import from Letterboxd',
                        ),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lang.pick(
                          'Letterboxd "Export Your Data" ile indirdiğin .zip arşivini veya çıkardığın CSV dosyalarını (watched, watchlist, ratings, diary, reviews) seçerek filmlerini, puanlarını, yorumlarını ve favorilerini aktarabilirsin.',
                          'Select the .zip archive downloaded from Letterboxd "Export Your Data" or extracted CSV files (watched, watchlist, ratings, diary, reviews) to import your films, ratings, reviews, and favorites.',
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: _importingLetterboxd
                            ? null
                            : () => _importLetterboxd(lang),
                        icon: const Icon(Icons.movie_filter_outlined),
                        label: Text(
                          lang.pick(
                            'Letterboxd (.zip / .csv) İçe Aktar',
                            'Import Letterboxd (.zip / .csv)',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: scheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SelectableText(
                          kTmdbAttributionText,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LetterboxdProgressState {
  const _LetterboxdProgressState({
    required this.processed,
    required this.total,
    required this.currentTitle,
  });

  final int processed;
  final int total;
  final String currentTitle;
}

class _LetterboxdProgressDialog extends StatefulWidget {
  const _LetterboxdProgressDialog({
    required this.lang,
    required this.progress,
    required this.onCancel,
  });

  final AppLanguage lang;
  final ValueNotifier<_LetterboxdProgressState> progress;
  final VoidCallback onCancel;

  @override
  State<_LetterboxdProgressDialog> createState() =>
      _LetterboxdProgressDialogState();
}

class _LetterboxdProgressDialogState extends State<_LetterboxdProgressDialog> {
  bool _cancelling = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(
          widget.lang.pick(
            'Letterboxd İçe Aktarılıyor',
            'Importing from Letterboxd',
          ),
        ),
        content: SizedBox(
          width: 380,
          child: ValueListenableBuilder<_LetterboxdProgressState>(
            valueListenable: widget.progress,
            builder: (context, state, _) {
              final hasTotal = state.total > 0;
              final ratio = hasTotal ? state.processed / state.total : null;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lang.pick(
                      'Filmler TMDB üzerinden eşleştiriliyor...',
                      'Matching films on TMDB...',
                    ),
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(value: ratio),
                  const SizedBox(height: 10),
                  if (hasTotal)
                    Text(
                      '${state.processed} / ${state.total}'
                      '${state.currentTitle.isNotEmpty ? ' — ${state.currentTitle}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: _cancelling
                ? null
                : () {
                    setState(() => _cancelling = true);
                    widget.onCancel();
                  },
            child: Text(
              _cancelling
                  ? widget.lang.pick('İptal ediliyor...', 'Cancelling...')
                  : widget.lang.pick('İptal', 'Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}

