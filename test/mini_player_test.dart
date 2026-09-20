import 'package:epp/data/playback/playback_controller.dart';
import 'package:epp/domain/models.dart';
import 'package:epp/ui/player/mini_player.dart';
import 'package:epp/ui/player/playback_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _episode = Episode(
  guid: 'e-1',
  feedUrl: 'https://x/f',
  title: 'The Test Episode',
  audioUrl: 'https://x/e-1.mp3',
);

void main() {
  testWidgets('MiniPlayer is empty when no episode is loaded',
      (tester) async {
    final controller = FakePlaybackController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        playbackControllerProvider.overrideWithValue(controller),
      ],
      child: const MaterialApp(
        home: Scaffold(body: MiniPlayer()),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('The Test Episode'), findsNothing);
  });

  testWidgets('MiniPlayer surfaces current episode and toggles playback',
      (tester) async {
    final controller = FakePlaybackController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        playbackControllerProvider.overrideWithValue(controller),
      ],
      child: const MaterialApp(
        home: Scaffold(body: MiniPlayer()),
      ),
    ));

    await controller.play(_episode);
    await tester.pumpAndSettle();

    expect(find.text('The Test Episode'), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(controller.current.playing, isFalse);
  });
}
