import 'package:epp/data/feed/feed_cache.dart';
import 'package:epp/data/feed/feed_client.dart';
import 'package:epp/data/feed/feed_repository.dart';
import 'package:epp/data/feed/rss_parser.dart';
import 'package:epp/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fixtures/sample_feed.dart';

const feedUrl = 'https://example.com/feed.xml';

void main() {
  test('refresh fetches, parses, and caches on first call', () async {
    final http.Client client = MockClient((req) async {
      expect(req.headers['If-None-Match'], isNull);
      return http.Response(sampleFeedXml, 200,
          headers: {'etag': 'W/"first"'});
    });
    final cache = InMemoryFeedCache();
    final repo = FeedRepository(
      client: FeedClient(httpClient: client, parser: const RssParser()),
      cache: cache,
    );

    final result = await repo.refresh(feedUrl);
    expect(result.episodes, hasLength(2));
    expect(result.etag, 'W/"first"');

    final cached = await cache.read(feedUrl);
    expect(cached, isNotNull);
    expect(cached!.etag, 'W/"first"');
  });

  test('refresh on 304 returns cached episodes without re-parsing', () async {
    var callCount = 0;
    final http.Client client = MockClient((req) async {
      callCount++;
      if (callCount == 1) {
        return http.Response(sampleFeedXml, 200,
            headers: {'etag': 'W/"first"'});
      }
      expect(req.headers['If-None-Match'], 'W/"first"');
      return http.Response('', 304);
    });
    final cache = InMemoryFeedCache();
    final repo = FeedRepository(
      client: FeedClient(httpClient: client, parser: const RssParser()),
      cache: cache,
    );

    await repo.refresh(feedUrl);
    final second = await repo.refresh(feedUrl);
    expect(second.episodes, hasLength(2));
    expect(second.etag, 'W/"first"');
    expect(callCount, 2);
  });

  test('client fetch throws on non-2xx, non-304', () async {
    final http.Client client = MockClient(
      (_) async => http.Response('nope', 500),
    );
    final repo = FeedRepository(
      client: FeedClient(httpClient: client),
      cache: InMemoryFeedCache(),
    );
    expect(repo.refresh(feedUrl), throwsA(isA<FeedFetchException>()));
  });

  test('caches only Episodes with a non-empty audio URL', () async {
    final http.Client client = MockClient(
      (_) async => http.Response(sampleFeedXml, 200),
    );
    final repo = FeedRepository(
      client: FeedClient(httpClient: client),
      cache: InMemoryFeedCache(),
    );
    final res = await repo.refresh(feedUrl);
    expect(res.episodes.every((Episode e) => e.audioUrl.isNotEmpty), isTrue);
  });
}
