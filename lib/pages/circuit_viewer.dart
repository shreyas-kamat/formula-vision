import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CircuitViewer extends StatefulWidget {
  final String circuitName;
  final String jsonFilename;
  final String country;

  const CircuitViewer({
    super.key,
    required this.circuitName,
    required this.jsonFilename,
    required this.country,
  });

  @override
  State<CircuitViewer> createState() => _CircuitViewerState();
}

class _CircuitViewerState extends State<CircuitViewer> {
  Map<String, dynamic>? _circuitData;
  bool _isLoading = true;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset? _startingFocalPoint;
  Offset? _previousOffset;
  double? _previousScale;

  @override
  void initState() {
    super.initState();
    _loadCircuitData();
  }

  Future<void> _loadCircuitData() async {
    try {
      final String jsonString =
          await rootBundle.loadString(widget.jsonFilename);
      final data = jsonDecode(jsonString);

      setState(() {
        _circuitData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading circuit data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Color.fromARGB(255, 87, 0, 0), // Dark red
            const Color.fromARGB(190, 244, 67, 54),
            Color.fromARGB(255, 80, 0, 0), // Dark red
            const Color.fromARGB(255, 36, 16, 16),
          ],
        ),
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              widget.circuitName,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'formula-bold',
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        widget.country,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onScaleStart: (details) {
                          _startingFocalPoint = details.focalPoint;
                          _previousOffset = _offset;
                          _previousScale = _scale;
                        },
                        onScaleUpdate: (details) {
                          setState(() {
                            // Update scale
                            _scale = (_previousScale ?? 1.0) * details.scale;
                            // Limit scale to reasonable values
                            if (_scale < 0.5) _scale = 0.5;
                            if (_scale > 5.0) _scale = 5.0;

                            // Update offset (pan)
                            final Offset delta = details.focalPoint -
                                (_startingFocalPoint ?? Offset.zero);
                            _offset = (_previousOffset ?? Offset.zero) +
                                delta / _scale;
                          });
                        },
                        child: Center(
                          child: ClipRect(
                            child: CustomPaint(
                              painter: CircuitPainter(
                                circuitData: _circuitData!,
                                scale: _scale,
                                offset: _offset,
                              ),
                              size: Size(
                                MediaQuery.of(context).size.width,
                                MediaQuery.of(context).size.height * 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.zoom_in, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _scale += 0.2;
                                if (_scale > 5.0) _scale = 5.0;
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.zoom_out, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _scale -= 0.2;
                                if (_scale < 0.5) _scale = 0.5;
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.center_focus_strong,
                                color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _scale = 1.0;
                                _offset = Offset.zero;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class CircuitPainter extends CustomPainter {
  final Map<String, dynamic> circuitData;
  final double scale;
  final Offset offset;

  CircuitPainter({
    required this.circuitData,
    this.scale = 1.0,
    this.offset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Center the circuit on the canvas
    final List<dynamic> x = circuitData['x'];
    final List<dynamic> y = circuitData['y'];

    if (x.isEmpty || y.isEmpty) return;

    // Calculate bounds to center the circuit
    double minX = x[0].toDouble();
    double maxX = x[0].toDouble();
    double minY = y[0].toDouble();
    double maxY = y[0].toDouble();

    for (int i = 0; i < x.length; i++) {
      minX = minX < x[i] ? minX : x[i].toDouble();
      maxX = maxX > x[i] ? maxX : x[i].toDouble();
      minY = minY < y[i] ? minY : y[i].toDouble();
      maxY = maxY > y[i] ? maxY : y[i].toDouble();
    }

    final trackWidth = maxX - minX;
    final trackHeight = maxY - minY;

    // Calculate scale factor to fit the circuit in the canvas
    double scaleX = size.width / trackWidth;
    double scaleY = size.height / trackHeight;
    double scaleFactor = scaleX < scaleY ? scaleX : scaleY;
    scaleFactor *= 0.9; // Margin

    // Create a path for the circuit
    final circuitPath = Path();

    // Move to the first point
    final firstX =
        ((x[0].toDouble() - minX) - trackWidth / 2) * scaleFactor * scale;
    final firstY =
        ((y[0].toDouble() - minY) - trackHeight / 2) * scaleFactor * scale;

    // Apply offset for panning
    final startX = size.width / 2 + firstX + offset.dx * scale;
    final startY = size.height / 2 + firstY + offset.dy * scale;

    circuitPath.moveTo(startX, startY);

    // Add all the other points to the path
    for (int i = 1; i < x.length; i++) {
      final pointX =
          ((x[i].toDouble() - minX) - trackWidth / 2) * scaleFactor * scale;
      final pointY =
          ((y[i].toDouble() - minY) - trackHeight / 2) * scaleFactor * scale;

      final transformedX = size.width / 2 + pointX + offset.dx * scale;
      final transformedY = size.height / 2 + pointY + offset.dy * scale;

      circuitPath.lineTo(transformedX, transformedY);
    }

    // Close the path for a complete circuit
    circuitPath.close();

    // Draw the circuit path
    final trackPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(circuitPath, trackPaint);

    // Draw corners
    if (circuitData.containsKey('corners')) {
      final cornerPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      for (var corner in circuitData['corners']) {
        double cornerX = corner['trackPosition']['x'].toDouble();
        double cornerY = corner['trackPosition']['y'].toDouble();

        final transformedX = size.width / 2 +
            ((cornerX - minX) - trackWidth / 2) * scaleFactor * scale +
            offset.dx * scale;

        final transformedY = size.height / 2 +
            ((cornerY - minY) - trackHeight / 2) * scaleFactor * scale +
            offset.dy * scale;

        canvas.drawCircle(
          Offset(transformedX, transformedY),
          6.0 * scale,
          cornerPaint,
        );

        // Draw corner numbers
        final textPainter = TextPainter(
          text: TextSpan(
            text: corner['number'].toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.0 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            transformedX - textPainter.width / 2,
            transformedY - textPainter.height / 2,
          ),
        );
      }
    }

    // Draw marshal lights
    if (circuitData.containsKey('marshalLights')) {
      final lightsPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;

      for (var light in circuitData['marshalLights']) {
        double lightX = light['trackPosition']['x'].toDouble();
        double lightY = light['trackPosition']['y'].toDouble();

        final transformedX = size.width / 2 +
            ((lightX - minX) - trackWidth / 2) * scaleFactor * scale +
            offset.dx * scale;

        final transformedY = size.height / 2 +
            ((lightY - minY) - trackHeight / 2) * scaleFactor * scale +
            offset.dy * scale;

        canvas.drawCircle(
          Offset(transformedX, transformedY),
          4.0 * scale,
          lightsPaint,
        );
      }
    }

    // Draw circuit name
    // if (circuitData.containsKey('circuitName')) {
    //   final textPainter = TextPainter(
    //     text: TextSpan(
    //       text: circuitData['circuitName'],
    //       style: TextStyle(
    //         color: Colors.white.withOpacity(0.7),
    //         fontSize: 24.0 * scale,
    //         fontWeight: FontWeight.bold,
    //       ),
    //     ),
    //     textDirection: TextDirection.ltr,
    //   );

    //   textPainter.layout();
    //   textPainter.paint(
    //     canvas,
    //     Offset(
    //       size.width / 2 - textPainter.width / 2 + offset.dx * scale,
    //       size.height / 2 - textPainter.height / 2 + offset.dy * scale,
    //     ),
    //   );
    // }
  }

  @override
  bool shouldRepaint(covariant CircuitPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.circuitData != circuitData;
  }
}
