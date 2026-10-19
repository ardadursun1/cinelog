// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../features/library/domain/watch_status.dart';
import '../models/media_type.dart';

const int kNoteMaxLength = 500;

@DataClassName('LibraryItem')
class LibraryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tmdbId => integer()();
  TextColumn get mediaType => textEnum<MediaType>()();
  TextColumn get title => text()();
  TextColumn get originalTitle => text().withDefault(const Constant(''))();
  TextColumn get posterPath => text().nullable()();
  TextColumn get overview => text().withDefault(const Constant(''))();
  IntColumn get releaseYear => integer().nullable()();
  TextColumn get status => textEnum<WatchStatus>()();
  IntColumn get userRating =>
      integer().nullable().check(userRating.isBetweenValues(1, 10))();
  TextColumn get note =>
      text().withLength(max: kNoteMaxLength).nullable()();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get watchedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {tmdbId, mediaType},
      ];
}

@DataClassName('ItemGenre')
class ItemGenres extends Table {
  IntColumn get itemId =>
      integer().references(LibraryItems, #id, onDelete: KeyAction.cascade)();
  IntColumn get genreId => integer()();
  TextColumn get genreName => text()();

  @override
  Set<Column> get primaryKey => {itemId, genreId};
}

@DataClassName('TvSeason')
class TvSeasons extends Table {
  IntColumn get itemId =>
      integer().references(LibraryItems, #id, onDelete: KeyAction.cascade)();
  IntColumn get seasonNumber => integer()();
  IntColumn get episodeCount => integer()();
  TextColumn get name => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {itemId, seasonNumber};
}

@DataClassName('WatchedEpisode')
class WatchedEpisodes extends Table {
  IntColumn get itemId =>
      integer().references(LibraryItems, #id, onDelete: KeyAction.cascade)();
  IntColumn get seasonNumber => integer()();
  IntColumn get episodeNumber => integer()();
  DateTimeColumn get watchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {itemId, seasonNumber, episodeNumber};
}

@DataClassName('AppSetting')
class AppSettings extends Table {
  TextColumn get name => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {name};
}
