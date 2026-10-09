import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/data/functions/f1_decompress.function.dart';
import 'package:formulavision/data/models/live_data.model.dart';

void main() {
  group('PositionData.fromJson', () {
    test('parses the live Position.z shape and keeps every frame', () {
      final json = {
        'Position': [
          {
            'Timestamp': '2026-03-28T05:50:21.036052Z',
            'Entries': {
              '1': {'Status': 'OnTrack', 'X': 10, 'Y': 20, 'Z': 0},
            }
          },
          {
            'Timestamp': '2026-03-28T05:50:21.3560033Z',
            'Entries': {
              '1': {'Status': 'OffTrack', 'X': 30, 'Y': 40, 'Z': 1},
            }
          },
        ]
      };

      final pd = PositionData.fromJson(json);

      expect(pd.samples.length, 2);
      expect(pd.samples.first.cars['1']!.x, 10);
      // 7 fractional digits (F1's format) must still parse.
      expect(pd.samples.last.time,
          DateTime.utc(2026, 3, 28, 5, 50, 21, 356, 3));
      // timestamp/cars mirror the newest frame.
      expect(pd.timestamp, '2026-03-28T05:50:21.3560033Z');
      expect(pd.cars['1']!.x, 30);
      expect(pd.cars['1']!.isOnTrack, isFalse);
    });

    test('parses a real archived Position.z message', () {
      final line = File('test/fixtures/position_z_suzuka_2026.txt')
          .readAsLinesSync()
          .first;
      final decoded = decodePositionZ(jsonDecode(line.substring(12)) as String);

      final pd = PositionData.fromJson(decoded!);

      expect(pd.samples.length, greaterThanOrEqualTo(3));
      expect(pd.cars.length, 22);
      expect(pd.cars.values.where((c) => c.hasFix).length, 22);
      expect(pd.samples.every((s) => s.time != null), isTrue);
    });

    test('parses the legacy relay Entries shape', () {
      final json = {
        'Entries': [
          {
            'Utc': 't0',
            'Cars': {
              '44': {'X': 10, 'Y': 20, 'Z': 0, 'Status': 'OnTrack'}
            }
          },
          {
            'Utc': 't1',
            'Cars': {
              '44': {'X': 30, 'Y': 40, 'Z': 1, 'Status': 'OffTrack'}
            }
          },
        ],
      };

      final pd = PositionData.fromJson(json);

      expect(pd.samples.length, 2);
      expect(pd.timestamp, 't1');
      expect(pd.cars['44']!.x, 30);
      expect(pd.cars['44']!.isOnTrack, isFalse);
      expect(pd.samples.last.time, isNull); // 't1' is not a date
    });

    test('parses the flat Cars / Timestamp shape', () {
      final pd = PositionData.fromJson({
        'Timestamp': 'ts',
        'Cars': {
          '1': {'X': 1, 'Y': 2, 'Z': 3, 'Status': 'OnTrack'}
        }
      });

      expect(pd.timestamp, 'ts');
      expect(pd.samples.length, 1);
      expect(pd.cars['1']!.x, 1);
      expect(pd.cars['1']!.isOnTrack, isTrue);
    });

    test('handles empty or missing data gracefully', () {
      expect(PositionData.fromJson({'Entries': []}).cars, isEmpty);
      expect(PositionData.fromJson({'Position': []}).samples, isEmpty);
      expect(PositionData.fromJson(<String, dynamic>{}).cars, isEmpty);
    });

    test('defaults missing status to OnTrack and flags (0,0) as no fix', () {
      final pd = PositionData.fromJson({
        'Cars': {
          '7': {'X': 0, 'Y': 0},
          '8': {'X': 5, 'Y': 0},
        }
      });
      expect(pd.cars['7']!.status, 'OnTrack');
      expect(pd.cars['7']!.hasFix, isFalse);
      expect(pd.cars['8']!.hasFix, isTrue);
    });

    test('constructor without samples wraps cars in one sample', () {
      final pd = PositionData(timestamp: 't', cars: {
        '1': PositionDataCar(x: 1, y: 2, z: 0, status: 'OnTrack'),
      });
      expect(pd.samples.single.cars['1']!.x, 1);
    });
  });
}
