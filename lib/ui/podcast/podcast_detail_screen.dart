import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../common/podcast_artwork.dart';
import '../downloads/downloads_providers.dart';
import '../player/mini_player.dart';
import '../player/now_playing_screen.dart';
import '../player/playback_providers.dart';
import 'podcast_detail_providers.dart';

class PodcastDetailScreen extends ConsumerWidget {
  const PodcastDetailScreen({super.key, required this.podcast});
  final Podcast podcast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(podcastFeedProvider(podcast.feedUrl));
    return Scaffold(
      appBar: AppBar(title: Text(podcast.title)),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(podcastFeedProvider(podcast.feedUrl).notifier).refresh(),
        child: async.when(
          data: (state) => _EpisodeList(podcast: podcast, state: state),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _fatalError(context, e),
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  Widget _fatalError(BuildContext context, Object e) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Failed to load feed:\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class _EpisodeList extends ConsumerWidget {
  const _EpisodeList({required this.podcast, required this.state});

  final Podcast podcast;
  final PodcastFeedState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.episodes.isEmpty && state.refreshing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.episodes.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(child: Text('No episodes yet.')),
        ],
      );
    }

    final visible = state.visible;
    final itemCount = visible.length +
        (state.hasMore ? 1 : 0) +
        (state.error != null ? 1 : 0);

    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (state.error != null && index == 0) {
          return _RefreshError(
            error: state.error!,
            onRetry: () => ref
                .read(podcastFeedProvider(podcast.feedUrl).notifier)
                .refresh(),
          );
        }
        final offset = state.error != null ? 1 : 0;
        final visibleIndex = index - offset;
        if (visibleIndex < visible.length) {
          return _EpisodeTile(episode: visible[visibleIndex]);
        }
        return _LoadMoreTile(
          onTap: () => ref
              .read(podcastFeedProvider(podcast.feedUrl).notifier)
              .loadMore(),
        );
      },
    );
  }
}

class _EpisodeTile extends ConsumerWidget {
  const _EpisodeTile({required this.episode});
  final Episode episode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final published = episode.publishedAt;
    final subtitle = <String>[
      if (published != null) DateFormat.yMMMd().format(published.toLocal()),
      if (episode.duration != null) _formatDuration(episode.duration!),
    ].join(' · ');
    final localAsync = ref.watch(localEpisodeProvider(episode.guid));
    final isDownloaded = localAsync.valueOrNull?.localPath != null;

    return ListTile(
      leading: SizedBox(
        width: 56,
        height: 56,
        child: PodcastArtwork(url: episode.artworkUrl, size: 56),
      ),
      title: Text(episode.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: isDownloaded
          ? const IconButton(
              icon: Icon(Icons.download_done),
              onPressed: null,
            )
          : IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Download',
              onPressed: () =>
                  ref.read(episodeDownloaderProvider).enqueue(episode),
            ),
      onTap: () {
        ref.read(playbackControllerProvider).play(episode);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
        );
      },
    );
  }
}

class _LoadMoreTile extends StatelessWidget {
  const _LoadMoreTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Center(child: Text('Load more')),
      onTap: onTap,
    );
  }
}

class _RefreshError extends StatelessWidget {
  const _RefreshError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Couldn\'t refresh feed. Showing cached episodes.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '${h}h ${m}m';
  }
  if (m > 0) {
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
  return '${s}s';
}
