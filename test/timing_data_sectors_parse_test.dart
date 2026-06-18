import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/data/models/live_data.model.dart';

void main() {
  group('TimingDataDriver.fromJson sectors', () {
    test('parses the live snapshot "Sectors" key (capitalised List form)', () {
      // Shape as delivered in the initial 'R' snapshot from the F1 feed.
      final json = {
        'Sectors': [
          {
            'Stopped': false,
            'Value': '28.123',
            'Status': 2051,
            'OverallFastest': true,
            'PersonalFastest': true,
            'Segments': [
              {'Status': 2051},
              {'Status': 2049},
            ],
          },
          {
            'Stopped': false,
            'Value': '31.456',
            'Status': 2049,
            'OverallFastest': false,
            'PersonalFastest': true,
            'Segments': [
              {'Status': 2049},
            ],
          },
        ],
      };

      final driver = TimingDataDriver.fromJson(json);

      expect(driver.sectors.length, 2);
      expect(driver.sectors[0].value, '28.123');
      expect(driver.sectors[0].overallFastest, isTrue);
      expect(driver.sectors[0].segments.length, 2);
      expect(driver.sectors[1].value, '31.456');
    });

    test('parses the index-keyed "Sectors" map form', () {
      final json = {
        'Sectors': {
          '0': {'Value': '28.1', 'Status': 0},
          '1': {'Value': '31.4', 'Status': 0},
        },
      };

      final driver = TimingDataDriver.fromJson(json);

      expect(driver.sectors.length, 2);
      expect(driver.sectors[0].value, '28.1');
      expect(driver.sectors[1].value, '31.4');
    });

    test('still parses the lowercase "sectors" key from cached toJson', () {
      final json = {
        'sectors': [
          {'Value': '29.0', 'Status': 0},
        ],
      };

      final driver = TimingDataDriver.fromJson(json);

      expect(driver.sectors.length, 1);
      expect(driver.sectors[0].value, '29.0');
    });
  });
}
