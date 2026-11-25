import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const int kMaxZipArchiveBytes = 50 * 1024 * 1024;
const int _maxZipEntries = 500;
const int _maxSingleUncompressedBytes = 20 * 1024 * 1024;
const int _maxTotalUncompressedBytes = 50 * 1024 * 1024;

const int _eocdSignature = 0x06054b50;
const int _centralDirSignature = 0x02014b50;
const int _localFileSignature = 0x04034b50;
const int _maxZipCommentLength = 0xFFFF;
const int _eocdMinLength = 22;

const int _methodStore = 0;
const int _methodDeflate = 8;

class ZipFormatException implements Exception {
  const ZipFormatException(this.messageTr, this.messageEn);

  final String messageTr;
  final String messageEn;

  @override
  String toString() => 'ZipFormatException: $messageEn';
}

/// Zero-dependency, memory-bounded ZIP text extractor with Zip-Slip and
/// streaming Zip-Bomb protection. Never touches the filesystem.
abstract final class ZipArchiveReader {
  static Map<String, String> extractTextFiles(
    Uint8List archiveBytes, {
    required bool Function(String normalizedPath) shouldExtract,
  }) {
    if (archiveBytes.length > kMaxZipArchiveBytes) {
      throw const ZipFormatException(
        'ZIP arşivi çok büyük (en fazla 50 MB).',
        'ZIP archive is too large (max 50 MB).',
      );
    }
    if (archiveBytes.length < _eocdMinLength) {
      throw const ZipFormatException(
        'Seçilen dosya geçerli bir ZIP arşivi değil.',
        'Selected file is not a valid ZIP archive.',
      );
    }

    final view = ByteData.sublistView(archiveBytes);
    final eocdOffset = _findEndOfCentralDirectory(archiveBytes, view);
    if (eocdOffset < 0) {
      throw const ZipFormatException(
        'ZIP arşivi bozuk veya desteklenmeyen bir formatta.',
        'ZIP archive is corrupted or uses an unsupported format.',
      );
    }

    final diskNumber = view.getUint16(eocdOffset + 4, Endian.little);
    final cdDiskNumber = view.getUint16(eocdOffset + 6, Endian.little);
    if (diskNumber != 0 || cdDiskNumber != 0) {
      throw const ZipFormatException(
        'Çok parçalı ZIP arşivleri desteklenmiyor.',
        'Multi-part ZIP archives are not supported.',
      );
    }

    final totalEntries = view.getUint16(eocdOffset + 10, Endian.little);
    final cdSize = view.getUint32(eocdOffset + 12, Endian.little);
    final cdOffset = view.getUint32(eocdOffset + 16, Endian.little);

    if (totalEntries == 0xFFFF ||
        cdSize == 0xFFFFFFFF ||
        cdOffset == 0xFFFFFFFF) {
      throw const ZipFormatException(
        'ZIP64 arşiv formatı desteklenmiyor.',
        'ZIP64 archive format is not supported.',
      );
    }
    if (totalEntries > _maxZipEntries) {
      throw const ZipFormatException(
        'ZIP arşivinde çok fazla dosya var.',
        'ZIP archive contains too many files.',
      );
    }
    if (cdOffset + cdSize > eocdOffset) {
      throw const ZipFormatException(
        'ZIP merkezi dizini bozuk.',
        'ZIP central directory is corrupted.',
      );
    }

    final result = <String, String>{};
    var cursor = cdOffset;
    var totalUncompressed = 0;

    for (var i = 0; i < totalEntries; i++) {
      if (cursor + 46 > eocdOffset) {
        throw const ZipFormatException(
          'ZIP merkezi dizin kaydı eksik.',
          'ZIP central directory entry is truncated.',
        );
      }
      final sig = view.getUint32(cursor, Endian.little);
      if (sig != _centralDirSignature) {
        throw const ZipFormatException(
          'ZIP merkezi dizin imzası geçersiz.',
          'Invalid ZIP central directory signature.',
        );
      }

      final flags = view.getUint16(cursor + 8, Endian.little);
      final method = view.getUint16(cursor + 10, Endian.little);
      final compressedSize = view.getUint32(cursor + 20, Endian.little);
      final uncompressedSize = view.getUint32(cursor + 24, Endian.little);
      final fileNameLen = view.getUint16(cursor + 28, Endian.little);
      final extraLen = view.getUint16(cursor + 30, Endian.little);
      final commentLen = view.getUint16(cursor + 32, Endian.little);
      final localHeaderOffset = view.getUint32(cursor + 42, Endian.little);

      final nameStart = cursor + 46;
      final nextCursor = nameStart + fileNameLen + extraLen + commentLen;
      if (nextCursor > eocdOffset) {
        throw const ZipFormatException(
          'ZIP dosya adı alanı bozuk.',
          'ZIP file name entry is corrupted.',
        );
      }

      final rawName = utf8.decode(
        Uint8List.sublistView(archiveBytes, nameStart, nameStart + fileNameLen),
        allowMalformed: true,
      );
      cursor = nextCursor;

      final normalizedPath = _normalizeSafePath(rawName);
      if (normalizedPath == null || !shouldExtract(normalizedPath)) {
        continue;
      }

      // Bit 0 indicates an encrypted entry.
      if ((flags & 0x01) != 0) {
        throw const ZipFormatException(
          'Şifreli ZIP arşivleri desteklenmiyor.',
          'Password-protected ZIP archives are not supported.',
        );
      }

      if (uncompressedSize > _maxSingleUncompressedBytes) {
        throw const ZipFormatException(
          'ZIP içindeki CSV dosyası çok büyük (>20 MB).',
          'CSV file inside ZIP is too large (>20 MB).',
        );
      }

      final compressedSlice = _readLocalEntrySlice(
        archiveBytes,
        view,
        localHeaderOffset: localHeaderOffset,
        compressedSize: compressedSize,
        cdEndOffset: cdOffset,
      );

      final Uint8List decompressed;
      if (method == _methodStore) {
        if (compressedSlice.length > _maxSingleUncompressedBytes ||
            totalUncompressed + compressedSlice.length >
                _maxTotalUncompressedBytes) {
          throw const ZipFormatException(
            'ZIP arşivi açıldığında izin verilen boyut sınırını aşıyor.',
            'Uncompressed ZIP data exceeds the maximum allowed size.',
          );
        }
        decompressed = compressedSlice;
      } else if (method == _methodDeflate) {
        decompressed = _inflateBounded(
          compressedSlice,
          remainingTotalBudget: _maxTotalUncompressedBytes - totalUncompressed,
        );
      } else {
        throw const ZipFormatException(
          'Desteklenmeyen ZIP sıkıştırma yöntemi.',
          'Unsupported ZIP compression method.',
        );
      }

      totalUncompressed += decompressed.length;
      result[normalizedPath] = _decodeUtf8StripBom(decompressed);
    }

    return result;
  }

