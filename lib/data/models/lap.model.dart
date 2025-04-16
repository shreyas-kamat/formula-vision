class Lap {
  final DateTime dateStart;
  final int driverNumber;
  final double durationSector1;
  final double durationSector2;
  final double durationSector3;
  final int i1Speed;
  final int i2Speed;
  final bool isPitOutLap;
  final double lapDuration;
  final int lapNumber;
  final int meetingKey;
  final List<int> segmentsSector1;
  final List<int> segmentsSector2;
  final List<int> segmentsSector3;
  final int sessionKey;
  final int stSpeed;

  Lap({
    required this.dateStart,
    required this.driverNumber,
    required this.durationSector1,
    required this.durationSector2,
    required this.durationSector3,
    required this.i1Speed,
    required this.i2Speed,
    required this.isPitOutLap,
    required this.lapDuration,
    required this.lapNumber,
    required this.meetingKey,
    required this.segmentsSector1,
    required this.segmentsSector2,
    required this.segmentsSector3,
    required this.sessionKey,
    required this.stSpeed,
  });

  factory Lap.fromJson(Map<String, dynamic> json) {
    return Lap(
      dateStart: DateTime.parse(json['date_start']),
      driverNumber: json['driver_number'],
      durationSector1: json['duration_sector_1']?.toDouble() ?? 0.0,
      durationSector2: json['duration_sector_2']?.toDouble() ?? 0.0,
      durationSector3: json['duration_sector_3']?.toDouble() ?? 0.0,
      i1Speed: json['i1_speed'] ?? 0,
      i2Speed: json['i2_speed'] ?? 0,
      isPitOutLap: json['is_pit_out_lap'] ?? false,
      lapDuration: json['lap_duration']?.toDouble() ?? 0.0,
      lapNumber: json['lap_number'],
      meetingKey: json['meeting_key'],
      segmentsSector1: json['segments_sector_1'] != null
          ? List<int>.from(json['segments_sector_1'])
          : [],
      segmentsSector2: json['segments_sector_2'] != null
          ? List<int>.from(json['segments_sector_2'])
          : [],
      segmentsSector3: json['segments_sector_3'] != null
          ? List<int>.from(json['segments_sector_3'])
          : [],
      sessionKey: json['session_key'],
      stSpeed: json['st_speed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date_start': dateStart.toIso8601String(),
      'driver_number': driverNumber,
      'duration_sector_1': durationSector1,
      'duration_sector_2': durationSector2,
      'duration_sector_3': durationSector3,
      'i1_speed': i1Speed,
      'i2_speed': i2Speed,
      'is_pit_out_lap': isPitOutLap,
      'lap_duration': lapDuration,
      'lap_number': lapNumber,
      'meeting_key': meetingKey,
      'segments_sector_1': segmentsSector1,
      'segments_sector_2': segmentsSector2,
      'segments_sector_3': segmentsSector3,
      'session_key': sessionKey,
      'st_speed': stSpeed,
    };
  }

  // Format lap duration as minutes:seconds.milliseconds
  String formatLapDuration() {
    final int minutes = (lapDuration / 60).floor();
    final double seconds = lapDuration % 60;
    return '$minutes:${seconds.toStringAsFixed(3)}';
  }

  // Get total lap time as formatted string
  String getLapTimeFormatted() {
    // For lap times under a minute, show as seconds.milliseconds
    if (lapDuration < 60) {
      return lapDuration.toStringAsFixed(3);
    }

    int minutes = (lapDuration / 60).floor();
    double seconds = lapDuration % 60;
    return '$minutes:${seconds.toStringAsFixed(3).padLeft(6, '0')}';
  }
}
