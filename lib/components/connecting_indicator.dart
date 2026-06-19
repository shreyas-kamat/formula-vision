import 'package:flutter/material.dart';

/// Connecting / loading state for the live dashboard, themed as the F1
/// start-light gantry: five red lights illuminate left-to-right, hold, then go
/// out ("lights out") before repeating — the sport's signature "about to go
/// live" moment. Shown while the feed is connecting and no telemetry has
/// arrived yet.
class ConnectingIndicator extends StatefulWidget {
  const ConnectingIndicator({
    super.key,
    this.message = 'Connecting to live timing',
    this.detail,
  });

  /// Primary line under the lights.
  final String message;

  /// Optional smaller status line (e.g. the current connection step).
  final String? detail;

  @override
  State<ConnectingIndicator> createState() => _ConnectingIndicatorState();
}

class _ConnectingIndicatorState extends State<ConnectingIndicator>
    with SingleTickerProviderStateMixin {
  static const int _lightCount = 5;
  // Each light switches on at this fraction of the cycle, spaced evenly.
  static const double _step = 0.11;
  // All five stay lit until here, then snap off together (lights out).
  static const double _holdEnd = 0.72;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isLit(int index, double v) {
    if (v >= _holdEnd) return false; // lights out — all off together
    return v >= index * _step;
  }

  @override
  Widget build(BuildContext context) {
    // Respect reduced-motion: hold all lights on, no looping flash.
    final bool animate = !MediaQuery.of(context).disableAnimations;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final v = animate ? _controller.value : 0.6; // 0.6 == all lit
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_lightCount, (i) {
                  return Padding(
                    padding: EdgeInsets.only(
                        right: i == _lightCount - 1 ? 0 : 8),
                    child: _LightPod(lit: _isLit(i, v)),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 28),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'formula-bold',
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          if (widget.detail != null && widget.detail!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.detail!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontFamily: 'formula',
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single gantry pod: a dark housing with two stacked lamps.
class _LightPod extends StatelessWidget {
  const _LightPod({required this.lit});

  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E11),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Lamp(lit: lit),
          const SizedBox(height: 6),
          _Lamp(lit: lit),
        ],
      ),
    );
  }
}

class _Lamp extends StatelessWidget {
  const _Lamp({required this.lit});

  final bool lit;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lit ? const Color(0xFFFF1E1E) : const Color(0xFF360A0A),
        boxShadow: lit
            ? [
                BoxShadow(
                  color: const Color(0xFFFF1E1E).withValues(alpha: 0.65),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}
