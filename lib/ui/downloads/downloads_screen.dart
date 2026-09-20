import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../player/mini_player.dart';
import '../player/playback_providers.dart';
import 'downloads_providers.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(downloadedEpisodesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: async.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No downloads yet.'));
          }
          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _DownloadTile(entry: entries[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  const _DownloadTile({required this.entry});
  final LocalEpisode entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(entry.guid, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          const Text('Autodelete on completion'),
          const SizedBox(width: 8),
          Switch(
            value: entry.autodelete,
            onChanged: (value) async {
              final store = ref.read(localEpisodeStoreProvider);
              await store.write(LocalEpisode(
                guid: entry.guid,
                localPath: entry.localPath,
                downloadedAt: entry.downloadedAt,
                position: entry.position,
                completedAt: entry.completedAt,
                autodelete: value,
              ));
              ref.invalidate(downloadedEpisodesProvider);
            },
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          await ref
              .read(episodeDownloaderProvider)
              .deleteDownload(entry.guid);
          ref.invalidate(downloadedEpisodesProvider);
        },
      ),
    );
  }
}
