import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/settings_dao.dart';
import '../../../core/l10n/app_language.dart';
import '../../../core/network/tmdb_client.dart';
import '../../../core/settings/app_settings_providers.dart';
import '../../backup/data/backup_codec.dart';
import '../../backup/data/backup_service.dart';

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
                        lang.pick('Yedekleme (JSON)', 'Backup (JSON)'),
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

