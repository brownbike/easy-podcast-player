import '../../domain/models.dart';

abstract class PodcastCatalog {
  Future<List<Podcast>> load();
}
