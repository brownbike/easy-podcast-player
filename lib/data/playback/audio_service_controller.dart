import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/models.dart';
import 'local_episode_store.dart';
import 'playback_controller.dart';

class EppAudioHandler extends BaseAudioHandler with SeekHandler {
  EppAudioHandler({required this.store});

  final LocalEpisodeStore store;
  final _player = AudioPlayer();
  Episode? _currentEpisode;
  Timer? _positionSaveTimer;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    _player.playbackEventStream.listen(_broadcastState,
        onError: (Object e, StackTrace st) {});

    _player.processingStateStream
        .where((s) => s == ProcessingState.completed)
        .listen((_) => _onCompleted());
  }

  Future<void> playEpisode(Episode episode) async {
    _currentEpisode = episode;
    final source = await _sourceFor(episode);
    await _player.setAudioSource(source);
    mediaItem.add(_mediaItemFor(episode));

    final local = await store.read(episode.guid);
    final start = local?.position ?? Duration.zero;
    final total = _player.duration;
    if (total != null &&
        start > Duration.zero &&
        (total - start).inSeconds > 15) {
      await _player.seek(start);
    }
    await _player.play();

    _positionSaveTimer?.cancel();
    _positionSaveTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _savePosition());
  }

  Future<AudioSource> _sourceFor(Episode episode) async {
    final local = await store.read(episode.guid);
    final path = local?.localPath;
    if (path != null && await File(path).exists()) {
      return AudioSource.file(path);
    }
    return AudioSource.uri(Uri.parse(episode.audioUrl));
  }

  MediaItem _mediaItemFor(Episode episode) => MediaItem(
        id: episode.guid,
        title: episode.title,
        album: episode.feedUrl,
        artUri: episode.artworkUrl != null
            ? Uri.tryParse(episode.artworkUrl!)
            : null,
        duration: episode.duration,
      );

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _savePosition();
    _positionSaveTimer?.cancel();
    await _player.stop();
    _currentEpisode = null;
  }

  Future<void> skip(Duration by) async {
    final target = _player.position + by;
    final clamped = target < Duration.zero ? Duration.zero : target;
    await _player.seek(clamped);
  }

  Future<void> _savePosition() async {
    final ep = _currentEpisode;
    if (ep == null) return;
    final prev = await store.read(ep.guid);
    await store.write(LocalEpisode(
      guid: ep.guid,
      localPath: prev?.localPath,
      downloadedAt: prev?.downloadedAt,
      position: _player.position,
      completedAt: prev?.completedAt,
      autodelete: prev?.autodelete ?? false,
    ));
  }

  Future<void> _onCompleted() async {
    final ep = _currentEpisode;
    if (ep == null) return;
    final prev = await store.read(ep.guid);
    await store.write(LocalEpisode(
      guid: ep.guid,
      localPath: prev?.localPath,
      downloadedAt: prev?.downloadedAt,
      position: Duration.zero,
      completedAt: DateTime.now(),
      autodelete: prev?.autodelete ?? false,
    ));
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.rewind,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  AudioPlayer get player => _player;
  Episode? get currentEpisode => _currentEpisode;
}

class AudioServicePlaybackController implements PlaybackController {
  AudioServicePlaybackController(this._handler);

  final EppAudioHandler _handler;
  final _snapshotController =
      StreamController<PlaybackSnapshot>.broadcast();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlaybackEvent>? _eventSub;
  PlaybackSnapshot _current = const PlaybackSnapshot();

  static Future<AudioServicePlaybackController> init({
    required LocalEpisodeStore store,
  }) async {
    final handler = EppAudioHandler(store: store);
    await AudioService.init(
      builder: () => handler,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.epp.audio',
        androidNotificationChannelName: 'Playback',
        androidNotificationOngoing: true,
      ),
    );
    await handler.init();
    final controller = AudioServicePlaybackController(handler);
    controller._start();
    return controller;
  }

  void _start() {
    _positionSub = _handler.player.positionStream.listen((p) {
      _emit(_current.copyWith(position: p));
    });
    _eventSub = _handler.player.playbackEventStream.listen((_) {
      _emit(_current.copyWith(
        playing: _handler.player.playing,
        duration: _handler.player.duration,
        completed:
            _handler.player.processingState == ProcessingState.completed,
      ));
    });
  }

  void _emit(PlaybackSnapshot next) {
    _current = next;
    _snapshotController.add(next);
  }

  @override
  PlaybackSnapshot get current => _current;

  @override
  Stream<PlaybackSnapshot> get snapshots => _snapshotController.stream;

  @override
  Future<void> play(Episode episode) async {
    _emit(_current.copyWith(
      episode: episode,
      position: Duration.zero,
      duration: episode.duration,
      completed: false,
    ));
    await _handler.playEpisode(episode);
  }

  @override
  Future<void> pauseOrResume() {
    return _handler.player.playing ? _handler.pause() : _handler.play();
  }

  @override
  Future<void> seekTo(Duration position) => _handler.seek(position);

  @override
  Future<void> skip(Duration by) => _handler.skip(by);

  @override
  Future<void> stop() async {
    await _handler.stop();
    _emit(const PlaybackSnapshot());
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _eventSub?.cancel();
    _snapshotController.close();
  }
}
