import '../../domain/models.dart';
import 'feed_cache.dart';
import 'feed_client.dart';

class FeedLoadResult {
  const FeedLoadResult({
    required this.episodes,
    required this.fromCache,
    this.refreshError,
  });

  final List<Episode> episodes;
  final bool fromCache;
  final Object? refreshError;
}

class FeedRepository {
  FeedRepository({required this.client, required this.cache});

  final FeedClient client;
  final FeedCache cache;

  Future<CachedFeed?> readCached(String feedUrl) => cache.read(feedUrl);

  Future<CachedFeed> refresh(String feedUrl) async {
    final cached = await cache.read(feedUrl);
    final result = await client.fetch(
      feedUrl,
      etag: cached?.etag,
      lastModified: cached?.lastModified,
    );
    if (result.notModified && cached != null) {
      return cached;
    }
    final fresh = CachedFeed(
      feedUrl: feedUrl,
      episodes: result.episodes ?? cached?.episodes ?? const [],
      etag: result.etag ?? cached?.etag,
      lastModified: result.lastModified ?? cached?.lastModified,
      fetchedAt: DateTime.now(),
    );
    await cache.write(fresh);
    return fresh;
  }
}
