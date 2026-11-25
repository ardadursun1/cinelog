import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_tracker/core/database/app_database.dart';
import 'package:movie_tracker/core/database/settings_dao.dart';
import 'package:movie_tracker/core/database/tables.dart';
import 'package:movie_tracker/core/models/media_type.dart';
import 'package:movie_tracker/core/models/title_summary.dart';
import 'package:movie_tracker/core/network/tmdb_client.dart';
import 'package:movie_tracker/core/settings/app_settings_providers.dart';
import 'package:movie_tracker/features/backup/data/letterboxd_codec.dart';
import 'package:movie_tracker/features/backup/data/letterboxd_import_service.dart';
import 'package:movie_tracker/features/library/data/library_dao.dart';
import 'package:movie_tracker/features/library/domain/watch_status.dart';

/// Builds a real standard PKZIP archive in memory using both Deflate (8) and Store (0).
Uint8List _buildTestZip(
  Map<String, String> files, {
  bool deflate = true,
}) {
  final out = BytesBuilder();
  final centralDir = BytesBuilder();
  var localOffset = 0;
  var count = 0;

  for (final entry in files.entries) {
    count++;
    final nameBytes = utf8.encode(entry.key);
    final rawData = utf8.encode(entry.value);
    final method = deflate ? 8 : 0;
    final compressedData = deflate
        ? Uint8List.fromList(ZLibEncoder(raw: true).convert(rawData))
        : Uint8List.fromList(rawData);

    // Local file header (30 bytes + filename + payload)
    final localHeader = ByteData(30)
      ..setUint32(0, 0x04034b50, Endian.little)
      ..setUint16(4, 20, Endian.little)
      ..setUint16(6, 0x0800, Endian.little) // UTF-8 flag
      ..setUint16(8, method, Endian.little)
      ..setUint16(10, 0, Endian.little)
      ..setUint16(12, 0, Endian.little)
      ..setUint32(14, 0, Endian.little)
      ..setUint32(18, compressedData.length, Endian.little)
      ..setUint32(22, rawData.length, Endian.little)
      ..setUint16(26, nameBytes.length, Endian.little)
      ..setUint16(28, 0, Endian.little);

    out
      ..add(localHeader.buffer.asUint8List())
      ..add(nameBytes)
      ..add(compressedData);

    // Central directory header (46 bytes + filename)
    final cdHeader = ByteData(46)
      ..setUint32(0, 0x02014b50, Endian.little)
      ..setUint16(4, 20, Endian.little)
      ..setUint16(6, 20, Endian.little)
      ..setUint16(8, 0x0800, Endian.little)
      ..setUint16(10, method, Endian.little)
      ..setUint16(12, 0, Endian.little)
      ..setUint16(14, 0, Endian.little)
      ..setUint32(16, 0, Endian.little)
      ..setUint32(20, compressedData.length, Endian.little)
      ..setUint32(24, rawData.length, Endian.little)
      ..setUint16(28, nameBytes.length, Endian.little)
      ..setUint16(30, 0, Endian.little)
      ..setUint16(32, 0, Endian.little)
      ..setUint16(34, 0, Endian.little)
      ..setUint16(36, 0, Endian.little)
      ..setUint32(38, 0, Endian.little)
      ..setUint32(42, localOffset, Endian.little);

    centralDir
      ..add(cdHeader.buffer.asUint8List())
      ..add(nameBytes);

    localOffset += 30 + nameBytes.length + compressedData.length;
  }

  final cdBytes = centralDir.takeBytes();
  final eocd = ByteData(22)
    ..setUint32(0, 0x06054b50, Endian.little)
    ..setUint16(4, 0, Endian.little)
    ..setUint16(6, 0, Endian.little)
    ..setUint16(8, count, Endian.little)
    ..setUint16(10, count, Endian.little)
    ..setUint32(12, cdBytes.length, Endian.little)
    ..setUint32(16, localOffset, Endian.little)
    ..setUint16(20, 0, Endian.little);

  out
    ..add(cdBytes)
    ..add(eocd.buffer.asUint8List());
  return out.takeBytes();
}

