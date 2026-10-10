import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart' as bd;
import 'package:path_provider/path_provider.dart';

import '../../domain/models.dart';
import '../playback/local_episode_store.dart';

enum DownloadStage { queued, running, complete, failed, cancelled }

class DownloadStatus {
  const DownloadStatus({
    required this.guid,
    required this.stage,
    this.progress = 0.0,
    this.localPath,
    this.error,
  });

  final String guid;
  final DownloadStage stage;
  final double progress;
  final String? localPath;
  final Object? error;
}

abstract class EpisodeDownloader {
  Stream<DownloadStatus> get updates;
  Future<void> enqueue(Episode episode);
  Future<void> cancel(String guid);
  Future<void> deleteDownload(String guid);
}

class BackgroundEpisodeDownloader implements EpisodeDownloader {
  BackgroundEpisodeDownloader({required this.store});

  final LocalEpisodeStore store;
  final _controller = StreamController<DownloadStatus>.broadcast();
  final _guidToTaskId = <String, String>{};

  static Future<BackgroundEpisodeDownloader> init({
    required LocalEpisodeStore store,
  }) async {
    final me = BackgroundEpisodeDownloader(store: store);
    bd.FileDownloader().updates.listen(me._onUpdate);
    await bd.FileDownloader().configure(
      globalConfig: [
        (bd.Config.requestTimeout, const Duration(minutes: 10)),
      ],
    );
    return me;
  }

  @override
  Stream<DownloadStatus> get updates => _controller.stream;

  @override
  Future<void> enqueue(Episode episode) async {
    final dir = await getApplicationDocumentsDirectory();
    final downloads = Directory('${dir.path}/downloads');
    if (!await downloads.exists()) await downloads.create(recursive: true);

    // Write metadata before enqueuing so _onUpdate always finds it in the
    // store, even if the download completes before this method returns.
    final prev = await store.read(episode.guid);
    await store.write(LocalEpisode(
      guid: episode.guid,
      localPath: prev?.localPath,
      downloadedAt: prev?.downloadedAt,
      position: prev?.position ?? Duration.zero,
      completedAt: prev?.completedAt,
      autodelete: prev?.autodelete ?? false,
      episodeTitle: episode.title,
      artworkUrl: episode.artworkUrl,
      publishedAt: episode.publishedAt,
      duration: episode.duration,
      feedUrl: episode.feedUrl,
      audioUrl: episode.audioUrl,
    ));

    final filename = '${_safeName(episode.guid)}.mp3';
    final task = bd.DownloadTask(
      taskId: episode.guid,
      url: episode.audioUrl,
      filename: filename,
      baseDirectory: bd.BaseDirectory.applicationDocuments,
      directory: 'downloads',
      requiresWiFi: true,
      updates: bd.Updates.statusAndProgress,
      retries: 3,
    );
    _guidToTaskId[episode.guid] = task.taskId;
    await bd.FileDownloader().enqueue(task);

    _controller.add(DownloadStatus(
      guid: episode.guid,
      stage: DownloadStage.queued,
    ));
  }

  @override
  Future<void> cancel(String guid) async {
    final taskId = _guidToTaskId[guid];
    if (taskId == null) return;
    await bd.FileDownloader().cancelTaskWithId(taskId);
  }

  @override
  Future<void> deleteDownload(String guid) async {
    final entry = await store.read(guid);
    final path = entry?.localPath;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    await store.delete(guid);
  }

  Future<void> _onUpdate(bd.TaskUpdate update) async {
    final guid = update.task.taskId;
    if (update is bd.TaskStatusUpdate) {
      switch (update.status) {
        case bd.TaskStatus.complete:
          final filePath = await update.task
              .filePath(withFilename: (update.task as bd.DownloadTask).filename);
          final prev = await store.read(guid);
          await store.write(LocalEpisode(
            guid: guid,
            localPath: filePath,
            downloadedAt: DateTime.now(),
            position: prev?.position ?? Duration.zero,
            completedAt: prev?.completedAt,
            autodelete: prev?.autodelete ?? false,
            episodeTitle: prev?.episodeTitle,
            artworkUrl: prev?.artworkUrl,
            publishedAt: prev?.publishedAt,
            duration: prev?.duration,
            feedUrl: prev?.feedUrl,
            audioUrl: prev?.audioUrl,
          ));
          _controller.add(DownloadStatus(
            guid: guid,
            stage: DownloadStage.complete,
            progress: 1.0,
            localPath: filePath,
          ));
        case bd.TaskStatus.failed:
          _controller.add(DownloadStatus(
            guid: guid,
            stage: DownloadStage.failed,
            error: update.exception,
          ));
        case bd.TaskStatus.canceled:
          _controller.add(DownloadStatus(
            guid: guid,
            stage: DownloadStage.cancelled,
          ));
        case bd.TaskStatus.running:
          _controller.add(DownloadStatus(
            guid: guid,
            stage: DownloadStage.running,
          ));
        default:
          break;
      }
    } else if (update is bd.TaskProgressUpdate) {
      _controller.add(DownloadStatus(
        guid: guid,
        stage: DownloadStage.running,
        progress: update.progress,
      ));
    }
  }

  String _safeName(String guid) =>
      guid.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
}

class FakeEpisodeDownloader implements EpisodeDownloader {
  FakeEpisodeDownloader({required this.store});

  final LocalEpisodeStore store;
  final _controller = StreamController<DownloadStatus>.broadcast();

  @override
  Stream<DownloadStatus> get updates => _controller.stream;

  @override
  Future<void> enqueue(Episode episode) async {
    _controller.add(DownloadStatus(
      guid: episode.guid,
      stage: DownloadStage.queued,
    ));
    // Simulate immediate completion so tests can drive follow-up behavior.
    final path = '/tmp/${episode.guid}.mp3';
    final prev = await store.read(episode.guid);
    await store.write(LocalEpisode(
      guid: episode.guid,
      localPath: path,
      downloadedAt: DateTime.now(),
      position: prev?.position ?? Duration.zero,
      autodelete: prev?.autodelete ?? false,
      episodeTitle: episode.title,
      artworkUrl: episode.artworkUrl,
      publishedAt: episode.publishedAt,
      duration: episode.duration,
      feedUrl: episode.feedUrl,
      audioUrl: episode.audioUrl,
    ));
    _controller.add(DownloadStatus(
      guid: episode.guid,
      stage: DownloadStage.complete,
      progress: 1.0,
      localPath: path,
    ));
  }

  @override
  Future<void> cancel(String guid) async {
    _controller.add(DownloadStatus(guid: guid, stage: DownloadStage.cancelled));
  }

  @override
  Future<void> deleteDownload(String guid) async {
    await store.delete(guid);
  }
}
