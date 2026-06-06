/// Persists how often each phrase has been used, keyed by phrase id.
abstract class PhraseRepository {
  Future<Map<String, int>> getUsageCounts();

  Future<void> save(Map<String, int> counts);
}
