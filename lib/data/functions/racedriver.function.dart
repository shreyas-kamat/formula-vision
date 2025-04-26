import 'dart:convert';
import 'package:formulavision/data/functions/race.function.dart';
import 'package:formulavision/data/models/openf1/racedriver.model.dart';
import 'package:http/http.dart' as http;
import 'package:formulavision/data/models/openf1/driver.model.dart';
import 'package:formulavision/data/models/openf1/interval.model.dart';
import 'package:formulavision/data/models/openf1/lap.model.dart';
import 'package:formulavision/data/models/openf1/pit.model.dart';
import 'package:formulavision/data/models/openf1/position.model.dart';
import 'package:formulavision/data/models/openf1/stint.model.dart';

Future<List<RaceDriverInfo>> fetchRaceDriverInfo() async {
  try {
    // Fetch all the required data
    final List<Driver> drivers = await fetchDriverDetails();
    // final List<Position> positions = await fetchPositions();
    final List<Lap> laps = await fetchLaps();
    final List<Interval> intervals = await fetchIntervals();
    final List<Stint> stints = await fetchStints();
    final List<Pit> pits = await fetchPits();

    // Debug each fetch - print the count of items returned
    print('Fetched ${drivers.length} drivers');
    // print('Fetched ${positions.length} positions');
    print('Fetched ${laps.length} laps');
    print('Fetched ${intervals.length} intervals');
    print('Fetched ${stints.length} stints');
    print('Fetched ${pits.length} pits');

    // Group laps by driver to find fastest lap
    Map<int, Lap> fastestLaps = {};
    for (var lap in laps) {
      if (!fastestLaps.containsKey(lap.driverNumber) ||
          fastestLaps[lap.driverNumber]!.lapDuration > lap.lapDuration) {
        fastestLaps[lap.driverNumber] = lap;
      }
    }

    // Find the most recent position for each driver
    Map<int, Position> latestPositions = {};
    // for (var position in positions) {
    //   if (!latestPositions.containsKey(position.driverNumber) ||
    //       latestPositions[position.driverNumber]!
    //           .date
    //           .isBefore(position.date)) {
    //     latestPositions[position.driverNumber] = position;
    //   }
    // }

    // Find the current stint for each driver
    Map<int, Stint> currentStints = {};
    for (var stint in stints) {
      if (!currentStints.containsKey(stint.driverNumber) ||
          currentStints[stint.driverNumber]!.stintNumber < stint.stintNumber) {
        currentStints[stint.driverNumber] = stint;
      }
    }

    // Find the most recent interval for each driver
    Map<int, Interval> latestIntervals = {};
    for (var interval in intervals) {
      if (!latestIntervals.containsKey(interval.driverNumber) ||
          latestIntervals[interval.driverNumber]!
              .date
              .isBefore(interval.date)) {
        latestIntervals[interval.driverNumber] = interval;
      }
    }

    // Group pit stops by driver
    Map<int, List<Pit>> driverPitStops = {};
    for (var pit in pits) {
      if (!driverPitStops.containsKey(pit.driverNumber)) {
        driverPitStops[pit.driverNumber] = [];
      }
      driverPitStops[pit.driverNumber]!.add(pit);
    }

    // Create RaceDriverInfo objects by combining all data
    List<RaceDriverInfo> raceDriverInfos = [];
    for (var driver in drivers) {
      try {
        final driverNumber = driver.driverNumber;

        // Skip if we don't have position data
        if (!latestPositions.containsKey(driverNumber)) {
          print(
              'Skipping driver ${driver.fullName} (${driver.driverNumber}): No position data');
          continue;
        }

        // Add debug information for each driver we're processing
        print('Processing driver: ${driver.fullName} (${driver.driverNumber})');
        print('  - teamColor: ${driver.teamColour}');
        print('  - position: ${latestPositions[driverNumber]!.position}');
        print('  - has fastest lap: ${fastestLaps.containsKey(driverNumber)}');
        print('  - has interval: ${latestIntervals.containsKey(driverNumber)}');
        print('  - has stint: ${currentStints.containsKey(driverNumber)}');
        print('  - pit stops: ${driverPitStops[driverNumber]?.length ?? 0}');

        raceDriverInfos.add(RaceDriverInfo(
          driver: driver,
          position: latestPositions[driverNumber]!,
          fastestLap: fastestLaps[driverNumber],
          interval: latestIntervals[driverNumber],
          currentStint: currentStints[driverNumber],
          pitStops: driverPitStops[driverNumber] ?? [],
        ));
      } catch (driverError) {
        print('Error processing driver ${driver.fullName}: $driverError');
        // Continue to next driver even if this one fails
      }
    }

    // Sort by position
    raceDriverInfos
        .sort((a, b) => a.position.position.compareTo(b.position.position));

    print('Returning ${raceDriverInfos.length} driver info objects');
    return raceDriverInfos;
  } catch (e) {
    print('Error fetching race driver info: $e');
    // Add stack trace for more detailed debugging
    // print(StackTrace.current);
    return [];
  }
}

// Helper functions to fetch individual data types
Future<List<Lap>> fetchLaps() async {
  try {
    var response = await http.get(
      Uri.parse(
          'http://10.0.2.2:8000/v1/laps?meeting_key=latest&session_key=latest'),
    );

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      List<Lap> laps = [];
      for (var eachLap in jsonData) {
        try {
          final lap = Lap.fromJson(eachLap);
          laps.add(lap);
        } catch (e) {
          print('Error parsing lap: $e');
          // Skip this lap and continue with others
        }
      }
      return laps;
    } else {
      print('Failed to fetch laps: ${response.statusCode} ${response.body}');
      return [];
    }
  } catch (e) {
    print('Error in fetchLaps: $e');
    return [];
  }
}

Future<List<Interval>> fetchIntervals() async {
  try {
    var response = await http.get(
      Uri.parse(
          'http://10.0.2.2:8000/v1/intervals?meeting_key=latest&session_key=latest'),
    );

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      List<Interval> intervals = [];
      for (var eachInterval in jsonData) {
        try {
          final interval = Interval.fromJson(eachInterval);
          intervals.add(interval);
        } catch (e) {
          print('Error parsing interval: $e');
          // Skip this interval and continue with others
        }
      }
      return intervals;
    } else {
      print(
          'Failed to fetch intervals: ${response.statusCode} ${response.body}');
      return [];
    }
  } catch (e) {
    print('Error in fetchIntervals: $e');
    return [];
  }
}

Future<List<Pit>> fetchPits() async {
  try {
    var response = await http.get(
      Uri.parse(
          'http://10.0.2.2:8000/v1/pits?meeting_key=latest&session_key=latest'),
    );

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      List<Pit> pits = [];
      for (var eachPit in jsonData) {
        try {
          final pit = Pit.fromJson(eachPit);
          pits.add(pit);
        } catch (e) {
          print('Error parsing pit: $e');
          // Skip this pit and continue with others
        }
      }
      return pits;
    } else {
      print('Failed to fetch pits: ${response.statusCode} ${response.body}');
      return [];
    }
  } catch (e) {
    print('Error in fetchPits: $e');
    return [];
  }
}
