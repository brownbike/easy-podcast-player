import 'package:http/http.dart' as http;

import '../../domain/models.dart';
import 'rss_parser.dart';

class FeedFetchResult {
  const FeedFetchResult({
    required this.notModified,
    this.episodes,
    this.etag,
    this.lastModified,
  });

  final bool notModified;
  final List<Episode>? episodes;
  final String? etag;
  final String? lastModified;
}

class FeedFetchException implements Exception {
  FeedFetchException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() =>
      'FeedFetchException($statusCode): $message';
}

class FeedClient {
  FeedClient({http.Client? httpClient, RssParser? parser})
      : _http = httpClient ?? http.Client(),
        _parser = parser ?? const RssParser();

  final http.Client _http;
  final RssParser _parser;

  Future<FeedFetchResult> fetch(
    String feedUrl, {
    String? etag,
    String? lastModified,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/rss+xml, application/xml;q=0.9, */*;q=0.5',
    };
    if (etag != null) headers['If-None-Match'] = etag;
    if (lastModified != null) headers['If-Modified-Since'] = lastModified;

    final resp = await _http.get(Uri.parse(feedUrl), headers: headers);
    if (resp.statusCode == 304) {
      return const FeedFetchResult(notModified: true);
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw FeedFetchException(
        'HTTP ${resp.statusCode} fetching $feedUrl',
        statusCode: resp.statusCode,
      );
    }

    final episodes = _parser.parse(resp.body, feedUrl: feedUrl);
    return FeedFetchResult(
      notModified: false,
      episodes: episodes,
      etag: resp.headers['etag'],
      lastModified: resp.headers['last-modified'],
    );
  }

  void dispose() => _http.close();
}
