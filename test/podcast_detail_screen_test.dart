import 'package:epp/data/download/episode_downloader.dart';
import 'package:epp/data/feed/feed_cache.dart';
import 'package:epp/data/feed/feed_client.dart';
import 'package:epp/data/feed/rss_parser.dart';
import 'package:epp/data/playback/local_episode_store.dart';
import 'package:epp/data/playback/playback_controller.dart';
import 'package:epp/domain/models.dart';
import 'package:epp/ui/downloads/downloads_providers.dart';
import 'package:epp/ui/player/playback_providers.dart';
import 'package:epp/ui/podcast/podcast_detail_providers.dart';
import 'package:epp/ui/podcast/podcast_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fixtures/sample_feed.dart';

const _testFeed = 'https://example.com/feed.xml';

const _podcast = Podcast(
  id: 'p1',
  title: 'Test Podcast',
  feedUrl: _testFeed,
);

Widget _wrap({
  required http.Client client,
  FeedCache? cache,
  PlaybackController? playback,
  LocalEpisodeStore? store,
  EpisodeDownloader? downloader,
}) {
  final localStore = store ?? InMemoryLocalEpisodeStore();
  return ProviderScope(
    overrides: [
      feedClientProvider.overrideWith((ref) => FeedClient(
            httpClient: client,
            parser: const RssParser(),
          )),
      feedCacheProvider.overrideWithValue(cache ?? InMemoryFeedCache()),
      playbackControllerProvider
          .overrideWithValue(playback ?? FakePlaybackController()),
      localEpisodeStoreProvider.overrideWithValue(localStore),
      episodeDownloaderProvider
          .overrideWithValue(downloader ?? FakeEpisodeDownloader(store: localStore)),
    ],
    child: const MaterialApp(home: PodcastDetailScreen(podcast: _podcast)),
  );
}

void main() {
  Future<void> pumpTall(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  testWidgets('shows first 10 episodes with Load more, then paginates',
      (tester) async {
    final client = MockClient(
      (_) async => http.Response(buildFeed(itemCount: 25), 200),
    );

    await pumpTall(tester, _wrap(client: client));

    expect(find.text('Episode 1'), findsOneWidget);
    expect(find.text('Episode 10'), findsOneWidget);
    expect(find.text('Episode 11'), findsNothing);
    expect(find.text('Load more'), findsOneWidget);

    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    expect(find.text('Episode 20'), findsOneWidget);
    expect(find.text('Episode 21'), findsNothing);
    expect(find.text('Load more'), findsOneWidget);

    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    expect(find.text('Episode 25'), findsOneWidget);
    expect(find.text('Load more'), findsNothing);
  });

  testWidgets('surfaces refresh error banner and keeps cached list',
      (tester) async {
    final cache = InMemoryFeedCache();
    await cache.write(CachedFeed(
      feedUrl: _testFeed,
      episodes: const [
        Episode(
          guid: 'c-1',
          feedUrl: _testFeed,
          title: 'Cached One',
          audioUrl: 'https://example.com/c1.mp3',
        ),
      ],
    ));

    final client = MockClient(
      (_) async => http.Response('server down', 503),
    );

    await tester.pumpWidget(_wrap(client: client, cache: cache));
    await tester.pumpAndSettle();

    expect(find.text('Cached One'), findsOneWidget);
    expect(find.textContaining("Couldn't refresh"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
