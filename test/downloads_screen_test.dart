import 'package:epp/data/download/episode_downloader.dart';
import 'package:epp/data/playback/local_episode_store.dart';
import 'package:epp/data/playback/playback_controller.dart';
import 'package:epp/domain/models.dart';
import 'package:epp/ui/downloads/downloads_providers.dart';
import 'package:epp/ui/downloads/downloads_screen.dart';
import 'package:epp/ui/player/playback_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(LocalEpisodeStore store) {
  return ProviderScope(
    overrides: [
      localEpisodeStoreProvider.overrideWithValue(store),
      episodeDownloaderProvider
          .overrideWithValue(FakeEpisodeDownloader(store: store)),
      playbackControllerProvider.overrideWithValue(FakePlaybackController()),
    ],
    child: const MaterialApp(home: DownloadsScreen()),
  );
}

void main() {
  testWidgets('empty state when no downloads', (tester) async {
    await tester.pumpWidget(_wrap(InMemoryLocalEpisodeStore()));
    await tester.pumpAndSettle();
    expect(find.text('No downloads yet.'), findsOneWidget);
  });

  testWidgets('lists downloaded episodes and toggles autodelete',
      (tester) async {
    final store = InMemoryLocalEpisodeStore();
    await store.write(const LocalEpisode(
      guid: 'ep-99',
      localPath: '/tmp/ep-99.mp3',
    ));

    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    expect(find.text('ep-99'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final updated = await store.read('ep-99');
    expect(updated?.autodelete, isTrue);
  });

  testWidgets('deleting removes the entry from the list', (tester) async {
    final store = InMemoryLocalEpisodeStore();
    await store.write(const LocalEpisode(
      guid: 'ep-77',
      localPath: '/tmp/ep-77.mp3',
    ));

    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    expect(find.text('ep-77'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('ep-77'), findsNothing);
    expect(await store.read('ep-77'), isNull);
  });
}
