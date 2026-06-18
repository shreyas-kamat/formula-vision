import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/data/models/live_data.model.dart';
import 'package:formulavision/pages/dashboard_page.dart';

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

// The widget always has something animating (the loading spinner, then the
// repainting CustomPaint), so pumpAndSettle never settles. Pump a bounded
// number of frames instead — enough to cover the async track load and the
// ~400ms car interpolation.
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

  Widget build(PositionData pos) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 200,
            child: LiveTrackMapWidget(
              positionData: pos,
              drivers: drivers,
              circuitShortName: 'Spielberg',
            ),
          ),
        ),
      );

  testWidgets('loads the track outline and paints', (tester) async {
    await tester.pumpWidget(build(_positions({
      '1': [1102, 1207],
      '44': [0, 0],
    })));
    await _pumpFrames(tester);

    // Once the track asset loads, the loading spinner is gone and the painter
    // is mounted.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('interpolates to new positions without throwing',
      (tester) async {
    await tester.pumpWidget(build(_positions({
      '1': [1102, 1207],
      '44': [0, 0],
    })));
    await _pumpFrames(tester);

    // Push new positions: the widget animates between frames.
    await tester.pumpWidget(build(_positions({
      '1': [0, 0],
      '44': [1102, 1207],
    })));
    await _pumpFrames(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
