import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/data/models/live_data.model.dart';

void main() {
  group('SessionStatus.fromJson', () {
    test('reads PascalCase Status (snapshot and delta form)', () {
      final status = SessionStatus.fromJson({'Status': 'Started', '_kf': true});
      expect(status.status, 'Started');
    });

    test('reads lowercase status', () {
      final status = SessionStatus.fromJson({'status': 'Aborted'});
      expect(status.status, 'Aborted');
    });

    test('defaults to empty string when no status key is present', () {
      final status = SessionStatus.fromJson({});
      expect(status.status, '');
    });
  });

  group('TimingStats', () {
    Map<String, dynamic> snapshot() => {
          'Withheld': false,
          'SessionType': 'Race',
          'Lines': {
            '1': {
              'Line': 1,
              'RacingNumber': '1',
              'PersonalBestLapTime': {'Value': '1:35.123', 'Lap': 12, 'Position': 3},
              'BestSectors': [
                {'Value': '28.123', 'Position': 2},
                {'Value': '40.000', 'Position': 5},
                {'Value': '27.000', 'Position': 1},
              ],
              'BestSpeeds': {
                'I1': {'Value': '290', 'Position': 4},
                'I2': {'Value': '295', 'Position': 3},
                'FL': {'Value': '300', 'Position': 2},
                'ST': {'Value': '312', 'Position': 1},
              },
            },
          },
        };

    test('parses PascalCase snapshot with List sectors and speed keys', () {
      final stats = TimingStats.fromJson(snapshot());
      expect(stats.sessionType, 'Race');
      expect(stats.withheld, false);
      final driver = stats.lines['1']!;
      expect(driver.racingNumber, '1');
      expect(driver.line, 1);
      expect(driver.personalBestLapTime.value, '1:35.123');
      expect(driver.personalBestLapTime.lap, 12);
      expect(driver.personalBestLapTime.position, 3);
      expect(driver.bestSectors.length, 3);
      expect(driver.bestSectors[0].value, '28.123');
      expect(driver.bestSpeeds.keys, containsAll(['I1', 'I2', 'FL', 'ST']));
      expect(driver.bestSpeeds['ST']!.value, '312');
      expect(driver.bestSpeeds['ST']!.position, 1);
    });

    test('parses index-keyed BestSectors Map and lowercase speed keys', () {
      final driver = TimingStatsDriver.fromJson({
        'line': 2,
        'racingNumber': '44',
        'bestSectors': {
          '1': {'Value': '35.2', 'Position': 1},
          '0': {'Value': '30.0', 'Position': 2},
        },
        'bestSpeeds': {
          'st': {'Value': '320', 'Position': 1},
        },
      });
      expect(driver.bestSectors.length, 2);
      expect(driver.bestSectors[0].value, '30.0');
      expect(driver.bestSectors[1].value, '35.2');
      expect(driver.bestSpeeds['ST']!.value, '320');
    });

    test('delta merge updates only ST and keeps I1', () {
      final prev = TimingStatsDriver.fromJson(snapshot()['Lines']['1']);
      final merged = TimingStatsDriver.merge(prev, {
        'BestSpeeds': {
          'ST': {'Value': '315', 'Position': 1},
        },
      });
      expect(merged.bestSpeeds['ST']!.value, '315');
      expect(merged.bestSpeeds['I1']!.value, '290');
      expect(merged.bestSpeeds['I1']!.position, 4);
      expect(merged.personalBestLapTime.value, '1:35.123');
      expect(merged.racingNumber, '1');
    });

    test('BestSectors index-keyed delta replaces only that sector', () {
      final prev = TimingStatsDriver.fromJson(snapshot()['Lines']['1']);
      final merged = TimingStatsDriver.merge(prev, {
        'BestSectors': {
          '1': {'Value': '35.2', 'Position': 1},
        },
      });
      expect(merged.bestSectors.length, 3);
      expect(merged.bestSectors[0].value, '28.123');
      expect(merged.bestSectors[1].value, '35.2');
      expect(merged.bestSectors[1].position, 1);
      expect(merged.bestSectors[2].value, '27.000');
    });

    test('position-only sector delta keeps the previous value', () {
      final prev = TimingStatsDriver.fromJson(snapshot()['Lines']['1']);
      final merged = TimingStatsDriver.merge(prev, {
        'BestSectors': {
          '0': {'Position': 1},
        },
      });
      expect(merged.bestSectors[0].value, '28.123');
      expect(merged.bestSectors[0].position, 1);
    });
  });

  group('TeamRadio', () {
    test('fromJson accepts a Captures List (snapshot)', () {
      final radio = TeamRadio.fromJson({
        'Captures': [
          {
            'Utc': '2026-10-11T12:05:01.2Z',
            'RacingNumber': '4',
            'Path': 'TeamRadio/LANNOR01_4_20261011_200501.mp3',
          },
        ],
      });
      expect(radio.captures.length, 1);
      expect(radio.captures[0].utc, '2026-10-11T12:05:01.2Z');
      expect(radio.captures[0].racingNumber, '4');
      expect(radio.captures[0].path, 'TeamRadio/LANNOR01_4_20261011_200501.mp3');
    });

    test('fromJson accepts an index-keyed Captures Map (delta) in key order', () {
      final radio = TeamRadio.fromJson({
        'Captures': {
          '7': {'Utc': 'b', 'RacingNumber': '7', 'Path': 'TeamRadio/b.mp3'},
          '2': {'Utc': 'a', 'RacingNumber': '2', 'Path': 'TeamRadio/a.mp3'},
        },
      });
      expect(radio.captures.map((c) => c.path).toList(),
          ['TeamRadio/a.mp3', 'TeamRadio/b.mp3']);
    });

    test('fromJson accepts lowercase keys', () {
      final radio = TeamRadio.fromJson({
        'captures': [
          {'utc': 'x', 'racingNumber': '1', 'path': 'TeamRadio/x.mp3'},
        ],
      });
      expect(radio.captures.single.racingNumber, '1');
      expect(radio.captures.single.path, 'TeamRadio/x.mp3');
    });

    test('mergeCaptures appends new captures and de-duplicates by path', () {
      final first = RadioCapture.fromJson({
        'Utc': '1', 'RacingNumber': '4', 'Path': 'TeamRadio/one.mp3',
      });
      final prev = [first];
      final merged = TeamRadio.mergeCaptures(prev, {
        '0': {'Utc': '1', 'RacingNumber': '4', 'Path': 'TeamRadio/one.mp3'},
        '1': {'Utc': '2', 'RacingNumber': '44', 'Path': 'TeamRadio/two.mp3'},
      });
      expect(merged.map((c) => c.path).toList(),
          ['TeamRadio/one.mp3', 'TeamRadio/two.mp3']);
      expect(prev.length, 1, reason: 'prev list must not be mutated');
    });

    test('mergeCaptures accepts a List delta', () {
      final merged = TeamRadio.mergeCaptures(const [], [
        {'Utc': '1', 'RacingNumber': '4', 'Path': 'TeamRadio/one.mp3'},
      ]);
      expect(merged.length, 1);
    });
  });
}
