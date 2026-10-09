# Live Track Map Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the dashboard's live track map actually show cars on the correct outline at every 2026 circuit, moving smoothly.

**Architecture:** Fix the `Position.z` parser so it reads F1's real payload and keeps every timestamped frame; add a `TrackMapService` that resolves outlines by circuit key (bundled asset → on-device cache → MultiViewer API) and converts bundled files back into F1's coordinate frame; add a pure-Dart `PositionPlayback` that replays frames on a slightly delayed clock; rewire `LiveTrackMapWidget` onto both.

**Tech Stack:** Flutter 3.41.6 / Dart (sdk ^3.6.1), `http`, `shared_preferences`, `flutter_test`, `package:http/testing.dart`. Python 3 for one offline asset-generation script.

**Spec:** This document (the findings below were verified against real F1 archive data on 2026-10-06).

## Background: verified findings (read before starting)

1. **Wrong payload shape → zero cars.** A decoded `Position.z` message is
   `{"Position": [{"Timestamp": "2026-03-28T05:50:21.3560033Z", "Entries": {"1": {"Status": "OnTrack", "X": 3309, "Y": -2755, "Z": 830}, ...}}, ...]}` — usually 4 frames ~250 ms apart, ~1 message/second.
   `PositionData.fromJson` (`lib/data/models/live_data.model.dart:1902`) only understands `{Entries: [{Utc, Cars}]}` (that is CarData's shape) and flat `{Timestamp, Cars}`, so on the on-device feed it parses **no cars**. The existing test `test/position_data_parse_test.dart` enshrines the wrong shape.
2. **Bundled outlines are mirrored relative to cars.** Commit `4d46a8e` negated every `y` in `assets/TrackMaps/*.json` so the static circuit viewer draws them upright. Real car positions from the 2026 Suzuka qualifying archive sit on average **128 units** from the un-negated MultiViewer outline and **2753 units** from the bundled one. Car X/Y = MultiViewer x/y frame. So: bundled file → negate `y` on load; API data → use as-is. **Do not edit the bundled files** (`lib/pages/circuit_viewer.dart` depends on their convention).
3. **Circuit key/name never parsed from the on-device snapshot.** `Meeting.fromJson` reads lowercase `circuit`/`key`; `Circuit.fromJson` reads `key`/`shortName`. F1 sends `Circuit: {Key, ShortName}` and `Key`. So the snapshot yields key `0`, name `''`.
4. **Name-based lookup is wrong.** F1's real `ShortName`s (from `static/2025|2026/Index.json`): Sakhir, Jeddah, Melbourne, Suzuka, Shanghai, Miami, Imola, Monte Carlo, Montreal, Catalunya, Spielberg, Silverstone, Hungaroring, Spa-Francorchamps, Zandvoort, Monza, Baku, Singapore, Austin, Mexico City, Interlagos, Las Vegas, Lusail, Yas Marina Circuit, Madring. The hardcoded list in `dashboard_page.dart:1617` misses Shanghai and uses wrong names for several.
5. **Madrid (circuit key 153, "Madring") has no outline anywhere.** MultiViewer returns 404 for it. The F1 static archive has the 2026 session: `https://livetiming.formula1.com/static/2026/2026-09-13_Spanish_Grand_Prix/2026-09-12_Qualifying/Position.z.jsonStream` (3.5 MB, needs `User-Agent: BestHTTP`). A tested generator script already exists at
   `C:/Users/SHREYA~1/AppData/Local/Temp/claude/D--Projects-Flutter-formulavision/73979907-ca10-4edc-9f1c-6300aeefffc2/scratchpad/track_from_archive.py` (validated: Suzuka output matches the bundled outline within ~5 m; Madrid → 5.33 km, 889 points). Downloaded streams are in the same folder: `madrid_pos.jsonStream`, `suzuka_pos.jsonStream`.
6. **MultiViewer API** (live, verified): `GET https://api.multiviewer.app/api/v1/circuits/{key}/{year}` → JSON with `x`, `y`, `rotation`, `circuitKey`, … ; 404 `Circuit not found` for unknown key/year. `GET https://api.multiviewer.app/api/v1/circuits` → `{"<key>": {"name", "years": [newest, ...], "circuitKey", ...}}`.
7. **Circuit key → bundled file** (from each file's own `circuitKey`):
   2 Silverstone, 4 Hungaroring, 6 Imola, 7 Spa-Francorchamps, 9 Austin, 10 Melbourne, 14 Interlagos, 15 Catalunya, 19 Spielberg, 22 Monte-Carlo, 23 Montreal, 28 Paul-Riccard, 34 Hockenheim, 39 Monza, 46 Suzuka, 49 Shanghai, 55 Zandvoort, 59 Istanbul, 61 Singapore, 63 Sakhir, 65 Mexico, 70 Yas-Marina, 72 Nurburgring, 79 Sochi, 144 Baku, 146 Mugello, 147 Algarve, 148 Sakhir-Outer, 149 Jeddah, 150 Losail, 151 Miami, 152 Las-Vegas (+ 153 Madring after Task 3).

## Global Constraints

- No new pub dependencies (`http`, `shared_preferences`, `flutter_test` already present; `package:http/testing.dart` ships with `http`).
- Do not modify existing files under `assets/TrackMaps/` or `lib/pages/circuit_viewer.dart` / `lib/pages/circuit_list.dart`.
- **Do not `git commit`, branch, or push.** Leave all changes in the working tree for the user to review. (The skill's "Commit" steps are replaced by "Checkpoint: run tests".)
- Shell is Git Bash on Windows; run Flutter from `D:/Projects/Flutter/formulavision`.
- Baseline before this work: `flutter test` → 23 pass, 1 fail (`test/widget_test.dart` "Counter increments smoke test" — pre-existing, unrelated; leave it).
- Match surrounding code style: `debugPrint('[ClassName] ...')` logging, doc comments on public types, no `print` in new code.
- After all code changes, run `graphify update .` (project CLAUDE.md rule).

## Review Focus

1. **Pre-session frames with every car at (0,0)** → those cars are hidden, not stacked at the origin. Test: Task 4 "ignores cars without a position fix".
2. **No network / API 404 for an unbundled circuit** → map shows "Track map unavailable for this circuit", never an endless spinner, never throws. Tests: Task 5 "returns null when offline", Task 6 "unknown circuit shows unavailable message".
3. **Circuit key 0 (legacy backend feed, or snapshot without Circuit)** → falls back to the F1 ShortName. Test: Task 5 `resolveCircuitKey` cases.
4. **Feed gap / reconnect (timestamps jump by minutes)** → playback restarts at the new data instead of crawling across the gap. Test: Task 4 "restarts after a feed gap".
5. **Session/circuit change while the map is open** → old buffer cleared, new outline loaded. Test: Task 6 "switching circuit reloads without throwing".

---

### Task 1: Parse the real `Position.z` shape and keep every frame

**Files:**
- Modify: `lib/data/models/live_data.model.dart` (classes `PositionData` ~line 1894 and `PositionDataCar` ~line 1944)
- Modify: `lib/data/services/live_data_service.dart:203-206` (seed debug log)
- Create: `test/fixtures/position_z_suzuka_2026.txt`
- Test: `test/position_data_parse_test.dart`

**Interfaces:**
- Produces:
  - `class PositionSample { final String timestamp; final DateTime? time; final Map<String, PositionDataCar> cars; PositionSample({required String timestamp, required Map<String, PositionDataCar> cars}); }` — `time` is `DateTime.tryParse(timestamp)?.toUtc()`.
  - `PositionData({required String timestamp, required Map<String, PositionDataCar> cars, List<PositionSample>? samples})` — when `samples` is null it defaults to one sample built from `timestamp`/`cars`. `PositionData.samples` is oldest-first; `timestamp`/`cars` mirror the last sample.
  - `bool PositionDataCar.hasFix` — `x != 0 || y != 0`.

- [ ] **Step 1: Create the real-data fixture**

```bash
cd "D:/Projects/Flutter/formulavision" && mkdir -p test/fixtures && python - <<'EOF'
S = r"C:/Users/SHREYA~1/AppData/Local/Temp/claude/D--Projects-Flutter-formulavision/73979907-ca10-4edc-9f1c-6300aeefffc2/scratchpad/suzuka_pos.jsonStream"
lines = [l.rstrip('\n') for l in open(S, encoding='utf-8-sig') if l.strip()]
mid = len(lines) // 3
open('test/fixtures/position_z_suzuka_2026.txt', 'w', newline='\n').write('\n'.join(lines[mid:mid + 3]) + '\n')
EOF
head -c 120 test/fixtures/position_z_suzuka_2026.txt
```
Expected: starts with `00:25:10.379"` followed by base64. Each line = 12-char session offset + a JSON string of base64 raw-DEFLATE. (If the scratchpad file is gone, re-download it: `curl -A BestHTTP -o <path> https://livetiming.formula1.com/static/2026/2026-03-29_Japanese_Grand_Prix/2026-03-28_Qualifying/Position.z.jsonStream`.)

- [ ] **Step 2: Write the failing tests** — replace the whole of `test/position_data_parse_test.dart` with:

```dart
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
```

- [ ] **Step 3: Run to verify failure**

Run: `flutter test test/position_data_parse_test.dart`
Expected: compile errors (`samples`, `hasFix`, `time` undefined).

- [ ] **Step 4: Implement** — in `live_data.model.dart`, replace the entire `PositionData` class (from `class PositionData {` through its closing `}` before `class PositionDataCar`) with:

```dart
/// One timestamped frame of car positions from a Position.z update.
class PositionSample {
  final String timestamp;

  /// [timestamp] parsed as UTC, or null when it is not a date (tests, legacy
  /// relay payloads).
  final DateTime? time;
  final Map<String, PositionDataCar> cars;

  PositionSample({required this.timestamp, required this.cars})
      : time = DateTime.tryParse(timestamp)?.toUtc();
}

class PositionData {
  /// Timestamp of the newest frame.
  final String timestamp;

  /// Cars in the newest frame.
  final Map<String, PositionDataCar> cars;

  /// Every frame in this update, oldest first. F1 batches ~4 frames (~250 ms
  /// apart) into each Position.z message.
  final List<PositionSample> samples;

  PositionData({
    required this.timestamp,
    required this.cars,
    List<PositionSample>? samples,
  }) : samples =
            samples ?? [PositionSample(timestamp: timestamp, cars: cars)];

  factory PositionData.fromJson(Map<String, dynamic> json) {
    // Accepted shapes:
    //   live Position.z: { Position: [ { Timestamp, Entries: { "44": {X,Y,Z,Status} } } ] }
    //   legacy relay:    { Entries: [ { Utc, Cars: { "44": {...} } } ] }
    //   flat snapshot:   { Timestamp, Cars: { "44": {...} } }
    final samples = <PositionSample>[];
    final position = json['Position'];
    final entries = json['Entries'];
    if (position is List) {
      for (final item in position) {
        if (item is Map) {
          samples.add(PositionSample(
            timestamp: item['Timestamp']?.toString() ?? '',
            cars: _parseCars(item['Entries']),
          ));
        }
      }
    } else if (entries is List) {
      for (final item in entries) {
        if (item is Map) {
          samples.add(PositionSample(
            timestamp: (item['Utc'] ?? item['Timestamp'])?.toString() ?? '',
            cars: _parseCars(item['Cars']),
          ));
        }
      }
    } else if (json['Cars'] != null) {
      samples.add(PositionSample(
        timestamp: json['Timestamp']?.toString() ?? '',
        cars: _parseCars(json['Cars']),
      ));
    }

    if (samples.isEmpty) {
      return PositionData(
        timestamp: json['Timestamp']?.toString() ?? '',
        cars: const {},
        samples: const [],
      );
    }
    return PositionData(
      timestamp: samples.last.timestamp,
      cars: samples.last.cars,
      samples: samples,
    );
  }

  static Map<String, PositionDataCar> _parseCars(dynamic source) {
    final cars = <String, PositionDataCar>{};
    if (source is Map) {
      source.forEach((key, value) {
        if (value is Map) {
          cars[key.toString()] =
              PositionDataCar.fromJson(value.cast<String, dynamic>());
        }
      });
    }
    return cars;
  }

  Map<String, dynamic> toJson() => {
        'Timestamp': timestamp,
        'Cars': Map.fromEntries(
            cars.entries.map((e) => MapEntry(e.key, e.value.toJson()))),
      };
}
```

In `PositionDataCar`, directly under `bool get isOnTrack => status == 'OnTrack';` add:

```dart
  /// F1 reports (0,0) for cars it has no position for (e.g. before the
  /// session starts); those should not be drawn.
  bool get hasFix => x != 0 || y != 0;
```

In `lib/data/services/live_data_service.dart` (~line 203), replace

```dart
        final entries = position?['Entries'];
        debugPrint('[LiveDataService] seeded positions, entries='
            '${entries is List ? entries.length : 'none'}');
```
with
```dart
        final frames = position?['Position'];
        debugPrint('[LiveDataService] seeded positions, frames='
            '${frames is List ? frames.length : 'none'}');
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/position_data_parse_test.dart test/f1_decompress_test.dart test/live_track_map_widget_test.dart`
Expected: all PASS (widget test still compiles because the constructor stays compatible).

- [ ] **Step 6: Checkpoint** — `flutter analyze lib/data/models/live_data.model.dart lib/data/services/live_data_service.dart` shows no new errors.

---

### Task 2: Read F1's capitalised Meeting/Circuit keys

**Files:**
- Modify: `lib/data/models/live_data.model.dart` — `Meeting.fromJson` (~line 929) and `Circuit.fromJson` (~line 966)
- Test: `test/session_info_parse_test.dart` (create)

**Interfaces:**
- Produces: `Meeting.fromJson` / `Circuit.fromJson` accept both F1 (`Key`, `Circuit`, `ShortName`) and legacy lowercase keys. `SessionInfo.meeting.circuit.key` is then the real circuit key (e.g. 153).

- [ ] **Step 1: Write the failing test** — create `test/session_info_parse_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/data/models/live_data.model.dart';

void main() {
  test('Meeting.fromJson reads F1 capitalised keys', () {
    final m = Meeting.fromJson({
      'Key': 1290,
      'Name': 'Spanish Grand Prix',
      'Location': 'Madrid',
      'Country': {'Key': 1, 'Code': 'ESP', 'Name': 'Spain'},
      'Circuit': {'Key': 153, 'ShortName': 'Madring'},
    });
    expect(m.key, 1290);
    expect(m.circuit.key, 153);
    expect(m.circuit.shortName, 'Madring');
  });

  test('Meeting.fromJson still reads legacy lowercase keys', () {
    final m = Meeting.fromJson({
      'key': 7,
      'Name': 'X',
      'circuit': {'key': 49, 'shortName': 'Shanghai'},
    });
    expect(m.key, 7);
    expect(m.circuit.key, 49);
    expect(m.circuit.shortName, 'Shanghai');
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/session_info_parse_test.dart`
Expected: FAIL (`m.circuit.key` is 0).

- [ ] **Step 3: Implement** — in `Meeting.fromJson` change

```dart
      key: json['key'] ?? 0,
```
to
```dart
      key: json['key'] ?? json['Key'] ?? 0,
```
and change
```dart
      circuit: json['circuit'] != null
          ? Circuit.fromJson(json['circuit'])
          : Circuit(key: 0, shortName: ''),
```
to
```dart
      circuit: json['circuit'] != null
          ? Circuit.fromJson(json['circuit'])
          : json['Circuit'] != null
              ? Circuit.fromJson(json['Circuit'])
              : Circuit(key: 0, shortName: ''),
```
In `Circuit.fromJson` change the body to:
```dart
    return Circuit(
      key: json['key'] ?? json['Key'] ?? 0,
      shortName: json['shortName'] ?? json['ShortName'] ?? '',
    );
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/session_info_parse_test.dart`
Expected: PASS.

- [ ] **Step 5: Checkpoint** — no new analyzer errors in the model file.

---

### Task 3: Bundle a Madring (Madrid) outline generated from the F1 archive

**Files:**
- Create: `tool/track_from_archive.py` (copy of the tested scratchpad script)
- Create: `assets/TrackMaps/Madring.json`
- Modify: `pubspec.yaml` (assets list, after `- assets/TrackMaps/Zandvoort.json`)

**Interfaces:**
- Produces: asset `assets/TrackMaps/Madring.json` with `circuitKey: 153`, `rotation: 90`, `x`/`y` arrays in the **bundled convention (y negated)**, same as every other TrackMaps file. Task 5's `bundledFiles` maps `153: 'Madring.json'`.

- [ ] **Step 1: Copy the generator into the repo**

```bash
cd "D:/Projects/Flutter/formulavision" && mkdir -p tool && cp "C:/Users/SHREYA~1/AppData/Local/Temp/claude/D--Projects-Flutter-formulavision/73979907-ca10-4edc-9f1c-6300aeefffc2/scratchpad/track_from_archive.py" tool/track_from_archive.py && head -8 tool/track_from_archive.py
```
Expected: docstring "Build a TrackMaps outline from an F1 static-archive Position.z.jsonStream." Do not change its logic (it is validated; the heading check is what makes Suzuka's figure-eight work).

- [ ] **Step 2: Generate Madring.json**

```bash
cd "D:/Projects/Flutter/formulavision" && python tool/track_from_archive.py "https://livetiming.formula1.com/static/2026/2026-09-13_Spanish_Grand_Prix/2026-09-12_Qualifying/Position.z.jsonStream" --out assets/TrackMaps/Madring.json --circuit-key 153 --circuit-name Madring --location Madrid --year 2026 --rotation 90
```
Expected output: `car 1: 90.9s, 5.329 km, 889 points` (±a few points is fine). Sanity: lap length must be 5.2–5.6 km; if not, stop and report.

- [ ] **Step 3: Register the asset** — in `pubspec.yaml` add directly below `    - assets/TrackMaps/Zandvoort.json`:

```yaml
    - assets/TrackMaps/Madring.json
```
Run: `flutter pub get` → succeeds.

- [ ] **Step 4: Checkpoint** — `python -c "import json;d=json.load(open('assets/TrackMaps/Madring.json'));print(d['circuitKey'],len(d['x']),len(d['y']),d['rotation'])"` prints `153 889 889 90` (counts may differ slightly but must be equal).

---

### Task 4: `PositionPlayback` — replay every frame on a delayed clock

**Files:**
- Create: `lib/data/services/position_playback.dart`
- Test: `test/position_playback_test.dart`

**Interfaces:**
- Consumes: `PositionData.samples`, `PositionSample.time`, `PositionSample.cars`, `PositionDataCar.hasFix`, `PositionDataCar.isOnTrack` (Task 1).
- Produces:
  - `class PlaybackCar { final Offset position; final bool onTrack; const PlaybackCar(this.position, this.onTrack); }`
  - `class PositionPlayback { PositionPlayback({Duration delay = const Duration(milliseconds: 1200), Duration resyncThreshold = const Duration(seconds: 3), Duration retention = const Duration(seconds: 5)}); void ingest(PositionData data, DateTime wallNow); Map<String, PlaybackCar> positionsAt(DateTime wallNow); void clear(); bool get isEmpty; }`

- [ ] **Step 1: Write the failing tests** — create `test/position_playback_test.dart`:

```dart
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
    // Well past retention (5s) of every frame.
    final later = p.positionsAt(_wall.add(const Duration(seconds: 12)));
    expect(later.containsKey('2'), isFalse);
    expect(later.containsKey('1'), isFalse); // also stale by then
    final soon = p.positionsAt(_wall.add(const Duration(seconds: 2)));
    expect(soon.containsKey('1'), isTrue);
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
```

Note on the "drops cars" test arithmetic: the first ingest sets the clock offset to `base − wall − 1.2s`. The second ingest's target is `base − wall − 0.3s` (newest frame base+2.9s at wall+2s); that is within the 3s resync threshold, so the offset only eases 10% toward it → `base − wall − 1.11s`. At wall+12s the feed time is base+10.89s, cutoff base+5.89s → both cars are stale. At wall+2s the feed time is base+0.89s → car 1 is between its base and base+2s frames, so present.

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/position_playback_test.dart`
Expected: compile error, `position_playback.dart` not found.

- [ ] **Step 3: Implement** — create `lib/data/services/position_playback.dart`:

```dart
import 'dart:ui' show Offset;

import '../models/live_data.model.dart';

/// A car's interpolated position at a playback instant.
class PlaybackCar {
  final Offset position;
  final bool onTrack;

  const PlaybackCar(this.position, this.onTrack);
}

class _Fix {
  final DateTime time;
  final Offset position;
  final bool onTrack;

  _Fix(this.time, this.position, this.onTrack);
}

/// Replays every timestamped Position.z frame on a clock that trails the feed
/// by [delay], interpolating each car between the frames either side.
///
/// F1 batches ~4 frames into a message roughly once a second. Drawing only the
/// newest frame makes cars jump once a second; playing the batch back in time
/// gives continuous motion at the cost of [delay] extra latency.
class PositionPlayback {
  PositionPlayback({
    this.delay = const Duration(milliseconds: 1200),
    this.resyncThreshold = const Duration(seconds: 3),
    this.retention = const Duration(seconds: 5),
  });

  /// How far playback trails the newest frame.
  final Duration delay;

  /// A frame further than this from the newest one (a feed gap, reconnect or
  /// replay restart) discards the buffer and restarts playback.
  final Duration resyncThreshold;

  /// Frames (and cars) older than this behind the playback clock are dropped.
  final Duration retention;

  final Map<String, List<_Fix>> _fixes = {};
  DateTime? _latest;

  // Playback clock: feedTime = wallNow + _offset.
  Duration? _offset;

  bool get isEmpty => _fixes.isEmpty;

  void clear() {
    _fixes.clear();
    _latest = null;
    _offset = null;
  }

  void ingest(PositionData data, DateTime wallNow) {
    final now = wallNow.toUtc();
    var added = false;
    for (final sample in data.samples) {
      // Frames without a parseable timestamp (tests, legacy relay) are stamped
      // with the wall clock on arrival.
      final time = sample.time ?? now;
      final latest = _latest;
      if (latest != null) {
        final gap = time.difference(latest);
        if (gap.abs() > resyncThreshold) {
          clear();
        } else if (!gap.isNegative && gap != Duration.zero) {
          // Newer frame: fall through and record it.
        } else {
          continue; // Already ingested (or slightly out of order).
        }
      }
      _latest = time;
      added = true;
      sample.cars.forEach((number, car) {
        if (!car.hasFix) return;
        _fixes
            .putIfAbsent(number, () => [])
            .add(_Fix(time, Offset(car.x, car.y), car.isOnTrack));
      });
    }

    // Only new frames move the playback clock; re-ingesting old data must not.
    final latest = _latest;
    if (!added || latest == null) return;
    final target = latest.difference(now) - delay;
    final offset = _offset;
    if (offset == null || (target - offset).abs() > resyncThreshold) {
      _offset = target;
    } else {
      // Ease toward the target so network jitter doesn't cause visible jumps.
      _offset = offset + (target - offset) * 0.1;
    }
  }

  Map<String, PlaybackCar> positionsAt(DateTime wallNow) {
    final offset = _offset;
    if (offset == null) return const {};
    final t = wallNow.toUtc().add(offset);
    final cutoff = t.subtract(retention);

    // Drop cars whose newest frame is already stale.
    _fixes.removeWhere(
        (_, fixes) => fixes.isEmpty || fixes.last.time.isBefore(cutoff));

    final result = <String, PlaybackCar>{};
    _fixes.forEach((number, fixes) {
      // Keep one frame before the cutoff as the left bracket.
      while (fixes.length > 2 && fixes[1].time.isBefore(cutoff)) {
        fixes.removeAt(0);
      }
      final first = fixes.first;
      final last = fixes.last;
      if (!t.isAfter(first.time)) {
        result[number] = PlaybackCar(first.position, first.onTrack);
        return;
      }
      if (!t.isBefore(last.time)) {
        result[number] = PlaybackCar(last.position, last.onTrack);
        return;
      }
      for (var i = 0; i < fixes.length - 1; i++) {
        final a = fixes[i];
        final b = fixes[i + 1];
        if (!t.isBefore(a.time) && t.isBefore(b.time)) {
          final span = b.time.difference(a.time).inMicroseconds;
          final f = span <= 0 ? 1.0 : t.difference(a.time).inMicroseconds / span;
          result[number] =
              PlaybackCar(Offset.lerp(a.position, b.position, f)!, a.onTrack);
          return;
        }
      }
    });
    return result;
  }
}
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/position_playback_test.dart`
Expected: all PASS. If "frames without parseable timestamps" fails, check the dedupe branch: two wall-stamped frames 1s apart must both be kept.

- [ ] **Step 5: Checkpoint** — `flutter analyze lib/data/services/position_playback.dart` clean.

---

### Task 5: `TrackMapService` — resolve outlines by circuit key

**Files:**
- Create: `lib/data/services/track_map_service.dart`
- Test: `test/track_map_service_test.dart`

**Interfaces:**
- Consumes: asset `assets/TrackMaps/Madring.json` (Task 3); fixture `test/fixtures/position_z_suzuka_2026.txt` (Task 1); `decodePositionZ`, `PositionData.fromJson`.
- Produces:
  - `class TrackMap { final int circuitKey; final List<Offset> points; final double rotationDeg; final String source; factory TrackMap.fromJson(Map<String, dynamic> json, {required bool yNegated, required String source, int? circuitKey}); }` — `points` are in F1 car coordinates. `source` ∈ `'asset' | 'cache' | 'network'`. Throws `FormatException` if `x`/`y` missing, empty or of different lengths.
  - `class TrackMapService { TrackMapService({AssetBundle? bundle, http.Client? client, Duration timeout = const Duration(seconds: 5)}); static final TrackMapService instance; static const Map<int, String> bundledFiles; static const Map<String, int> circuitKeysByName; static int? resolveCircuitKey(int circuitKey, String shortName); Future<TrackMap?> load({int circuitKey = 0, String shortName = '', int? year}); }`

- [ ] **Step 1: Write the failing tests** — create `test/track_map_service_test.dart`:

```dart
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
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/track_map_service_test.dart`
Expected: compile error, `track_map_service.dart` not found.

- [ ] **Step 3: Implement** — create `lib/data/services/track_map_service.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A circuit outline in F1 position coordinates (the same frame as the X/Y of
/// `Position.z` cars), plus the display rotation from the map data.
class TrackMap {
  final int circuitKey;
  final List<Offset> points;
  final double rotationDeg;

  /// Where the outline came from: 'asset', 'cache' or 'network'.
  final String source;

  const TrackMap({
    required this.circuitKey,
    required this.points,
    required this.rotationDeg,
    required this.source,
  });

  /// Parses MultiViewer-style map JSON (`x`, `y`, `rotation`). Bundled assets
  /// store Y negated (mirrored for the static circuit viewer), so [yNegated]
  /// flips them back into the car frame.
  factory TrackMap.fromJson(
    Map<String, dynamic> json, {
    required bool yNegated,
    required String source,
    int? circuitKey,
  }) {
    final xs = json['x'];
    final ys = json['y'];
    if (xs is! List || ys is! List || xs.isEmpty || xs.length != ys.length) {
      throw const FormatException('Track map needs equal-length x/y arrays');
    }
    final sign = yNegated ? -1.0 : 1.0;
    return TrackMap(
      circuitKey: circuitKey ?? (json['circuitKey'] as num?)?.toInt() ?? 0,
      points: [
        for (var i = 0; i < xs.length; i++)
          Offset((xs[i] as num).toDouble(), sign * (ys[i] as num).toDouble()),
      ],
      rotationDeg: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      source: source,
    );
  }
}

/// Resolves circuit outlines by F1 circuit key: bundled asset first, then the
/// on-device cache, then MultiViewer's circuit API (cached on success).
class TrackMapService {
  TrackMapService({
    AssetBundle? bundle,
    http.Client? client,
    this.timeout = const Duration(seconds: 5),
  })  : _bundle = bundle,
        _client = client ?? http.Client();

  static final TrackMapService instance = TrackMapService();

  static const String apiBase = 'https://api.multiviewer.app/api/v1/circuits';
  static const String _prefsPrefix = 'track_map_v1_';

  /// F1 circuit key → file in assets/TrackMaps (each file's own circuitKey).
  static const Map<int, String> bundledFiles = {
    2: 'Silverstone.json',
    4: 'Hungaroring.json',
    6: 'Imola.json',
    7: 'Spa-Francorchamps.json',
    9: 'Austin.json',
    10: 'Melbourne.json',
    14: 'Interlagos.json',
    15: 'Catalunya.json',
    19: 'Spielberg.json',
    22: 'Monte-Carlo.json',
    23: 'Montreal.json',
    28: 'Paul-Riccard.json',
    34: 'Hockenheim.json',
    39: 'Monza.json',
    46: 'Suzuka.json',
    49: 'Shanghai.json',
    55: 'Zandvoort.json',
    59: 'Istanbul.json',
    61: 'Singapore.json',
    63: 'Sakhir.json',
    65: 'Mexico.json',
    70: 'Yas-Marina.json',
    72: 'Nurburgring.json',
    79: 'Sochi.json',
    144: 'Baku.json',
    146: 'Mugello.json',
    147: 'Algarve.json',
    148: 'Sakhir-Outer.json',
    149: 'Jeddah.json',
    150: 'Losail.json',
    151: 'Miami.json',
    152: 'Las-Vegas.json',
    153: 'Madring.json',
  };

  /// Fallback for feeds without a circuit key: F1 `Circuit.ShortName` (plus a
  /// few legacy aliases) → circuit key.
  static const Map<String, int> circuitKeysByName = {
    'Silverstone': 2,
    'Hungaroring': 4,
    'Imola': 6,
    'Spa-Francorchamps': 7,
    'Austin': 9,
    'Melbourne': 10,
    'Interlagos': 14,
    'Catalunya': 15,
    'Spielberg': 19,
    'Monte Carlo': 22,
    'Montreal': 23,
    'Monza': 39,
    'Suzuka': 46,
    'Shanghai': 49,
    'Zandvoort': 55,
    'Singapore': 61,
    'Sakhir': 63,
    'Mexico City': 65,
    'Yas Marina Circuit': 70,
    'Baku': 144,
    'Jeddah': 149,
    'Lusail': 150,
    'Miami': 151,
    'Las Vegas': 152,
    'Madring': 153,
    // Legacy aliases.
    'Monaco': 22,
    'Bahrain': 63,
    'Marina Bay': 61,
    'COTA': 9,
    'Qatar': 150,
    'Barcelona': 15,
    'Spa': 7,
    'Yas Marina': 70,
    'Azerbaijan': 144,
    'Red Bull Ring': 19,
  };

  final AssetBundle? _bundle;
  final http.Client _client;
  final Duration timeout;
  final Map<int, Future<TrackMap?>> _memo = {};

  static int? resolveCircuitKey(int circuitKey, String shortName) {
    if (circuitKey > 0) return circuitKey;
    return circuitKeysByName[shortName.trim()];
  }

  Future<TrackMap?> load({
    int circuitKey = 0,
    String shortName = '',
    int? year,
  }) async {
    final key = resolveCircuitKey(circuitKey, shortName);
    if (key == null) {
      debugPrint('[TrackMapService] no circuit for key=$circuitKey '
          'name="$shortName"');
      return null;
    }
    final future =
        _memo.putIfAbsent(key, () => _load(key, year ?? DateTime.now().year));
    final map = await future;
    // Don't memoise failures, so a later attempt can succeed once online.
    if (map == null) _memo.remove(key);
    return map;
  }

  Future<TrackMap?> _load(int key, int year) async {
    final file = bundledFiles[key];
    if (file != null) {
      try {
        final raw =
            await (_bundle ?? rootBundle).loadString('assets/TrackMaps/$file');
        return TrackMap.fromJson(jsonDecode(raw) as Map<String, dynamic>,
            yNegated: true, source: 'asset', circuitKey: key);
      } catch (e) {
        debugPrint('[TrackMapService] bundled $file failed: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('$_prefsPrefix$key');
    if (cached != null) {
      try {
        return TrackMap.fromJson(jsonDecode(cached) as Map<String, dynamic>,
            yNegated: false, source: 'cache', circuitKey: key);
      } catch (e) {
        debugPrint('[TrackMapService] dropping bad cache for $key: $e');
        await prefs.remove('$_prefsPrefix$key');
      }
    }

    final body = await _fetch(key, year);
    if (body == null) return null;
    try {
      final map = TrackMap.fromJson(jsonDecode(body) as Map<String, dynamic>,
          yNegated: false, source: 'network', circuitKey: key);
      await prefs.setString('$_prefsPrefix$key', body);
      return map;
    } catch (e) {
      debugPrint('[TrackMapService] bad map from network for $key: $e');
      return null;
    }
  }

  Future<String?> _fetch(int key, int year) async {
    try {
      final exact = await _get('$apiBase/$key/$year');
      if (exact != null) return exact;
      // MultiViewer only has some years per circuit; retry with its newest.
      final listing = await _get(apiBase);
      if (listing == null) return null;
      final entry = (jsonDecode(listing) as Map<String, dynamic>)['$key'];
      final years = entry is Map ? entry['years'] : null;
      if (years is List && years.isNotEmpty && years.first != year) {
        return await _get('$apiBase/$key/${years.first}');
      }
    } catch (e) {
      debugPrint('[TrackMapService] fetch failed for $key: $e');
    }
    return null;
  }

  Future<String?> _get(String url) async {
    final resp = await _client.get(Uri.parse(url),
        headers: const {'User-Agent': 'FormulaVision'}).timeout(timeout);
    return resp.statusCode == 200 ? resp.body : null;
  }
}
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/track_map_service_test.dart`
Expected: all PASS. If "every bundled file…" fails for Madring, Task 3's asset or pubspec entry is missing.

- [ ] **Step 5: Checkpoint** — `flutter analyze lib/data/services/track_map_service.dart` clean.

---

### Task 6: Rewire `LiveTrackMapWidget` and the dashboard

**Files:**
- Modify: `lib/pages/dashboard_page.dart` — `_buildLiveMap` (~line 615-640) and `LiveTrackMapWidget` / `_LiveTrackMapWidgetState` / `_LiveTrackPainter` (~line 1450 to end of file)
- Test: `test/live_track_map_widget_test.dart` (rewrite)

**Interfaces:**
- Consumes: `TrackMapService`, `TrackMap` (Task 5); `PositionPlayback`, `PlaybackCar` (Task 4); `SessionInfo.meeting.circuit.key/shortName`, `SessionInfo.startDate` (Task 2).
- Produces: `LiveTrackMapWidget({Key? key, required PositionData positionData, required Map<String, Driver> drivers, int circuitKey = 0, String circuitShortName = '', int? year, Color trackColor = const Color(0xFF9E9E9E), TrackMapService? trackMapService})`. Shows the text `Track map unavailable for this circuit` when no outline can be found.

- [ ] **Step 1: Rewrite the widget test** — replace `test/live_track_map_widget_test.dart` entirely:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/data/models/live_data.model.dart';
import 'package:formulavision/data/services/track_map_service.dart';
import 'package:formulavision/pages/dashboard_page.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// The map repaints every frame (playback ticker), so pumpAndSettle never
// settles. Pump a bounded number of frames instead.
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

  // Never hit the real network from widget tests.
  final service =
      TrackMapService(client: MockClient((_) async => http.Response('', 404)));

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget build(PositionData pos, {int circuitKey = 19}) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 200,
            child: LiveTrackMapWidget(
              positionData: pos,
              drivers: drivers,
              circuitKey: circuitKey,
              trackMapService: service,
            ),
          ),
        ),
      );

  testWidgets('loads the track outline by circuit key and paints',
      (tester) async {
    await tester.pumpWidget(build(_positions({
      '1': [1102, -1207],
      '44': [0, 0],
    })));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _pumpFrames(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Track map unavailable for this circuit'), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('animates new positions without throwing', (tester) async {
    await tester.pumpWidget(build(_positions({'1': [1102, -1207]})));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _pumpFrames(tester);

    await tester.pumpWidget(build(_positions({'1': [1200, -1300]})));
    await _pumpFrames(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('unknown circuit shows unavailable message', (tester) async {
    await tester.pumpWidget(
        build(_positions({'1': [1, 1]}), circuitKey: 99999));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _pumpFrames(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Track map unavailable for this circuit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching circuit reloads without throwing', (tester) async {
    await tester.pumpWidget(build(_positions({'1': [1, 1]}), circuitKey: 19));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _pumpFrames(tester);

    await tester.pumpWidget(build(_positions({'1': [2, 2]}), circuitKey: 22));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _pumpFrames(tester);

    expect(find.text('Track map unavailable for this circuit'), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
```

(The `runAsync` delay lets real async work — asset loading, SharedPreferences, the mock HTTP client — complete; if the asset test was already passing without it in the old version, it's harmless.)

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/live_track_map_widget_test.dart`
Expected: compile errors (`circuitKey`, `trackMapService` not parameters).

- [ ] **Step 3: Update `_buildLiveMap`** — in `dashboard_page.dart` replace the `return LiveTrackMapWidget(...)` inside `_buildLiveMap` with:

```dart
        final session = data.sessionInfo;
        return LiveTrackMapWidget(
          positionData: positionData,
          drivers: data.driverList?.drivers ?? {},
          circuitKey: session?.meeting.circuit.key ?? 0,
          circuitShortName: session?.meeting.circuit.shortName ?? '',
          year: int.tryParse((session?.startDate ?? '').split('-').first),
          trackColor: _trackLineColor(data.trackStatus?.status),
        );
```

- [ ] **Step 4: Replace the widget, state and painter** — delete everything from the comment block above `class LiveTrackMapWidget` (`// Cars are interpolated between successive Position.z updates…`) to the end of the file, and put this in its place:

```dart
// Live track map. Every Position.z frame is replayed slightly behind real time
// (see PositionPlayback) so cars move continuously, the outline is looked up
// by circuit key (see TrackMapService) and drawn aspect-correct with the Y axis
// flipped to a conventional orientation, the outline is tinted by track
// status, and off-track / pitting cars are dimmed.
class LiveTrackMapWidget extends StatefulWidget {
  final PositionData positionData;
  final Map<String, Driver> drivers;
  final int circuitKey;
  final String circuitShortName;
  final int? year;
  final Color trackColor;

  /// Override for tests; defaults to [TrackMapService.instance].
  final TrackMapService? trackMapService;

  const LiveTrackMapWidget({
    super.key,
    required this.positionData,
    required this.drivers,
    this.circuitKey = 0,
    this.circuitShortName = '',
    this.year,
    this.trackColor = const Color(0xFF9E9E9E),
    this.trackMapService,
  });

  @override
  State<LiveTrackMapWidget> createState() => _LiveTrackMapWidgetState();
}

class _LiveTrackMapWidgetState extends State<LiveTrackMapWidget>
    with SingleTickerProviderStateMixin {
  List<Offset> _trackPoints = [];
  double? minX, maxX, minY, maxY;
  // Rotation (from the track JSON) applied to both the outline and the cars so
  // the circuit is shown in a conventional orientation.
  double _rotationRad = 0;
  Offset _rotCenter = Offset.zero;
  bool _loadingTrack = true;
  int _loadGeneration = 0;

  final PositionPlayback _playback = PositionPlayback();
  // Bumped every frame by the ticker to repaint the cars.
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;

  // Rotates [p] around [center] by [rad] radians.
  static Offset rotateAround(Offset p, Offset center, double rad) {
    if (rad == 0) return p;
    final dx = p.dx - center.dx;
    final dy = p.dy - center.dy;
    final cos = math.cos(rad);
    final sin = math.sin(rad);
    return Offset(
      center.dx + dx * cos - dy * sin,
      center.dy + dx * sin + dy * cos,
    );
  }

  @override
  void initState() {
    super.initState();
    _playback.ingest(widget.positionData, DateTime.now());
    _ticker = createTicker((_) => _frame.value++)..start();
    _loadTrack();
  }

  @override
  void didUpdateWidget(LiveTrackMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circuitKey != widget.circuitKey ||
        oldWidget.circuitShortName != widget.circuitShortName) {
      _playback.clear();
      _loadTrack();
    }
    // The parent rebuilds on every topic update; only ingest new position
    // objects.
    if (!identical(oldWidget.positionData, widget.positionData)) {
      _playback.ingest(widget.positionData, DateTime.now());
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  Future<void> _loadTrack() async {
    final generation = ++_loadGeneration;
    // Called from initState/didUpdateWidget, which are always followed by a
    // build, so no setState is needed here.
    _loadingTrack = true;
    final service = widget.trackMapService ?? TrackMapService.instance;
    final track = await service.load(
      circuitKey: widget.circuitKey,
      shortName: widget.circuitShortName,
      year: widget.year,
    );
    if (!mounted || generation != _loadGeneration) return;
    if (track == null) {
      setState(() {
        _trackPoints = [];
        _loadingTrack = false;
      });
      return;
    }

    final rawPoints = track.points;
    final rotationRad = track.rotationDeg * math.pi / 180.0;
    // Rotate around the raw centre; the cars are later rotated about the same
    // point so they stay aligned with the outline.
    final rMinX = rawPoints.map((e) => e.dx).reduce(math.min);
    final rMaxX = rawPoints.map((e) => e.dx).reduce(math.max);
    final rMinY = rawPoints.map((e) => e.dy).reduce(math.min);
    final rMaxY = rawPoints.map((e) => e.dy).reduce(math.max);
    final center = Offset((rMinX + rMaxX) / 2, (rMinY + rMaxY) / 2);

    final rotated =
        rawPoints.map((p) => rotateAround(p, center, rotationRad)).toList();

    setState(() {
      _trackPoints = rotated;
      _rotationRad = rotationRad;
      _rotCenter = center;
      minX = rotated.map((e) => e.dx).reduce(math.min);
      maxX = rotated.map((e) => e.dx).reduce(math.max);
      minY = rotated.map((e) => e.dy).reduce(math.min);
      maxY = rotated.map((e) => e.dy).reduce(math.max);
      _loadingTrack = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingTrack) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading track map...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }
    if (_trackPoints.isEmpty) {
      return const Center(
        child: Text(
          'Track map unavailable for this circuit',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _LiveTrackPainter(
            trackPoints: _trackPoints,
            bounds: Rect.fromLTRB(minX!, minY!, maxX!, maxY!),
            rotationRad: _rotationRad,
            rotCenter: _rotCenter,
            drivers: widget.drivers,
            trackColor: widget.trackColor,
            playback: _playback,
            repaint: _frame,
          ),
        );
      },
    );
  }
}

class _LiveTrackPainter extends CustomPainter {
  final List<Offset> trackPoints;
  final Rect bounds;
  final double rotationRad;
  final Offset rotCenter;
  final Map<String, Driver> drivers;
  final Color trackColor;
  final PositionPlayback playback;

  _LiveTrackPainter({
    required this.trackPoints,
    required this.bounds,
    required this.rotationRad,
    required this.rotCenter,
    required this.drivers,
    required this.trackColor,
    required this.playback,
    required Listenable repaint,
  }) : super(repaint: repaint);

  static const double _pad = 18.0;

  // Projects a track-space point into canvas space: uniform scale to preserve
  // aspect ratio, centered, with the Y axis flipped (track is y-up, canvas is
  // y-down). The same transform is applied to the outline and the cars so they
  // stay aligned.
  Offset _project(Offset p, Size size) {
    final spanX = bounds.width.abs() < 1e-6 ? 1.0 : bounds.width;
    final spanY = bounds.height.abs() < 1e-6 ? 1.0 : bounds.height;
    final availW = math.max(1.0, size.width - _pad * 2);
    final availH = math.max(1.0, size.height - _pad * 2);
    final scale = math.min(availW / spanX, availH / spanY);
    final drawnW = spanX * scale;
    final drawnH = spanY * scale;
    final originX = _pad + (availW - drawnW) / 2;
    final originY = _pad + (availH - drawnH) / 2;
    final x = originX + (p.dx - bounds.left) * scale;
    final y = originY + (bounds.bottom - p.dy) * scale;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Track outline: dark base stroke + status-tinted line on top.
    if (trackPoints.isNotEmpty) {
      final path = Path();
      final first = _project(trackPoints.first, size);
      path.moveTo(first.dx, first.dy);
      for (final pt in trackPoints.skip(1)) {
        final p = _project(pt, size);
        path.lineTo(p.dx, p.dy);
      }
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withOpacity(0.45)
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = trackColor
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    // Cars at the current playback instant.
    final cars = playback.positionsAt(DateTime.now());
    for (final entry in cars.entries) {
      final number = entry.key;
      final car = entry.value;
      final driver = drivers[number];
      final pos = _project(
        _LiveTrackMapWidgetState.rotateAround(
            car.position, rotCenter, rotationRad),
        size,
      );

      Color teamColor = Colors.red;
      final tc = driver?.teamColour;
      if (tc != null && tc.isNotEmpty && tc.length == 6) {
        try {
          teamColor = Color(int.parse('0xFF$tc'));
        } catch (_) {
          teamColor = Colors.red;
        }
      }

      // Dim cars that are not actively on track (pits, retired, off track).
      final opacity = car.onTrack ? 1.0 : 0.3;

      canvas.drawCircle(
        pos,
        6,
        Paint()
          ..color = teamColor.withOpacity(opacity)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        pos,
        6,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );

      final label = (driver?.tla.isNotEmpty ?? false) ? driver!.tla : number;
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white.withOpacity(opacity),
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, pos + Offset(-textPainter.width / 2, -18));
    }
  }

  @override
  bool shouldRepaint(covariant _LiveTrackPainter oldDelegate) {
    return oldDelegate.trackPoints != trackPoints ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.bounds != bounds ||
        oldDelegate.drivers != drivers ||
        oldDelegate.playback != playback;
  }
}
```

Add these imports at the top of `dashboard_page.dart` (keep alphabetical-ish grouping with the existing `package:formulavision/...` imports):

```dart
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:formulavision/data/services/position_playback.dart';
import 'package:formulavision/data/services/track_map_service.dart';
```

Then remove imports that are now unused (the old `_loadTrack` was the only user of `jsonDecode`/`rootBundle` in this file **if** `flutter analyze` reports `dart:convert` or `package:flutter/services.dart` as unused — only remove what the analyzer flags).

- [ ] **Step 5: Run tests**

Run: `flutter test test/live_track_map_widget_test.dart`
Expected: all 4 PASS.

- [ ] **Step 6: Analyze**

Run: `flutter analyze lib/pages/dashboard_page.dart lib/data lib/components`
Expected: no new errors/warnings introduced by this work (pre-existing infos like `withOpacity` deprecation are fine). No remaining reference to `_getTrackFile` or `circuitShortName:`-only call sites that break.

---

### Task 7: Full verification and graph update

- [ ] **Step 1: Full test suite**

Run: `flutter test`
Expected: everything passes except the pre-existing `test/widget_test.dart` "Counter increments smoke test" failure (same as baseline). Report exact counts.

- [ ] **Step 2: Build check**

Run: `flutter build apk --debug`
Expected: build succeeds. (If it fails for reasons unrelated to these files — e.g. signing/Gradle environment — report the error verbatim and do not try to fix unrelated build config.)

- [ ] **Step 3: Update the knowledge graph**

Run: `graphify update .`
Expected: completes (AST-only, no API cost).

- [ ] **Step 4: Report** — list every file created/modified, test counts, analyzer status, and the `track_from_archive.py` output line for Madring. Do not commit.

## Manual verification (for the user, after the agent finishes)

On a **real device** (the emulator can't resolve livetiming.formula1.com) during a live session: open Dashboard → Track Map. Expect cars on the outline, moving continuously (~1.2 s behind timing), correct outline at Shanghai/Monaco/Bahrain/Madrid-type circuits, and "Track map unavailable for this circuit" instead of an endless spinner for unknown circuits.
