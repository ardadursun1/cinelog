import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_tracker/core/database/app_database.dart';
import 'package:movie_tracker/core/database/settings_dao.dart';
import 'package:movie_tracker/core/models/media_type.dart';
import 'package:movie_tracker/core/models/title_summary.dart';
import 'package:movie_tracker/core/network/tmdb_models.dart';
import 'package:movie_tracker/core/settings/app_settings_providers.dart';
import 'package:movie_tracker/features/backup/data/backup_codec.dart';
import 'package:movie_tracker/features/backup/data/backup_service.dart';
import 'package:movie_tracker/features/episodes/data/episode_dao.dart';
import 'package:movie_tracker/features/library/data/library_dao.dart';
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

      await episodeDao.markUpTo(id, (1, 3));
      item = await libraryDao.findById(id);
      expect(item?.status, WatchStatus.watched);
      expect(item?.watchedAt, isNotNull);

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
  });
}

