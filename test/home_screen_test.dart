import 'package:epp/data/catalog/podcast_catalog.dart';
import 'package:epp/domain/models.dart';
import 'package:epp/ui/home/home_providers.dart';
import 'package:epp/ui/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCatalog implements PodcastCatalog {
  _FakeCatalog(this.podcasts);
  final List<Podcast> podcasts;

  @override
  Future<List<Podcast>> load() async => podcasts;
}

Widget _wrap(PodcastCatalog catalog) {
  return ProviderScope(
    overrides: [
      podcastCatalogProvider.overrideWithValue(catalog),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  testWidgets('HomeScreen renders podcast titles from the catalog',
      (tester) async {
    final catalog = _FakeCatalog(const [
      Podcast(id: 'a', title: 'Alpha Show', feedUrl: 'https://a/f'),
      Podcast(id: 'b', title: 'Beta Show', feedUrl: 'https://b/f'),
    ]);

    await tester.pumpWidget(_wrap(catalog));
    await tester.pumpAndSettle();

    expect(find.text('Alpha Show'), findsOneWidget);
    expect(find.text('Beta Show'), findsOneWidget);
  });

  testWidgets('HomeScreen shows empty state for empty catalog',
      (tester) async {
    await tester.pumpWidget(_wrap(_FakeCatalog(const [])));
    await tester.pumpAndSettle();

    expect(find.text('No podcasts in catalog.'), findsOneWidget);
  });
}
