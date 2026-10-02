import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/data/models/jolpica/drivers.model.dart';
import 'package:formulavision/pages/drivers_standings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final currentYear = DateTime.now().year.toString();

  setUp(() {
    final response = _driverStandingsResponse(
      code: 'ANT',
      givenName: 'Andrea Kimi',
      familyName: 'Antonelli',
    );

    SharedPreferences.setMockInitialValues({
      'driver_standings_$currentYear': jsonEncode(response.toJson()),
      'driver_standings_${currentYear}_timestamp':
          DateTime.now().millisecondsSinceEpoch,
    });
  });

  testWidgets('iOS standings show the driver three-letter code',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(
        const MaterialApp(home: DriversStandingsPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ANT'), findsOneWidget);
      expect(find.text('Andrea Kimi\nAntonelli'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('non-iOS standings retain the full driver name', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(
        const MaterialApp(home: DriversStandingsPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Andrea Kimi\nAntonelli'), findsOneWidget);
      expect(find.text('ANT'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

DriverStandingsResponse _driverStandingsResponse({
  required String code,
  required String givenName,
  required String familyName,
}) {
  return DriverStandingsResponse(
    mRData: MRData(
      xmlns: '',
      series: 'f1',
      url: '',
      limit: '30',
      offset: '0',
      total: '1',
      standingsTable: StandingsTable(
        season: DateTime.now().year.toString(),
        round: '1',
        standingsLists: [
          StandingsList(
            season: DateTime.now().year.toString(),
            round: '1',
            driverStandings: [
              DriverStanding(
                position: '1',
                positionText: '1',
                points: '25',
                wins: '1',
                driver: Driver(
                  driverId: 'antonelli',
                  permanentNumber: '12',
                  code: code,
                  url: '',
                  givenName: givenName,
                  familyName: familyName,
                  dateOfBirth: '2006-08-25',
                  nationality: 'Italian',
                ),
                constructors: [
                  Constructor(
                    constructorId: 'mercedes',
                    url: '',
                    name: 'Mercedes',
                    nationality: 'German',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