  static int _findEndOfCentralDirectory(Uint8List bytes, ByteData view) {
    final minOffset = bytes.length - _eocdMinLength - _maxZipCommentLength;
    final stop = minOffset < 0 ? 0 : minOffset;
    for (var pos = bytes.length - _eocdMinLength; pos >= stop; pos--) {
      if (view.getUint32(pos, Endian.little) == _eocdSignature) {
        final commentLen = view.getUint16(pos + 20, Endian.little);
        if (pos + _eocdMinLength + commentLen == bytes.length) {
          return pos;
        }
      }
    }
    return -1;
  }

  /// Normalizes slashes and rejects directory entries or Zip-Slip (`..`) paths.
  static String? _normalizeSafePath(String rawName) {
    if (rawName.isEmpty || rawName.contains('\u0000')) return null;
    var path = rawName.replaceAll('\\', '/').trim();
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.isEmpty || path.endsWith('/')) return null;
    final segments = path.split('/');
    for (final seg in segments) {
      if (seg.isEmpty || seg == '.' || seg == '..') return null;
    }
    return segments.join('/');
  }

  static Uint8List _readLocalEntrySlice(
    Uint8List archiveBytes,
    ByteData view, {
    required int localHeaderOffset,
    required int compressedSize,
    required int cdEndOffset,
  }) {
    if (localHeaderOffset + 30 > cdEndOffset) {
      throw const ZipFormatException(
        'ZIP yerel dosya başlığı bozuk.',
        'ZIP local file header is corrupted.',
      );
    }
    final sig = view.getUint32(localHeaderOffset, Endian.little);
    if (sig != _localFileSignature) {
      throw const ZipFormatException(
        'ZIP yerel dosya imzası geçersiz.',
        'Invalid ZIP local file signature.',
      );
    }
    final localNameLen = view.getUint16(localHeaderOffset + 26, Endian.little);
    final localExtraLen = view.getUint16(localHeaderOffset + 28, Endian.little);
    final dataStart = localHeaderOffset + 30 + localNameLen + localExtraLen;
    final dataEnd = dataStart + compressedSize;
    if (dataStart < 0 || dataEnd > cdEndOffset) {
      throw const ZipFormatException(
        'ZIP veri bloğu sınırları geçersiz.',
        'ZIP entry data bounds are invalid.',
      );
    }
    return Uint8List.sublistView(archiveBytes, dataStart, dataEnd);
  }

  static Uint8List _inflateBounded(
    Uint8List compressed, {
    required int remainingTotalBudget,
  }) {
    final maxAllowed = remainingTotalBudget < _maxSingleUncompressedBytes
        ? remainingTotalBudget
        : _maxSingleUncompressedBytes;
    if (maxAllowed <= 0) {
      throw const ZipFormatException(
        'ZIP arşivi açıldığında izin verilen boyut sınırını aşıyor.',
        'Uncompressed ZIP data exceeds the maximum allowed size.',
      );
    }

    final builder = BytesBuilder(copy: false);
    final outSink = ByteConversionSink.withCallback(( _) {});
    final boundedSink = _BoundedByteSink(builder, maxAllowed, outSink);

    try {
      final inputSink =
          ZLibDecoder(raw: true).startChunkedConversion(boundedSink);
      const chunkSize = 16 * 1024;
      for (var offset = 0; offset < compressed.length; offset += chunkSize) {
        final end = offset + chunkSize < compressed.length
            ? offset + chunkSize
            : compressed.length;
        inputSink.addSlice(compressed, offset, end, end == compressed.length);
      }
      inputSink.close();
    } on ZipFormatException {
      rethrow;
    } catch (_) {
      throw const ZipFormatException(
        'ZIP sıkıştırılmış verisi açılamadı.',
        'Failed to decompress ZIP entry.',
      );
    }

    return builder.takeBytes();
  }

  static String _decodeUtf8StripBom(Uint8List bytes) {
    final text = utf8.decode(bytes);
    return text.startsWith('\uFEFF') ? text.substring(1) : text;
  }
}

class _BoundedByteSink extends ByteConversionSinkBase {
  _BoundedByteSink(this._builder, this._maxBytes, this._delegate);

  final BytesBuilder _builder;
  final int _maxBytes;
  final ByteConversionSink _delegate;
  int _total = 0;

  @override
  void add(List<int> chunk) {
    _total += chunk.length;
    if (_total > _maxBytes) {
      throw const ZipFormatException(
        'ZIP arşivi açıldığında izin verilen boyut sınırını aşıyor.',
        'Uncompressed ZIP data exceeds the maximum allowed size.',
      );
    }
    _builder.add(chunk);
  }

  @override
  void close() => _delegate.close();
}
