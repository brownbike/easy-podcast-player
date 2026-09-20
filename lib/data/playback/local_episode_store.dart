import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models.dart';

abstract class LocalEpisodeStore {
  Future<LocalEpisode?> read(String guid);
  Future<void> write(LocalEpisode entry);
  Future<void> delete(String guid);
  Future<List<LocalEpisode>> readAll();
}

class SharedPrefsLocalEpisodeStore implements LocalEpisodeStore {
  SharedPrefsLocalEpisodeStore({Future<SharedPreferences>? prefs})
      : _prefs = prefs ?? SharedPreferences.getInstance();

  static const _key = 'local_episodes';
  final Future<SharedPreferences> _prefs;

  Future<Map<String, dynamic>> _load() async {
    final raw = (await _prefs).getString(_key);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    return decoded.cast<String, dynamic>();
  }

  Future<void> _save(Map<String, dynamic> map) async {
    await (await _prefs).setString(_key, jsonEncode(map));
  }

  @override
  Future<LocalEpisode?> read(String guid) async {
    final map = await _load();
    final entry = map[guid];
    if (entry is! Map) return null;
    return _fromJson(guid, entry.cast<String, dynamic>());
  }

  @override
  Future<List<LocalEpisode>> readAll() async {
    final map = await _load();
    return map.entries
        .map((e) => _fromJson(e.key, (e.value as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  @override
  Future<void> write(LocalEpisode entry) async {
    final map = await _load();
    map[entry.guid] = _toJson(entry);
    await _save(map);
  }

  @override
  Future<void> delete(String guid) async {
    final map = await _load();
    map.remove(guid);
    await _save(map);
  }
}

class InMemoryLocalEpisodeStore implements LocalEpisodeStore {
  final _store = <String, LocalEpisode>{};

  @override
  Future<LocalEpisode?> read(String guid) async => _store[guid];

  @override
  Future<List<LocalEpisode>> readAll() async =>
      _store.values.toList(growable: false);

  @override
  Future<void> write(LocalEpisode entry) async {
    _store[entry.guid] = entry;
  }

  @override
  Future<void> delete(String guid) async {
    _store.remove(guid);
  }
}

Map<String, dynamic> _toJson(LocalEpisode e) => {
      'localPath': e.localPath,
      'downloadedAt': e.downloadedAt?.toIso8601String(),
      'positionSec': e.position.inSeconds,
      'completedAt': e.completedAt?.toIso8601String(),
      'autodelete': e.autodelete,
    };

LocalEpisode _fromJson(String guid, Map<String, dynamic> json) => LocalEpisode(
      guid: guid,
      localPath: json['localPath'] as String?,
      downloadedAt: (json['downloadedAt'] as String?) != null
          ? DateTime.parse(json['downloadedAt'] as String)
          : null,
      position: Duration(seconds: (json['positionSec'] as int?) ?? 0),
      completedAt: (json['completedAt'] as String?) != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      autodelete: (json['autodelete'] as bool?) ?? false,
    );
