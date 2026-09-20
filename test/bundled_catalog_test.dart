import 'package:epp/data/catalog/bundled_catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this._payload);
  final String _payload;

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(_payload.codeUnits);
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => _payload;
}

void main() {
  test('BundledCatalog parses a JSON array of podcasts', () async {
    const json = '''
      [
        {"id":"a","title":"Alpha","feedUrl":"https://a/f","artworkUrl":"https://a/x"},
        {"id":"b","title":"Beta","feedUrl":"https://b/f"}
      ]
    ''';
    final catalog = BundledCatalog(bundle: _FakeBundle(json));

    final podcasts = await catalog.load();

    expect(podcasts, hasLength(2));
    expect(podcasts[0].id, 'a');
    expect(podcasts[0].artworkUrl, 'https://a/x');
    expect(podcasts[1].artworkUrl, isNull);
  });

  test('BundledCatalog throws on non-array JSON', () async {
    final catalog = BundledCatalog(bundle: _FakeBundle('{"not":"array"}'));
    expect(catalog.load(), throwsFormatException);
  });
}
