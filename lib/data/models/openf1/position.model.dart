class Position {
  final DateTime date;
  final int driverNumber;
  final int meetingKey;
  final int position;
  final int sessionKey;

  Position({
    required this.date,
    required this.driverNumber,
    required this.meetingKey,
    required this.position,
    required this.sessionKey,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      date: DateTime.parse(json['date']),
      driverNumber: json['driver_number'],
      meetingKey: json['meeting_key'],
      position: json['position'],
      sessionKey: json['session_key'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'driver_number': driverNumber,
      'meeting_key': meetingKey,
      'position': position,
      'session_key': sessionKey,
    };
  }

  // Helper method to format position with appropriate suffix (1st, 2nd, 3rd, etc.)
  String getFormattedPosition() {
    String suffix;

    if (position >= 11 && position <= 13) {
      suffix = 'th';
    } else {
      switch (position % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }

    return '$position$suffix';
  }

  // Helper method to check if driver is in podium position
  bool isOnPodium() {
    return position <= 3;
  }

  // Helper method to check if driver is in points-scoring position (top 10)
  bool isInPoints() {
    return position <= 10;
  }
}