TmdbClient _buildFakeTmdbClient({
  required Object? Function(RequestOptions options) responder,
}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final payload = responder(options);
        if (payload is DioException) {
          handler.reject(payload);
          return;
        }
        handler.resolve(
          Response<Object?>(
            requestOptions: options,
            statusCode: 200,
            data: payload,
          ),
        );
      },
    ),
  );
  return TmdbClient('FAKE_TEST_KEY', language: 'tr-TR', dio: dio);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('LetterboxdCodec & ZipArchiveReader', () {
    test(
        'extracts deflated Letterboxd ZIP, merges CSVs, cleans HTML reviews, '
        'and ignores deleted/lists/zip-slip entries', () {
      final longTail = 'harika ' * 90;
      final zipBytes = _buildTestZip({
        'watched.csv': '\uFEFFDate,Name,Year,Letterboxd URI\r\n'
            '2024-01-10,"Three Billboards Outside Ebbing, Missouri",2017,https://boxd.it/bill\r\n'
            '2024-02-01,Spirited Away,2001,https://boxd.it/spirit\r\n',
        'watchlist.csv': 'Date,Name,Year,Letterboxd URI\n'
            '2023-12-01,Spirited Away,2001,https://boxd.it/spirit\n'
            '2024-03-05,Dune: Part Two,2024,https://boxd.it/dune2\n',
        'ratings.csv': 'Date,Name,Year,Letterboxd URI,Rating\n'
            '2024-02-02,Spirited Away,2001,https://boxd.it/spirit,4.5\n'
            '2024-01-10,"Three Billboards Outside Ebbing, Missouri",2017,https://boxd.it/bill,0.5\n',
        'diary.csv':
            'Date,Name,Year,Letterboxd URI,Rating,Rewatch,Tags,Watched Date\n'
            '2024-02-01,Spirited Away,2001,https://boxd.it/d1,4.0,,anime,2023-11-20\n'
            '2024-05-10,Spirited Away,2001,https://boxd.it/d2,5.0,Yes,anime,2024-05-09\n',
        'reviews.csv':
            'Date,Name,Year,Letterboxd URI,Rating,Rewatch,Review,Tags,Watched Date\n'
            '2024-05-10,Spirited Away,2001,https://boxd.it/r1,5.0,Yes,"<p>Büyülü &amp; ""zamansız"" bir başyapıt.<br/>$longTail</p>",anime,2024-05-09\n',
        'likes/films.csv': 'Date,Name,Year,Letterboxd URI\n'
            '2024-02-02,Spirited Away,2001,https://boxd.it/spirit\n',
        // Ignored / untrusted paths:
        'likes/reviews.csv': 'Date,Name,Year,Letterboxd URI\n'
            '2024-01-01,Ignored Liked Review,2020,https://boxd.it/x\n',
        'deleted/diary.csv':
            'Date,Name,Year,Letterboxd URI,Rating,Rewatch,Tags,Watched Date\n'
            '2024-01-01,Deleted Movie,2019,https://boxd.it/del,5.0,,,2024-01-01\n',
        'lists/top-10.csv': 'Date,Name,Year,Letterboxd URI\n'
            '2024-01-01,List Only Movie,1999,https://boxd.it/lst\n',
        '../../evil/watched.csv': 'Date,Name,Year,Letterboxd URI\n'
            '2024-01-01,Evil Traversal,2020,https://boxd.it/evil\n',
      });

      final result = LetterboxdCodec.decodeZipArchive(zipBytes);
      expect(result.entries, hasLength(3));

      final byName = {for (final e in result.entries) e.name: e};

      final spirited = byName['Spirited Away']!;
      // Watched wins over watchlist; authoritative rating (4.5 -> 9) wins over diary.
      expect(spirited.status, WatchStatus.watched);
      expect(spirited.userRating, 9);
      expect(spirited.isFavorite, isTrue);
      expect(spirited.watchedAt, DateTime(2024, 5, 9));
      expect(spirited.addedAt, DateTime(2023, 12, 1));
      expect(spirited.note, isNotNull);
      expect(
        spirited.note,
        startsWith('Büyülü & "zamansız" bir başyapıt.\n'),
      );
      expect(spirited.note!.length, lessThanOrEqualTo(kNoteMaxLength));
      expect(spirited.note!.endsWith('…'), isTrue);

      final billboards =
          byName['Three Billboards Outside Ebbing, Missouri']!;
      expect(billboards.status, WatchStatus.watched);
      expect(billboards.userRating, 1); // 0.5 stars -> 1/10

      final dune = byName['Dune: Part Two']!;
      expect(dune.status, WatchStatus.planned);
      expect(dune.userRating, isNull);
      expect(dune.watchedAt, isNull);
    });

    test('rejects corrupted ZIP bytes cleanly', () {
      expect(
        () => LetterboxdCodec.decodeZipArchive(
          Uint8List.fromList([1, 2, 3, 4, 5]),
        ),
        throwsA(isA<LetterboxdFormatException>()),
      );
    });
  });

  group('LetterboxdImportService end-to-end', () {
    late AppDatabase db;
    late LibraryDao libraryDao;
    late SettingsDao settingsDao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      libraryDao = LibraryDao(db);
      settingsDao = SettingsDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
        'matches localized foreign films, falls back to TV miniseries, '
        'merges non-destructively, and skips network on re-import', () async {
      // Pre-populate an existing watched movie with a personal note to verify
      // non-destructive merging when Letterboxd only has it in watchlist/ratings.
      final existingId = await libraryDao.add(
        const TitleSummary(
          tmdbId: 693134,
          mediaType: MediaType.movie,
          title: 'Dune: Çöl Gezegeni Bölüm İki',
          originalTitle: 'Dune: Part Two',
          releaseYear: 2024,
          genres: [Genre(878, 'Bilim-Kurgu')],
        ),
        WatchStatus.watched,
      );
      await libraryDao.setNote(existingId, 'IMAX salonunda izlendi');

      var searchCalls = 0;
      final fakeClient = _buildFakeTmdbClient(
        responder: (options) {
          final path = options.path;
          final q = options.queryParameters;

          if (path == 'genre/movie/list') {
            return {
              'genres': [
                {'id': 16, 'name': 'Animasyon'},
                {'id': 18, 'name': 'Dram'},
              ],
            };
          }
          if (path == 'genre/tv/list') {
            return {
              'genres': [
                {'id': 18, 'name': 'Dram'},
              ],
            };
          }
          if (path == 'search/movie') {
            searchCalls++;
            final query = q['query'] as String?;
            if (query == 'Spirited Away') {
              // Localized Turkish title + Japanese original title:
              return {
                'page': 1,
                'total_pages': 1,
                'results': [
                  {
                    'id': 129,
                    'title': 'Ruhların Kaçışı',
                    'original_title': '千と千尋の神隠し',
                    'poster_path': '/spirited.jpg',
                    'overview': 'Chihiro ruhlar dünyasında.',
                    'release_date': '2001-07-20',
                    'vote_average': 8.5,
                    'vote_count': 16000,
                    'genre_ids': [16, 18],
                  },
                ],
              };
            }
            // Chernobyl & Unknown Film return empty on search/movie:
            return {'page': 1, 'total_pages': 0, 'results': <Object>[]};
          }
          if (path == 'search/multi') {
            searchCalls++;
            final query = q['query'] as String?;
            if (query == 'Chernobyl') {
              return {
                'page': 1,
                'total_pages': 1,
                'results': [
                  {
                    'id': 87108,
                    'media_type': 'tv',
                    'name': 'Chernobyl',
                    'original_name': 'Chernobyl',
                    'poster_path': '/chernobyl.jpg',
                    'first_air_date': '2019-05-06',
                    'vote_average': 8.7,
                    'vote_count': 6000,
                    'genre_ids': [18],
                  },
                ],
              };
            }
            return {'page': 1, 'total_pages': 0, 'results': <Object>[]};
          }
          if (path == 'tv/87108') {
            return {
              'seasons': [
                {
                  'season_number': 1,
                  'episode_count': 5,
                  'name': 'Mini Dizi',
                },
              ],
            };
          }
          return {'results': <Object>[]};
        },
      );

      final service = LetterboxdImportService(db, () => fakeClient);
      final zipBytes = _buildTestZip({
        'watched.csv': 'Date,Name,Year,Letterboxd URI\n'
            '2024-04-01,Spirited Away,2001,https://boxd.it/sp\n'
            '2024-04-02,Chernobyl,2019,https://boxd.it/ch\n'
            '2024-04-03,Nonexistent Obscure Film XYZ,2022,https://boxd.it/no\n',
        'watchlist.csv': 'Date,Name,Year,Letterboxd URI\n'
            '2024-01-01,Dune: Part Two,2024,https://boxd.it/d2\n',
        'ratings.csv': 'Date,Name,Year,Letterboxd URI,Rating\n'
            '2024-04-01,Spirited Away,2001,https://boxd.it/sp,5\n'
            '2024-04-05,Dune: Part Two,2024,https://boxd.it/d2,4.5\n',
        'likes/films.csv': 'Date,Name,Year,Letterboxd URI\n'
            '2024-04-01,Spirited Away,2001,https://boxd.it/sp\n',
      });

      final progressSteps = <int>[];
      final res = await service.importZipBytes(
        zipBytes,
        onProgress: (processed, total, _) => progressSteps.add(processed),
      );

      expect(progressSteps, hasLength(4));
      expect(res.inserted, 2); // Spirited Away + Chernobyl
      expect(res.updated, 1); // Dune: Part Two got rating=9 while keeping note & watched
      expect(res.unmatchedTitles, ['Nonexistent Obscure Film XYZ (2022)']);

      final entries = await libraryDao.watchEntries().first;
      expect(entries, hasLength(3));

      final byTmdb = {for (final e in entries) e.item.tmdbId: e};

      final spirited = byTmdb[129]!;
      expect(spirited.item.title, 'Ruhların Kaçışı');
      expect(spirited.item.userRating, 10);
      expect(spirited.genres.map((g) => g.name), containsAll(['Animasyon', 'Dram']));

      final chernobyl = byTmdb[87108]!;
      expect(chernobyl.item.mediaType, MediaType.tv);
      expect(chernobyl.item.status, WatchStatus.watched);
      expect(chernobyl.watchedEpisodeCount, 5);
      expect(chernobyl.totalEpisodeCount, 5);

      final dune = byTmdb[693134]!;
      expect(dune.item.status, WatchStatus.watched); // Never downgraded to planned
      expect(dune.item.userRating, 9);
      expect(dune.item.note, 'IMAX salonunda izlendi'); // Existing note preserved

      final favRaw = await settingsDao.watch(SettingKeys.favoriteTitles).first;
      expect(
        parseFavoriteTitleKeys(favRaw),
        contains((tmdbId: 129, mediaType: MediaType.movie)),
      );

      // Re-importing the matched titles hits local fast-path with 0 search calls!
      searchCalls = 0;
      final csvReimport = await service.importCsvFiles(const [
        (
          fileName: 'watched.csv',
          content: 'Date,Name,Year,Letterboxd URI\n'
              '2024-04-02,Chernobyl,2019,https://boxd.it/ch\n'
              '2024-04-05,Dune: Part Two,2024,https://boxd.it/d2\n',
        ),
      ]);
      expect(searchCalls, 0);
      expect(csvReimport.inserted, 0);
      expect(csvReimport.unchanged, 2);
    });
  });
}
