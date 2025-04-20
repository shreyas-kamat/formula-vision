// f1_data_model.dart

import 'package:flutter/foundation.dart';

class F1DataModel extends ChangeNotifier {
  LiveData _state = LiveData();

  LiveData get state => _state;

  void updateData(Map<String, dynamic> data) {
    // Process and update data based on received WebSocket message
    if (data["M"] != null && data["M"] is List) {
      for (var message in data["M"]) {
        // Handle standard feed messages
        if (message["H"] == "Streaming" &&
            message["M"] == "feed" &&
            message["A"] != null) {
          final telemetryUpdate = message["A"];
          if (telemetryUpdate != null) {
            // Update specific parts of the state based on the data received
            if (telemetryUpdate["HeartBeat"] != null) {
              _state.heartbeat =
                  Heartbeat.fromJson(telemetryUpdate["HeartBeat"]);
            }
            if (telemetryUpdate["ExtrapolatedClock"] != null) {
              _state.extrapolatedClock = ExtrapolatedClock.fromJson(
                  telemetryUpdate["ExtrapolatedClock"]);
            }
            if (telemetryUpdate["TopThree"] != null) {
              _state.topThree = TopThree.fromJson(telemetryUpdate["TopThree"]);
            }
            if (telemetryUpdate["TimingStats"] != null) {
              _state.timingStats =
                  TimingStats.fromJson(telemetryUpdate["TimingStats"]);
            }
            if (telemetryUpdate["TimingAppData"] != null) {
              _state.timingAppData =
                  TimingAppData.fromJson(telemetryUpdate["TimingAppData"]);
            }
            if (telemetryUpdate["WeatherData"] != null) {
              _state.weatherData =
                  WeatherData.fromJson(telemetryUpdate["WeatherData"]);
            }
            if (telemetryUpdate["TrackStatus"] != null) {
              _state.trackStatus =
                  TrackStatus.fromJson(telemetryUpdate["TrackStatus"]);
            }
            if (telemetryUpdate["SessionStatus"] != null) {
              _state.sessionStatus =
                  SessionStatus.fromJson(telemetryUpdate["SessionStatus"]);
            }
            if (telemetryUpdate["DriverList"] != null) {
              _state.driverList =
                  DriverList.fromJson(telemetryUpdate["DriverList"]);
            }
            if (telemetryUpdate["RaceControlMessages"] != null) {
              _state.raceControlMessages = RaceControlMessages.fromJson(
                  telemetryUpdate["RaceControlMessages"]);
            }
            if (telemetryUpdate["SessionInfo"] != null) {
              _state.sessionInfo =
                  SessionInfo.fromJson(telemetryUpdate["SessionInfo"]);
            }
            if (telemetryUpdate["SessionData"] != null) {
              _state.sessionData =
                  SessionData.fromJson(telemetryUpdate["SessionData"]);
            }
            if (telemetryUpdate["LapCount"] != null) {
              _state.lapCount = LapCount.fromJson(telemetryUpdate["LapCount"]);
            }
            if (telemetryUpdate["TimingData"] != null) {
              _state.timingData =
                  TimingData.fromJson(telemetryUpdate["TimingData"]);
            }
            if (telemetryUpdate["TeamRadio"] != null) {
              _state.teamRadio =
                  TeamRadio.fromJson(telemetryUpdate["TeamRadio"]);
            }
            if (telemetryUpdate["ChampionshipPrediction"] != null) {
              _state.championshipPrediction = ChampionshipPrediction.fromJson(
                  telemetryUpdate["ChampionshipPrediction"]);
            }
            if (telemetryUpdate["Position"] != null) {
              // Process position data
              // Note: Position data might need special handling
            }
            if (telemetryUpdate["CarData"] != null) {
              // Process car data
              // Note: Car data might need special handling
            }

            // Notify listeners that the state has been updated
            notifyListeners();
          }
        }
      }
    }
  }
}

class LiveData {
  Heartbeat? heartbeat;
  ExtrapolatedClock? extrapolatedClock;
  TopThree? topThree;
  TimingStats? timingStats;
  TimingAppData? timingAppData;
  WeatherData? weatherData;
  TrackStatus? trackStatus;
  SessionStatus? sessionStatus;
  DriverList? driverList;
  RaceControlMessages? raceControlMessages;
  SessionInfo? sessionInfo;
  SessionData? sessionData;
  LapCount? lapCount;
  TimingData? timingData;
  TeamRadio? teamRadio;
  ChampionshipPrediction? championshipPrediction;

  LiveData({
    this.heartbeat,
    this.extrapolatedClock,
    this.topThree,
    this.timingStats,
    this.timingAppData,
    this.weatherData,
    this.trackStatus,
    this.sessionStatus,
    this.driverList,
    this.raceControlMessages,
    this.sessionInfo,
    this.sessionData,
    this.lapCount,
    this.timingData,
    this.teamRadio,
    this.championshipPrediction,
  });
}

class Heartbeat {
  final String utc;

  Heartbeat({required this.utc});

