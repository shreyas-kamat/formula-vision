import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/data/functions/live_data.function.dart';
import 'package:formulavision/data/models/live_data.model.dart';

void main() {
  group('TimeDiff.mergeAll', () {
    test('parses the snapshot list form with F1 key casing', () {
      final stats = TimeDiff.mergeAll(null, [
        {'TimeDiffToFastest': '+0.506', 'TimeDifftoPositionAhead': '+0.108'},
        {'TimeDiffToFastest': '', 'TimeDifftoPositionAhead': ''},
      ]);
      expect(stats.length, 2);
      expect(stats[0].timeDiffToFastest, '+0.506');
      expect(stats[0].timeDifftoPositionAhead, '+0.108');
    });

    test('applies partial index-keyed deltas without losing other fields', () {
      final base = TimeDiff.mergeAll(null, [
        {'TimeDiffToFastest': '+0.506', 'TimeDifftoPositionAhead': '+0.108'},
      ]);
      final merged = TimeDiff.mergeAll(base, {
        '0': {'TimeDifftoPositionAhead': '+0.042'},
        '1': {'TimeDiffToFastest': '+0.300'},
      });
      expect(merged[0].timeDiffToFastest, '+0.506');
      expect(merged[0].timeDifftoPositionAhead, '+0.042');
      expect(merged[1].timeDiffToFastest, '+0.300');
      expect(merged[1].timeDifftoPositionAhead, '');
    });
  });

  group('TimingData.mergeNoEntries', () {
    test('accepts list and index-keyed map forms', () {
      expect(TimingData.mergeNoEntries(null, [20, 15, 10]), [20, 15, 10]);
      expect(
        TimingData.mergeNoEntries([0, 0, 0], {'0': 22, '1': 16, '2': 10}),
        [22, 16, 10],
      );
      expect(TimingData.mergeNoEntries([20, 15, 10], null), [20, 15, 10]);
    });
  });

  test('snapshot parsing reads qualifying fields from F1 casing', () async {
    final data = await fetchLiveData({
      'TimingData': {
        'NoEntries': [20, 15, 10],
        'SessionPart': 2,
        'Lines': {
          '7': {
            'Line': 16,
            'KnockedOut': true,
            'Cutoff': false,
            'InPit': true,
            'Stats': [
              {
                'TimeDiffToFastest': '+1.363',
                'TimeDifftoPositionAhead': '+0.036'
              },
              {'TimeDiffToFastest': '', 'TimeDifftoPositionAhead': ''},
            ],
          },
        },
      },
    });
    final timing = data.first.timingData!;
    expect(timing.sessionPart, 2);
    expect(timing.noEntries, [20, 15, 10]);
    final driver = timing.lines['7']!;
    expect(driver.knockedOut, isTrue);
    expect(driver.cutoff, isFalse);
    expect(driver.inPit, isTrue);
    expect(driver.stats![0].timeDifftoPositionAhead, '+0.036');
  });
}
