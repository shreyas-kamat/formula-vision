import 'package:flutter/material.dart';
import 'package:formulavision/data/models/live_data.model.dart';
import 'package:formulavision/data/services/app_settings_service.dart';

/// A flat, F1 cockpit-style telemetry HUD: a large central speed read-out
/// (km/h primary with mph beneath, tap to swap) over an RPM "boost" bar,
/// flanked by a brake bar (left) and throttle bar (right), with gear and an
/// Active Aero (DRS) indicator on the right.
class TelemetryHud extends StatefulWidget {
  final CarTelemetry? telemetry;

  const TelemetryHud({super.key, required this.telemetry});

  @override
  State<TelemetryHud> createState() => _TelemetryHudState();
}

class _TelemetryHudState extends State<TelemetryHud> {
  // Cached across instances so toggling on one row reflects on the next build
  // of any other row, while persistence makes it survive restarts.
  static String _unit = AppSettings.speedUnitKmh;
  static bool _loaded = false;

  static const int _maxRpm = 13000;
  static const Color _green = Color(0xFF10B981);
  static const Color _red = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    if (!_loaded) {
      AppSettings.getSpeedUnit().then((u) {
        if (!mounted) return;
        setState(() {
          _unit = u;
          _loaded = true;
        });
      });
    }
  }

  void _toggleUnit() {
    setState(() {
      _unit =
          _unit == AppSettings.speedUnitKmh ? AppSettings.speedUnitMph : AppSettings.speedUnitKmh;
    });
    AppSettings.setSpeedUnit(_unit);
  }

  int get _mph => (((widget.telemetry?.speed ?? 0)) * 0.621371).round();

  @override
  Widget build(BuildContext context) {
    final t = widget.telemetry;
    if (t == null) {
      return Container(
        height: 132,
        alignment: Alignment.center,
        child: const Text(
          'NO TELEMETRY',
          style: TextStyle(
            color: Colors.white30,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      );
    }

    final kmhPrimary = _unit == AppSettings.speedUnitKmh;
    final primaryValue = kmhPrimary ? t.speed : _mph;
    final primaryUnit = kmhPrimary ? 'KM/H' : 'MPH';
    final secondaryValue = kmhPrimary ? _mph : t.speed;
    final secondaryUnit = kmhPrimary ? 'MPH' : 'KM/H';

    return SizedBox(
      height: 132,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PedalBar(
            label: 'BRAKE',
            percent: t.brake.clamp(0, 100).toDouble(),
            color: _red,
          ),
          const SizedBox(width: 14),
          // Center stack
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  primaryUnit,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleUnit,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$primaryValue',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 46,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Roboto Mono',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _RpmBar(rpm: t.rpm, maxRpm: _maxRpm),
                const SizedBox(height: 6),
                Text(
                  '$secondaryValue $secondaryUnit',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto Mono',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _PedalBar(
            label: 'THROTTLE',
            percent: t.throttle.clamp(0, 100).toDouble(),
            color: _green,
          ),
          const SizedBox(width: 14),
          // Right cluster: gear + active aero
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'GEAR',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t.gear <= 0 ? 'N' : '${t.gear}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Roboto Mono',
                ),
              ),
              const SizedBox(height: 10),
              _AeroPill(active: t.isDrsActive),
            ],
          ),
        ],
      ),
    );
  }
}

/// A vertical pedal-input bar that fills bottom-up by [percent] (0..100).
class _PedalBar extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;

  const _PedalBar({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: 14,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.white12),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: (percent / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// A horizontal segmented RPM bar that shifts green → amber → red as revs climb.
class _RpmBar extends StatelessWidget {
  final int rpm;
  final int maxRpm;
  static const int _segments = 16;

  const _RpmBar({required this.rpm, required this.maxRpm});

  @override
  Widget build(BuildContext context) {
    final lit = ((rpm / maxRpm) * _segments).round().clamp(0, _segments);
    return SizedBox(
      width: 150,
      height: 8,
      child: Row(
        children: [
          for (int i = 0; i < _segments; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: i < lit
                      ? _segmentColor(i)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _segmentColor(int index) {
    final frac = index / _segments;
    if (frac > 0.85) return const Color(0xFFEF4444); // red
    if (frac > 0.65) return const Color(0xFFFBBF24); // amber
    return const Color(0xFF10B981); // green
  }
}

/// Active Aero (DRS) on/off indicator.
class _AeroPill extends StatelessWidget {
  final bool active;
  const _AeroPill({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF10B981) : Colors.white24;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'AERO',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          Text(
            active ? 'ON' : 'OFF',
            style: TextStyle(
              color: active ? const Color(0xFF10B981) : Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
