import 'package:flutter/material.dart';
import 'package:formulavision/components/speedometer.dart';
import 'package:formulavision/data/models/live_data.model.dart';
import 'package:formulavision/data/services/live_data_service.dart';

/// Full-screen live speedometer for a single driver. Subscribes to the shared
/// [LiveDataService] and drives the circular [F1Speedometer] gauge from the
/// driver's live [CarTelemetry], updating in step with the feed.
class LiveDetailsPage extends StatefulWidget {
  final String racingNumber;
  final String? driverName;
  final Color? teamColor;

  const LiveDetailsPage({
    super.key,
    required this.racingNumber,
    this.driverName,
    this.teamColor,
  });

  @override
  State<LiveDetailsPage> createState() => _LiveDetailsPageState();
}

class _LiveDetailsPageState extends State<LiveDetailsPage> {
  @override
  void initState() {
    super.initState();
    // Keep the feed alive while this page is open (the dashboard underneath is
    // usually still attached, but attach/detach is ref-counted so this is safe).
    LiveDataService.instance.attach();
  }

  @override
  void dispose() {
    LiveDataService.instance.detach();
    super.dispose();
  }

  CarTelemetry? _telemetryFrom(List<LiveData>? data) {
    if (data == null || data.isEmpty) return null;
    return data[0].carData[widget.racingNumber];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 6,
              height: 22,
              decoration: BoxDecoration(
                color: widget.teamColor ?? Colors.red,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.driverName?.isNotEmpty == true
                  ? widget.driverName!
                  : widget.racingNumber,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<LiveData>>(
        stream: LiveDataService.instance.stream,
        initialData: LiveDataService.instance.current,
        builder: (context, snapshot) {
          final t = _telemetryFrom(snapshot.data);
          return SafeArea(
            child: Center(
              child: t == null
                  ? const Text(
                      'NO TELEMETRY',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.biggest.shortestSide
                            .clamp(220.0, 360.0);
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            F1Speedometer(
                              speed: t.speed.toDouble(),
                              maxSpeed: 360,
                              size: size,
                              throttle: t.throttle.toDouble(),
                              brake: t.brake.toDouble(),
                              rpm: t.rpm.toDouble(),
                              gear: t.gear,
                              drsActive: t.isDrsActive,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.05),
                              textColor: Colors.white,
                            ),
                            const SizedBox(height: 32),
                            Text(
                              t.gear <= 0 ? 'GEAR N' : 'GEAR ${t.gear}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                fontFamily: 'Roboto Mono',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }
}
