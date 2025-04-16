import 'dart:math';
import 'package:flutter/material.dart';

class F1Speedometer extends StatelessWidget {
  final double speed;
  final double maxSpeed;
  final double size;
  final double throttle; // New: Throttle percentage
  final double brake; // New: Brake percentage
  final double rpm; // New: RPM value
  final int gear; // New: Current gear
  final bool drsActive; // New: DRS status
  final Color backgroundColor;
  final Color needleColor;
  final Color textColor;

  const F1Speedometer({
    Key? key,
    required this.speed,
    this.maxSpeed = 320,
    this.size = 300,
    this.throttle = 0,
    this.brake = 0,
    this.rpm = 0,
    this.gear = 0,
    this.drsActive = false,
    this.backgroundColor = Colors.black,
    this.needleColor = Colors.red,
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Speedometer background
        _buildSpeedometerBackground(),

        // Speed markings
        // _buildSpeedMarkings(),

        // Needle
        // _buildNeedle(),

        // Center cap
        // _buildCenterCap(),

        // Throttle and brake arcs
        _buildThrottleIndicator(),
        _buildSpeedArc(),
        _buildBrakeIndicator(),
        // _buildBrakeArc(),

        // Digital speed display
        _buildDigitalSpeed(),
        if (drsActive) _buildDRSIndicator(),

        // RPM and gear display
        _buildRPM(),

        // DRS status
      ],
    );
  }

  Widget _buildSpeedometerBackground() {
    return CustomPaint(
      size: Size(size, size),
      painter: SpeedometerBackgroundPainter(
        backgroundColor: backgroundColor,
      ),
    );
  }

  Widget _buildSpeedMarkings() {
    return CustomPaint(
      size: Size(size, size),
      painter: SpeedMarkingsPainter(
        maxSpeed: maxSpeed,
        textColor: textColor,
      ),
    );
  }

  // Widget _buildNeedle() {
  //   final angle = (speed / maxSpeed) * 240 - 210;

  //   return Transform.rotate(
  //     angle: angle * pi / 180,
  //     child: Container(
  //       width: size * 0.04,
  //       height: size * 0.5,
  //       decoration: BoxDecoration(
  //         color: needleColor,
  //         borderRadius: BorderRadius.circular(size * 0.02),
  //       ),
  //       alignment: Alignment.topCenter,
  //       transformAlignment: Alignment.bottomCenter,
  //     ),
  //   );
  // }

  Widget _buildThrottleIndicator() {
    return CustomPaint(
      size: Size(size, size),
      painter: ArcPainter(
        percentage: throttle,
        color: Colors.green,
        startAngle:
            -210, // Start from 7:00 clock position (adjusted to end at 12 o'clock)
        sweepAngle: 148, // From -210° to -60° (12 o'clock position)
        thickness: size * 0.02,
      ),
    );
  }

  Widget _buildBrakeIndicator() {
    return CustomPaint(
      size: Size(size, size),
      painter: ArcPainter(
        percentage: brake,
        color: Colors.red,
        startAngle: 30, // Start from 4:00 clock position
        sweepAngle: -88, // Move counterclockwise to end at 12 o'clock
        thickness: size * 0.02,
      ),
    );
  }

  Widget _buildSpeedArc() {
    // Calculate the angle based on current speed relative to max speed
    final speedPercentage = (speed / maxSpeed) * 100;

    // Add a little padding outside the throttle and brake arcs
    final outerRadius = size * 0.04; // Thickness of the speed arc

    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.all(size * 0.05), // Add padding outside other arcs
        child: CustomPaint(
          painter: ArcPainter(
            percentage: speedPercentage,
            color: Colors.green.withValues(alpha: 0.3),
            startAngle: -210, // Start from the same position as the speedometer
            sweepAngle: 240, // Match the standard speedometer sweep angle
            thickness: outerRadius,
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalSpeed() {
    return Positioned(
      top: size * 0.1,
      child: Column(
        children: [
          Text(
            speed.toInt().toString(),
            style: TextStyle(
              fontSize: size * 0.15,
              fontWeight: FontWeight.bold,
              fontFamily: 'formula-bold',
              color: brake == 100
                  ? Colors.red.withValues(alpha: 0.8)
                  : Colors.green,
            ),
          ),
          Text(
            'KMH',
            style: TextStyle(
              fontSize: size * 0.05,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRPM() {
    return Positioned(
      top: size * 0.4,
      child: Column(
        children: [
          Text(
            '${rpm.toInt()}',
            style: TextStyle(
              fontSize: size * 0.15,
              fontWeight: FontWeight.bold,
              fontFamily: 'formula-bold',
              color: brake == 100
                  ? Colors.red.withValues(alpha: 0.8)
                  : Colors.green,
            ),
          ),
          Text(
            'RPM',
            style: TextStyle(
              fontSize: size * 0.05,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          )
          // Text(
          //   'Gear: $gear',
          //   style: TextStyle(
          //     fontSize: size * 0.05,
          //     color: textColor,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildDRSIndicator() {
    return Positioned(
      bottom: size * 0.1,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: size * 0.05, vertical: size * 0.02),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.green, width: 5),
        ),
        child: Text(
          'DRS',
          style: TextStyle(
            fontSize: size * 0.05,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class ArcPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double startAngle;
  final double sweepAngle;
  final double thickness;

  ArcPainter({
    required this.percentage,
    required this.color,
    required this.startAngle,
    required this.sweepAngle,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - thickness / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final angle = (sweepAngle * percentage / 100) * pi / 180;
    final start = startAngle * pi / 180;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      angle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SpeedometerBackgroundPainter extends CustomPainter {
  final Color backgroundColor;

  SpeedometerBackgroundPainter({
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the background circle
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SpeedMarkingsPainter extends CustomPainter {
  final double maxSpeed;
  final Color textColor;

  SpeedMarkingsPainter({
    required this.maxSpeed,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    final majorTickCount = 8; // 0, 40, 80, 120, 160, 200, 240, 280, 320
    final minorTicksPerMajor = 4; // 5 minor ticks between each major tick

    final majorTickPaint = Paint()
      ..color = textColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final minorTickPaint = Paint()
      ..color = textColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw ticks - standard orientation starting from -210 degrees (bottom left)
    // and sweeping 240 degrees clockwise
    for (int i = 0; i <= majorTickCount; i++) {
      final angle = -210 + (i * 240 / majorTickCount);
      final tickAngle = angle * pi / 180;

      // Major tick
      final outerMajor = Offset(
        center.dx + radius * cos(tickAngle),
        center.dy + radius * sin(tickAngle),
      );
      final innerMajor = Offset(
        center.dx + (radius - size.width * 0.05) * cos(tickAngle),
        center.dy + (radius - size.width * 0.05) * sin(tickAngle),
      );
      canvas.drawLine(innerMajor, outerMajor, majorTickPaint);

      // Major tick speed value
      final speed = (i * maxSpeed / majorTickCount).round();
      final textPainter = TextPainter(
        text: TextSpan(
          text: speed.toString(),
          style: TextStyle(
            color: textColor,
            fontSize: size.width * 0.04,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final labelRadius = radius - size.width * 0.09;
      final labelPosition = Offset(
        center.dx + labelRadius * cos(tickAngle) - textPainter.width / 2,
        center.dy + labelRadius * sin(tickAngle) - textPainter.height / 2,
      );
      textPainter.paint(canvas, labelPosition);

      // Minor ticks
      if (i < majorTickCount) {
        for (int j = 1; j <= minorTicksPerMajor; j++) {
          final minorAngle =
              angle + (j * 240 / (majorTickCount * minorTicksPerMajor));
          final minorTickAngle = minorAngle * pi / 180;
          final outerMinor = Offset(
            center.dx + radius * cos(minorTickAngle),
            center.dy + radius * sin(minorTickAngle),
          );
          final innerMinor = Offset(
            center.dx + (radius - size.width * 0.03) * cos(minorTickAngle),
            center.dy + (radius - size.width * 0.03) * sin(minorTickAngle),
          );
          canvas.drawLine(innerMinor, outerMinor, minorTickPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
