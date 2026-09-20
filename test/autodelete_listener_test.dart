import 'dart:async';
import 'dart:io';

import 'package:epp/data/download/episode_downloader.dart';
import 'package:epp/data/playback/autodelete_listener.dart';
import 'package:epp/data/playback/local_episode_store.dart';
import 'package:epp/data/playback/playback_controller.dart';
import 'package:epp/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Downloader that deletes the file on disk first, then the store row —
/// exercising the deletion-order invariant.
class _RealFileDownloader implements EpisodeDownloader {
  _RealFileDownloader({required this.store});
  final LocalEpisodeStore store;
  final _c = StreamController<DownloadStatus>.broadcast();

  final deletionOrder = <String>[];

  @override
  Stream<DownloadStatus> get updates => _c.stream;

  @override
  Future<void> enqueue(Episode episode) async {}

  @override
  Future<void> cancel(String guid) async {}

  @override
  Future<void> deleteDownload(String guid) async {
    final entry = await store.read(guid);
    final path = entry?.localPath;
    if (path != null && await File(path).exists()) {
      await File(path).delete();
      deletionOrder.add('file');
    }
    await store.delete(guid);
    deletionOrder.add('row');
  }
}

const _episode = Episode(
  guid: 'ep-auto',
  feedUrl: 'https://x/f',
  title: 'Autodelete Me',
  audioUrl: 'https://x/ep.mp3',
);

void main() {
  test('deletes downloaded file and row when autodelete=true on completion',
      () async {
    final tmp = await Directory.systemTemp.createTemp('epp_autodel_');
    addTearDown(() => tmp.delete(recursive: true));
    final file = File('${tmp.path}/ep.mp3');
    await file.writeAsBytes(const [1, 2, 3]);

    final store = InMemoryLocalEpisodeStore();
    await store.write(LocalEpisode(
      guid: _episode.guid,
      localPath: file.path,
      downloadedAt: DateTime.now(),
      autodelete: true,
    ));

    final playback = FakePlaybackController();
    addTearDown(playback.dispose);
    final downloader = _RealFileDownloader(store: store);

    final listener = AutodeleteListener(
      playback: playback,
      store: store,
      downloader: downloader,
    )..start();
    addTearDown(listener.dispose);

    await playback.play(_episode);
    playback.emitCompletion();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(await file.exists(), isFalse);
    expect(await store.read(_episode.guid), isNull);
    expect(downloader.deletionOrder, ['file', 'row']);
  });

  test('does nothing when autodelete=false', () async {
    final tmp = await Directory.systemTemp.createTemp('epp_autodel_');
    addTearDown(() => tmp.delete(recursive: true));
    final file = File('${tmp.path}/ep.mp3');
    await file.writeAsBytes(const [1, 2, 3]);

    final store = InMemoryLocalEpisodeStore();
    await store.write(LocalEpisode(
      guid: _episode.guid,
      localPath: file.path,
      autodelete: false,
    ));

    final playback = FakePlaybackController();
    addTearDown(playback.dispose);
    final downloader = _RealFileDownloader(store: store);

    final listener = AutodeleteListener(
      playback: playback,
      store: store,
      downloader: downloader,
    )..start();
    addTearDown(listener.dispose);

    await playback.play(_episode);
    playback.emitCompletion();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(await file.exists(), isTrue);
    expect(await store.read(_episode.guid), isNotNull);
  });
}
