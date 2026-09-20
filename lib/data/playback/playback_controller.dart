import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models.dart';

@immutable
class PlaybackSnapshot {
  const PlaybackSnapshot({
    this.episode,
    this.position = Duration.zero,
    this.duration,
    this.playing = false,
    this.completed = false,
  });

  final Episode? episode;
  final Duration position;
  final Duration? duration;
  final bool playing;
  final bool completed;

  PlaybackSnapshot copyWith({
    Episode? episode,
    Duration? position,
    Duration? duration,
    bool? playing,
    bool? completed,
    bool clearEpisode = false,
  }) {
    return PlaybackSnapshot(
      episode: clearEpisode ? null : (episode ?? this.episode),
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playing: playing ?? this.playing,
      completed: completed ?? this.completed,
    );
  }
}

abstract class PlaybackController {
  Stream<PlaybackSnapshot> get snapshots;
  PlaybackSnapshot get current;

  Future<void> play(Episode episode);
  Future<void> pauseOrResume();
  Future<void> seekTo(Duration position);
  Future<void> skip(Duration by);
  Future<void> stop();

  void dispose();
}

class FakePlaybackController implements PlaybackController {
  FakePlaybackController();

  final _controller = StreamController<PlaybackSnapshot>.broadcast();
  PlaybackSnapshot _snapshot = const PlaybackSnapshot();

  @override
  PlaybackSnapshot get current => _snapshot;

  @override
  Stream<PlaybackSnapshot> get snapshots => _controller.stream;

  void _emit(PlaybackSnapshot next) {
    _snapshot = next;
    _controller.add(next);
  }

  @override
  Future<void> play(Episode episode) async {
    _emit(PlaybackSnapshot(
      episode: episode,
      playing: true,
      duration: episode.duration,
    ));
  }

  @override
  Future<void> pauseOrResume() async {
    _emit(_snapshot.copyWith(playing: !_snapshot.playing));
  }

  @override
  Future<void> seekTo(Duration position) async {
    _emit(_snapshot.copyWith(position: position));
  }

  @override
  Future<void> skip(Duration by) async {
    final next = _snapshot.position + by;
    final clamped = next < Duration.zero ? Duration.zero : next;
    _emit(_snapshot.copyWith(position: clamped));
  }

  @override
  Future<void> stop() async {
    _emit(const PlaybackSnapshot());
  }

  void emitCompletion() {
    _emit(_snapshot.copyWith(completed: true, playing: false));
  }

  @override
  void dispose() {
    _controller.close();
  }
}
