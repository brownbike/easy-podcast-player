import 'package:flutter/foundation.dart';

@immutable
class Podcast {
  final String id;
  final String title;
  final String feedUrl;
  final String? artworkUrl;

  const Podcast({
    required this.id,
    required this.title,
    required this.feedUrl,
    this.artworkUrl,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) => Podcast(
        id: json['id'] as String,
        title: json['title'] as String,
        feedUrl: json['feedUrl'] as String,
        artworkUrl: json['artworkUrl'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Podcast &&
          other.id == id &&
          other.title == title &&
          other.feedUrl == feedUrl &&
          other.artworkUrl == artworkUrl;

  @override
  int get hashCode => Object.hash(id, title, feedUrl, artworkUrl);
}

@immutable
class Episode {
  final String guid;
  final String feedUrl;
  final String title;
  final String? description;
  final DateTime? publishedAt;
  final Duration? duration;
  final String audioUrl;
  final String? artworkUrl;

  const Episode({
    required this.guid,
    required this.feedUrl,
    required this.title,
    required this.audioUrl,
    this.description,
    this.publishedAt,
    this.duration,
    this.artworkUrl,
  });
}

@immutable
class LocalEpisode {
  final String guid;
  final String? localPath;
  final DateTime? downloadedAt;
  final Duration position;
  final DateTime? completedAt;
  final bool autodelete;

  const LocalEpisode({
    required this.guid,
    this.localPath,
    this.downloadedAt,
    this.position = Duration.zero,
    this.completedAt,
    this.autodelete = false,
  });
}
