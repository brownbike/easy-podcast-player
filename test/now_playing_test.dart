import 'package:epp/data/playback/playback_controller.dart';
import 'package:epp/domain/models.dart';
import 'package:epp/ui/player/now_playing_screen.dart';
import 'package:epp/ui/player/playback_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _episode = Episode(
  guid: 'e-1',
  feedUrl: 'https://x/f',
  title: 'Now Playing Test',
  audioUrl: 'https://x/e-1.mp3',
  duration: Duration(minutes: 30),
);

void main() {
  testWidgets('skip forward / back move playback position by 30s',
      (tester) async {
    final controller = FakePlaybackController();
    addTearDown(controller.dispose);

    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        playbackControllerProvider.overrideWithValue(controller),
      ],
      child: const MaterialApp(home: NowPlayingScreen()),
    ));

    await controller.play(_episode);
    await controller.seekTo(const Duration(minutes: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.forward_30));
    await tester.pumpAndSettle();
    expect(controller.current.position, const Duration(minutes: 5, seconds: 30));

    await tester.tap(find.byIcon(Icons.replay_30));
    await tester.pumpAndSettle();
    expect(controller.current.position, const Duration(minutes: 5));
  });

  testWidgets('skip back clamps at zero', (tester) async {
    final controller = FakePlaybackController();
    addTearDown(controller.dispose);

    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        playbackControllerProvider.overrideWithValue(controller),
      ],
      child: const MaterialApp(home: NowPlayingScreen()),
    ));

    await controller.play(_episode);
    await controller.seekTo(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.replay_30));
    await tester.pumpAndSettle();
    expect(controller.current.position, Duration.zero);
  });

  testWidgets('renders "Nothing playing" when no episode is set',
      (tester) async {
    final controller = FakePlaybackController();
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        playbackControllerProvider.overrideWithValue(controller),
      ],
      child: const MaterialApp(home: NowPlayingScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Nothing playing.'), findsOneWidget);
  });
}
