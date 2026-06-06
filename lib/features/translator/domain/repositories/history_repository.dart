import '../entities/history_entry.dart';

/// Local persistence for translation history. The implementation chooses the
/// storage backend; the feature programs only to this contract.
abstract class HistoryRepository {
  Future<List<HistoryEntry>> getAll();
  Future<void> save(List<HistoryEntry> entries);
}
