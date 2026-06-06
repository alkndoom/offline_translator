/// A travel situation that scopes the quick-phrase list.
enum Scenario {
  general('General'),
  airport('Airport'),
  hotel('Hotel'),
  customs('Customs'),
  emergency('Emergency', isEmergency: true);

  const Scenario(this.label, {this.isEmergency = false});

  final String label;
  final bool isEmergency;
}
