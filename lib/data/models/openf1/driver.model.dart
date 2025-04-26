import 'package:flutter/material.dart';

class Driver {
  final String broadcastName;
  // final String countryCode;
  final int driverNumber;
  final String firstName;
  final String fullName;
  // final String headshotUrl;
  final String lastName;
  final int meetingKey;
  final String nameAcronym;
  final int sessionKey;
  final String teamColour;
  final String teamName;

  Driver({
    required this.broadcastName,
    // required this.countryCode,
    required this.driverNumber,
    required this.firstName,
    required this.fullName,
    // required this.headshotUrl,
    required this.lastName,
    required this.meetingKey,
    required this.nameAcronym,
    required this.sessionKey,
    required this.teamColour,
    required this.teamName,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      broadcastName: json['broadcast_name'],
      // countryCode: json['country_code'],
      driverNumber: json['driver_number'],
      firstName: json['first_name'],
      fullName: json['full_name'],
      // headshotUrl: json['headshot_url'],
      lastName: json['last_name'],
      meetingKey: json['meeting_key'],
      nameAcronym: json['name_acronym'],
      sessionKey: json['session_key'],
      teamColour: json['team_colour'],
      teamName: json['team_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'broadcast_name': broadcastName,
      // 'country_code': countryCode,
      'driver_number': driverNumber,
      'first_name': firstName,
      'full_name': fullName,
      // 'headshot_url': headshotUrl,
      'last_name': lastName,
      'meeting_key': meetingKey,
      'name_acronym': nameAcronym,
      'session_key': sessionKey,
      'team_colour': teamColour,
      'team_name': teamName,
    };
  }

  // Utility method to get team color as a Color object
  Color getTeamColor() {
    // Convert hex string to Color
    return Color(int.parse('0xFF${teamColour}'));
  }
}
