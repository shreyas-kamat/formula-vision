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
