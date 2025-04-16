class Interval {
  final DateTime date;
  final int driverNumber;
  final double gapToLeader;
  final double interval;
  final int meetingKey;
  final int sessionKey;

  Interval({
    required this.date,
    required this.driverNumber,
    required this.gapToLeader,
    required this.interval,
    required this.meetingKey,
    required this.sessionKey,
  });

  factory Interval.fromJson(Map<String, dynamic> json) {
    return Interval(
      date: DateTime.parse(json['date']),
      driverNumber: json['driver_number'],
      gapToLeader: json['gap_to_leader']?.toDouble() ?? 0.0,
      interval: json['interval']?.toDouble() ?? 0.0,
      meetingKey: json['meeting_key'],
      sessionKey: json['session_key'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'driver_number': driverNumber,
      'gap_to_leader': gapToLeader,
      'interval': interval,
      'meeting_key': meetingKey,
      'session_key': sessionKey,
    };
  }

  // Format interval for display
  String formatInterval() {
    if (interval <= 0) {
      return "LEADER";
    } else if (interval < 0.1) {
      return "+${interval.toStringAsFixed(3)}";
    } else {
      return "+${interval.toStringAsFixed(3)}";
    }
  }

  // Format gap to leader for display
  String formatGapToLeader() {
    if (gapToLeader <= 0) {
      return "LEADER";
    } else if (gapToLeader < 0.1) {
      return "+${gapToLeader.toStringAsFixed(3)}";
    } else {
      return "+${gapToLeader.toStringAsFixed(3)}";
    }
  }
}
