/// A saved past translation.
class HistoryEntry {
  final String id;
  final String task;
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final DateTime createdAt;
  final bool isFavorite;

  const HistoryEntry({
    required this.id,
    required this.task,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.createdAt,
    this.isFavorite = false,
  });

  HistoryEntry copyWith({bool? isFavorite}) => HistoryEntry(
    id: id,
    task: task,
    sourceText: sourceText,
    translatedText: translatedText,
    sourceLang: sourceLang,
    targetLang: targetLang,
    createdAt: createdAt,
    isFavorite: isFavorite ?? this.isFavorite,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'task': task,
    'sourceText': sourceText,
    'translatedText': translatedText,
    'sourceLang': sourceLang,
    'targetLang': targetLang,
    'createdAt': createdAt.toIso8601String(),
    'isFavorite': isFavorite,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    id: json['id'] as String,
    task: json['task'] as String? ?? 'Translate',
    sourceText: json['sourceText'] as String,
    translatedText: json['translatedText'] as String,
    sourceLang: json['sourceLang'] as String,
    targetLang: json['targetLang'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    isFavorite: json['isFavorite'] as bool? ?? false,
  );
}
