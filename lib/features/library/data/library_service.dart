import '../../../core/models/media_type.dart';
import '../../../core/network/tmdb_client.dart';
import '../../../core/models/title_summary.dart';
import '../../episodes/data/episode_dao.dart';
import '../domain/watch_status.dart';
import 'library_dao.dart';

class AddResult {
  const AddResult(this.itemId, {this.seasonError});

  final int itemId;

  /// Set when the title was saved but TV season info could not be fetched.
  final TmdbException? seasonError;
}

/// Coordinates library writes that also need TMDB (e.g. TV seasons).
class LibraryService {
  LibraryService(this._library, this._episodes, this._client);

  final LibraryDao _library;
  final EpisodeDao _episodes;
  final TmdbClient? Function() _client;

  Future<AddResult> add(TitleSummary summary, WatchStatus status) async {
    final id = await _library.add(summary, status);
    if (summary.mediaType != MediaType.tv) return AddResult(id);
    try {
      await refreshSeasons(id, summary.tmdbId);
      return AddResult(id);
    } on TmdbException catch (e) {
      return AddResult(id, seasonError: e);
    }
  }

  Future<AddResult> setOrAddStatus(
    TitleSummary summary,
    WatchStatus status,
  ) async {
    final existing = await _library.findByKey(summary.key);
    if (existing != null) {
      await _library.setStatus(existing.id, status);
      return AddResult(existing.id);
    }
    return add(summary, status);
  }

  Future<void> refreshSeasons(int itemId, int tmdbId) async {
    final client = _client();
    if (client == null) {
      throw const TmdbException(TmdbErrorKind.missingKey);
    }
    final seasons = await client.fetchTvSeasons(tmdbId);
    await _episodes.replaceSeasons(itemId, seasons);
  }
}
