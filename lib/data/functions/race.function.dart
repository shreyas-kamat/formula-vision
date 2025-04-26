import 'dart:convert';
import 'package:formulavision/data/models/openf1/driver.model.dart';
import 'package:formulavision/data/models/openf1/meeting.model.dart';
import 'package:formulavision/data/models/openf1/position.model.dart';
import 'package:formulavision/data/models/openf1/session.model.dart';
import 'package:formulavision/data/models/openf1/stint.model.dart';
import 'package:http/http.dart' as http;

Future<List<Meeting>> fetchLatestMeetings() async {
  var response = await http.get(
    Uri.parse('http://10.0.2.2:8000/v1/meetings?meeting_key=latest'),
  );

  if (response.statusCode == 200) {
    var jsonData = jsonDecode(response.body);
    List<Meeting> fetchedMeetings = [];
    for (var eachMeeting in jsonData) {
      final meeting = Meeting(
        circuitKey: eachMeeting['circuit_key'],
        circuitShortName: eachMeeting['circuit_short_name'],
        countryCode: eachMeeting['country_code'],
        countryKey: eachMeeting['country_key'],
        countryName: eachMeeting['country_name'],
        dateStart: DateTime.parse(eachMeeting['date_start']),
        gmtOffset: eachMeeting['gmt_offset'],
        location: eachMeeting['location'],
        meetingKey: eachMeeting['meeting_key'],
        meetingName: eachMeeting['meeting_name'],
        meetingOfficialName: eachMeeting['meeting_official_name'],
        year: eachMeeting['year'],
      );
      fetchedMeetings.add(meeting);
    }
    return fetchedMeetings;
  } else {
    print('Failed to fetch meetings: ${response.statusCode} ${response.body}');
    return [];
  }
}

