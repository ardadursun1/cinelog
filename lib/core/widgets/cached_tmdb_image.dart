import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../database/app_database.dart';
import '../network/tmdb_models.dart';

/// Local disk-backed TMDB image cache with strict path sanitization, in-flight
/// request deduplication, atomic temp-file writes, and bounded LRU pruning.
abstract final class TmdbImageCache {
  static const int _maxCacheFiles = 900;
  static const int _maxCacheBytes = 150 * 1024 * 1024;
  static const int _maxSingleImageBytes = 8 * 1024 * 1024;
  static final RegExp _safeSizePattern = RegExp(r'^(w92|w185|w342|w500)$');

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.bytes,
    ),
  );

  static Future<Directory?>? _cacheDirFuture;
  static final Map<String, Future<File?>> _inFlight = {};
  static bool _prunedThisSession = false;

  static Future<File?> resolve(String rawPath, {String size = 'w342'}) async {
    final safePath = sanitizePosterPath(rawPath);
    if (safePath == null || !_safeSizePattern.hasMatch(size)) return null;

    final dir = await _getCacheDir();
    if (dir == null) return null;

    // Flatten "/abc_123.jpg" -> "w342_abc_123.jpg" so subdirectories/traversal are impossible.
    final fileName = '${size}_${safePath.substring(1)}';
    final file = File(p.join(dir.path, fileName));

    try {
      if (await file.exists() && await file.length() > 0) {
        return file;
      }
    } catch (_) {
      return null;
    }

    return _inFlight.putIfAbsent(
      fileName,
      () => _downloadAndStore(safePath, size, file).whenComplete(() {
        _inFlight.remove(fileName);
      }),
    );
  }

  static Future<Directory?> _getCacheDir() {
    return _cacheDirFuture ??= () async {
      try {
        final base = await AppDatabase.dataDirectory();
        final dir = Directory(p.join(base.path, 'poster_cache'));
        await dir.create(recursive: true);
        if (!_prunedThisSession) {
          _prunedThisSession = true;
          unawaited(_pruneIfNeeded(dir));
        }
        return dir;
      } catch (_) {
        return null;
      }
    }();
  }

  static Future<File?> _downloadAndStore(
    String safePath,
    String size,
    File target,
  ) async {
    final tmp = File('${target.path}.tmp');
    try {
      final response = await _dio.get<List<int>>(
        tmdbPosterUrl(safePath, size: size),
      );
      final data = response.data;
      if (data == null ||
          data.isEmpty ||
          data.length > _maxSingleImageBytes) {
        return null;
      }
      await tmp.writeAsBytes(Uint8List.fromList(data), flush: true);
      await tmp.rename(target.path);
      return target;
    } catch (_) {
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
      return null;
    }
  }

  static Future<void> _pruneIfNeeded(Directory dir) async {
    try {
      final entries = <({File file, int size, DateTime modified})>[];
      var totalBytes = 0;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        if (entity.path.endsWith('.tmp')) {
          try {
            await entity.delete();
          } catch (_) {}
          continue;
        }
        final stat = await entity.stat();
        totalBytes += stat.size;
        entries.add((
          file: entity,
          size: stat.size,
          modified: stat.modified,
        ));
      }

      if (entries.length <= _maxCacheFiles && totalBytes <= _maxCacheBytes) {
        return;
      }

      entries.sort((a, b) => a.modified.compareTo(b.modified));
      var remainingFiles = entries.length;
      for (final entry in entries) {
        if (remainingFiles <= (_maxCacheFiles * 0.8).round() &&
            totalBytes <= (_maxCacheBytes * 0.8).round()) {
          break;
        }
        try {
          await entry.file.delete();
          totalBytes -= entry.size;
          remainingFiles--;
        } catch (_) {}
      }
    } catch (_) {}
  }
}

class CachedTmdbImage extends StatefulWidget {
  const CachedTmdbImage({
    super.key,
    required this.imagePath,
    this.size = 'w342',
    this.cacheWidth,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.movie_outlined,
    this.placeholderIconSize = 42,
  });

  final String? imagePath;
  final String size;
  final int? cacheWidth;
  final BoxFit fit;
  final IconData placeholderIcon;
  final double placeholderIconSize;

  @override
  State<CachedTmdbImage> createState() => _CachedTmdbImageState();
}

class _CachedTmdbImageState extends State<CachedTmdbImage> {
  Future<File?>? _fileFuture;

  @override
  void initState() {
    super.initState();
    _resolveFile();
  }

  @override
  void didUpdateWidget(covariant CachedTmdbImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.size != widget.size) {
      _resolveFile();
    }
  }

  void _resolveFile() {
    final safe = sanitizePosterPath(widget.imagePath);
    _fileFuture = safe != null
        ? TmdbImageCache.resolve(safe, size: widget.size)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final safePath = sanitizePosterPath(widget.imagePath);
    if (safePath == null) {
      return _buildPlaceholder(scheme, widget.placeholderIcon);
    }

    return FutureBuilder<File?>(
      future: _fileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ColoredBox(
            color: scheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final file = snapshot.data;
        if (file != null) {
          return Image.file(
            file,
            fit: widget.fit,
            cacheWidth: widget.cacheWidth,
            errorBuilder: (_, _, _) =>
                _buildPlaceholder(scheme, Icons.broken_image_outlined),
          );
        }

        // Fallback to direct network load (e.g. if local directory is unavailable).
        return Image.network(
          tmdbPosterUrl(safePath, size: widget.size),
          fit: widget.fit,
          cacheWidth: widget.cacheWidth,
          errorBuilder: (_, _, _) =>
              _buildPlaceholder(scheme, Icons.broken_image_outlined),
        );
      },
    );
  }

  Widget _buildPlaceholder(ColorScheme scheme, IconData icon) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        icon,
        size: widget.placeholderIconSize,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
