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
