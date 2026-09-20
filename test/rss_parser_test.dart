import 'package:epp/data/feed/rss_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/sample_feed.dart';

void main() {
  const parser = RssParser();
  const feedUrl = 'https://example.com/feed.xml';

  test('parses items with enclosures and skips those without', () {
    final episodes = parser.parse(sampleFeedXml, feedUrl: feedUrl);
    expect(episodes, hasLength(2));

    final ep1 = episodes.first;
    expect(ep1.title, 'Episode 1');
    expect(ep1.guid, 'ep-1');
    expect(ep1.audioUrl, 'https://example.com/ep1.mp3');
    expect(ep1.duration, const Duration(hours: 1, minutes: 23, seconds: 45));
    expect(ep1.artworkUrl, 'https://example.com/ep1.jpg');
    expect(ep1.publishedAt, isNotNull);
    // 15:04:05 -0500 == 20:04:05 UTC
    expect(ep1.publishedAt!.toUtc(),
        DateTime.utc(2026, 2, 10, 20, 4, 5));

    final ep2 = episodes[1];
    expect(ep2.duration, const Duration(hours: 1));
  });

  test('throws on malformed XML', () {
    expect(() => parser.parse('<not xml', feedUrl: feedUrl),
        throwsA(isA<RssParseException>()));
  });

  test('throws when no channel present', () {
    expect(
      () => parser.parse('<?xml version="1.0"?><rss></rss>',
          feedUrl: feedUrl),
      throwsA(isA<RssParseException>()),
    );
  });
}