Future<List<Session>> fetchLatestSessions() async {
  var response = await http.get(
    Uri.parse('http://10.0.2.2:8000/v1/sessions?session_key=latest'),
  );

  if (response.statusCode == 200) {
    var jsonData = jsonDecode(response.body);
    List<Session> fetchedSessions = [];
    for (var eachSession in jsonData) {
      final session = Session(
        sessionKey: eachSession['session_key'],
        sessionName: eachSession['session_name'],
        sessionType: eachSession['session_type'],
        dateStart: DateTime.parse(eachSession['date_start']),
        dateEnd: DateTime.parse(eachSession['date_end']),
        meetingKey: eachSession['meeting_key'],
        circuitKey: eachSession['circuit_key'],
        circuitShortName: eachSession['circuit_short_name'],
        countryCode: eachSession['country_code'],
        countryKey: eachSession['country_key'],
        countryName: eachSession['country_name'],
        gmtOffset: eachSession['gmt_offset'],
        location: eachSession['location'],
        year: eachSession['year'],
      );
      fetchedSessions.add(session);
    }
    return fetchedSessions;
  } else {
    print('Failed to fetch sessions: ${response.statusCode} ${response.body}');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchLatestMeetingAndSessionDetails() async {
  var meetings = await fetchLatestMeetings();
  var sessions = await fetchLatestSessions();

  List<Map<String, dynamic>> combinedDetails = [];

  for (var meeting in meetings) {
    combinedDetails.add({
      'meetingName': meeting.meetingName,
    });
  }

  for (var session in sessions) {
    combinedDetails.add({
      'sessionName': session.sessionName,
      'sessionType': session.sessionType,
    });
  }

  print(combinedDetails);

  return combinedDetails;
}

Future<String> fetchCircuitShortNames() async {
  var meeting = await fetchLatestMeetings();

  if (meeting.isNotEmpty) {
    return meeting.first.circuitShortName;
  } else {
    return '';
  }
}

Future<List<Driver>> fetchDriverDetails() async {
  var response = await http.get(
    Uri.parse(
        'http://10.0.2.2:8000/v1/drivers?meeting_key=latest&session_key=latest'),
  );

  if (response.statusCode == 200) {
    var jsonData = jsonDecode(response.body);
    List<Driver> fetchedDrivers = [];
    for (var eachDriver in jsonData) {
      final driver = Driver(
        broadcastName: eachDriver['broadcast_name'],
        // countryCode: eachDriver['country_code'],
        driverNumber: eachDriver['driver_number'],
        firstName: eachDriver['first_name'],
        fullName: eachDriver['full_name'],
        // headshotUrl: eachDriver['headshot_url'],
        lastName: eachDriver['last_name'],
        meetingKey: eachDriver['meeting_key'],
        nameAcronym: eachDriver['name_acronym'],
        sessionKey: eachDriver['session_key'],
        teamColour: eachDriver['team_colour'],
        teamName: eachDriver['team_name'],
      );
      fetchedDrivers.add(driver);
    }
    return fetchedDrivers;
  } else {
    print('Failed to fetch drivers: ${response.statusCode} ${response.body}');
    return [];
  }
}

Future<List<Position>> fetchPositions(String driverNumber) async {
  var response = await http.get(
    Uri.parse(
        'http://10.0.2.2:8000/v1/position?meeting_key=latest&driver_number=$driverNumber&date=2025-04-04T02:30:06.679000+00:00'),
  );

  if (response.statusCode == 200) {
    var jsonData = jsonDecode(response.body);
    List<Position> positions = [];
    for (var eachPosition in jsonData) {
      final position = Position(
        date: DateTime.parse(eachPosition['date']),
        driverNumber: eachPosition['driver_number'],
        meetingKey: eachPosition['meeting_key'],
        position: eachPosition['position'],
        sessionKey: eachPosition['session_key'],
      );
      positions.add(position);
    }
    return positions;
  } else {
    print('Failed to fetch positions: ${response.statusCode} ${response.body}');
    return [];
  }
}

Future<List<Stint>> fetchStints() async {
  var response = await http.get(
    Uri.parse(
        'http://10.0.2.2:8000/v1/stints?meeting_key=latest&session_key=latest'),
  );

  if (response.statusCode == 200) {
    var jsonData = jsonDecode(response.body);
    List<Stint> stints = [];
    for (var eachStint in jsonData) {
      final stint = Stint(
        compound: eachStint['compound'],
        driverNumber: eachStint['driver_number'],
        lapEnd: eachStint['lap_end'],
        lapStart: eachStint['lap_start'],
        meetingKey: eachStint['meeting_key'],
        sessionKey: eachStint['session_key'],
        stintNumber: eachStint['stint_number'],
        tyreAgeAtStart: eachStint['tyre_age_at_start'],
      );
      stints.add(stint);
    }
    return stints;
  } else {
    print('Failed to fetch stints: ${response.statusCode} ${response.body}');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchCombinedRaceDetails() async {
  var drivers = await fetchDriverDetails();
  // var positions = await fetchPositions();
  var stints = await fetchStints();

  List<Map<String, dynamic>> combinedDetails = [];

  for (var driver in drivers) {
    var driverPositions = await fetchPositions(driver.driverNumber.toString());
    // positions.where((p) => p.driverNumber == driver.driverNumber).toList();
    var driverStints =
        stints.where((s) => s.driverNumber == driver.driverNumber).toList();

    for (var position in driverPositions) {
      var stint = driverStints.firstWhere(
        (s) => s.lapStart <= position.position && s.lapEnd >= position.position,
        orElse: () => Stint(
          compound: 'Unknown',
          driverNumber: driver.driverNumber,
          lapEnd: 0,
          lapStart: 0,
          meetingKey: '',
          sessionKey: '',
          stintNumber: 0,
          tyreAgeAtStart: 0,
        ),
      );

      combinedDetails.add({
        'driverNumber': driver.driverNumber,
        'driverName': driver.fullName,
        'teamColor': driver.teamColour,
        'position': position.position,
        'lapDuration': position.date.toIso8601String(),
        'interval': position.date.difference(DateTime.now()).inSeconds,
        'tyreType': stint.compound,
        'pit': stint.lapEnd == position.position ? 'Yes' : 'No',
      });
    }
  }

  return combinedDetails;
}

Future<String> fetchDriverNumberFromApi(String pos) async {
  var response = await http.get(
    Uri.parse(
        'http://10.0.2.2:8000/v1/position?meeting_key=1256&position=$pos&date=2025-04-04T02:30:06.679000+00:00'),
  );

  if (response.statusCode == 200) {
    var jsonData = jsonDecode(response.body);
    if (jsonData.isNotEmpty) {
      print(jsonData.first['driver_number'].toString());
      return jsonData.first['driver_number'].toString();
    } else {
      print('No driver numbers found in the response.');
      return '';
    }
  } else {
    print(
        'Failed to fetch driver number: ${response.statusCode} ${response.body}');
    return '';
  }
}

Future<String> fetchDriverName(String pos) async {
  String DriverNum = await fetchDriverNumberFromApi(pos);

  var response = await http.get(
    Uri.parse(
        'http://10.0.2.2:8000/v1/drivers?meeting_key=1256&session_key=10006&driver_number=$DriverNum'),
  );

  if (response.statusCode == 200) {
    var jsonData = jsonDecode(response.body);
    if (jsonData.isNotEmpty) {
      print(jsonData.first['name_acronym'].toString());
      return jsonData.first['name_acronym'].toString();
    } else {
      print('No driver numbers found in the response.');
      return '';
    }
  } else {
    print(
        'Failed to fetch driver number: ${response.statusCode} ${response.body}');
    return '';
  }
}

Future<String> fetchDriverLapDuration(String pos) async {
  String DriverNum = await fetchDriverNumberFromApi(pos);

  var response = await http.get(
    Uri.parse(
        'http://10.0.2.2:8000/v1/laps?session_key=10006&driver_number=$DriverNum&date_start=2025-04-06T05:05:27.883000+00:00'),
  );

  if (response.statusCode == 200) {
    var jsonData = jsonDecode(response.body);
    if (jsonData.isNotEmpty) {
      print(jsonData.first['lap_duration'].toString());
      return jsonData.first['lap_duration'].toString();
    } else {
      print('No driver numbers found in the response.');
      return '';
    }
  } else {
    print(
        'Failed to fetch driver number: ${response.statusCode} ${response.body}');
    return '';
  }
}

Future<String> fetchDriverInterval(String pos) async {
  String DriverNum = await fetchDriverNumberFromApi(pos);

  var response = await http.get(
    Uri.parse(
        'http://10.0.2.2:8000/v1/intervals?session_key=10006&driver_number=$DriverNum&date=2025-04-06T05:03:55.814000+00:00'),
  );

  if (response.statusCode == 200) {
    var jsonData = jsonDecode(response.body);
    if (jsonData.isNotEmpty) {
      print(jsonData.first['interval'].toString());
      return jsonData.first['interval'].toString();
    } else {
      print('No driver numbers found in the response.');
      return '';
    }
  } else {
    print(
        'Failed to fetch driver number: ${response.statusCode} ${response.body}');
    return '';
  }
}

Future<String> fetchDriverTyreCompound(String pos) async {
  String DriverNum = await fetchDriverNumberFromApi(pos);

  var response = await http.get(
    Uri.parse(
        'http://10.0.2.2:8000/v1/stints?session_key=10006&driver_number=$DriverNum'),
  );

  if (response.statusCode == 200) {
    var jsonData = jsonDecode(response.body);
    if (jsonData.isNotEmpty) {
      print(jsonData.first['compound'].toString());
      return jsonData.first['compound'].toString();
    } else {
      print('No driver numbers found in the response.');
      return '';
    }
  } else {
    print(
        'Failed to fetch driver number: ${response.statusCode} ${response.body}');
    return '';
  }
}

Future<List<Map<String, dynamic>>> fetchCombinedDriverDetails(
    String pos) async {
  var drivers = await fetchDriverDetails();

  List<Map<String, dynamic>> combinedDetails = [];

  for (var driver in drivers) {
    var positions = await fetchPositions(pos);
    for (var position in positions) {
      var lapDuration =
          await fetchDriverLapDuration(position.position.toString());
      var interval = await fetchDriverInterval(position.position.toString());
      var tyreCompound =
          await fetchDriverTyreCompound(position.position.toString());

      combinedDetails.add({
        'position': position.position,
        'shortName': driver.nameAcronym,
        'lapDuration': lapDuration,
        'interval': interval,
        'tyres': tyreCompound,
      });
    }
  }
  print(combinedDetails);
  return combinedDetails;
}
