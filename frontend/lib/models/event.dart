class Event {
  final DateTime time;
  final String text;
  final String type;

  Event({required this.time, required this.text, this.type = 'info'});
}
