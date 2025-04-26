import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formulavision/data/functions/race.function.dart';
import 'package:formulavision/data/functions/racedriver.function.dart';
import 'package:formulavision/data/models/openf1/meeting.model.dart';
import 'package:formulavision/data/models/openf1/racedriver.model.dart';
import 'package:formulavision/live/live_timing_service.dart';
import 'package:http/http.dart' as http;

class TestPage extends StatefulWidget {
  const TestPage({
    super.key,
  });

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  // Define a variable to hold the circuit name

  Map<String, dynamic>? _circuitData;
  bool _isLoading = true;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset? _startingFocalPoint;
  Offset? _previousOffset;
  double? _previousScale;

  late Future<String> _fetchCircuitName;

  @override
  void initState() {
    super.initState();
    fetchLatestMeetingAndSessionDetails();
    _fetchCircuitName = fetchCircuitShortNames();
    _fetchCircuitName.then((circuitName) {
      _loadCircuitData(circuitName); // Load the default circuit data
    });
    // Initialize the future once
  }

  @override
  void dispose() {
    super.dispose();
  }

  _loadCircuitData(String circuitName) async {
    // Load the circuit data from the JSON file
    String filename = getCircuitFilename(circuitName);
    String jsonString =
        await rootBundle.loadString('assets/TrackMaps/$filename.json');
    Map<String, dynamic> jsonData = json.decode(jsonString);
    setState(() {
      _circuitData = jsonData;
      _isLoading = false;
    });
  }