  factory Heartbeat.fromJson(Map<String, dynamic> json) {
    return Heartbeat(
      utc: json['utc'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'utc': utc,
      };
}

class ExtrapolatedClock {
  final String utc;
  final String remaining;
  final bool extrapolating;

  ExtrapolatedClock({
    required this.utc,
    required this.remaining,
    required this.extrapolating,
  });

  factory ExtrapolatedClock.fromJson(Map<String, dynamic> json) {
    return ExtrapolatedClock(
      utc: json['Utc'] ?? '',
      remaining: json['Remaining'] ?? '',
      extrapolating: json['Extrapolating'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'Utc': utc,
        'Remaining': remaining,
        'Extrapolating': extrapolating,
      };
}

class TopThree {
  final bool withheld;
  final List<TopThreeDriver> lines;

  TopThree({
    required this.withheld,
    required this.lines,
  });

  factory TopThree.fromJson(Map<String, dynamic> json) {
    List<TopThreeDriver> linesList = [];
    if (json['lines'] != null) {
      linesList = List<TopThreeDriver>.from(
        json['lines'].map((x) => TopThreeDriver.fromJson(x)),
      );
    }

    return TopThree(
      withheld: json['withheld'] ?? false,
      lines: linesList,
    );
  }

  Map<String, dynamic> toJson() => {
        'withheld': withheld,
        'lines': lines.map((x) => x.toJson()).toList(),
      };
}

class TopThreeDriver {
  final String position;
  final bool showPosition;
  final String racingNumber;
  final String tla;
  final String broadcastName;
  final String fullName;
  final String team;
  final String teamColour;
  final String lapTime;
  final int lapState;
  final String diffToAhead;
  final String diffToLeader;
  final bool overallFastest;
  final bool personalFastest;

  TopThreeDriver({
    required this.position,
    required this.showPosition,
    required this.racingNumber,
    required this.tla,
    required this.broadcastName,
    required this.fullName,
    required this.team,
    required this.teamColour,
    required this.lapTime,
    required this.lapState,
    required this.diffToAhead,
    required this.diffToLeader,
    required this.overallFastest,
    required this.personalFastest,
  });

  factory TopThreeDriver.fromJson(Map<String, dynamic> json) {
    return TopThreeDriver(
      position: json['position'] ?? '',
      showPosition: json['showPosition'] ?? false,
      racingNumber: json['racingNumber'] ?? '',
      tla: json['tla'] ?? '',
      broadcastName: json['broadcastName'] ?? '',
      fullName: json['fullName'] ?? '',
      team: json['team'] ?? '',
      teamColour: json['teamColour'] ?? '',
      lapTime: json['lapTime'] ?? '',
      lapState: json['lapState'] ?? 0,
      diffToAhead: json['diffToAhead'] ?? '',
      diffToLeader: json['diffToLeader'] ?? '',
      overallFastest: json['overallFastest'] ?? false,
      personalFastest: json['personalFastest'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'position': position,
        'showPosition': showPosition,
        'racingNumber': racingNumber,
        'tla': tla,
        'broadcastName': broadcastName,
        'fullName': fullName,
        'team': team,
        'teamColour': teamColour,
        'lapTime': lapTime,
        'lapState': lapState,
        'diffToAhead': diffToAhead,
        'diffToLeader': diffToLeader,
        'overallFastest': overallFastest,
        'personalFastest': personalFastest,
      };
}

class TimingStats {
  final bool withheld;
  final Map<String, TimingStatsDriver> lines;
  final String sessionType;
  final bool kf;

  TimingStats({
    required this.withheld,
    required this.lines,
    required this.sessionType,
    required this.kf,
  });

  factory TimingStats.fromJson(Map<String, dynamic> json) {
    Map<String, TimingStatsDriver> linesMap = {};
    if (json['lines'] != null) {
      json['lines'].forEach((key, value) {
        linesMap[key] = TimingStatsDriver.fromJson(value);
      });
    }

    return TimingStats(
      withheld: json['withheld'] ?? false,
      lines: linesMap,
      sessionType: json['sessionType'] ?? '',
      kf: json['_kf'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> linesMap = {};
    lines.forEach((key, value) {
      linesMap[key] = value.toJson();
    });

    return {
      'withheld': withheld,
      'lines': linesMap,
      'sessionType': sessionType,
      '_kf': kf,
    };
  }
}

class TimingStatsDriver {
  final int line;
  final String racingNumber;
  final PersonalBestLapTime personalBestLapTime;
  final List<PersonalBestLapTime> bestSectors;
  final Map<String, PersonalBestLapTime> bestSpeeds;

  TimingStatsDriver({
    required this.line,
    required this.racingNumber,
    required this.personalBestLapTime,
    required this.bestSectors,
    required this.bestSpeeds,
  });

  factory TimingStatsDriver.fromJson(Map<String, dynamic> json) {
    List<PersonalBestLapTime> sectors = [];
    if (json['bestSectors'] != null) {
      sectors = List<PersonalBestLapTime>.from(
        json['bestSectors'].map((x) => PersonalBestLapTime.fromJson(x)),
      );
    }

    Map<String, PersonalBestLapTime> speeds = {};
    if (json['bestSpeeds'] != null) {
      if (json['bestSpeeds']['i1'] != null)
        speeds['i1'] = PersonalBestLapTime.fromJson(json['bestSpeeds']['i1']);
      if (json['bestSpeeds']['i2'] != null)
        speeds['i2'] = PersonalBestLapTime.fromJson(json['bestSpeeds']['i2']);
      if (json['bestSpeeds']['fl'] != null)
        speeds['fl'] = PersonalBestLapTime.fromJson(json['bestSpeeds']['fl']);
      if (json['bestSpeeds']['st'] != null)
        speeds['st'] = PersonalBestLapTime.fromJson(json['bestSpeeds']['st']);
    }

    return TimingStatsDriver(
      line: json['line'] ?? 0,
      racingNumber: json['racingNumber'] ?? '',
      personalBestLapTime: json['personalBestLapTime'] != null
          ? PersonalBestLapTime.fromJson(json['personalBestLapTime'])
          : PersonalBestLapTime(value: '', lap: 0),
      bestSectors: sectors,
      bestSpeeds: speeds,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> speedsMap = {};
    bestSpeeds.forEach((key, value) {
      speedsMap[key] = value.toJson();
    });

    return {
      'line': line,
      'racingNumber': racingNumber,
      'personalBestLapTime': personalBestLapTime.toJson(),
      'bestSectors': bestSectors.map((x) => x.toJson()).toList(),
      'bestSpeeds': speedsMap,
    };
  }
}

class PersonalBestLapTime {
  final String value;
  final int lap;

  PersonalBestLapTime({
    required this.value,
    required this.lap,
  });

  factory PersonalBestLapTime.fromJson(Map<String, dynamic> json) {
    return PersonalBestLapTime(
      value: json['Value'] ?? '',
      lap: json['Lap'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'lap': lap,
      };
}

class TimingAppData {
  final Map<String, TimingAppDataDriver> lines;

  TimingAppData({
    required this.lines,
  });

  factory TimingAppData.fromJson(Map<String, dynamic> json) {
    Map<String, TimingAppDataDriver> linesMap = {};
    if (json['lines'] != null) {
      json['lines'].forEach((key, value) {
        linesMap[key] = TimingAppDataDriver.fromJson(value);
      });
    }

    return TimingAppData(
      lines: linesMap,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> linesMap = {};
    lines.forEach((key, value) {
      linesMap[key] = value.toJson();
    });

    return {
      'lines': linesMap,
    };
  }
}

class TimingAppDataDriver {
  final String racingNumber;
  final List<Stint> stints;
  final int line;
  final String gridPos;

  TimingAppDataDriver({
    required this.racingNumber,
    required this.stints,
    required this.line,
    required this.gridPos,
  });

  factory TimingAppDataDriver.fromJson(Map<String, dynamic> json) {
    List<Stint> stintsList = [];
    if (json['Stints'] != null) {
      stintsList = List<Stint>.from(
        json['Stints'].map((x) => Stint.fromJson(x)),
      );
    }

    return TimingAppDataDriver(
      racingNumber: json['racingNumber'] ?? '',
      stints: stintsList,
      line: json['line'] ?? 0,
      gridPos: json['GridPos'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'racingNumber': racingNumber,
        'stints': stints.map((x) => x.toJson()).toList(),
        'line': line,
        'gridPos': gridPos,
      };
}

class Stint {
  final int? totalLaps;
  final String? compound;
  final String? isNew;

  Stint({
    this.totalLaps,
    this.compound,
    this.isNew,
  });

  factory Stint.fromJson(Map<String, dynamic> json) {
    return Stint(
      totalLaps: json['totalLaps'],
      compound: json['Compound'],
      isNew: json['new'],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    if (totalLaps != null) result['totalLaps'] = totalLaps;
    if (compound != null) result['compound'] = compound;
    if (isNew != null) result['new'] = isNew;
    return result;
  }
}

class WeatherData {
  final String airTemp;
  final String humidity;
  final String pressure;
  final String rainfall;
  final String trackTemp;
  final String windDirection;
  final String windSpeed;

  WeatherData({
    required this.airTemp,
    required this.humidity,
    required this.pressure,
    required this.rainfall,
    required this.trackTemp,
    required this.windDirection,
    required this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      airTemp: json['airTemp']?.toString() ?? '',
      humidity: json['humidity']?.toString() ?? '',
      pressure: json['pressure']?.toString() ?? '',
      rainfall: json['rainfall']?.toString() ?? '',
      trackTemp: json['trackTemp']?.toString() ?? '',
      windDirection: json['windDirection']?.toString() ?? '',
      windSpeed: json['windSpeed']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'airTemp': airTemp,
        'humidity': humidity,
        'pressure': pressure,
        'rainfall': rainfall,
        'trackTemp': trackTemp,
        'windDirection': windDirection,
        'windSpeed': windSpeed,
      };
}

class TrackStatus {
  final String status;
  final String message;

  TrackStatus({
    required this.status,
    required this.message,
  });

  factory TrackStatus.fromJson(Map<String, dynamic> json) {
    return TrackStatus(
      status: json['status'] ?? json['TrackStatus'] ?? '',
      message: json['message'] ?? json['Message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
      };
}

class SessionStatus {
  final String status;

  SessionStatus({
    required this.status,
  });

  factory SessionStatus.fromJson(Map<String, dynamic> json) {
    return SessionStatus(
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
      };
}

class DriverList {
  final Map<String, Driver> drivers;

  DriverList({
    required this.drivers,
  });

  factory DriverList.fromJson(Map<String, dynamic> json) {
    Map<String, Driver> driversMap = {};
    json.forEach((key, value) {
      driversMap[key] = Driver.fromJson(value);
    });

    return DriverList(
      drivers: driversMap,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> driversMap = {};
    drivers.forEach((key, value) {
      driversMap[key] = value.toJson();
    });
    return driversMap;
  }
}

class Driver {
  final String racingNumber;
  final String broadcastName;
  final String fullName;
  final String tla;
  final int line;
  final String teamName;
  final String teamColour;
  final String firstName;
  final String lastName;
  final String reference;
  final String headshotUrl;
  final String countryCode;

  Driver({
    required this.racingNumber,
    required this.broadcastName,
    required this.fullName,
    required this.tla,
    required this.line,
    required this.teamName,
    required this.teamColour,
    required this.firstName,
    required this.lastName,
    required this.reference,
    required this.headshotUrl,
    required this.countryCode,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      racingNumber: json['racingNumber'] ?? json['RacingNumber'] ?? '',
      broadcastName: json['broadcastName'] ?? json['BroadcastName'] ?? '',
      fullName: json['fullName'] ?? json['FullName'] ?? '',
      tla: json['tla'] ?? json['Tla'] ?? '',
      line: json['Line'] ?? 0,
      teamName: json['teamName'] ?? json['TeamName'] ?? '',
      teamColour: json['teamColour'] ?? json['TeamColour'] ?? '',
      firstName: json['firstName'] ?? json['FirstName'] ?? '',
      lastName: json['lastName'] ?? json['LastName'] ?? '',
      reference: json['reference'] ?? json['Reference'] ?? '',
      headshotUrl: json['headshotUrl'] ?? json['HeadshotUrl'] ?? '',
      countryCode: json['countryCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'racingNumber': racingNumber,
        'broadcastName': broadcastName,
        'fullName': fullName,
        'tla': tla,
        'line': line,
        'teamName': teamName,
        'teamColour': teamColour,
        'firstName': firstName,
        'lastName': lastName,
        'reference': reference,
        'headshotUrl': headshotUrl,
        'countryCode': countryCode,
      };
}

class RaceControlMessages {
  final List<Message> messages;

  RaceControlMessages({
    required this.messages,
  });

  factory RaceControlMessages.fromJson(Map<String, dynamic> json) {
    List<Message> messagesList = [];
    if (json['messages'] != null) {
      messagesList = List<Message>.from(
        json['messages'].map((x) => Message.fromJson(x)),
      );
    }

    return RaceControlMessages(
      messages: messagesList,
    );
  }

  Map<String, dynamic> toJson() => {
        'messages': messages.map((x) => x.toJson()).toList(),
      };
}

class Message {
  final String utc;
  final int lap;
  final String message;
  final String category;
  final String? flag;
  final String? scope;
  final int? sector;
  final String? status;

  Message({
    required this.utc,
    required this.lap,
    required this.message,
    required this.category,
    this.flag,
    this.scope,
    this.sector,
    this.status,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      utc: json['utc'] ?? '',
      lap: json['lap'] ?? 0,
      message: json['message'] ?? '',
      category: json['category'] ?? '',
      flag: json['flag'],
      scope: json['scope'],
      sector: json['sector'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {
      'utc': utc,
      'lap': lap,
      'message': message,
      'category': category,
    };
    if (flag != null) result['flag'] = flag;
    if (scope != null) result['scope'] = scope;
    if (sector != null) result['sector'] = sector;
    if (status != null) result['status'] = status;
    return result;
  }
}

class SessionInfo {
  final Meeting meeting;
  final ArchiveStatus archiveStatus;
  final int key;
  final String type;
  final String name;
  final String startDate;
  final String endDate;
  final String gmtOffset;
  final String path;
  final bool? kf;

  SessionInfo({
    required this.meeting,
    required this.archiveStatus,
    required this.key,
    required this.type,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.gmtOffset,
    required this.path,
    this.kf,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      meeting: json['meeting'] != null
          ? Meeting.fromJson(json['meeting'])
          : json['Meeting'] != null
              ? Meeting.fromJson(json['Meeting'])
              : Meeting(
                  key: 0,
                  name: '',
                  officialName: '',
                  location: '',
                  country: Country(key: 0, code: '', name: ''),
                  circuit: Circuit(key: 0, shortName: ''),
                ),
      archiveStatus: json['ArchiveStatus'] != null
          ? ArchiveStatus.fromJson(json['ArchiveStatus'])
          : ArchiveStatus(status: ''),
      key: json['key'] ?? 0,
      type: json['type'] ?? json['Type'] ?? '',
      name: json['name'] ?? json['Name'] ?? '',
      startDate: json['startDate'] ?? json['StartDate'] ?? '',
      endDate: json['endDate'] ?? json['EndDate'] ?? '',
      gmtOffset: json['gmtOffset'] ?? '',
      path: json['path'] ?? '',
      kf: json['kf'],
    );
  }

  // https://media.formula1.com/image/upload/f_auto,c_limit,w_1440,q_auto/f_auto/q_auto/content/dam/fom-website/2018-redesign-assets/Track%20icons%204x3/{CountryName}%20carbon

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {
      'meeting': meeting.toJson(),
      'ArchiveStatus': archiveStatus.toJson(),
      'key': key,
      'type': type,
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'gmtOffset': gmtOffset,
      'path': path,
    };
    if (kf != null) result['number'] = kf;
    return result;
  }
}

class ArchiveStatus {
  final String status;

  ArchiveStatus({
    required this.status,
  });

  factory ArchiveStatus.fromJson(Map<String, dynamic> json) {
    return ArchiveStatus(
      status: json['Status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'Status': status,
      };
}

class Meeting {
  final int key;
  final String name;
  final String officialName;
  final String location;
  final Country country;
  final Circuit circuit;

  Meeting({
    required this.key,
    required this.name,
    required this.officialName,
    required this.location,
    required this.country,
    required this.circuit,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      key: json['key'] ?? 0,
      name: json['Name'] ?? '',
      officialName: json['officialName'] ?? json['OfficialName'] ?? '',
      location: json['location'] ?? json['Location'] ?? '',
      country: json['country'] != null
          ? Country.fromJson(json['country'])
          : json['Country'] != null
              ? Country.fromJson(json['Country'])
              : Country(key: 0, code: '', name: ''),
      circuit: json['circuit'] != null
          ? Circuit.fromJson(json['circuit'])
          : Circuit(key: 0, shortName: ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'officialName': officialName,
        'location': location,
        'country': country.toJson(),
        'circuit': circuit.toJson(),
      };
}

class Circuit {
  final int key;
  final String shortName;

  Circuit({
    required this.key,
    required this.shortName,
  });

  factory Circuit.fromJson(Map<String, dynamic> json) {
    return Circuit(
      key: json['key'] ?? 0,
      shortName: json['shortName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'shortName': shortName,
      };
}

class Country {
  final int key;
  final String code;
  final String name;

  Country({
    required this.key,
    required this.code,
    required this.name,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      key: json['key'] ?? 0,
      code: json['code'] ?? json['Code'] ?? '',
      name: json['name'] ?? json['Name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'code': code,
        'name': name,
      };
}

class SessionData {
  final List<Series> series;
  final List<StatusSeries> statusSeries;

  SessionData({
    required this.series,
    required this.statusSeries,
  });

  factory SessionData.fromJson(Map<String, dynamic> json) {
    List<Series> seriesList = [];
    if (json['series'] != null) {
      seriesList = List<Series>.from(
        json['series'].map((x) => Series.fromJson(x)),
      );
    }

    List<StatusSeries> statusSeriesList = [];
    if (json['statusSeries'] != null) {
      statusSeriesList = List<StatusSeries>.from(
        json['statusSeries'].map((x) => StatusSeries.fromJson(x)),
      );
    }

    return SessionData(
      series: seriesList,
      statusSeries: statusSeriesList,
    );
  }

  Map<String, dynamic> toJson() => {
        'series': series.map((x) => x.toJson()).toList(),
        'statusSeries': statusSeries.map((x) => x.toJson()).toList(),
      };
}

class Series {
  final String utc;
  final int lap;

  Series({
    required this.utc,
    required this.lap,
  });

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      utc: json['utc'] ?? '',
      lap: json['lap'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'utc': utc,
        'lap': lap,
      };
}

class StatusSeries {
  final String utc;
  final String? trackStatus;
  final String? sessionStatus;

  StatusSeries({
    required this.utc,
    this.trackStatus,
    this.sessionStatus,
  });

  factory StatusSeries.fromJson(Map<String, dynamic> json) {
    return StatusSeries(
      utc: json['utc'] ?? '',
      trackStatus: json['trackStatus'],
      sessionStatus:
          json['sesionStatus'], // Note: typo in the original type definition
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {
      'utc': utc,
    };
    if (trackStatus != null) result['trackStatus'] = trackStatus;
    if (sessionStatus != null) result['sesionStatus'] = sessionStatus;
    return result;
  }
}

class LapCount {
  final int currentLap;
  final int totalLaps;

  LapCount({
    required this.currentLap,
    required this.totalLaps,
  });

  factory LapCount.fromJson(Map<String, dynamic> json) {
    return LapCount(
      currentLap: json['currentLap'] ?? 0,
      totalLaps: json['totalLaps'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentLap': currentLap,
        'totalLaps': totalLaps,
      };
}

class TimingData {
  final List<int>? noEntries;
  final int? sessionPart;
  final String? cutOffTime;
  final String? cutOffPercentage;
  final Map<String, TimingDataDriver> lines;
  final bool withheld;

  TimingData({
    this.noEntries,
    this.sessionPart,
    this.cutOffTime,
    this.cutOffPercentage,
    required this.lines,
    required this.withheld,
  });

  factory TimingData.fromJson(Map<String, dynamic> json) {
    Map<String, TimingDataDriver> linesMap = {};
    if (json['lines'] != null) {
      json['lines'].forEach((key, value) {
        linesMap[key] = TimingDataDriver.fromJson(value);
      });
    }

    return TimingData(
      noEntries:
          json['noEntries'] != null ? List<int>.from(json['noEntries']) : null,
      sessionPart: json['sessionPart'],
      cutOffTime: json['cutOffTime'],
      cutOffPercentage: json['cutOffPercentage'],
      lines: linesMap,
      withheld: json['withheld'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {
      'lines': Map.fromEntries(
          lines.entries.map((e) => MapEntry(e.key, e.value.toJson()))),
      'withheld': withheld,
    };
    if (noEntries != null) result['noEntries'] = noEntries;
    if (sessionPart != null) result['sessionPart'] = sessionPart;
    if (cutOffTime != null) result['cutOffTime'] = cutOffTime;
    if (cutOffPercentage != null) result['cutOffPercentage'] = cutOffPercentage;
    return result;
  }
}

class TimingDataDriver {
  final List<TimeDiff>? stats;
  final String? timeDiffToFastest;
  final String? timeDiffToPositionAhead;
  late final String gapToLeader;
  late final IntervalToPositionAhead? intervalToPositionAhead;
  late final int line;
  late final String position;
  final bool showPosition;
  final String racingNumber;
  late final bool retired;
  final bool inPit;
  final bool pitOut;
  final bool stopped;
  final int status;
  final List<Sector> sectors;
  final Speeds speeds;
  final PersonalBestLapTime bestLapTime;
  final I1 lastLapTime;
  final int numberOfLaps;
  final int numberOfPitStops;
  final bool? knockedOut;
  final bool? cutoff;

  TimingDataDriver({
    this.stats,
    this.timeDiffToFastest,
    this.timeDiffToPositionAhead,
    required this.gapToLeader,
    this.intervalToPositionAhead,
    required this.line,
    required this.position,
    required this.showPosition,
    required this.racingNumber,
    required this.retired,
    required this.inPit,
    required this.pitOut,
    required this.stopped,
    required this.status,
    required this.sectors,
    required this.speeds,
    required this.bestLapTime,
    required this.lastLapTime,
    required this.numberOfLaps,
    required this.numberOfPitStops,
    this.knockedOut,
    this.cutoff,
  });

  factory TimingDataDriver.fromJson(Map<String, dynamic> json) {
    List<TimeDiff>? statsList;
    if (json['stats'] != null) {
      statsList = List<TimeDiff>.from(
        json['stats'].map((x) => TimeDiff.fromJson(x)),
      );
    }

    List<Sector> sectorsList = [];
    if (json['sectors'] != null) {
      sectorsList = List<Sector>.from(
        json['sectors'].map((x) => Sector.fromJson(x)),
      );
    }

    return TimingDataDriver(
      stats: statsList,
      timeDiffToFastest: json['timeDiffToFastest'],
      timeDiffToPositionAhead: json['timeDiffToPositionAhead'],
      gapToLeader: json['GapToLeader'] ?? '',
      intervalToPositionAhead: json['IntervalToPositionAhead'] != null
          ? IntervalToPositionAhead.fromJson(json['IntervalToPositionAhead'])
          : null,
      line: json['line'] ?? 0,
      position: json['position'] ?? '',
      showPosition: json['showPosition'] ?? false,
      racingNumber: json['racingNumber'] ?? '',
      retired: json['retired'] ?? false,
      inPit: json['inPit'] ?? false,
      pitOut: json['pitOut'] ?? false,
      stopped: json['stopped'] ?? false,
      status: json['status'] ?? 0,
      sectors: sectorsList,
      speeds: json['Speeds'] != null
          ? Speeds.fromJson(json['Speeds'])
          : Speeds(
              i1: I1(
                  value: '',
                  status: 0,
                  overallFastest: false,
                  personalFastest: false),
              i2: I1(
                  value: '',
                  status: 0,
                  overallFastest: false,
                  personalFastest: false),
              fl: I1(
                  value: '',
                  status: 0,
                  overallFastest: false,
                  personalFastest: false),
              st: I1(
                  value: '',
                  status: 0,
                  overallFastest: false,
                  personalFastest: false),
            ),
      bestLapTime: json['BestLapTime'] != null
          ? PersonalBestLapTime.fromJson(json['BestLapTime'])
          : PersonalBestLapTime(value: '', lap: 0),
      lastLapTime: json['LastLapTime'] != null
          ? I1.fromJson(json['LastLapTime'])
          : I1(
              value: '',
              status: 0,
              overallFastest: false,
              personalFastest: false),
      numberOfLaps: json['numberOfLaps'] ?? 0,
      numberOfPitStops: json['NumberOfPitStops'] ?? 0,
      knockedOut: json['knockedOut'],
      cutoff: json['cutoff'],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {
      'gapToLeader': gapToLeader,
      'line': line,
      'position': position,
      'showPosition': showPosition,
      'racingNumber': racingNumber,
      'retired': retired,
      'inPit': inPit,
      'pitOut': pitOut,
      'stopped': stopped,
      'status': status,
      'sectors': sectors.map((x) => x.toJson()).toList(),
      'speeds': speeds.toJson(),
      'bestLapTime': bestLapTime.toJson(),
      'lastLapTime': lastLapTime.toJson(),
      'numberOfLaps': numberOfLaps,
      'numberOfPitStops': numberOfPitStops,
    };
    if (stats != null) result['stats'] = stats!.map((x) => x.toJson()).toList();
    if (timeDiffToFastest != null)
      result['timeDiffToFastest'] = timeDiffToFastest;
    if (timeDiffToPositionAhead != null)
      result['timeDiffToPositionAhead'] = timeDiffToPositionAhead;
    if (intervalToPositionAhead != null)
      result['intervalToPositionAhead'] = intervalToPositionAhead!.toJson();
    if (knockedOut != null) result['knockedOut'] = knockedOut;
    if (cutoff != null) result['cutoff'] = cutoff;
    return result;
  }
}

class TimeDiff {
  final String timeDiffToFastest;
  final String timeDifftoPositionAhead;

  TimeDiff({
    required this.timeDiffToFastest,
    required this.timeDifftoPositionAhead,
  });

  factory TimeDiff.fromJson(Map<String, dynamic> json) {
    return TimeDiff(
      timeDiffToFastest: json['timeDiffToFastest'] ?? '',
      timeDifftoPositionAhead: json['timeDifftoPositionAhead'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'timeDiffToFastest': timeDiffToFastest,
        'timeDifftoPositionAhead': timeDifftoPositionAhead,
      };
}

class IntervalToPositionAhead {
  final String value;
  final bool catching;

  IntervalToPositionAhead({
    required this.value,
    required this.catching,
  });

  factory IntervalToPositionAhead.fromJson(Map<String, dynamic> json) {
    return IntervalToPositionAhead(
      value: json['Value'] ?? '',
      catching: json['Catching'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'catching': catching,
      };
}

class Sector {
  final bool stopped;
  final String value;
  final String? previousValue;
  final int status;
  final bool overallFastest;
  final bool personalFastest;
  final List<Segment> segments;

  Sector({
    required this.stopped,
    required this.value,
    this.previousValue,
    required this.status,
    required this.overallFastest,
    required this.personalFastest,
    required this.segments,
  });

  factory Sector.fromJson(Map<String, dynamic> json) {
    List<Segment> segmentsList = [];
    if (json['Segments'] != null) {
      segmentsList = List<Segment>.from(
        json['Segments'].map((x) => Segment.fromJson(x)),
      );
    }

    return Sector(
      stopped: json['Stopped'] ?? false,
      value: json['Value'] ?? '',
      previousValue: json['PreviousValue'],
      status: json['Status'] ?? 0,
      overallFastest: json['OverallFastest'] ?? false,
      personalFastest: json['PersonalFastest'] ?? false,
      segments: segmentsList,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {
      'stopped': stopped,
      'value': value,
      'status': status,
      'overallFastest': overallFastest,
      'personalFastest': personalFastest,
      'segments': segments.map((x) => x.toJson()).toList(),
    };
    if (previousValue != null) result['previousValue'] = previousValue;
    return result;
  }
}

class Segment {
  final int status;

  Segment({
    required this.status,
  });

  factory Segment.fromJson(Map<String, dynamic> json) {
    return Segment(
      status: json['Status'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
      };
}

class Speeds {
  final I1 i1;
  final I1 i2;
  final I1 fl;
  final I1 st;

  Speeds({
    required this.i1,
    required this.i2,
    required this.fl,
    required this.st,
  });

  factory Speeds.fromJson(Map<String, dynamic> json) {
    return Speeds(
      i1: json['I1'] != null
          ? I1.fromJson(json['I1'])
          : I1(
              value: '',
              status: 0,
              overallFastest: false,
              personalFastest: false),
      i2: json['I2'] != null
          ? I1.fromJson(json['I2'])
          : I1(
              value: '',
              status: 0,
              overallFastest: false,
              personalFastest: false),
      fl: json['FL'] != null
          ? I1.fromJson(json['FL'])
          : I1(
              value: '',
              status: 0,
              overallFastest: false,
              personalFastest: false),
      st: json['ST'] != null
          ? I1.fromJson(json['ST'])
          : I1(
              value: '',
              status: 0,
              overallFastest: false,
              personalFastest: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'i1': i1.toJson(),
        'i2': i2.toJson(),
        'fl': fl.toJson(),
        'st': st.toJson(),
      };
}

class I1 {
  final String value;
  final int status;
  final bool overallFastest;
  final bool personalFastest;

  I1({
    required this.value,
    required this.status,
    required this.overallFastest,
    required this.personalFastest,
  });

  factory I1.fromJson(Map<String, dynamic> json) {
    return I1(
      value: json['Value'] ?? '',
      status: json['Status'] ?? 0,
      overallFastest: json['OverallFastest'] ?? false,
      personalFastest: json['PersonalFastest'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'status': status,
        'overallFastest': overallFastest,
        'personalFastest': personalFastest,
      };
}

class TeamRadio {
  final List<RadioCapture> captures;

  TeamRadio({
    required this.captures,
  });

  factory TeamRadio.fromJson(Map<String, dynamic> json) {
    List<RadioCapture> capturesList = [];
    if (json['captures'] != null) {
      capturesList = List<RadioCapture>.from(
        json['captures'].map((x) => RadioCapture.fromJson(x)),
      );
    }

    return TeamRadio(
      captures: capturesList,
    );
  }

  Map<String, dynamic> toJson() => {
        'captures': captures.map((x) => x.toJson()).toList(),
      };
}

class RadioCapture {
  final String utc;
  final String racingNumber;
  final String path;

  RadioCapture({
    required this.utc,
    required this.racingNumber,
    required this.path,
  });

  factory RadioCapture.fromJson(Map<String, dynamic> json) {
    return RadioCapture(
      utc: json['utc'] ?? '',
      racingNumber: json['racingNumber'] ?? '',
      path: json['path'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'utc': utc,
        'racingNumber': racingNumber,
        'path': path,
      };
}

class ChampionshipPrediction {
  final Map<String, ChampionshipDriver> drivers;
  final Map<String, ChampionshipTeam> teams;

  ChampionshipPrediction({
    required this.drivers,
    required this.teams,
  });

  factory ChampionshipPrediction.fromJson(Map<String, dynamic> json) {
    Map<String, ChampionshipDriver> driversMap = {};
    if (json['drivers'] != null) {
      json['drivers'].forEach((key, value) {
        driversMap[key] = ChampionshipDriver.fromJson(value);
      });
    }

    Map<String, ChampionshipTeam> teamsMap = {};
    if (json['teams'] != null) {
      json['teams'].forEach((key, value) {
        teamsMap[key] = ChampionshipTeam.fromJson(value);
      });
    }

    return ChampionshipPrediction(
      drivers: driversMap,
      teams: teamsMap,
    );
  }

  Map<String, dynamic> toJson() => {
        'drivers': Map.fromEntries(
            drivers.entries.map((e) => MapEntry(e.key, e.value.toJson()))),
        'teams': Map.fromEntries(
            teams.entries.map((e) => MapEntry(e.key, e.value.toJson()))),
      };
}

class ChampionshipDriver {
  final String racingNumber;
  final int currentPosition;
  final int predictedPosition;
  final int currentPoints;
  final int predictedPoints;

  ChampionshipDriver({
    required this.racingNumber,
    required this.currentPosition,
    required this.predictedPosition,
    required this.currentPoints,
    required this.predictedPoints,
  });

  factory ChampionshipDriver.fromJson(Map<String, dynamic> json) {
    return ChampionshipDriver(
      racingNumber: json['racingNumber'] ?? '',
      currentPosition: json['currentPosition'] ?? 0,
      predictedPosition: json['predictedPosition'] ?? 0,
      currentPoints: json['currentPoints'] ?? 0,
      predictedPoints: json['predictedPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'racingNumber': racingNumber,
        'currentPosition': currentPosition,
        'predictedPosition': predictedPosition,
        'currentPoints': currentPoints,
        'predictedPoints': predictedPoints,
      };
}

class ChampionshipTeam {
  final String teamName;
  final int currentPosition;
  final int predictedPosition;
  final int currentPoints;
  final int predictedPoints;

  ChampionshipTeam({
    required this.teamName,
    required this.currentPosition,
    required this.predictedPosition,
    required this.currentPoints,
    required this.predictedPoints,
  });

  factory ChampionshipTeam.fromJson(Map<String, dynamic> json) {
    return ChampionshipTeam(
      teamName: json['teamName'] ?? '',
      currentPosition: json['currentPosition'] ?? 0,
      predictedPosition: json['predictedPosition'] ?? 0,
      currentPoints: json['currentPoints'] ?? 0,
      predictedPoints: json['predictedPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'teamName': teamName,
        'currentPosition': currentPosition,
        'predictedPosition': predictedPosition,
        'currentPoints': currentPoints,
        'predictedPoints': predictedPoints,
      };
}

class Position {
  final List<PositionItem> positions;

  Position({
    required this.positions,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    List<PositionItem> positionsList = [];
    if (json['Position'] != null) {
      positionsList = List<PositionItem>.from(
        json['Position'].map((x) => PositionItem.fromJson(x)),
      );
    }

    return Position(
      positions: positionsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'Position': positions.map((x) => x.toJson()).toList(),
      };
}

class PositionItem {
  final String timestamp;
  final Map<String, PositionCar> entries;

  PositionItem({
    required this.timestamp,
    required this.entries,
  });

  factory PositionItem.fromJson(Map<String, dynamic> json) {
    Map<String, PositionCar> entriesMap = {};
    if (json['Entries'] != null) {
      json['Entries'].forEach((key, value) {
        entriesMap[key] = PositionCar.fromJson(value);
      });
    }

    return PositionItem(
      timestamp: json['Timestamp'] ?? '',
      entries: entriesMap,
    );
  }

  Map<String, dynamic> toJson() => {
        'Timestamp': timestamp,
        'Entries': Map.fromEntries(
            entries.entries.map((e) => MapEntry(e.key, e.value.toJson()))),
      };
}

class PositionCar {
  final String status;
  final double x;
  final double y;
  final double z;

  PositionCar({
    required this.status,
    required this.x,
    required this.y,
    required this.z,
  });

  factory PositionCar.fromJson(Map<String, dynamic> json) {
    return PositionCar(
      status: json['Status'] ?? '',
      x: (json['X'] ?? 0).toDouble(),
      y: (json['Y'] ?? 0).toDouble(),
      z: (json['Z'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'Status': status,
        'X': x,
        'Y': y,
        'Z': z,
      };
}

class CarData {
  final List<Entry> entries;

  CarData({
    required this.entries,
  });

  factory CarData.fromJson(Map<String, dynamic> json) {
    List<Entry> entriesList = [];
    if (json['Entries'] != null) {
      entriesList = List<Entry>.from(
        json['Entries'].map((x) => Entry.fromJson(x)),
      );
    }

    return CarData(
      entries: entriesList,
    );
  }

  Map<String, dynamic> toJson() => {
        'Entries': entries.map((x) => x.toJson()).toList(),
      };
}

class Entry {
  final String utc;
  final Map<String, Car> cars;

  Entry({
    required this.utc,
    required this.cars,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    Map<String, Car> carsMap = {};
    if (json['Cars'] != null) {
      json['Cars'].forEach((key, value) {
        carsMap[key] = Car.fromJson(value);
      });
    }

    return Entry(
      utc: json['Utc'] ?? '',
      cars: carsMap,
    );
  }

  Map<String, dynamic> toJson() => {
        'Utc': utc,
        'Cars': Map.fromEntries(
            cars.entries.map((e) => MapEntry(e.key, e.value.toJson()))),
      };
}

class Car {
  final CarDataChannels channels;

  Car({
    required this.channels,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      channels: json['Channels'] != null
          ? CarDataChannels.fromJson(json['Channels'])
          : CarDataChannels(
              rpm: 0,
              speed: 0,
              gear: 0,
              throttle: 0,
              brake: 0,
              drs: 0,
            ),
    );
  }

  Map<String, dynamic> toJson() => {
        'Channels': channels.toJson(),
      };
}

class CarDataChannels {
  final int rpm; // Channel 0
  final int speed; // Channel 2
  final int gear; // Channel 3
  final int throttle; // Channel 4
  final int brake; // Channel 5
  final int drs; // Channel 45

  CarDataChannels({
    required this.rpm,
    required this.speed,
    required this.gear,
    required this.throttle,
    required this.brake,
    required this.drs,
  });

  factory CarDataChannels.fromJson(Map<String, dynamic> json) {
    return CarDataChannels(
      rpm: json['0'] ?? 0,
      speed: json['2'] ?? 0,
      gear: json['3'] ?? 0,
      throttle: json['4'] ?? 0,
      brake: json['5'] ?? 0,
      drs: json['45'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        '0': rpm,
        '2': speed,
        '3': gear,
        '4': throttle,
        '5': brake,
        '45': drs,
      };
}
