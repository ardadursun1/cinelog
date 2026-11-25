import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_tracker/core/database/app_database.dart';
import 'package:movie_tracker/core/database/settings_dao.dart';
import 'package:movie_tracker/core/l10n/app_language.dart';
import 'package:movie_tracker/core/models/content_category.dart';
import 'package:movie_tracker/core/models/media_type.dart';
import 'package:movie_tracker/core/models/title_summary.dart';
import 'package:movie_tracker/core/network/tmdb_client.dart';
import 'package:movie_tracker/core/network/tmdb_models.dart';
import 'package:movie_tracker/core/settings/app_settings_providers.dart';
import 'package:movie_tracker/features/backup/data/backup_codec.dart';
import 'package:movie_tracker/features/backup/data/backup_service.dart';
import 'package:movie_tracker/features/episodes/data/episode_dao.dart';
import 'package:movie_tracker/features/library/data/library_dao.dart';
import 'package:movie_tracker/features/library/data/library_service.dart';
import 'package:movie_tracker/features/library/domain/library_filter.dart';
import 'package:movie_tracker/features/library/domain/watch_status.dart';
import 'package:movie_tracker/features/stats/data/stats_dao.dart';

import 'package:drift/drift.dart' show driftRuntimeOptions;

AppDatabase _openInMemory() => AppDatabase(NativeDatabase.memory());

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  group('TmdbModels', () {
    test('sanitizes poster paths and ignores person results', () {
      expect(sanitizePosterPath('/abc_123.jpg'), '/abc_123.jpg');
      expect(sanitizePosterPath('https://evil.example/x.jpg'), isNull);
      expect(sanitizePosterPath('/../../etc/passwd'), isNull);

      final page = TmdbSearchPage.fromJson({
        'page': 1,
        'total_pages': 2,
        'results': [
          {'media_type': 'person', 'id': 9, 'name': 'Actor'},
          {
            'media_type': 'movie',
            'id': 42,
            'title': 'Inception',
            'original_title': 'Inception',
            'poster_path': '/poster.jpg',
            'overview': 'Dream heist',
            'release_date': '2010-07-16',
            'genre_ids': [28, 878],
          },
        ],
      });
      expect(page.results, hasLength(1));
      expect(page.results.first.title, 'Inception');
      expect(page.results.first.year, 2010);
    });

    test('parses watch providers and person filmography safely', () {
      final providers = WatchProvidersInfo.fromJson({
        'results': {
          'TR': {
            'link': 'https://www.themoviedb.org/movie/42/watch',
            'flatrate': [
              {
                'provider_id': 8,
                'provider_name': 'Netflix',
                'logo_path': '/netflix.jpg',
              },
            ],
            'rent': [
              {
                'provider_id': 8,
                'provider_name': 'Netflix',
                'logo_path': '/netflix.jpg',
              },
              {
                'provider_id': 2,
                'provider_name': 'Apple TV',
                'logo_path': 'https://evil.example/logo.png',
              },
            ],
          },
        },
      });
      expect(providers.region, 'TR');
      expect(providers.link, 'https://www.themoviedb.org/movie/42/watch');
      expect(providers.flatrate.single.name, 'Netflix');
      expect(providers.flatrate.single.logoPath, '/netflix.jpg');
      expect(providers.rent.single.name, 'Apple TV');
      expect(providers.rent.single.logoPath, isNull);

      final person = PersonDetails.fromJson(
        {
          'id': 525,
          'name': 'Christopher Nolan',
          'birthday': '1970-07-30',
          'combined_credits': {
            'cast': [
              {
                'id': 42,
                'media_type': 'movie',
                'title': 'Inception',
                'vote_count': 30000,
              },
            ],
            'crew': [
              {
                'id': 42,
                'media_type': 'movie',
                'title': 'Inception',
                'job': 'Director',
                'vote_count': 30000,
              },
              {
                'id': 157336,
                'media_type': 'movie',
                'title': 'Interstellar',
                'job': 'Director',
                'vote_count': 35000,
              },
            ],
          },
        },
        fallbackId: 525,
      );
      expect(person.name, 'Christopher Nolan');
      expect(person.birthYear, 1970);
      expect(person.credits, hasLength(2));
      expect(person.credits.first.title, 'Interstellar');
    });
  });

  group('Library, Episodes, Stats & Backup', () {
    late AppDatabase db;
    late LibraryDao libraryDao;
    late EpisodeDao episodeDao;
    late StatsDao statsDao;
    late BackupService backupService;
    late SettingsDao settingsDao;

    setUp(() {
      db = _openInMemory();
      libraryDao = LibraryDao(db);
      episodeDao = EpisodeDao(db, libraryDao);
      statsDao = StatsDao(db);
      backupService = BackupService(db);
      settingsDao = SettingsDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('completing all episodes automatically marks TV show as watched',
        () async {
      const show = TitleSummary(
        tmdbId: 100,
        mediaType: MediaType.tv,
        title: 'Mini Dizi',
        releaseYear: 2024,
        genres: [Genre(18, 'Dram')],
      );
      final id = await libraryDao.add(show, WatchStatus.planned);
      await episodeDao.replaceSeasons(id, const [
        SeasonInfo(number: 1, episodeCount: 3, name: 'Sezon 1'),
      ]);

      await episodeDao.setEpisode(id, (1, 1), watched: true);
      var item = await libraryDao.findById(id);
      expect(item?.status, WatchStatus.watching);

      var entry = (await libraryDao.watchEntries().first).single;
      expect(entry.progressLabel, 'S01E01 · 1/3');
      expect(entry.nextEpisode, (1, 2));
      expect(entry.nextEpisodeLabel, 'S01E02 → ✓');

      await episodeDao.markUpTo(id, (1, 3));
      item = await libraryDao.findById(id);
      expect(item?.status, WatchStatus.watched);
      expect(item?.watchedAt, isNotNull);

      entry = (await libraryDao.watchEntries().first).single;
      expect(entry.nextEpisode, isNull);

      final stats = await statsDao.watchStats().first;
      expect(stats.count(WatchStatus.watched, MediaType.tv), 1);
      expect(stats.watchedEpisodes, 3);
      expect(stats.genres.single.label, 'Dram');
      expect(stats.releaseYears.single.label, 2024);
    });

    test('backup export excludes API key and round-trips favorites & notes',
        () async {
      await settingsDao.write(SettingKeys.tmdbApiKey, 'SECRET_KEY_VALUE');
      await settingsDao.write(
        SettingKeys.favoriteTitles,
        serializeFavoriteTitleKeys([(tmdbId: 550, mediaType: MediaType.movie)]),
      );
      const movie = TitleSummary(
        tmdbId: 550,
        mediaType: MediaType.movie,
        title: 'Fight Club',
        releaseYear: 1999,
        posterPath: '/fight.jpg',
        genres: [Genre(18, 'Dram')],
      );
      final id = await libraryDao.add(movie, WatchStatus.watched);
      await libraryDao.setRating(id, 9);
      await libraryDao.setNote(id, 'Klasik');

      final json = await backupService.exportJson();
      expect(json.contains('SECRET_KEY_VALUE'), isFalse);

      final db2 = _openInMemory();
      addTearDown(db2.close);
      final res = await BackupService(db2).importJson(json);
      expect(res.inserted, 1);
      expect(res.errors, isEmpty);

      final entries = await LibraryDao(db2).watchEntries().first;
      expect(entries, hasLength(1));
      expect(entries.single.item.userRating, 9);
      expect(entries.single.item.note, 'Klasik');

      final favRaw =
          await SettingsDao(db2).watch(SettingKeys.favoriteTitles).first;
      final favs = parseFavoriteTitleKeys(favRaw);
      expect(favs, contains((tmdbId: 550, mediaType: MediaType.movie)));

      final filteredByQuery =
          const LibraryFilter(searchQuery: 'klasik', favoritesOnly: true)
              .apply(entries, favorites: favs);
      expect(filteredByQuery, hasLength(1));
    });

    test('backup codec rejects invalid root', () {
      expect(
        () => BackupCodec.decode('{"app":"other"}'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test(
        'clicking quick status button a second time removes entry and '
        'restoreRemoved recovers rating, note, episodes, and favorite',
        () async {
      final service = LibraryService(db, libraryDao, episodeDao, () => null);
      const show = TitleSummary(
        tmdbId: 1396,
        mediaType: MediaType.tv,
        title: 'Breaking Bad',
        releaseYear: 2008,
        genres: [Genre(18, 'Dram')],
      );

      // 1st click on + (planned) -> adds to library
      final first = await service.toggleQuickStatus(show, WatchStatus.planned);
      expect(first.outcome, QuickStatusOutcome.added);

      // Switch to watched, add rating, note, episode progress, and favorite
      final switched =
          await service.toggleQuickStatus(show, WatchStatus.watched);
      expect(switched.outcome, QuickStatusOutcome.updated);

      final item = (await libraryDao.findByKey(show.key))!;
      await libraryDao.setRating(item.id, 10);
      await libraryDao.setNote(item.id, 'Başyapıt');
      await episodeDao.replaceSeasons(item.id, const [
        SeasonInfo(number: 1, episodeCount: 7, name: 'Sezon 1'),
      ]);
      await episodeDao.markAll(item.id);
      await settingsDao.write(
        SettingKeys.favoriteTitles,
        serializeFavoriteTitleKeys([show.key]),
      );

      // 2nd click on ✓ (watched) -> removes from library and clears favorite
      final second =
          await service.toggleQuickStatus(show, WatchStatus.watched);
      expect(second.outcome, QuickStatusOutcome.removed);
      expect(second.removedSnapshot, isNotNull);
      expect(await libraryDao.findByKey(show.key), isNull);
      final favAfterRemove =
          await settingsDao.watch(SettingKeys.favoriteTitles).first;
      expect(parseFavoriteTitleKeys(favAfterRemove), isEmpty);

      // Undo -> restores everything losslessly
      await service.restoreRemoved(second.removedSnapshot!);
      final restored = (await libraryDao.watchEntries().first).single;
      expect(restored.item.status, WatchStatus.watched);
      expect(restored.item.userRating, 10);
      expect(restored.item.note, 'Başyapıt');
      expect(restored.watchedEpisodeCount, 7);
      final favAfterRestore =
          await settingsDao.watch(SettingKeys.favoriteTitles).first;
      expect(parseFavoriteTitleKeys(favAfterRestore), contains(show.key));
    });

    test(
        'excluding anime or kdrama preserves non-Japanese animations and '
        'non-Korean dramas', () async {
      final animeCat = kCategoryByKey['anime']!;
      final kdramaCat = kCategoryByKey['kdrama']!;

      const spiderVerse = TmdbSearchItem(
        id: 569094,
        mediaType: MediaType.movie,
        title: 'Spider-Verse',
        originalTitle: 'Spider-Man: Across the Spider-Verse',
        posterPath: '/sv.jpg',
        overview: '',
        year: 2023,
        voteAverage: 8.4,
        genreIds: [16, 28],
        originalLanguage: 'en',
      );
      const jujutsu = TmdbSearchItem(
        id: 95479,
        mediaType: MediaType.tv,
        title: 'Jujutsu Kaisen',
        originalTitle: '呪術廻戦',
        posterPath: '/jjk.jpg',
        overview: '',
        year: 2020,
        voteAverage: 8.5,
        genreIds: [16, 10759],
        originalLanguage: 'ja',
      );
      const squidGame = TmdbSearchItem(
        id: 93405,
        mediaType: MediaType.tv,
        title: 'Squid Game',
        originalTitle: '오징어 게임',
        posterPath: '/sg.jpg',
        overview: '',
        year: 2021,
        voteAverage: 7.8,
        genreIds: [18, 9648],
        originalLanguage: 'ko',
      );

      expect(animeCat.matchesExcluded(jujutsu), isTrue);
      expect(animeCat.matchesExcluded(spiderVerse), isFalse);
      expect(kdramaCat.matchesExcluded(squidGame), isTrue);
      expect(kdramaCat.matchesExcluded(spiderVerse), isFalse);

      Map<String, dynamic>? capturedQuery;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedQuery = Map<String, dynamic>.of(options.queryParameters);
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 200,
                data: {'page': 1, 'total_pages': 1, 'results': <Object>[]},
              ),
            );
          },
        ),
      );
      final client = TmdbClient('FAKE_KEY', dio: dio);
      addTearDown(client.close);

      await client.discover(
        MediaType.tv,
        sortByRating: true,
        excludedCategoryKeys: const {'anime'},
      );
      expect(capturedQuery?['without_genres'], isNull);
      expect(capturedQuery?['without_keywords'], '210024');
    });

    test(
        'nextEpisode fills gaps across seasons, stats merge bilingual genres '
        'and use actual runtimeMinutes, and merge-import preserves user edits',
        () async {
      // 1. Episode gap & planned status badge test
      const tv = TitleSummary(
        tmdbId: 200,
        mediaType: MediaType.tv,
        title: 'Gap Show',
        releaseYear: 2023,
      );
      final tvId = await libraryDao.add(tv, WatchStatus.watching);
      await libraryDao.setRuntimeMinutes(tvId, 30);
      await episodeDao.replaceSeasons(tvId, const [
        SeasonInfo(number: 1, episodeCount: 3, name: 'S1'),
        SeasonInfo(number: 2, episodeCount: 3, name: 'S2'),
      ]);
      await episodeDao.setEpisode(tvId, (1, 1), watched: true);
      await episodeDao.setEpisode(tvId, (2, 1), watched: true);

      var tvEntry = (await libraryDao.watchEntries().first)
          .singleWhere((e) => e.item.id == tvId);
      // Must suggest S01E02 (the first unwatched episode), NOT S02E02!
      expect(tvEntry.nextEpisode, (1, 2));

      await libraryDao.setStatus(tvId, WatchStatus.planned);
      tvEntry = (await libraryDao.watchEntries().first)
          .singleWhere((e) => e.item.id == tvId);
      expect(tvEntry.progressLabel, isNull);

      // 2. Bilingual genre merging & actual movie runtime test
      final m1 = await libraryDao.add(
        const TitleSummary(
          tmdbId: 601,
          mediaType: MediaType.movie,
          title: 'Interstellar',
          runtimeMinutes: 169,
          genres: [Genre(878, 'Bilim-Kurgu')],
        ),
        WatchStatus.watched,
      );
      await libraryDao.setRating(m1, 10);
      await libraryDao.setNote(m1, 'Mevcut not');

      await libraryDao.add(
        const TitleSummary(
          tmdbId: 602,
          mediaType: MediaType.movie,
          title: 'Arrival',
          runtimeMinutes: 116,
          genres: [Genre(878, 'Science Fiction')],
        ),
        WatchStatus.watched,
      );

      final stats = await statsDao.watchStats().first;
      // 169 + 116 (movies) + 2 watched episodes * 30m = 345 mins
      expect(stats.estimatedWatchMinutes, 345);
      expect(stats.genresFor(AppLanguage.tr).single.label, 'Bilim Kurgu');
      expect(stats.genresFor(AppLanguage.tr).single.count, 2);
      expect(stats.genresFor(AppLanguage.en).single.label, 'Sci-Fi');
      expect(stats.genresFor(AppLanguage.en).single.count, 2);

      // 3. Non-destructive JSON merge mode test (overwriteExisting: false)
      final incomingJson = BackupCodec.encode([
        BackupItem(
          tmdbId: 601,
          mediaType: MediaType.movie,
          title: 'Interstellar',
          status: WatchStatus.planned,
          userRating: 6,
          note: 'Eski yedek notu',
          addedAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ]);
      await backupService.importJson(incomingJson, overwriteExisting: false);
      final afterMerge = (await libraryDao.findById(m1))!;
      expect(afterMerge.status, WatchStatus.watched);
      expect(afterMerge.userRating, 10);
      expect(afterMerge.note, 'Mevcut not');
    });
  });
}

