import 'dart:convert';

class F1ScheduleResponse {
  final MRData mrData;

  F1ScheduleResponse({
    required this.mrData,
  });

  factory F1ScheduleResponse.fromJson(Map<String, dynamic> json) {
    return F1ScheduleResponse(
      mrData: MRData.fromJson(json['MRData']),
    );
  }

  factory F1ScheduleResponse.fromRawJson(String str) =>
      F1ScheduleResponse.fromJson(json.decode(str));

  Map<String, dynamic> toJson() => {
        'MRData': mrData.toJson(),
      };
}

class MRData {
  final String xmlns;
  final String series;
  final String url;
  final String limit;
  final String offset;
  final String total;
  final RaceTable raceTable;

  MRData({
    required this.xmlns,
    required this.series,
    required this.url,
    required this.limit,
    required this.offset,
    required this.total,
    required this.raceTable,
  });

  factory MRData.fromJson(Map<String, dynamic> json) {
    return MRData(
      xmlns: json['xmlns'] ?? '',
      series: json['series'] ?? '',
      url: json['url'] ?? '',
      limit: json['limit'] ?? '',
      offset: json['offset'] ?? '',
      total: json['total'] ?? '',
      raceTable: RaceTable.fromJson(json['RaceTable']),
    );
  }

  Map<String, dynamic> toJson() => {
        'xmlns': xmlns,
        'series': series,
        'url': url,
        'limit': limit,
        'offset': offset,
        'total': total,
        'RaceTable': raceTable.toJson(),
      };
}

class RaceTable {
  final String season;
  final List<Race> races;

  RaceTable({
    required this.season,
    required this.races,
  });

  factory RaceTable.fromJson(Map<String, dynamic> json) {
    return RaceTable(
      season: json['season'] ?? '',
      races: json['Races'] != null
          ? List<Race>.from(json['Races'].map((x) => Race.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'season': season,
        'Races': List<dynamic>.from(races.map((x) => x.toJson())),
      };
}

class Race {
  final String season;
  final String round;
  final String url;
  final String raceName;
  final Circuit circuit;
  final String date;
  final String time;
  final SessionInfo? firstPractice;
  final SessionInfo? secondPractice;
  final SessionInfo? thirdPractice;
  final SessionInfo? qualifying;
  final SessionInfo? sprint;
  final SessionInfo? sprintQualifying;

  Race({
    required this.season,
    required this.round,
    required this.url,
    required this.raceName,
    required this.circuit,
    required this.date,
    required this.time,
    this.firstPractice,
    this.secondPractice,
    this.thirdPractice,
    this.qualifying,
    this.sprint,
    this.sprintQualifying,
  });

  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      season: json['season'] ?? '',
      round: json['round'] ?? '',
      url: json['url'] ?? '',
      raceName: json['raceName'] ?? '',
      circuit: Circuit.fromJson(json['Circuit']),
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      firstPractice: json['FirstPractice'] != null
          ? SessionInfo.fromJson(json['FirstPractice'])
          : null,
      secondPractice: json['SecondPractice'] != null
          ? SessionInfo.fromJson(json['SecondPractice'])
          : null,
      thirdPractice: json['ThirdPractice'] != null
          ? SessionInfo.fromJson(json['ThirdPractice'])
          : null,
      qualifying: json['Qualifying'] != null
          ? SessionInfo.fromJson(json['Qualifying'])
          : null,
      sprint:
          json['Sprint'] != null ? SessionInfo.fromJson(json['Sprint']) : null,
      sprintQualifying: json['SprintQualifying'] != null
          ? SessionInfo.fromJson(json['SprintQualifying'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'season': season,
      'round': round,
      'url': url,
      'raceName': raceName,
      'Circuit': circuit.toJson(),
      'date': date,
      'time': time,
    };

    if (firstPractice != null) data['FirstPractice'] = firstPractice!.toJson();
    if (secondPractice != null)
      data['SecondPractice'] = secondPractice!.toJson();
    if (thirdPractice != null) data['ThirdPractice'] = thirdPractice!.toJson();
    if (qualifying != null) data['Qualifying'] = qualifying!.toJson();
    if (sprint != null) data['Sprint'] = sprint!.toJson();
    if (sprintQualifying != null)
      data['SprintQualifying'] = sprintQualifying!.toJson();

    return data;
  }

  /// Returns a DateTime object for the race start time
  DateTime get raceDateTime {
    // Combines date and time strings into a DateTime object
    return DateTime.parse('${date}T$time');
  }

  /// Checks if this race weekend includes a sprint race
  bool get hasSprint => sprint != null;
}

class Circuit {
  final String circuitId;
  final String url;
  final String circuitName;
  final Location location;

  Circuit({
    required this.circuitId,
    required this.url,
    required this.circuitName,
    required this.location,
  });

  factory Circuit.fromJson(Map<String, dynamic> json) {
    return Circuit(
      circuitId: json['circuitId'] ?? '',
      url: json['url'] ?? '',
      circuitName: json['circuitName'] ?? '',
      location: Location.fromJson(json['Location']),
    );
  }

  Map<String, dynamic> toJson() => {
        'circuitId': circuitId,
        'url': url,
        'circuitName': circuitName,
        'Location': location.toJson(),
      };
}

class Location {
  final String lat;
  final String long;
  final String locality;
  final String country;

  Location({
    required this.lat,
    required this.long,
    required this.locality,
    required this.country,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: json['lat'] ?? '',
      long: json['long'] ?? '',
      locality: json['locality'] ?? '',
      country: json['country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'long': long,
        'locality': locality,
        'country': country,
      };

  /// Returns latitude as double
  double get latitude => double.tryParse(lat) ?? 0.0;

  /// Returns longitude as double
  double get longitude => double.tryParse(long) ?? 0.0;
}

class SessionInfo {
  final String date;
  final String time;

  SessionInfo({
    required this.date,
    required this.time,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      date: json['date'] ?? '',
      time: json['time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'time': time,
      };

  /// Returns a DateTime object for the session start time
  DateTime get dateTime {
    // Combines date and time strings into a DateTime object
    return DateTime.parse('${date}T$time');
  }
}