  String getCircuitFilename(String circuitName) {
    // Map circuit names to their corresponding JSON file names
    final Map<String, String> circuitToFilename = {
      'Silverstone': 'Silverstone',
      'Hungaroring': 'Hungaroring',
      'Imola': 'Imola',
      'Spa-Francorchamps': 'Spa-Francorchamps',
      'Austin': 'Austin',
      'Algarve International Circuit': 'Algarve',
      'Baku': 'Baku',
      'Miami': 'Miami',
      'Las Vegas': 'Las-Vegas',
      'Yas Marina Circuit': 'Yas-Marina',
      'Sakhir': 'Sakhir',
      'Sakhir Outer Track': 'Sakhir-Outer',
      'Sochi': 'Sochi',
      'Melbourne': 'Melbourne',
      'Mexico City': 'Mexico',
      'Interlagos': 'Interlagos',
      'Catalunya': 'Catalunya',
      'Spielberg': 'Spielberg',
      'Monte Carlo': 'Monte-Carlo',
      'Montreal': 'Montreal',
      'Paul Ricard': 'Paul-Riccard',
      'Hockenheim': 'Hockenheim',
      'Monza': 'Monza',
      'Suzuka': 'Suzuka',
      'Shanghai': 'Shanghai',
      'Zandvoort': 'Zandvoort',
      'Istanbul': 'Istanbul',
      'Singapore': 'Singapore',
      'Jeddah': 'Jeddah',
      'Losail': 'Losail',
      'Mugello': 'Mugello',
      'Nürburgring': 'Nurburgring',
      // Add more mappings as needed
    };

    // Return the mapped filename or a default name based on circuit name
    return circuitToFilename[circuitName] ?? circuitName.replaceAll(' ', '-');
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
            body: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: FutureBuilder(
                future:
                    fetchLatestMeetingAndSessionDetails(), // Use stored future instead of calling fetchMeeting() again
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _isLoading) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.red));
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white));
                  } else {
                    // Use the stored circuit name or snapshot data

                    final meetings = snapshot.data is List<Map<String, dynamic>>
                        ? snapshot.data as List<Map<String, dynamic>>
                        : [];
                    return Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 75,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.flag, color: Colors.white),
                              ),
                              Spacer(),
                              Column(
                                children: [
                                  Text(
                                    snapshot.data != null &&
                                            snapshot.data!.isNotEmpty
                                        ? meetings[0]['meetingName']
                                        : 'No Meeting Name',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    snapshot.data != null &&
                                            snapshot.data!.isNotEmpty
                                        ? meetings[1]['sessionName']
                                        : 'No Meeting Name',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                              Spacer(),
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
                                  _scale =
                                      (_previousScale ?? 1.0) * details.scale;
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
                                  child: _circuitData == null
                                      ? Center(
                                          child: Text(
                                              'Circuit data not available',
                                              style: TextStyle(
                                                  color: Colors.white)))
                                      : CustomPaint(
                                          painter: CircuitPainter(
                                            circuitData: _circuitData!,
                                            scale: _scale,
                                            offset: _offset,
                                          ),
                                          size: Size(
                                            MediaQuery.of(context).size.width,
                                            MediaQuery.of(context).size.height *
                                                1,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Center(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text('Pos',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(width: 25),
                                    Text('Driver',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    Spacer(),
                                    Text('Fastest Lap',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(width: 15),
                                    Text('Interval',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(width: 25),
                                    Text('Tyres',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(width: 20),
                                    Text('Pit',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                FutureBuilder<List<RaceDriverInfo>>(
                                  future: fetchRaceDriverInfo(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                          child: CircularProgressIndicator(
                                              color: Colors.red));
                                    } else if (snapshot.hasError) {
                                      return Text(
                                          'ErrorDriver: ${snapshot.error}',
                                          style:
                                              TextStyle(color: Colors.white));
                                    } else if (!snapshot.hasData ||
                                        snapshot.data!.isEmpty) {
                                      return Text('No driver data available',
                                          style:
                                              TextStyle(color: Colors.white));
                                    } else {
                                      final drivers = snapshot.data!;
                                      print(drivers.length);
                                      return ListView.builder(
                                        itemCount: drivers.length,
                                        itemBuilder: (context, index) {
                                          final driverInfo = drivers[index];
                                          return DriverListTile(
                                              driverInfo: driverInfo);
                                        },
                                      );
                                    }
                                  },
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Container(
                                  width: double.infinity,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Color.fromRGBO(115, 115, 115, 0.69),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text('1',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 25,
                                                  fontWeight: FontWeight.w900)),
                                          SizedBox(width: 20),
                                          Container(
                                            width: 5,
                                            height: 25,
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          SizedBox(width: 5),
                                          Text('HAM',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                              )),
                                          Spacer(),
                                          Text('1:31.052',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 15,
                                              )),
                                          SizedBox(width: 5),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Container(
                                              width: 70,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(40),
                                              ),
                                              child: Center(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(4.0),
                                                  child: Text('+0.452',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      )),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          SvgPicture.asset(
                                            'assets/tyres/Hard.svg',
                                            width: 30,
                                            height: 30,
                                            placeholderBuilder: (context) =>
                                                CircularProgressIndicator(),
                                          ),
                                          SizedBox(width: 15),
                                          Text('1',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 25,
                                                  fontWeight: FontWeight.w900)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            )),
      ),
    );
  }
}

class LiveTimingDataWidget extends StatelessWidget {
  final Map<String, dynamic> timingData;
  final Map<String, dynamic>? positionData;

  const LiveTimingDataWidget({
    Key? key,
    required this.timingData,
    this.positionData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Timing Data',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'formula-bold',
            ),
          ),
          Divider(color: Colors.red),
          Expanded(
            child: timingData.isEmpty
                ? Center(
                    child: Text('No data available',
                        style: TextStyle(color: Colors.white60)))
                : ListView(
                    children: _buildTimingDataWidgets(),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimingDataWidgets() {
    List<Widget> widgets = [];

    try {
      // Extract and format the relevant timing data based on the actual structure
      // This will need to be adjusted based on the actual structure of the F1 LiveTiming data

      widgets.add(ListTile(
        title: Text('Session Status', style: TextStyle(color: Colors.white70)),
        subtitle: Text(
          timingData['SessionStatus']?.toString() ?? 'Unknown',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ));

      // Process driver timing data if available
      if (timingData.containsKey('Lines')) {
        final driverData = timingData['Lines'] as Map<String, dynamic>? ?? {};

        driverData.forEach((driverId, data) {
          widgets.add(Card(
            color: Colors.black54,
            child: ListTile(
              title: Text(
                'Driver: ${data['RacingNumber'] ?? driverId}',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Position: ${data['Position'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Last Lap: ${data['LastLapTime']?.toString() ?? 'N/A'}',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Gap: ${data['GapToLeader'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ));
        });
      }
    } catch (e) {
      widgets.add(ListTile(
        title: Text('Error parsing data', style: TextStyle(color: Colors.red)),
        subtitle: Text(e.toString(), style: TextStyle(color: Colors.white70)),
      ));
    }

    return widgets;
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

// Custom DriverListTile widget
class DriverListTile extends StatelessWidget {
  final RaceDriverInfo driverInfo;

  const DriverListTile({Key? key, required this.driverInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Color.fromRGBO(115, 115, 115, 0.69),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Position
            Text(driverInfo.getCurrentPosition().toString(),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900)),
            SizedBox(width: 20),

            // Team color bar
            Container(
              width: 5,
              height: 25,
              decoration: BoxDecoration(
                color: driverInfo.getTeamColor(),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(width: 5),

            // Driver acronym
            Text(driverInfo.getDriverShortName(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                )),
            Spacer(),

            // Fastest lap
            Text(driverInfo.getFastestLapFormatted(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                )),
            SizedBox(width: 5),

            // Interval
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 70,
                height: 30,
                decoration: BoxDecoration(
                  color: driverInfo.isRaceLeader() ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(driverInfo.getIntervalFormatted(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        )),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),

            // Tyre compound
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: driverInfo.getCurrentTyreColor(),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  driverInfo.getCurrentTyreCompound(),
                  style: TextStyle(
                    color: driverInfo.getCurrentTyreCompound() == 'H'
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 15),

            // Pit stops
            Text(driverInfo.getPitStopCount().toString(),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
