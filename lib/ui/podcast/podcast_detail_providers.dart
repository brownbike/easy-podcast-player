import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/feed/feed_cache.dart';
import '../../data/feed/feed_client.dart';
import '../../data/feed/feed_repository.dart';
import '../../domain/models.dart';

const int kPageSize = 10;

final feedClientProvider = Provider<FeedClient>((ref) {
  final client = FeedClient();
  ref.onDispose(client.dispose);
  return client;
});

final feedCacheProvider = Provider<FeedCache>((ref) => FileFeedCache());

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(
    client: ref.watch(feedClientProvider),
    cache: ref.watch(feedCacheProvider),
  );
});

class PodcastFeedState {
  const PodcastFeedState({
    required this.episodes,
    required this.visibleCount,
    this.fromCache = true,
    this.refreshing = false,
    this.error,
  });

  final List<Episode> episodes;
  final int visibleCount;
  final bool fromCache;
  final bool refreshing;
  final Object? error;

  List<Episode> get visible =>
      episodes.take(visibleCount).toList(growable: false);

  bool get hasMore => visibleCount < episodes.length;

  PodcastFeedState copyWith({
    List<Episode>? episodes,
    int? visibleCount,
    bool? fromCache,
    bool? refreshing,
    Object? error,
    bool clearError = false,
  }) {
    return PodcastFeedState(
      episodes: episodes ?? this.episodes,
      visibleCount: visibleCount ?? this.visibleCount,
      fromCache: fromCache ?? this.fromCache,
      refreshing: refreshing ?? this.refreshing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PodcastFeedController
    extends AutoDisposeFamilyAsyncNotifier<PodcastFeedState, String> {
  @override
  Future<PodcastFeedState> build(String feedUrl) async {
    final repo = ref.watch(feedRepositoryProvider);
    final cached = await repo.readCached(feedUrl);
    final initial = PodcastFeedState(
      episodes: cached?.episodes ?? const [],
      visibleCount: kPageSize,
      fromCache: true,
      refreshing: true,
    );
    // Fire-and-forget refresh so the cached list can render immediately.
    Future.microtask(() => _refresh(feedUrl, existing: initial));
    return initial;
  }

  Future<void> _refresh(
    String feedUrl, {
    required PodcastFeedState existing,
  }) async {
    final repo = ref.read(feedRepositoryProvider);
    try {
      final fresh = await repo.refresh(feedUrl);
      state = AsyncData(existing.copyWith(
        episodes: fresh.episodes,
        fromCache: false,
        refreshing: false,
        clearError: true,
      ));
    } catch (e) {
      state = AsyncData(existing.copyWith(
        refreshing: false,
        error: e,
      ));
    }
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(refreshing: true, clearError: true));
    await _refresh(arg, existing: state.value!);
  }

  void loadMore() {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;
    final next = (current.visibleCount + kPageSize)
        .clamp(0, current.episodes.length);
    state = AsyncData(current.copyWith(visibleCount: next));
  }
}

final podcastFeedProvider = AsyncNotifierProvider.autoDispose
    .family<PodcastFeedController, PodcastFeedState, String>(
  PodcastFeedController.new,
);
