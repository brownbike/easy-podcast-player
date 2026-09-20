import 'package:epp/data/playback/local_episode_store.dart';
import 'package:epp/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SharedPrefsLocalEpisodeStore round-trips an entry', () async {
    final store = SharedPrefsLocalEpisodeStore();

    await store.write(const LocalEpisode(
      guid: 'e-1',
      position: Duration(seconds: 42),
      autodelete: true,
    ));

    final loaded = await store.read('e-1');
    expect(loaded, isNotNull);
    expect(loaded!.position, const Duration(seconds: 42));
    expect(loaded.autodelete, isTrue);
  });

  test('write overwrites; readAll returns everything', () async {
    final store = SharedPrefsLocalEpisodeStore();

    await store.write(const LocalEpisode(guid: 'a'));
    await store.write(const LocalEpisode(guid: 'b'));
    await store.write(const LocalEpisode(
      guid: 'a',
      position: Duration(seconds: 5),
    ));

    final all = await store.readAll();
    expect(all.map((e) => e.guid).toSet(), {'a', 'b'});
    final a = all.firstWhere((e) => e.guid == 'a');
    expect(a.position, const Duration(seconds: 5));
  });

  test('delete removes an entry', () async {
    final store = SharedPrefsLocalEpisodeStore();
    await store.write(const LocalEpisode(guid: 'a'));
    await store.delete('a');
    expect(await store.read('a'), isNull);
  });
}
