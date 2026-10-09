import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/data/functions/f1_decompress.function.dart';
import 'package:formulavision/data/models/live_data.model.dart';
import 'package:formulavision/data/services/track_map_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _apiTrack = {
  'circuitKey': 999,
  'rotation': 45,
  'x': [0, 100, 100, 0],
  'y': [0, 0, -100, -100],
};

http.Client _offline() => MockClient((_) async => throw const SocketException('offline'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every bundled file carries the circuit key it is mapped to', () async {
    for (final e in TrackMapService.bundledFiles.entries) {
      final raw = await rootBundle.loadString('assets/TrackMaps/${e.value}');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      expect(json['circuitKey'], e.key, reason: e.value);
    }
  });

  test('resolveCircuitKey prefers the key, falls back to F1 short names', () {
    expect(TrackMapService.resolveCircuitKey(49, ''), 49);
    expect(TrackMapService.resolveCircuitKey(0, 'Monte Carlo'), 22);
    expect(TrackMapService.resolveCircuitKey(0, 'Sakhir'), 63);
    expect(TrackMapService.resolveCircuitKey(0, 'Lusail'), 150);
    expect(TrackMapService.resolveCircuitKey(0, 'Yas Marina Circuit'), 70);
    expect(TrackMapService.resolveCircuitKey(0, 'Madring'), 153);
    expect(TrackMapService.resolveCircuitKey(0, ' Shanghai '), 49);
    expect(TrackMapService.resolveCircuitKey(0, 'Nowhere'), isNull);
    expect(TrackMapService.resolveCircuitKey(0, ''), isNull);
  });

  test('bundled assets are flipped back into the car frame', () async {
    final service = TrackMapService(client: _offline());
    final map = await service.load(circuitKey: 49); // Shanghai
    expect(map, isNotNull);
    expect(map!.source, 'asset');
    // Shanghai.json starts at x=344, y=1489 (stored negated).
    expect(map.points.first, const Offset(344, -1489));
    expect(map.rotationDeg, 237);
  });

  test('loads Madrid (key 153) from the bundled asset', () async {
    final map = await TrackMapService(client: _offline()).load(circuitKey: 153);
    expect(map, isNotNull);
    expect(map!.points.length, greaterThan(500));
  });

  test('real Suzuka car positions sit on the loaded outline', () async {
    final map = await TrackMapService(client: _offline()).load(circuitKey: 46);
    final line = File('test/fixtures/position_z_suzuka_2026.txt')
        .readAsLinesSync()
        .first;
    final pd = PositionData.fromJson(
        decodePositionZ(jsonDecode(line.substring(12)) as String)!);
    final cars = pd.cars.values.where((c) => c.hasFix).toList();
    double total = 0;
    for (final c in cars) {
      total += map!.points
          .map((p) => math.sqrt(math.pow(p.dx - c.x, 2) + math.pow(p.dy - c.y, 2)))
          .reduce(math.min);
    }
    // Aligned ≈ 100; the mirrored (pre-fix) outline averages ≈ 2700.
    expect(total / cars.length, lessThan(400));
  });

  test('fetches unbundled circuits from MultiViewer and caches them', () async {
    final requests = <String>[];
    final online = MockClient((req) async {
      requests.add(req.url.toString());
      if (req.url.path == '/api/v1/circuits/999/2026') {
        return http.Response(jsonEncode(_apiTrack), 200);
      }
      return http.Response('Circuit not found', 404);
    });

    final first = await TrackMapService(client: online)
        .load(circuitKey: 999, year: 2026);
    expect(first!.source, 'network');
    expect(first.points[2], const Offset(100, -100)); // API y used as-is
    expect(first.rotationDeg, 45);
    expect(requests.single,
        'https://api.multiviewer.app/api/v1/circuits/999/2026');

    // A fresh service instance (new app launch) with no network uses the cache.
    final cached = await TrackMapService(client: _offline())
        .load(circuitKey: 999, year: 2026);
    expect(cached!.source, 'cache');
    expect(cached.points.length, 4);
  });

  test('retries with the newest year MultiViewer has for the circuit', () async {
    final online = MockClient((req) async {
      switch (req.url.path) {
        case '/api/v1/circuits/999/2026':
          return http.Response('Circuit not found', 404);
        case '/api/v1/circuits':
          return http.Response(
              jsonEncode({
                '999': {'name': 'Test', 'years': [2023, 2021], 'circuitKey': 999}
              }),
              200);
        case '/api/v1/circuits/999/2023':
          return http.Response(jsonEncode(_apiTrack), 200);
      }
      return http.Response('nope', 404);
    });
    final map =
        await TrackMapService(client: online).load(circuitKey: 999, year: 2026);
    expect(map, isNotNull);
    expect(map!.source, 'network');
  });

  test('returns null when offline and nothing is bundled or cached', () async {
    final map = await TrackMapService(client: _offline())
        .load(circuitKey: 999, year: 2026);
    expect(map, isNull);
  });

  test('returns null for an unresolvable circuit without any request', () async {
    var called = false;
    final client = MockClient((_) async {
      called = true;
      return http.Response('', 404);
    });
    expect(await TrackMapService(client: client).load(shortName: 'Nowhere'),
        isNull);
    expect(called, isFalse);
  });

  test('TrackMap.fromJson rejects malformed data', () {
    expect(
        () => TrackMap.fromJson({'x': [1, 2], 'y': [1]},
            yNegated: false, source: 'network'),
        throwsFormatException);
    expect(
        () => TrackMap.fromJson(<String, dynamic>{},
            yNegated: false, source: 'network'),
        throwsFormatException);
  });
}
