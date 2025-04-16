class Meeting {
  final int circuitKey;
  final String circuitShortName;
  final String countryCode;
  final int countryKey;
  final String countryName;
  final DateTime dateStart;
  final String gmtOffset;
  final String location;
  final int meetingKey;
  final String meetingName;
  final String meetingOfficialName;
  final int year;

  Meeting({
    required this.circuitKey,
    required this.circuitShortName,
    required this.countryCode,
    required this.countryKey,
    required this.countryName,
    required this.dateStart,
    required this.gmtOffset,
    required this.location,
    required this.meetingKey,
    required this.meetingName,
    required this.meetingOfficialName,
    required this.year,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      circuitKey: json['circuit_key'],
      circuitShortName: json['circuit_short_name'],
      countryCode: json['country_code'],
      countryKey: json['country_key'],
      countryName: json['country_name'],
      dateStart: DateTime.parse(json['date_start']),
      gmtOffset: json['gmt_offset'],
      location: json['location'],
      meetingKey: json['meeting_key'],
      meetingName: json['meeting_name'],
      meetingOfficialName: json['meeting_official_name'],
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
      'date_start': dateStart.toIso8601String(),
      'gmt_offset': gmtOffset,
      'location': location,
      'meeting_key': meetingKey,
      'meeting_name': meetingName,
      'meeting_official_name': meetingOfficialName,
      'year': year,
    };
  }
}
