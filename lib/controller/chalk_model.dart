class Chalk {
  final int id;
  final String plate;
  final String controllerUsername;
  final DateTime chalkTime;
  final String? reason;
  final String? notes;

  Chalk({
    required this.id,
    required this.plate,
    required this.controllerUsername,
    required this.chalkTime,
    this.reason,
    this.notes,
  });

  factory Chalk.fromJson(Map<String, dynamic> json) {
    return Chalk(
      id: json['id'],
      plate: json['plate'],
      controllerUsername: json['controller_username'],
      chalkTime: DateTime.parse(json['chalk_time']),
      reason: json['reason'],
      notes: json['notes'],
    );
  }
}
