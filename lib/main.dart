import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/playback/audio_service_controller.dart';
import 'data/playback/local_episode_store.dart';
import 'ui/player/playback_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = SharedPrefsLocalEpisodeStore();
  final controller = await AudioServicePlaybackController.init(store: store);

  runApp(
    ProviderScope(
      overrides: [
        localEpisodeStoreProvider.overrideWithValue(store),
        playbackControllerProvider.overrideWithValue(controller),
      ],
      child: const EppApp(),
    ),
  );
}
