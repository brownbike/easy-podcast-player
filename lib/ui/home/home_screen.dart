import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../common/podcast_artwork.dart';
import '../podcast/podcast_detail_screen.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Podcasts')),
      body: catalog.when(
        data: (podcasts) => _Grid(podcasts: podcasts),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(message: err.toString()),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.podcasts});
  final List<Podcast> podcasts;

  @override
  Widget build(BuildContext context) {
    if (podcasts.isEmpty) {
      return const Center(child: Text('No podcasts in catalog.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: podcasts.length,
      itemBuilder: (context, index) => _PodcastTile(podcast: podcasts[index]),
    );
  }
}

class _PodcastTile extends StatelessWidget {
  const _PodcastTile({required this.podcast});
  final Podcast podcast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PodcastDetailScreen(podcast: podcast),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PodcastArtwork(url: podcast.artworkUrl),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            podcast.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'Failed to load catalog:\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
