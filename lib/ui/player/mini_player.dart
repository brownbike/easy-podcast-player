import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/podcast_artwork.dart';
import 'now_playing_screen.dart';
import 'playback_providers.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playbackSnapshotProvider);
    final snapshot = async.valueOrNull;
    final episode = snapshot?.episode;
    if (episode == null) return const SizedBox.shrink();

    final controller = ref.read(playbackControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: PodcastArtwork(url: episode.artworkUrl, size: 48),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  episode.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                onPressed: () => controller.pauseOrResume(),
                icon: Icon(
                  snapshot!.playing ? Icons.pause : Icons.play_arrow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
