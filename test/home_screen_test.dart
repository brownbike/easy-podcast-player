import 'package:epp/data/catalog/podcast_catalog.dart';
import 'package:epp/data/download/episode_downloader.dart';
import 'package:epp/data/playback/local_episode_store.dart';
import 'package:epp/data/playback/playback_controller.dart';
import 'package:epp/domain/models.dart';
import 'package:epp/ui/downloads/downloads_providers.dart';
import 'package:epp/ui/home/home_providers.dart';
import 'package:epp/ui/home/home_screen.dart';
import 'package:epp/ui/player/playback_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCatalog implements PodcastCatalog {
  _FakeCatalog(this.podcasts);
  final List<Podcast> podcasts;

  @override
  Future<List<Podcast>> load() async => podcasts;
}

Widget _wrap(PodcastCatalog catalog) {
  final store = InMemoryLocalEpisodeStore();
  return ProviderScope(
    overrides: [
      podcastCatalogProvider.overrideWithValue(catalog),
      playbackControllerProvider.overrideWithValue(FakePlaybackController()),
      localEpisodeStoreProvider.overrideWithValue(store),
      episodeDownloaderProvider
          .overrideWithValue(FakeEpisodeDownloader(store: store)),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  testWidgets('HomeScreen renders podcast titles from the catalog',
      (tester) async {
    final catalog = _FakeCatalog(const [
      Podcast(id: 'a', title: 'Alpha Show', feedUrl: 'https://a/f'),
      Podcast(id: 'b', title: 'Beta Show', feedUrl: 'https://b/f'),
    ]);

    await tester.pumpWidget(_wrap(catalog));
    await tester.pumpAndSettle();

    expect(find.text('Alpha Show'), findsOneWidget);
    expect(find.text('Beta Show'), findsOneWidget);
  });

  testWidgets('HomeScreen shows empty state for empty catalog',
      (tester) async {
    await tester.pumpWidget(_wrap(_FakeCatalog(const [])));
    await tester.pumpAndSettle();

    expect(find.text('No podcasts in catalog.'), findsOneWidget);
  });
}
