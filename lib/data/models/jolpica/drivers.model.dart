import 'dart:convert';

class DriverStandingsResponse {
  final MRData mRData;

  DriverStandingsResponse({
    required this.mRData,
  });

  factory DriverStandingsResponse.fromRawJson(String str) =>
      DriverStandingsResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory DriverStandingsResponse.fromJson(Map<String, dynamic> json) =>
      DriverStandingsResponse(
        mRData: MRData.fromJson(json["MRData"]),
      );

  Map<String, dynamic> toJson() => {
        "MRData": mRData.toJson(),
      };
}

class MRData {
  final String xmlns;
  final String series;
  final String url;
  final String limit;
  final String offset;
  final String total;
  final StandingsTable standingsTable;

  MRData({
    required this.xmlns,
    required this.series,
    required this.url,
    required this.limit,
    required this.offset,
    required this.total,
    required this.standingsTable,
  });

  factory MRData.fromRawJson(String str) => MRData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory MRData.fromJson(Map<String, dynamic> json) => MRData(
        xmlns: json["xmlns"],
        series: json["series"],
        url: json["url"],
        limit: json["limit"],
        offset: json["offset"],
        total: json["total"],
        standingsTable: StandingsTable.fromJson(json["StandingsTable"]),
      );

  Map<String, dynamic> toJson() => {
        "xmlns": xmlns,
        "series": series,
        "url": url,
        "limit": limit,
        "offset": offset,
        "total": total,
        "StandingsTable": standingsTable.toJson(),
      };
}

class StandingsTable {
  final String season;
  final String round;
  final List<StandingsList> standingsLists;

  StandingsTable({
    required this.season,
    required this.round,
    required this.standingsLists,
  });

  factory StandingsTable.fromRawJson(String str) =>
      StandingsTable.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory StandingsTable.fromJson(Map<String, dynamic> json) => StandingsTable(
        season: json["season"],
        round: json["round"],
        standingsLists: List<StandingsList>.from(
            json["StandingsLists"].map((x) => StandingsList.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "season": season,
        "round": round,
        "StandingsLists":
            List<dynamic>.from(standingsLists.map((x) => x.toJson())),
      };
}

class StandingsList {
  final String season;
  final String round;
  final List<DriverStanding> driverStandings;

  StandingsList({
    required this.season,
    required this.round,
    required this.driverStandings,
  });

  factory StandingsList.fromRawJson(String str) =>
      StandingsList.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory StandingsList.fromJson(Map<String, dynamic> json) => StandingsList(
        season: json["season"],
        round: json["round"],
        driverStandings: List<DriverStanding>.from(
            json["DriverStandings"].map((x) => DriverStanding.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "season": season,
        "round": round,
        "DriverStandings":
            List<dynamic>.from(driverStandings.map((x) => x.toJson())),
      };
}

class DriverStanding {
  final String position;
  final String positionText;
  final String points;
  final String wins;
  final Driver driver;
  final List<Constructor> constructors;

  DriverStanding({
    required this.position,
    required this.positionText,
    required this.points,
    required this.wins,
    required this.driver,
    required this.constructors,
  });

  factory DriverStanding.fromRawJson(String str) =>
      DriverStanding.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory DriverStanding.fromJson(Map<String, dynamic> json) => DriverStanding(
        position: json["position"],
        positionText: json["positionText"],
        points: json["points"],
        wins: json["wins"],
        driver: Driver.fromJson(json["Driver"]),
        constructors: List<Constructor>.from(
            json["Constructors"].map((x) => Constructor.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "position": position,
        "positionText": positionText,
        "points": points,
        "wins": wins,
        "Driver": driver.toJson(),
        "Constructors": List<dynamic>.from(constructors.map((x) => x.toJson())),
      };
}

class Constructor {
  final String constructorId;
  final String url;
  final String name;
  final String nationality;

  Constructor({
    required this.constructorId,
    required this.url,
    required this.name,
    required this.nationality,
  });

  factory Constructor.fromRawJson(String str) =>
      Constructor.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Constructor.fromJson(Map<String, dynamic> json) => Constructor(
        constructorId: json["constructorId"],
        url: json["url"],
        name: json["name"],
        nationality: json["nationality"],
      );

  Map<String, dynamic> toJson() => {
        "constructorId": constructorId,
        "url": url,
        "name": name,
        "nationality": nationality,
      };
}

class Driver {
  final String driverId;
  final String permanentNumber;
  final String code;
  final String url;
  final String givenName;
  final String familyName;
  final String dateOfBirth;
  final String nationality;

  Driver({
    required this.driverId,
    required this.permanentNumber,
    required this.code,
    required this.url,
    required this.givenName,
    required this.familyName,
    required this.dateOfBirth,
    required this.nationality,
  });

  factory Driver.fromRawJson(String str) => Driver.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
        driverId: json["driverId"],
        permanentNumber: json["permanentNumber"],
        code: json["code"],
        url: json["url"],
        givenName: json["givenName"],
        familyName: json["familyName"],
        dateOfBirth: json["dateOfBirth"],
        nationality: json["nationality"],
      );

  Map<String, dynamic> toJson() => {
        "driverId": driverId,
        "permanentNumber": permanentNumber,
        "code": code,
        "url": url,
        "givenName": givenName,
        "familyName": familyName,
        "dateOfBirth": dateOfBirth,
        "nationality": nationality,
      };
}
