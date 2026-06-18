import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/data/models/live_data.model.dart';

void main() {
  group('PositionData.fromJson', () {
    test('parses the live Position.z Entries shape using the last entry', () {
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

      expect(pd.timestamp, 't1');
      expect(pd.cars.length, 1);
      final car = pd.cars['44']!;
      expect(car.x, 30);
      expect(car.y, 40);
      expect(car.status, 'OffTrack');
      expect(car.isOnTrack, isFalse);
    });

    test('parses the flat Cars / Timestamp shape', () {
      final json = {
        'Timestamp': 'ts',
        'Cars': {
          '1': {'X': 1, 'Y': 2, 'Z': 3, 'Status': 'OnTrack'}
        }
      };

      final pd = PositionData.fromJson(json);

      expect(pd.timestamp, 'ts');
      expect(pd.cars['1']!.x, 1);
      expect(pd.cars['1']!.isOnTrack, isTrue);
    });

    test('handles empty or missing data gracefully', () {
      expect(PositionData.fromJson({'Entries': []}).cars, isEmpty);
      expect(PositionData.fromJson(<String, dynamic>{}).cars, isEmpty);
    });

    test('defaults missing status to OnTrack', () {
      final pd = PositionData.fromJson({
        'Cars': {
          '7': {'X': 0, 'Y': 0}
        }
      });
      expect(pd.cars['7']!.status, 'OnTrack');
    });
  });
}
