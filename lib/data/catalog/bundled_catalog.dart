import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../domain/models.dart';
import 'podcast_catalog.dart';

class BundledCatalog implements PodcastCatalog {
  BundledCatalog({AssetBundle? bundle, this.assetKey = 'assets/catalog.json'})
      : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetKey;

  @override
  Future<List<Podcast>> load() async {
    final raw = await _bundle.loadString(assetKey);
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('catalog.json must be a JSON array');
    }
    return decoded
        .cast<Map<String, dynamic>>()
        .map(Podcast.fromJson)
        .toList(growable: false);
  }
}
