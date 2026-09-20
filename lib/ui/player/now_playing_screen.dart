import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/podcast_artwork.dart';
import 'playback_providers.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playbackSnapshotProvider);
    final snapshot = async.valueOrNull;
    final episode = snapshot?.episode;

    if (episode == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Nothing playing.')),
      );
    }

    final controller = ref.read(playbackControllerProvider);
    final duration = snapshot!.duration ?? episode.duration ?? Duration.zero;
    final position = snapshot.position;

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PodcastArtwork(url: episode.artworkUrl),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              episode.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Slider(
              min: 0,
              max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
              value: position.inMilliseconds
                  .clamp(0, duration.inMilliseconds)
                  .toDouble(),
              onChanged: (value) =>
                  controller.seekTo(Duration(milliseconds: value.toInt())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(position)),
                Text(_fmt(duration)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  iconSize: 40,
                  onPressed: () =>
                      controller.skip(const Duration(seconds: -30)),
                  icon: const Icon(Icons.replay_30),
                ),
                IconButton(
                  iconSize: 64,
                  onPressed: () => controller.pauseOrResume(),
                  icon: Icon(
                    snapshot.playing ? Icons.pause_circle : Icons.play_circle,
                  ),
                ),
                IconButton(
                  iconSize: 40,
                  onPressed: () =>
                      controller.skip(const Duration(seconds: 30)),
                  icon: const Icon(Icons.forward_30),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}
