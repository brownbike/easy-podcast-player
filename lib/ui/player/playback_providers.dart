import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/playback/local_episode_store.dart';
import '../../data/playback/playback_controller.dart';

/// Set from main() with the real audio_service-backed controller.
/// Widget tests override this with a FakePlaybackController.
final playbackControllerProvider = Provider<PlaybackController>((ref) {
  throw UnimplementedError(
    'playbackControllerProvider must be overridden before use.',
  );
});

final localEpisodeStoreProvider = Provider<LocalEpisodeStore>((ref) {
  throw UnimplementedError(
    'localEpisodeStoreProvider must be overridden before use.',
  );
});

final playbackSnapshotProvider = StreamProvider<PlaybackSnapshot>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.snapshots;
});
