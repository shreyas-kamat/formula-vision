import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/data/models/live_data.model.dart';
import 'package:formulavision/data/services/track_map_service.dart';
import 'package:formulavision/pages/dashboard_page.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

PositionData _positions(Map<String, List<double>> cars) {
  return PositionData(
    timestamp: 't',
    cars: {
      for (final e in cars.entries)
        e.key: PositionDataCar(
            x: e.value[0], y: e.value[1], z: 0, status: 'OnTrack'),
    },
  );
}

// The map repaints every frame (playback ticker), so pumpAndSettle never
// settles. Pump a bounded number of frames instead.
Future<void> _pumpFrames(WidgetTester tester,
    {int frames = 16, int stepMs = 50}) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: stepMs));
  }
}

void main() {
  final drivers = {
    '1': Driver.fromJson(
        {'racingNumber': '1', 'tla': 'VER', 'teamColour': '3671C6'}),
    '44': Driver.fromJson(
        {'racingNumber': '44', 'tla': 'HAM', 'teamColour': '27F4D2'}),
  };

  // Never hit the real network from widget tests.
  final service =
      TrackMapService(client: MockClient((_) async => http.Response('', 404)));

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget build(PositionData pos, {int circuitKey = 19}) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 200,
            child: LiveTrackMapWidget(
              positionData: pos,
              drivers: drivers,
              circuitKey: circuitKey,
              trackMapService: service,
            ),
          ),
        ),
      );

  testWidgets('loads the track outline by circuit key and paints',
      (tester) async {
    await tester.pumpWidget(build(_positions({
      '1': [1102, -1207],
      '44': [0, 0],
    })));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _pumpFrames(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Track map unavailable for this circuit'), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('animates new positions without throwing', (tester) async {
    await tester.pumpWidget(build(_positions({'1': [1102, -1207]})));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _pumpFrames(tester);

    await tester.pumpWidget(build(_positions({'1': [1200, -1300]})));
    await _pumpFrames(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('unknown circuit shows unavailable message', (tester) async {
    await tester.pumpWidget(
        build(_positions({'1': [1, 1]}), circuitKey: 99999));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _pumpFrames(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Track map unavailable for this circuit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching circuit reloads without throwing', (tester) async {
    await tester.pumpWidget(build(_positions({'1': [1, 1]}), circuitKey: 19));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _pumpFrames(tester);

    await tester.pumpWidget(build(_positions({'1': [2, 2]}), circuitKey: 22));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _pumpFrames(tester);

    expect(find.text('Track map unavailable for this circuit'), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
