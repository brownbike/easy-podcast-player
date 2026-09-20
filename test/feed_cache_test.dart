import 'dart:io';

import 'package:epp/data/feed/feed_cache.dart';
import 'package:epp/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FileFeedCache round-trips a feed', () async {
    final tmp = await Directory.systemTemp.createTemp('epp_feed_cache_');
    addTearDown(() => tmp.delete(recursive: true));

    final cache = FileFeedCache(root: tmp);
    final now = DateTime.utc(2026, 3, 1, 12);
    final feed = CachedFeed(
      feedUrl: 'https://example.com/feed.xml',
      etag: 'W/"abc"',
      lastModified: 'Sun, 01 Mar 2026 12:00:00 GMT',
      fetchedAt: now,
      episodes: const [
        Episode(
          guid: 'ep-1',
          feedUrl: 'https://example.com/feed.xml',
          title: 'One',
          audioUrl: 'https://example.com/1.mp3',
          duration: Duration(minutes: 30),
        ),
      ],
    );

    await cache.write(feed);
    final round = await cache.read('https://example.com/feed.xml');
    expect(round, isNotNull);
    expect(round!.etag, 'W/"abc"');
    expect(round.episodes.single.title, 'One');
    expect(round.episodes.single.duration, const Duration(minutes: 30));
    expect(round.fetchedAt, now);
  });

  test('FileFeedCache returns null for unknown feed', () async {
    final tmp = await Directory.systemTemp.createTemp('epp_feed_cache_');
    addTearDown(() => tmp.delete(recursive: true));
    final cache = FileFeedCache(root: tmp);
    expect(await cache.read('https://nowhere/feed.xml'), isNull);
  });
}
