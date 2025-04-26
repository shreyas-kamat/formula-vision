class CarData {
  final int? brake;
  final DateTime date;
  final int driverNumber;
  final int drs;
  final int meetingKey;
  final int nGear;
  final int rpm;
  final int sessionKey;
  final int speed;
  final int throttle;

  CarData({
    this.brake,
    required this.date,
    required this.driverNumber,
    required this.drs,
    required this.meetingKey,
    required this.nGear,
    required this.rpm,
    required this.sessionKey,
    required this.speed,
    required this.throttle,
  });

  factory CarData.fromJson(Map<String, dynamic> json) {
    return CarData(
      brake: json['brake'],
      date: DateTime.parse(json['date']),
      driverNumber: json['driver_number'],
      drs: json['drs'],
      meetingKey: json['meeting_key'],
      nGear: json['n_gear'],
      rpm: json['rpm'],
      sessionKey: json['session_key'],
      speed: json['speed'],
      throttle: json['throttle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brake': brake,
      'date': date.toIso8601String(),
      'driver_number': driverNumber,
      'drs': drs,
      'meeting_key': meetingKey,
      'n_gear': nGear,
      'rpm': rpm,
      'session_key': sessionKey,
      'speed': speed,
      'throttle': throttle,
    };
  }

  // Helper method to get DRS status as a readable string
  String getDrsStatus() {
    switch (drs) {
      case 0:
      case 1:
        return "Off";
      case 8:
        return "Eligible";
      case 10:
      case 12:
      case 14:
        return "Active";
      case 2:
      case 3:
      case 9:
        return "Unknown State ${drs}";
      default:
        return "Unknown";
    }
  }

  // Returns whether DRS is currently active
  bool isDrsActive() {
    return drs == 10 || drs == 12 || drs == 14;
  }

  // Returns whether DRS is eligible but not yet activated
  bool isDrsEligible() {
    return drs == 8;
  }

  // Helper method to get throttle percentage
  double getThrottlePercentage() {
    return throttle / 100.0;
  }

  // Helper method to get brake percentage
  double getBrakePercentage() {
    return (brake ?? 0) / 100.0;
  }
}
