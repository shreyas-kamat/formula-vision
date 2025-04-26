import 'package:flutter/material.dart';

class Stint {
  final String compound;
  final int driverNumber;
  final int lapEnd;
  final int lapStart;
  final String meetingKey;
  final String sessionKey;
  final int stintNumber;
  final int tyreAgeAtStart;

  Stint({
    required this.compound,
    required this.driverNumber,
    required this.lapEnd,
    required this.lapStart,
    required this.meetingKey,
    required this.sessionKey,
    required this.stintNumber,
    required this.tyreAgeAtStart,
  });

  factory Stint.fromJson(Map<String, dynamic> json) {
    return Stint(
      compound: json['compound'] ?? 'UNKNOWN', // Add null handling here
      driverNumber: json['driver_number'] ?? 0,
      lapEnd: json['lap_end'] ?? 0,
      lapStart: json['lap_start'] ?? 0,
      meetingKey: json['meeting_key'] ?? 0,
      sessionKey: json['session_key'] ?? 0,
      stintNumber: json['stint_number'] ?? 0,
      tyreAgeAtStart: json['tyre_age_at_start'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'compound': compound,
      'driver_number': driverNumber,
      'lap_end': lapEnd,
      'lap_start': lapStart,
      'meeting_key': meetingKey,
      'session_key': sessionKey,
      'stint_number': stintNumber,
      'tyre_age_at_start': tyreAgeAtStart,
    };
  }

  // Get the stint duration in laps
  int getStintDuration() {
    return lapEnd - lapStart + 1;
  }

  // Get the total age of the tyre at the end of the stint
  int getTotalTyreAge() {
    return tyreAgeAtStart + getStintDuration() - 1;
  }

  // Get color based on compound
  Color getCompoundColor() {
    switch (compound.toUpperCase()) {
      case 'SOFT':
        return Colors.red;
      case 'MEDIUM':
        return Colors.yellow;
      case 'HARD':
        return Colors.white;
      case 'INTERMEDIATE':
        return Colors.green;
      case 'WET':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Get short code for compound
  String getCompoundCode() {
    switch (compound.toUpperCase()) {
      case 'SOFT':
        return 'S';
      case 'MEDIUM':
        return 'M';
      case 'HARD':
        return 'H';
      case 'INTERMEDIATE':
        return 'I';
      case 'WET':
        return 'W';
      default:
        return '?';
    }
  }

  // Check if this stint is the current one for a given lap
  bool isCurrentStint(int currentLap) {
    return currentLap >= lapStart && currentLap <= lapEnd;
  }
}
