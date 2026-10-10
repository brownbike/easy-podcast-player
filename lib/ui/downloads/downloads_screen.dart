import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../common/podcast_artwork.dart';
import '../player/mini_player.dart';
import '../player/now_playing_screen.dart';
import '../player/playback_providers.dart';
import 'downloads_providers.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(downloadedEpisodesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: async.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No downloads yet.'));
          }
          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _DownloadTile(entry: entries[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  const _DownloadTile({required this.entry});
  final LocalEpisode entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final published = entry.publishedAt;
    final subtitle = <String>[
      if (published != null) DateFormat.yMMMd().format(published.toLocal()),
      if (entry.duration != null) _formatDuration(entry.duration!),
    ].join(' · ');

    return ListTile(
      leading: SizedBox(
        width: 56,
        height: 56,
        child: PodcastArtwork(url: entry.artworkUrl, size: 56),
      ),
      title: Text(
        entry.episodeTitle ?? entry.guid,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle.isNotEmpty) Text(subtitle),
          Row(
            children: [
              const Text('Auto-delete'),
              const SizedBox(width: 4),
              Switch(
                value: entry.autodelete,
                onChanged: (value) async {
                  final store = ref.read(localEpisodeStoreProvider);
                  await store.write(LocalEpisode(
                    guid: entry.guid,
                    localPath: entry.localPath,
                    downloadedAt: entry.downloadedAt,
                    position: entry.position,
                    completedAt: entry.completedAt,
                    autodelete: value,
                    episodeTitle: entry.episodeTitle,
                    artworkUrl: entry.artworkUrl,
                    publishedAt: entry.publishedAt,
                    duration: entry.duration,
                    feedUrl: entry.feedUrl,
                    audioUrl: entry.audioUrl,
                  ));
                  ref.invalidate(downloadedEpisodesProvider);
                },
              ),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          await ref.read(episodeDownloaderProvider).deleteDownload(entry.guid);
          ref.invalidate(downloadedEpisodesProvider);
        },
      ),
      onTap: () {
        final episode = entry.toEpisode();
        if (episode == null) return;
        ref.read(playbackControllerProvider).play(episode);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
        );
      },
    );
  }
}

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
  return '${s}s';
}
