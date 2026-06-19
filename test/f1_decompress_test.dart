import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/data/functions/f1_decompress.function.dart';

/// Encode a JSON object the way F1 sends its `.z` topics: raw DEFLATE
/// (no zlib/gzip header) then base64. Mirrors the on-wire format that
/// `decodeCarDataZ` / `decodePositionZ` must inflate.
String _toF1Z(Object json) {
  final bytes = utf8.encode(jsonEncode(json));
  final deflated = ZLibCodec(raw: true).encode(bytes);
  return base64Encode(deflated);
}

void main() {
  group('decodeCarDataZ', () {
    test('inflates and reduces to the latest-entry named-channel shape', () {
      // Two entries; the decoder must use the latest. Channels are keyed by
      // string index as F1 sends them: 0=RPM, 2=Speed, 3=Gear, 4=Throttle,
      // 5=Brake, 45=DRS.
      final payload = _toF1Z({
        'Entries': [
          {
            'Utc': 't0',
            'Cars': {
              '44': {
                'Channels': {'0': 1000, '2': 100, '3': 4, '4': 50, '5': 0, '45': 0}
              }
            }
          },
          {
            'Utc': 't1',
            'Cars': {
              '44': {
                'Channels': {
                  '0': 11104,
                  '2': 285,
                  '3': 7,
                  '4': 99,
                  '5': 0,
                  '45': 10
                }
              },
              '1': {
                'Channels': {'0': 9000, '2': 250, '3': 6, '4': 80, '5': 5, '45': 0}
              }
            }
          },
        ],
      });

      final result = decodeCarDataZ(payload)!;

      expect(result['Timestamp'], 't1');
      final cars = result['Cars'] as Map<String, dynamic>;
      expect(cars.keys.toSet(), {'44', '1'});

      final car44 = cars['44'] as Map<String, dynamic>;
      expect(car44['RPM'], 11104);
      expect(car44['Speed'], 285);
      expect(car44['Gear'], 7);
      expect(car44['Throttle'], 99);
      expect(car44['Brake'], 0);
      expect(car44['DRS'], 10);
    });

    test('returns null for malformed base64 / empty entries', () {
      expect(decodeCarDataZ('not-base64-@@@'), isNull);
      expect(decodeCarDataZ(_toF1Z({'Entries': []})), isNull);
    });
  });

  group('decodePositionZ', () {
    test('inflates the raw Position.z object unchanged', () {
      final original = {
        'Entries': [
          {
            'Utc': 't1',
            'Cars': {
              '44': {'X': 30, 'Y': 40, 'Z': 1, 'Status': 'OnTrack'}
            }
          }
        ]
      };

      final result = decodePositionZ(_toF1Z(original))!;
      expect(result, equals(original));
    });

    test('returns null on bad input', () {
      expect(decodePositionZ('@@@bad'), isNull);
    });
  });
}
