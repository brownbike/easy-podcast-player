import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/models.dart';

class CachedFeed {
  const CachedFeed({
    required this.feedUrl,
    required this.episodes,
    this.etag,
    this.lastModified,
    this.fetchedAt,
  });

  final String feedUrl;
  final List<Episode> episodes;
  final String? etag;
  final String? lastModified;
  final DateTime? fetchedAt;
}

abstract class FeedCache {
  Future<CachedFeed?> read(String feedUrl);
  Future<void> write(CachedFeed feed);
}

class FileFeedCache implements FeedCache {
  FileFeedCache({Directory? root}) : _rootOverride = root;

  final Directory? _rootOverride;
  Directory? _resolved;

  Future<Directory> _dir() async {
    if (_resolved != null) return _resolved!;
    final base = _rootOverride ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/feed_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    _resolved = dir;
    return dir;
  }

  String _keyFor(String feedUrl) {
    final bytes = utf8.encode(feedUrl);
    // Simple, stable, filesystem-safe key. Not cryptographic.
    var h = 5381;
    for (final b in bytes) {
      h = ((h << 5) + h + b) & 0x7fffffff;
    }
    return 'feed_${h.toRadixString(16)}.json';
  }

  @override
  Future<CachedFeed?> read(String feedUrl) async {
    final file = File('${(await _dir()).path}/${_keyFor(feedUrl)}');
    if (!await file.exists()) return null;
    final decoded = jsonDecode(await file.readAsString());
    return _deserialize(decoded as Map<String, dynamic>);
  }

  @override
  Future<void> write(CachedFeed feed) async {
    final file = File('${(await _dir()).path}/${_keyFor(feed.feedUrl)}');
    await file.writeAsString(jsonEncode(_serialize(feed)));
  }
}

class InMemoryFeedCache implements FeedCache {
  final _store = <String, CachedFeed>{};

  @override
  Future<CachedFeed?> read(String feedUrl) async => _store[feedUrl];

  @override
  Future<void> write(CachedFeed feed) async {
    _store[feed.feedUrl] = feed;
  }
}

Map<String, dynamic> _serialize(CachedFeed feed) => {
      'feedUrl': feed.feedUrl,
      'etag': feed.etag,
      'lastModified': feed.lastModified,
      'fetchedAt': feed.fetchedAt?.toIso8601String(),
      'episodes': feed.episodes.map(_serializeEpisode).toList(),
    };

CachedFeed _deserialize(Map<String, dynamic> json) => CachedFeed(
      feedUrl: json['feedUrl'] as String,
      etag: json['etag'] as String?,
      lastModified: json['lastModified'] as String?,
      fetchedAt: (json['fetchedAt'] as String?) != null
          ? DateTime.parse(json['fetchedAt'] as String)
          : null,
      episodes: (json['episodes'] as List)
          .cast<Map<String, dynamic>>()
          .map(_deserializeEpisode)
          .toList(),
    );

Map<String, dynamic> _serializeEpisode(Episode e) => {
      'guid': e.guid,
      'feedUrl': e.feedUrl,
      'title': e.title,
      'description': e.description,
      'publishedAt': e.publishedAt?.toIso8601String(),
      'durationSec': e.duration?.inSeconds,
      'audioUrl': e.audioUrl,
      'artworkUrl': e.artworkUrl,
    };

Episode _deserializeEpisode(Map<String, dynamic> json) => Episode(
      guid: json['guid'] as String,
      feedUrl: json['feedUrl'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      audioUrl: json['audioUrl'] as String,
      publishedAt: (json['publishedAt'] as String?) != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
      duration: (json['durationSec'] as int?) != null
          ? Duration(seconds: json['durationSec'] as int)
          : null,
      artworkUrl: json['artworkUrl'] as String?,
    );
