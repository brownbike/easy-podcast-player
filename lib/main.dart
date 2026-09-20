import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/download/episode_downloader.dart';
import 'data/playback/audio_service_controller.dart';
import 'data/playback/autodelete_listener.dart';
import 'data/playback/local_episode_store.dart';
import 'ui/downloads/downloads_providers.dart';
import 'ui/player/playback_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = SharedPrefsLocalEpisodeStore();
  final playback = await AudioServicePlaybackController.init(store: store);
  final downloader = await BackgroundEpisodeDownloader.init(store: store);
  AutodeleteListener(
    playback: playback,
    store: store,
    downloader: downloader,
  ).start();

  runApp(
    ProviderScope(
      overrides: [
        localEpisodeStoreProvider.overrideWithValue(store),
        playbackControllerProvider.overrideWithValue(playback),
        episodeDownloaderProvider.overrideWithValue(downloader),
      ],
      child: const EppApp(),
    ),
  );
}
