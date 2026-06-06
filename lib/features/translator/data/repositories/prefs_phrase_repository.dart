import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/phrase_repository.dart';

/// [PhraseRepository] backed by `shared_preferences`.
class PrefsPhraseRepository implements PhraseRepository {
  static const _key = 'phrase_usage';

  @override
  Future<Map<String, int>> getUsageCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  @override
  Future<void> save(Map<String, int> counts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(counts));
  }
}
