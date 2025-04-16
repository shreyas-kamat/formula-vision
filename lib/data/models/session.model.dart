class Session {
  final int circuitKey;
  final String circuitShortName;
  final String countryCode;
  final int countryKey;
  final String countryName;
  final DateTime dateEnd;
  final DateTime dateStart;
  final String gmtOffset;
  final String location;
  final int meetingKey;
  final int sessionKey;
  final String sessionName;
  final String sessionType;
  final int year;

  Session({
    required this.circuitKey,
    required this.circuitShortName,
    required this.countryCode,
    required this.countryKey,
    required this.countryName,
    required this.dateEnd,
    required this.dateStart,
    required this.gmtOffset,
    required this.location,
    required this.meetingKey,
    required this.sessionKey,
    required this.sessionName,
    required this.sessionType,
    required this.year,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      circuitKey: json['circuit_key'],
      circuitShortName: json['circuit_short_name'],
      countryCode: json['country_code'],
      countryKey: json['country_key'],
      countryName: json['country_name'],
      dateEnd: DateTime.parse(json['date_end']),
      dateStart: DateTime.parse(json['date_start']),
      gmtOffset: json['gmt_offset'],
      location: json['location'],
      meetingKey: json['meeting_key'],
      sessionKey: json['session_key'],
      sessionName: json['session_name'],
      sessionType: json['session_type'],
      year: json['year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'circuit_key': circuitKey,
      'circuit_short_name': circuitShortName,
      'country_code': countryCode,
      'country_key': countryKey,
      'country_name': countryName,
      'date_end': dateEnd.toIso8601String(),
      'date_start': dateStart.toIso8601String(),
      'gmt_offset': gmtOffset,
      'location': location,
      'meeting_key': meetingKey,
      'session_key': sessionKey,
      'session_name': sessionName,
      'session_type': sessionType,
      'year': year,
    };
  }
}
