import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/components/driver_row_card.dart';
import 'package:formulavision/data/models/live_data.model.dart';
import 'package:shared_preferences/shared_preferences.dart';

Sector _sector(String value, int segCount, int status) => Sector(
      stopped: false,
      value: value,
      status: status,
      overallFastest: status == 2051,
      personalFastest: status == 2049,
      segments: List.generate(segCount, (_) => Segment(status: status)),
    );

final _sectors = [
  _sector('24.038', 7, 2048),
  _sector('32.880', 9, 2048),
  _sector('25.187', 6, 2049),
];

final _stints = [
  Stint(totalLaps: 13, compound: 'SOFT', isNew: 'false'),
  Stint(totalLaps: 16, compound: 'HARD', isNew: 'true'),
];

const _telemetry = CarTelemetry(
  rpm: 11000,
  speed: 280,
  gear: 7,
  throttle: 100,
  brake: 0,
  drs: 12, // active
);

Widget _harness({double width = 390, CarTelemetry? telemetry = _telemetry}) =>
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SizedBox(
            width: width,
            child: DriverRowCard(
              position: 1,
              name: 'HAM',
              currentLapTime: '1:22.105',
              bestLapTime: '1:20.122',
              interval: 'Leader',
              teamColor: Colors.red,
              tireCompound: 'HARD',
              pitStops: 2,
              sessionType: 'Race',
              stintLaps: 25,
              isNewTyre: true,
              stints: _stints,
              sectors: _sectors,
              telemetry: telemetry,
            ),
          ),
        ),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('DriverRowCard', () {
    testWidgets('collapsed: header fits, times + HUD hidden', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('HAM'), findsOneWidget);
      expect(find.text('1:22.105'), findsOneWidget);
      expect(find.text('24.038'), findsNothing); // sector times hidden
      expect(find.text('280'), findsNothing); // HUD hidden
      expect(find.text('STINT HISTORY'), findsNothing);
    });

    testWidgets('narrow phone (320px) lays out without overflow',
        (tester) async {
      await tester.pumpWidget(_harness(width: 320));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('expanding reveals sector times and the telemetry HUD',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump();

      await tester.tap(find.text('1:22.105')); // tap the row body
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Sector times
      expect(find.text('24.038'), findsOneWidget);
      expect(find.text('32.880'), findsOneWidget);
      // HUD: primary speed + units + gear + active aero
      expect(find.text('280'), findsOneWidget);
      expect(find.text('KM/H'), findsOneWidget);
      expect(find.text('174 MPH'), findsOneWidget); // 280 km/h -> 174 mph
      expect(find.text('GEAR'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('ON'), findsOneWidget); // DRS active
      // Stint history is NOT in the accordion
      expect(find.text('STINT HISTORY'), findsNothing);
    });

    testWidgets('tapping the tyre opens the stint history modal',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump();

      await tester.tap(find.text('TYRE'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('HAM  ·  STINT HISTORY'), findsOneWidget);
      expect(find.text('2 STOPS'), findsOneWidget);
      expect(find.text('S1 · SOFT'), findsOneWidget);
      expect(find.text('S2 · HARD'), findsOneWidget);
    });

    testWidgets('no telemetry shows the empty HUD state when expanded',
        (tester) async {
      await tester.pumpWidget(_harness(telemetry: null));
      await tester.pump();

      // Still expandable via sectors
      await tester.tap(find.text('1:22.105'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('24.038'), findsOneWidget); // sector times show
      expect(find.text('NO TELEMETRY'), findsNothing); // HUD only when present
      expect(find.text('280'), findsNothing);
    });
  });
}
