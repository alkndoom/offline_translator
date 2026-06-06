/// A selectable translation language and its BCP-47 tag (used by the speech
/// engines, e.g. 'en-US').
class Language {
  final String name;
  final String localeTag;

  const Language(this.name, this.localeTag);

  @override
  bool operator ==(Object other) =>
      other is Language && other.name == name && other.localeTag == localeTag;

  @override
  int get hashCode => Object.hash(name, localeTag);
}

/// Languages offered in the picker. Keep this aligned with the model's reliable
/// training target.
const kSupportedLanguages = <Language>[
  Language('English', 'en-US'),
  Language('Turkish', 'tr-TR'),
];
