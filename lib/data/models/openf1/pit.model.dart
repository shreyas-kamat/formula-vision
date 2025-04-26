class Pit {
  final DateTime date;
  final int driverNumber;
  final int lapNumber;
  final int meetingKey;
  final double pitDuration;
  final int sessionKey;

  Pit({
    required this.date,
    required this.driverNumber,
    required this.lapNumber,
    required this.meetingKey,
    required this.pitDuration,
    required this.sessionKey,
  });

  factory Pit.fromJson(Map<String, dynamic> json) {
    return Pit(
      date: DateTime.parse(json['date']),
      driverNumber: json['driver_number'],
      lapNumber: json['lap_number'],
      meetingKey: json['meeting_key'],
      pitDuration: json['pit_duration']?.toDouble() ?? 0.0,
      sessionKey: json['session_key'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'driver_number': driverNumber,
      'lap_number': lapNumber,
      'meeting_key': meetingKey,
      'pit_duration': pitDuration,
      'session_key': sessionKey,
    };
  }

  // Format pit duration for display
  String formatPitDuration() {
    return pitDuration.toStringAsFixed(1);
  }
}
