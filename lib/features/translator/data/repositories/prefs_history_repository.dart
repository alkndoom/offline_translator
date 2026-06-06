import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';

/// [HistoryRepository] backed by `shared_preferences`, storing the list as a
/// single JSON string.
class PrefsHistoryRepository implements HistoryRepository {
  static const _key = 'translation_history';

  @override
  Future<List<HistoryEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<void> save(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
