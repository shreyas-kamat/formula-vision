import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/data/functions/live_data.function.dart';

void main() {
  group('latestQualifyingPart', () {
    test('reads the last part from the snapshot list form', () {
      expect(
        latestQualifyingPart({
          'Series': [
            {'Utc': '2026-10-09T12:30:00Z', 'QualifyingPart': 0},
            {'Utc': '2026-10-09T12:31:00Z', 'QualifyingPart': 1},
          ],
        }),
        1,
      );
    });

    test('reads the highest-index entry from the delta map form', () {
      expect(
        latestQualifyingPart({
          'Series': {
            '10': {'Utc': '2026-10-09T12:55:00Z', 'QualifyingPart': 3},
            '2': {'Utc': '2026-10-09T12:45:00Z', 'QualifyingPart': 2},
          },
        }),
        3,
      );
    });

    test('returns null for race sessions and status-only deltas', () {
      expect(
        latestQualifyingPart({
          'Series': [
            {'Utc': '2026-10-09T12:30:00Z', 'Lap': 1},
          ],
        }),
        isNull,
      );
      expect(
        latestQualifyingPart({
          'StatusSeries': {
            '5': {'Utc': '2026-10-09T12:40:00Z', 'TrackStatus': 'Red'},
          },
        }),
        isNull,
      );
      expect(latestQualifyingPart(null), isNull);
    });
  });
}
