import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalog/bundled_catalog.dart';
import '../../data/catalog/podcast_catalog.dart';
import '../../domain/models.dart';

final podcastCatalogProvider = Provider<PodcastCatalog>((ref) {
  return BundledCatalog();
});

final catalogProvider = FutureProvider<List<Podcast>>((ref) {
  return ref.watch(podcastCatalogProvider).load();
});
