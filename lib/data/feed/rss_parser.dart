import 'package:xml/xml.dart';

import '../../domain/models.dart';

class RssParseException implements Exception {
  RssParseException(this.message);
  final String message;
  @override
  String toString() => 'RssParseException: $message';
}

class RssParser {
  const RssParser();

  List<Episode> parse(String xmlText, {required String feedUrl}) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(xmlText);
    } on XmlException catch (e) {
      throw RssParseException('malformed XML: $e');
    }

    final channel = doc.findAllElements('channel').firstOrNull;
    if (channel == null) {
      throw RssParseException('no <channel> element');
    }

    final items = channel.findElements('item');
    final episodes = <Episode>[];
    for (final item in items) {
      final episode = _parseItem(item, feedUrl: feedUrl);
      if (episode != null) episodes.add(episode);
    }
    return episodes;
  }

  Episode? _parseItem(XmlElement item, {required String feedUrl}) {
    final enclosure = item.findElements('enclosure').firstOrNull;
    final audioUrl = enclosure?.getAttribute('url');
    if (audioUrl == null || audioUrl.isEmpty) return null;

    final title = _text(item, 'title') ?? '(untitled)';
    final description = _text(item, 'description');
    final pubDateText = _text(item, 'pubDate');
    final guid = _text(item, 'guid') ?? audioUrl;

    final artwork = item
            .findElements('itunes:image')
            .firstOrNull
            ?.getAttribute('href') ??
        _text(item, 'itunes:image');

    final durationText = _text(item, 'itunes:duration');

    return Episode(
      guid: guid,
      feedUrl: feedUrl,
      title: title,
      description: description,
      audioUrl: audioUrl,
      publishedAt: _parseDate(pubDateText),
      duration: _parseDuration(durationText),
      artworkUrl: artwork,
    );
  }

  String? _text(XmlElement el, String tag) {
    final match = el.findElements(tag).firstOrNull;
    if (match == null) return null;
    final text = match.innerText.trim();
    return text.isEmpty ? null : text;
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    try {
      return _rfc822.parse(raw);
    } catch (_) {
      try {
        return DateTime.parse(raw);
      } catch (_) {
        return null;
      }
    }
  }

  Duration? _parseDuration(String? raw) {
    if (raw == null) return null;
    if (RegExp(r'^\d+$').hasMatch(raw)) {
      return Duration(seconds: int.parse(raw));
    }
    final parts = raw.split(':').map(int.tryParse).toList();
    if (parts.any((p) => p == null)) return null;
    final ints = parts.cast<int>();
    if (ints.length == 3) {
      return Duration(hours: ints[0], minutes: ints[1], seconds: ints[2]);
    }
    if (ints.length == 2) {
      return Duration(minutes: ints[0], seconds: ints[1]);
    }
    return null;
  }
}

final _rfc822 = _Rfc822Parser();

class _Rfc822Parser {
  static const _months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  DateTime parse(String s) {
    // Example: "Tue, 10 Feb 2026 15:04:05 -0500"
    final re = RegExp(
      r'^(?:\w{3},\s*)?(\d{1,2})\s+(\w{3})\s+(\d{2,4})\s+(\d{2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4}|\w{2,4})?',
    );
    final m = re.firstMatch(s.trim());
    if (m == null) throw FormatException('bad rfc822 date: $s');
    final day = int.parse(m.group(1)!);
    final month = _months[m.group(2)] ?? (throw FormatException(s));
    var year = int.parse(m.group(3)!);
    if (year < 100) year += 2000;
    final hour = int.parse(m.group(4)!);
    final minute = int.parse(m.group(5)!);
    final second = int.tryParse(m.group(6) ?? '') ?? 0;
    final tz = m.group(7);
    final base = DateTime.utc(year, month, day, hour, minute, second);
    return base.subtract(_offset(tz));
  }

  Duration _offset(String? tz) {
    if (tz == null) return Duration.zero;
    if (RegExp(r'^[+-]\d{4}$').hasMatch(tz)) {
      final sign = tz[0] == '-' ? -1 : 1;
      final h = int.parse(tz.substring(1, 3));
      final min = int.parse(tz.substring(3, 5));
      return Duration(minutes: sign * (h * 60 + min));
    }
    // Named zones we care about (GMT/UTC treated as zero).
    return Duration.zero;
  }
}
