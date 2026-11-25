import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/library/domain/watch_status.dart';
import '../models/media_type.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [LibraryItems, ItemGenres, TvSeasons, WatchedEpisodes, AppSettings],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  static const String fileName = 'movie_tracker.sqlite';

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(libraryItems, libraryItems.runtimeMinutes);
          }
          await _createIndexes();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_library_items_status '
      'ON library_items (status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_library_items_added_at '
      'ON library_items (added_at DESC)',
    );
  }

  static Future<Directory> dataDirectory() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return dir;
  }

  static QueryExecutor openDefault() => LazyDatabase(() async {
        final dir = await dataDirectory();
        return NativeDatabase.createInBackground(
          File(p.join(dir.path, fileName)),
        );
      });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(AppDatabase.openDefault());
  ref.onDispose(db.close);
  return db;
});
