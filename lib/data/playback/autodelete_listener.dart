import 'dart:async';

import '../download/episode_downloader.dart';
import 'local_episode_store.dart';
import 'playback_controller.dart';

/// Subscribes to a [PlaybackController] and, when playback completes for an
/// episode whose LocalEpisode entry has `autodelete=true`, removes the
/// downloaded file (via [EpisodeDownloader]) *before* the store row.
class AutodeleteListener {
  AutodeleteListener({
    required this.playback,
    required this.store,
    required this.downloader,
  });

  final PlaybackController playback;
  final LocalEpisodeStore store;
  final EpisodeDownloader downloader;

  StreamSubscription<PlaybackSnapshot>? _sub;

  void start() {
    _sub = playback.snapshots.listen((snap) async {
      if (!snap.completed) return;
      final ep = snap.episode;
      if (ep == null) return;
      final local = await store.read(ep.guid);
      if (local == null || !local.autodelete) return;
      // deleteDownload removes the file first, then the store row.
      await downloader.deleteDownload(ep.guid);
    });
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }
}
