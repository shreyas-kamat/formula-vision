import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/data/models/live_data.model.dart';
import 'package:formulavision/data/services/position_playback.dart';

final _base = DateTime.utc(2026, 1, 1, 12);
final _wall = DateTime.utc(2030, 6, 1, 8); // unrelated wall clock

PositionSample _sample(DateTime t, Map<String, List<double>> cars,
    {String status = 'OnTrack'}) {
  return PositionSample(
    timestamp: t.toIso8601String(),
    cars: {
      for (final e in cars.entries)
        e.key: PositionDataCar(
            x: e.value[0], y: e.value[1], z: 0, status: status),
    },
  );
}

PositionData _data(List<PositionSample> samples) => PositionData(
    timestamp: samples.last.timestamp,
    cars: samples.last.cars,
    samples: samples);

void main() {
  test('interpolates between frames on a clock trailing the feed by 1.2s', () {
    final p = PositionPlayback();
    p.ingest(
        _data([
          _sample(_base, {'1': [100, 100]}),
          _sample(_base.add(const Duration(seconds: 1)), {'1': [200, 100]}),
        ]),
        _wall);

    // feed time = newest (base+1s) - 1.2s + 0.7s = base + 0.5s -> midpoint.
    final mid = p.positionsAt(_wall.add(const Duration(milliseconds: 700)));
    expect(mid['1']!.position.dx, closeTo(150, 0.01));
    expect(mid['1']!.position.dy, closeTo(100, 0.01));

    // Before the first frame: hold the first position.
    expect(p.positionsAt(_wall)['1']!.position.dx, 100);

    // Past the newest frame: hold the newest position.
    expect(
        p.positionsAt(_wall.add(const Duration(seconds: 3)))['1']!.position.dx,
        200);
  });

  test('ignores cars without a position fix', () {
    final p = PositionPlayback();
    p.ingest(
        _data([
          _sample(_base, {'1': [0, 0], '2': [50, 60]}),
        ]),
        _wall);
    final cars = p.positionsAt(_wall);
    expect(cars.containsKey('1'), isFalse);
    expect(cars['2']!.position, const Offset(50, 60));
  });

  test('carries on-track status from the frame being played', () {
    final p = PositionPlayback();
    p.ingest(_data([_sample(_base, {'1': [10, 10]}, status: 'OffTrack')]),
        _wall);
    expect(p.positionsAt(_wall)['1']!.onTrack, isFalse);
  });

  test('skips frames it has already ingested', () {
    final p = PositionPlayback();
    final data = _data([
      _sample(_base, {'1': [100, 100]}),
      _sample(_base.add(const Duration(seconds: 1)), {'1': [200, 100]}),
    ]);
    p.ingest(data, _wall);
    p.ingest(data, _wall.add(const Duration(milliseconds: 500)));
    final mid = p.positionsAt(_wall.add(const Duration(milliseconds: 700)));
    expect(mid['1']!.position.dx, closeTo(150, 0.01));
  });

  test('restarts after a feed gap instead of crawling across it', () {
    final p = PositionPlayback();
    p.ingest(
        _data([
          _sample(_base, {'1': [100, 100]}),
          _sample(_base.add(const Duration(seconds: 1)), {'1': [200, 100]}),
        ]),
        _wall);
    // A minute of feed is missing (reconnect).
    final wall2 = _wall.add(const Duration(seconds: 1));
    p.ingest(
        _data([
          _sample(_base.add(const Duration(seconds: 60)), {'1': [1000, 100]}),
          _sample(_base.add(const Duration(seconds: 61)), {'1': [1100, 100]}),
        ]),
        wall2);
    // feed time = base+61s - 1.2s = base+59.8s -> before the first new frame.
    expect(p.positionsAt(wall2)['1']!.position.dx, 1000);
  });

  test('frames without parseable timestamps are stamped with wall time', () {
    final p = PositionPlayback();
    PositionData flat(double x) => PositionData(timestamp: 't', cars: {
          '1': PositionDataCar(x: x, y: 0, z: 0, status: 'OnTrack'),
        });
    p.ingest(flat(100), _wall);
    p.ingest(flat(200), _wall.add(const Duration(seconds: 1)));
    // feed time = wall+1.7s - 1.2s = wall+0.5s -> midpoint.
    final mid = p.positionsAt(_wall.add(const Duration(milliseconds: 1700)));
    expect(mid['1']!.position.dx, closeTo(150, 0.01));
  });

  test('drops cars that stop appearing in the feed', () {
    final p = PositionPlayback();
    p.ingest(_data([_sample(_base, {'1': [10, 10], '2': [20, 20]})]), _wall);
    p.ingest(
        _data([
          _sample(_base.add(const Duration(seconds: 2)), {'1': [30, 30]}),
          _sample(_base.add(const Duration(seconds: 2, milliseconds: 500)),
              {'1': [40, 40]}),
          _sample(_base.add(const Duration(seconds: 2, milliseconds: 900)),
              {'1': [50, 50]}),
        ]),
        _wall.add(const Duration(seconds: 2)));
    // Query the earlier instant first: positionsAt prunes stale frames for good.
    final soon = p.positionsAt(_wall.add(const Duration(seconds: 2)));
    expect(soon.containsKey('1'), isTrue);
    // Well past retention (5s) of every frame.
    final later = p.positionsAt(_wall.add(const Duration(seconds: 12)));
    expect(later.containsKey('2'), isFalse);
    expect(later.containsKey('1'), isFalse); // also stale by then
  });

  test('clear empties the buffer', () {
    final p = PositionPlayback();
    p.ingest(_data([_sample(_base, {'1': [10, 10]})]), _wall);
    expect(p.isEmpty, isFalse);
    p.clear();
    expect(p.isEmpty, isTrue);
    expect(p.positionsAt(_wall), isEmpty);
  });
}
