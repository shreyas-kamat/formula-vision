import 'package:flutter/material.dart';
import 'package:formulavision/data/models/openf1/driver.model.dart';
import 'package:formulavision/data/models/openf1/interval.model.dart'
    as custom_interval;
import 'package:formulavision/data/models/openf1/lap.model.dart';
import 'package:formulavision/data/models/openf1/pit.model.dart';
import 'package:formulavision/data/models/openf1/position.model.dart';
import 'package:formulavision/data/models/openf1/stint.model.dart';

class RaceDriverInfo {
  final Driver driver;
  final Position position;
  final Lap? fastestLap;
  final custom_interval.Interval? interval;
  final Stint? currentStint;
  final List<Pit> pitStops;

  RaceDriverInfo({
    required this.driver,
    required this.position,
    this.fastestLap,
    this.interval,
    this.currentStint,
    required this.pitStops,
  });

  // Get driver's current position
  int getCurrentPosition() {
    return position.position;
  }

  // Get driver's short name (e.g., HAM)
  String getDriverShortName() {
    return driver.nameAcronym;
  }

  // Get driver's team color
  Color getTeamColor() {
    return driver.getTeamColor();
  }

  // Get fastest lap time formatted
  String getFastestLapFormatted() {
    if (fastestLap == null) return "--:--.---";
    return fastestLap!.getLapTimeFormatted();
  }

  // Get interval to leader or previous driver
  String getIntervalFormatted() {
    if (interval == null) return "";
    return interval!.formatInterval();
  }

  // Get current tyre compound
  String getCurrentTyreCompound() {
    if (currentStint == null) return "?";
    return currentStint!.getCompoundCode();
  }

  // Get tyre compound color
  Color getCurrentTyreColor() {
    if (currentStint == null) return Colors.grey;
    return currentStint!.getCompoundColor();
  }

  // Get number of pit stops
  int getPitStopCount() {
    return pitStops.length;
  }

  // Check if this driver has the fastest lap
  bool hasSessionFastestLap(List<RaceDriverInfo> allDrivers) {
    if (fastestLap == null) return false;

    double myFastestTime = fastestLap!.lapDuration;
    for (var driver in allDrivers) {
      if (driver.fastestLap == null) continue;
      if (driver.fastestLap!.lapDuration < myFastestTime) {
        return false;
      }
    }
    return true;
  }

  // Check if driver is on podium (top 3)
  bool isOnPodium() {
    return position.isOnPodium();
  }

  // Check if driver is the race leader
  bool isRaceLeader() {
    return position.position == 1;
  }

  // Get current tyre age
  int getCurrentTyreAge() {
    if (currentStint == null) return 0;
    return currentStint!.getTotalTyreAge();
  }
}
