import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/download/episode_downloader.dart';
import '../../domain/models.dart';
import '../player/playback_providers.dart';

final episodeDownloaderProvider = Provider<EpisodeDownloader>((ref) {
  throw UnimplementedError(
    'episodeDownloaderProvider must be overridden before use.',
  );
});

/// Emits whenever a download finishes so downloads screens can refresh.
final downloadStatusStreamProvider = StreamProvider<DownloadStatus>((ref) {
  return ref.watch(episodeDownloaderProvider).updates;
});

/// Maps GUIDs that are currently queued or downloading to their progress
/// (0.0–1.0). A value of 0.0 means queued but not yet started.
class _ActiveDownloadsNotifier extends StateNotifier<Map<String, double>> {
  _ActiveDownloadsNotifier(Stream<DownloadStatus> stream) : super({}) {
    _sub = stream.listen((status) {
      final active = status.stage == DownloadStage.queued ||
          status.stage == DownloadStage.running;
      if (active) {
        state = {...state, status.guid: status.progress};
      } else {
        final next = Map<String, double>.from(state);
        next.remove(status.guid);
        state = next;
      }
    });
  }

  late final StreamSubscription<DownloadStatus> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final activeDownloadsProvider =
    StateNotifierProvider<_ActiveDownloadsNotifier, Map<String, double>>((ref) {
  return _ActiveDownloadsNotifier(
    ref.watch(episodeDownloaderProvider).updates,
  );
});

final downloadedEpisodesProvider = FutureProvider<List<LocalEpisode>>((ref) {
  // Depend on the status stream so the list refreshes on new completions.
  ref.watch(downloadStatusStreamProvider);
  final store = ref.watch(localEpisodeStoreProvider);
  return store
      .readAll()
      .then((all) => all.where((e) => e.localPath != null).toList());
});

final localEpisodeProvider =
    FutureProvider.autoDispose.family<LocalEpisode?, String>((ref, guid) {
  ref.watch(downloadStatusStreamProvider);
  return ref.watch(localEpisodeStoreProvider).read(guid);
});
