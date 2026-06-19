import 'dart:async';

/// Local countdown of the session clock.
///
/// F1 publishes `ExtrapolatedClock` only occasionally with an `Extrapolating`
/// flag; the client is expected to tick the remaining time down each second in
/// between. This is a direct port of the backend's `clockService.js` so the
/// on-device feed behaves identically to the old server path. Each tick (and
/// each fresh F1 update) is handed to [onClock] as a
/// `{ Utc, Remaining, Extrapolating }` map.
class F1ClockExtrapolator {
  F1ClockExtrapolator(this.onClock);

  final void Function(Map<String, dynamic> clock) onClock;

  Timer? _timer;
  bool _running = false;
  bool _extrapolating = false;
  int _baseRemainingSeconds = 0;
  DateTime? _lastF1Update;

  /// Feed a fresh `ExtrapolatedClock` payload from F1.
  void updateFromF1Clock(Map<String, dynamic> clockData) {
    _lastF1Update = DateTime.now();

    final remaining = clockData['Remaining'];
    if (remaining != null) {
      _baseRemainingSeconds = _parseRemaining(remaining);
    }
    _extrapolating = clockData['Extrapolating'] == true;

    onClock({
      'Utc': clockData['Utc'] ?? DateTime.now().toUtc().toIso8601String(),
      'Remaining': clockData['Remaining'] ?? _format(_baseRemainingSeconds),
      'Extrapolating': _extrapolating,
    });

    if (_extrapolating && !_running) {
      _start();
    } else if (!_extrapolating && _running) {
      _stop();
    }
  }

  void _start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if (!_extrapolating || _lastF1Update == null) return;

    final elapsedSeconds =
        DateTime.now().difference(_lastF1Update!).inSeconds;
    final currentRemaining =
        (_baseRemainingSeconds - elapsedSeconds).clamp(0, _baseRemainingSeconds);

    onClock({
      'Utc': DateTime.now().toUtc().toIso8601String(),
      'Remaining': _format(currentRemaining),
      'Extrapolating': _extrapolating,
    });

    if (currentRemaining <= 0) {
      _extrapolating = false;
      _stop();
    }
  }

  int _parseRemaining(dynamic remaining) {
    if (remaining is num) return remaining.toInt();
    if (remaining is String && remaining.contains(':')) {
      final parts = remaining.split(':');
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      final seconds = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
      return hours * 3600 + minutes * 60 + seconds;
    }
    return int.tryParse(remaining.toString()) ?? 0;
  }

  String _format(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Reset all state (new session) and stop ticking.
  void reset() {
    _stop();
    _extrapolating = false;
    _baseRemainingSeconds = 0;
    _lastF1Update = null;
  }

  void dispose() => _stop();
}
