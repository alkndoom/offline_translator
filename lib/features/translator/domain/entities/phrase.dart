import 'scenario.dart';

/// A curated, bilingual English-Turkish phrase.
class Phrase {
  final String id;
  final Scenario scenario;
  final String en;
  final String tr;

  const Phrase({
    required this.id,
    required this.scenario,
    required this.en,
    required this.tr,
  });

  /// Returns Turkish for "Turkish"; English for every other supported source.
  String inLanguage(String languageName) => languageName == 'Turkish' ? tr : en;
}
