/// The generative tasks the assistant can perform. Each carries its UI labels;
/// the per-mode system prompts live in the data-layer gateway.
enum TaskMode {
  translate('Translate', 'Enter text to translate...'),
  summarize('Summarize', 'Enter text to summarize...'),
  simplify('Simplify', 'Enter text to simplify...'),
  explain('Explain', 'Enter a word or phrase to explain...');

  const TaskMode(this.actionLabel, this.inputHint);

  /// Label for the action button (and history).
  final String actionLabel;

  /// Hint shown in the input field for this mode.
  final String inputHint;
}
