import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Saves durable queue entries so they survive an app restart.
///
/// Implement this to use your own storage (SQLite, Hive, secure storage).
abstract class SmartConnectivityQueueStore {
  /// Creates a queue store.
  const SmartConnectivityQueueStore();

  /// Returns the saved entries, oldest first.
  Future<List<Map<String, Object?>>> load();

  /// Replaces the saved entries with [entries].
  Future<void> save(List<Map<String, Object?>> entries);
}

/// Keeps durable entries in memory only. Used by default and in tests.
///
/// Entries survive a new controller that shares this store instance, but not
/// a full app restart.
class MemorySmartConnectivityQueueStore extends SmartConnectivityQueueStore {
  /// Creates an empty in-memory store.
  MemorySmartConnectivityQueueStore();

  List<Map<String, Object?>> _entries = [];

  @override
  Future<List<Map<String, Object?>>> load() async =>
      _entries.map(Map<String, Object?>.from).toList();

  @override
  Future<void> save(List<Map<String, Object?>> entries) async {
    _entries = entries.map(Map<String, Object?>.from).toList();
  }
}

/// Saves durable entries with `shared_preferences` so they survive restarts.
class SharedPreferencesQueueStore extends SmartConnectivityQueueStore {
  /// Creates a store that writes JSON under [key].
  const SharedPreferencesQueueStore({
    this.key = 'flutter_smart_connectivity_plus.queue',
  });

  /// Preferences key for the saved queue.
  final String key;

  @override
  Future<List<Map<String, Object?>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map(Map<String, Object?>.from).toList();
    } on FormatException {
      return [];
    }
  }

  @override
  Future<void> save(List<Map<String, Object?>> entries) async {
    final prefs = await SharedPreferences.getInstance();
    if (entries.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, jsonEncode(entries));
  }
}
