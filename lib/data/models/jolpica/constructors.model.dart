import 'dart:convert';

class ConstructorStandingsResponse {
  final MRData mRData;

  ConstructorStandingsResponse({
    required this.mRData,
  });

  factory ConstructorStandingsResponse.fromRawJson(String str) =>
      ConstructorStandingsResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ConstructorStandingsResponse.fromJson(Map<String, dynamic> json) =>
      ConstructorStandingsResponse(
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
  final List<ConstructorStanding> constructorStandings;

  StandingsList({
    required this.season,
    required this.round,
    required this.constructorStandings,
  });

  factory StandingsList.fromRawJson(String str) =>
      StandingsList.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory StandingsList.fromJson(Map<String, dynamic> json) => StandingsList(
        season: json["season"],
        round: json["round"],
        constructorStandings: List<ConstructorStanding>.from(
            json["ConstructorStandings"]
                .map((x) => ConstructorStanding.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "season": season,
        "round": round,
        "ConstructorStandings":
            List<dynamic>.from(constructorStandings.map((x) => x.toJson())),
      };
}

class ConstructorStanding {
  final String position;
  final String positionText;
  final String points;
  final String wins;
  final Constructor constructor;

  ConstructorStanding({
    required this.position,
    required this.positionText,
    required this.points,
    required this.wins,
    required this.constructor,
  });

  factory ConstructorStanding.fromRawJson(String str) =>
      ConstructorStanding.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ConstructorStanding.fromJson(Map<String, dynamic> json) =>
      ConstructorStanding(
        position: json["position"],
        positionText: json["positionText"],
        points: json["points"],
        wins: json["wins"],
        constructor: Constructor.fromJson(json["Constructor"]),
      );

  Map<String, dynamic> toJson() => {
        "position": position,
        "positionText": positionText,
        "points": points,
        "wins": wins,
        "Constructor": constructor.toJson(),
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
