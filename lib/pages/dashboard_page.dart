import 'dart:convert';
import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formulavision/components/driver_tile.dart';
import 'package:formulavision/components/weather_info_card.dart';
import 'package:formulavision/data/functions/cardata.function.dart';
import 'package:formulavision/data/functions/live_data.function.dart';
import 'package:formulavision/data/models/live_data.model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

// Helper class to queue messages with timestamps
class _DelayedMessage {
  final dynamic data;
  final DateTime receivedAt;

  _DelayedMessage(this.data, this.receivedAt);
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live',
      theme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const TelemetryPage(),
    );
  }
}

class TelemetryPage extends StatefulWidget {
  const TelemetryPage({super.key});

  @override
  State<TelemetryPage> createState() => _TelemetryPageState();
}

class _TelemetryPageState extends State<TelemetryPage> {
  WebSocketChannel? _channel;
  StreamSubscription? _sseSubscription;
  Map<String, dynamic> _telemetryData = {};
  Future<List<SessionInfo>>? _sessionInfoFuture;
  Future<List<WeatherData>>? _weatherDataFuture;
  Future<List<LiveData>>? _liveDataFuture;
  bool _isConnected = false;
  String _connectionStatus = "Disconnected";
  String _errorMessage = "";
  int _messageCount = 0;
  bool _useSimulation = false;
  bool _useSSE = true; // Add flag to use SSE instead of WebSockets

  // Delay-related variables
  int _delaySeconds = 0; // User-defined delay in seconds
  final Queue<_DelayedMessage> _messageQueue = Queue<_DelayedMessage>();
  Timer? _delayTimer;
  bool _delayEnabled = false;

  final _liveDataController = StreamController<List<LiveData>>.broadcast();
  Stream<List<LiveData>> get liveDataStream => _liveDataController.stream;

  @override
  void initState() {
    super.initState();
    _initialize();
    final data = decompressCarData();
    print(data);
  }

  Future<void> _initialize() async {
    await fetchInitialData();
    // Only connect to SSE if initial data was fetched successfully
    // and we are not already connected.
    if (_connectionStatus == "Initial data loaded" && !_isConnected) {
      await _connectSSE();
    }
  }

  @override
  void dispose() {
    if (_sseSubscription != null) {
      _sseSubscription!.cancel();
      _sseSubscription = null;
    }
    _delayTimer?.cancel(); // Clean up delay timer
    _messageQueue.clear(); // Clear any queued messages
    _liveDataController.close(); // Close the StreamController
    super.dispose();
  }

  Future<void> fetchInitialData() async {
    setState(() {
      _connectionStatus = "Fetching initial data...";
      _errorMessage = "";
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/initialData'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Initial: $data');
        // Check if data contains SessionInfo
        setState(() {
          _liveDataFuture = fetchLiveData(data['R']);
        });

        setState(() {
          _connectionStatus = "Initial data loaded";
        });
      } else {
        setState(() {
          _connectionStatus = "Failed to fetch initial data";
          _errorMessage = "HTTP Status: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = "Error fetching initial data";
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _connectToServer() async {
    setState(() {
      _connectionStatus = " ...";
      _errorMessage = "";
    });

    try {
      // Negotiate connection with simulation parameter
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['API_URL']}/negotiate?simulation=${_useSimulation}'),
      );

      if (response.statusCode == 200) {
        // Connect to either WebSocket or SSE based on _useSSE flag
        await _connectSSE();
      } else {
        setState(() {
          _connectionStatus = "Failed to connect";
          _errorMessage = "HTTP Status: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = "Connection error";
        _errorMessage = e.toString();
      });
    }
  }

  // Custom SSE client implementation
  Future<void> _connectSSE() async {
    try {
      final sseUrl =
          '${dotenv.env['API_URL']}/events${_useSimulation ? '?simulation=true' : ''}';
      print('Connecting to SSE endpoint: $sseUrl');

      // Create a client that doesn't automatically close the connection
      final client = http.Client();
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      // Connect to the SSE endpoint with appropriate headers
      final request = http.Request('GET', Uri.parse(sseUrl));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.headers['Content-Type'] = 'application/json; charset=UTF-8';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // final response = await http.get(
      //   Uri.parse('${dotenv.env['API_URL']}/initialData'),
      //   headers: <String, String>{
      //     'Content-Type': 'application/json; charset=UTF-8',
      //     'Authorization': 'Bearer $token',
      //   },
      // );

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        throw Exception(
            'Failed to connect to SSE endpoint: ${streamedResponse.statusCode}');
      }

      setState(() {
        _isConnected = true;
        _connectionStatus = _useSimulation ? "Connected (Sim)" : "Connected";
      });

      // Start delay timer if delay is enabled
      if (_delayEnabled && _delaySeconds > 0) {
        _startDelayTimer();
      }

      // Process the stream of events
      _sseSubscription = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          // SSE format: lines starting with "data:" contain the payload
          if (line.startsWith('data: ')) {
            _messageCount++;
            try {
              final jsonData = line.substring(6); // Remove 'data: ' prefix
              print('Received SSE message: $jsonData');
              final data = jsonDecode(jsonData);
              _processTelemetryData(data);
            } catch (e) {
              print("Error processing SSE message: $e");
              setState(() {}); // Just update the message count
            }
          }
        },
        onError: (error) {
          print('SSE stream error: $error');
          if (mounted) {
            setState(() {
              _isConnected = false;
              _connectionStatus = "SSE connection error";
              _errorMessage = error.toString();
            });
          }
          client.close();
        },
        onDone: () {
          print('SSE connection closed');
          setState(() {
            _isConnected = false;
            _connectionStatus = "SSE disconnected";
          });
          client.close();
        },
      );
    } catch (e) {
      print('Error connecting to SSE: $e');
      setState(() {
        _isConnected = false;
        _connectionStatus = "SSE connection error";
        _errorMessage = e.toString();
      });
    }
  }

  void _disconnectFromServer() {
    if (_sseSubscription != null) {
      _sseSubscription!.cancel();
      _sseSubscription = null;
    }

    if (mounted) {
      setState(() {
        _isConnected = false;
        _connectionStatus = "Disconnected";
      });
    }
  }

  // Method to toggle delay on/off
  void _toggleDelay() {
    setState(() {
      _delayEnabled = !_delayEnabled;
      if (!_delayEnabled) {
        // Process all queued messages immediately when disabled
        _processQueuedMessages();
        _delayTimer?.cancel();
      } else if (_delaySeconds > 0) {
        _startDelayTimer();
      }
    });
  }

  // Method to update delay value
  void _updateDelay(int seconds) {
    setState(() {
      _delaySeconds = seconds;
      if (_delayEnabled && seconds > 0) {
        _startDelayTimer();
      } else if (seconds == 0) {
        _processQueuedMessages();
        _delayTimer?.cancel();
      }
    });
  }

  // Start the delay timer
  void _startDelayTimer() {
    _delayTimer?.cancel();
    _delayTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _processQueuedMessages();
    });
  }

  // Process messages that have waited long enough
  void _processQueuedMessages() {
    final now = DateTime.now();
    while (_messageQueue.isNotEmpty) {
      final message = _messageQueue.first;
      final waitTime = now.difference(message.receivedAt).inSeconds;

      if (waitTime >= _delaySeconds) {
        _messageQueue.removeFirst();
        _processTelemetryDataImmediate(message.data);
      } else {
        break; // Stop processing if this message isn't ready yet
      }
    }
  }

  // Add message to delay queue or process immediately
  void _processTelemetryData(dynamic data) {
    if (_delayEnabled && _delaySeconds > 0) {
      _messageQueue.add(_DelayedMessage(data, DateTime.now()));
    } else {
      _processTelemetryDataImmediate(data);
    }
  }

  // Original processing method renamed
  void _processTelemetryDataImmediate(dynamic data) {
    // Handle empty data case
    print('Processing telemetry data: ${data.runtimeType}');
    print('Data keys: ${data.keys.toList()}');
    if (data is Map) {
      // SignalR connection init message (has "C" key)
      if (data.containsKey('C')) {
        print('Received Partial Update Message with ID: ${data['C']}');
        // This is just a connection message, not actual data
        setState(() {});
      }

      // Handle different types of messages
      if (data.containsKey('M') && data['M'] is List) {
        final messageArray = data['M'];
        print('Processing ${messageArray.length} messages in update');

        // Process each message in the array
        for (var messageObject in messageArray) {
          if (messageObject is Map &&
              messageObject.containsKey('A') &&
              messageObject['A'] is List &&
              messageObject['A'].isNotEmpty) {
            final messageType = messageObject['A'][0];

            if (messageObject['A'].length > 1) {
              final updated = messageObject['A'][1];
              final timestamp =
                  messageObject['A'].length > 2 ? messageObject['A'][2] : null;

              print(
                  'Processing $messageType update with timestamp: $timestamp');

              // Handle each message type appropriately
              switch (messageType) {
                case 'ExtrapolatedClock':
                  setState(() {
                    _updateExtrapolatedClock(updated);
                  });
                  print('ExtrapolatedClock Updated Successfully');
                  break;

                case 'WeatherData':
                  setState(() {
                    _updateWeatherData(updated);
                  });
                  print('WeatherData Updated Successfully');
                  break;

                case 'SessionInfo':
                  setState(() {
                    _updateSessionInfo(updated);
                  });
                  print('SessionInfo Updated Successfully');
                  break;

                case 'TimingData':
                  setState(() {
                    _updateTimingData(updated);
                  });
                  print('TimingData Updated Successfully');
                  break;

                // case 'TimingAppData':
                //   setState(() {
                //     _updateTimingAppData(updated);
                //   });
                //   print('TimingAppData Updated Successfully');
                //   break;

                case 'DriverList':
                  setState(() {
                    _updateDriverList(updated);
                  });
                  print('DriverList Updated Successfully');
                  break;

                case 'TrackStatus':
                  setState(() {
                    _updateTrackStatus(updated);
                  });
                  print('TrackStatus Updated Successfully');
                  break;

                default:
                  print('No handler for message type: $messageType');
              }
            } else {
              print('Message "$messageType" has no data payload');
            }
          } else {
            print('Message does not contain valid "A" array structure');
          }
        }
      }
    }
    // After processing all updates in a batch
    if (_liveDataController != null && !_liveDataController.isClosed) {
      _liveDataFuture!.then((liveDataList) {
        _liveDataController.add(liveDataList);
      });
    }
  }

  void _updateExtrapolatedClock(dynamic data) {
    if (data is Map<String, dynamic>) {
      print('Updating extrapolated clock with: ${data.keys.toList()}');
      if (data.isEmpty) {
        print('Received empty extrapolated clock data, skipping update');
        return;
      }

      setState(() {
        if (_liveDataFuture != null) {
          _liveDataFuture = _liveDataFuture!.then((liveDataList) {
            if (liveDataList.isNotEmpty) {
              final currentLiveData = liveDataList[0];

              // Create a new ExtrapolatedClock with updated values
              ExtrapolatedClock updatedExtrapolatedClock = ExtrapolatedClock(
                utc: data.containsKey('Utc')
                    ? data['Utc']
                    : currentLiveData.extrapolatedClock!.utc,
                remaining: data.containsKey('Remaining')
                    ? data['Remaining']
                    : currentLiveData.extrapolatedClock!.remaining,
                extrapolating: data.containsKey('Extrapolating')
                    ? data['Extrapolating']
                    : currentLiveData.extrapolatedClock!.extrapolating,
              );

              // Update the extrapolated clock in the current live data object
              currentLiveData.extrapolatedClock = updatedExtrapolatedClock;

              return liveDataList;
            }
            return liveDataList;
          });
        }
      });
    } else {
      print(
          'Received non-map extrapolated clock data: ${data.runtimeType}, cannot update');
    }
  }

  void _updateTrackStatus(dynamic data) {
    if (data is Map<String, dynamic>) {
      print('Updating track status with: ${data.keys.toList()}');
      if (data.isEmpty) {
        print('Received empty track status data, skipping update');
        return;
      }

      setState(() {
        if (_liveDataFuture != null) {
          _liveDataFuture = _liveDataFuture!.then((liveDataList) {
            if (liveDataList.isNotEmpty) {
              final currentLiveData = liveDataList[0];

              // Create a new TrackStatus with updated values
              TrackStatus updatedTrackStatus = TrackStatus(
                status: data.containsKey('Status')
                    ? data['Status']
                    : currentLiveData.trackStatus!.status,
                message: data.containsKey('Message')
                    ? data['Message']
                    : currentLiveData.trackStatus!.message,
              );

              // Update the track status in the current live data object
              currentLiveData.trackStatus = updatedTrackStatus;

              return liveDataList;
            }
            return liveDataList;
          });
        }
      });
    } else {
      print(
          'Received non-map track status data: ${data.runtimeType}, cannot update');
    }
  }

  void _updateDriverList(dynamic data) {
    if (data is Map<String, dynamic>) {
      print('Updating driver list with: ${data.keys.toList()}');
      if (data.isEmpty) {
        print('Received empty driver list data, skipping update');
        return;
      }

      setState(() {
        _liveDataFuture = _liveDataFuture!.then((liveDataList) {
          final currentLiveData = liveDataList[0];
          Map<String, Driver> currentDrivers =
              currentLiveData.driverList?.drivers ?? {};

          // Remove '_kf' from keys to process since it's a special field
          final driverKeys = data.keys.where((key) => key != '_kf').toList();

          // Update each driver in the list
          for (var racingNumber in driverKeys) {
            final driverData = data[racingNumber] ?? {};
            final prev = currentDrivers[racingNumber];

            Driver updatedDriver = Driver(
              racingNumber: driverData['RacingNumber'] ??
                  driverData['racingNumber'] ??
                  prev?.racingNumber ??
                  racingNumber,
              broadcastName: driverData['BroadcastName'] ??
                  driverData['broadcastName'] ??
                  prev?.broadcastName ??
                  '',
              fullName: driverData['FullName'] ??
                  driverData['fullName'] ??
                  prev?.fullName ??
                  '',
              countryCode: driverData['CountryCode'] ??
                  driverData['countryCode'] ??
                  prev?.countryCode ??
                  '',
              tla: driverData['Tla'] ??
                  driverData['tla'] ??
                  driverData['TLA'] ??
                  prev?.tla ??
                  '',
              line: driverData['Line'] ?? driverData['line'] ?? prev?.line ?? 0,
              teamName: driverData['TeamName'] ??
                  driverData['teamName'] ??
                  prev?.teamName ??
                  '',
              teamColour: driverData['TeamColour'] ??
                  driverData['teamColour'] ??
                  driverData['team_color'] ??
                  prev?.teamColour ??
                  '',
              firstName: driverData['FirstName'] ??
                  driverData['firstName'] ??
                  prev?.firstName ??
                  '',
              lastName: driverData['LastName'] ??
                  driverData['lastName'] ??
                  prev?.lastName ??
                  '',
              reference: driverData['Reference'] ??
                  driverData['reference'] ??
                  prev?.reference ??
                  '',
              headshotUrl: driverData['HeadshotUrl'] ??
                  driverData['headshotUrl'] ??
                  prev?.headshotUrl ??
                  '',
            );

            currentDrivers[racingNumber] = updatedDriver;
          }

          // Create a new DriverList
          DriverList updatedDriverList = DriverList(
            drivers: currentDrivers,
          );

          // Update the driver list in the current live data object
          currentLiveData.driverList = updatedDriverList;

          return liveDataList;
        });
      });
    } else {
      print(
          'Received non-map driver list data: ${data.runtimeType}, cannot update');
    }
  }

  void _updateTimingData(dynamic data) {
    if (data is Map<String, dynamic>) {
      print('Updating timing data with: ${data.keys.toList()}');
      if (data.isEmpty) {
        print('Received empty timing data, skipping update');
        return;
      }

      setState(() {
        if (_liveDataFuture != null) {
          _liveDataFuture = _liveDataFuture!.then((liveDataList) {
            if (liveDataList.isNotEmpty) {
              final currentLiveData = liveDataList[0];

              // Check if we have the Lines property which contains driver timing data
              if (data.containsKey('Lines') &&
                  data['Lines'] is Map<String, dynamic>) {
                // Get the current timing data lines
                Map<String, TimingDataDriver> currentLines =
                    currentLiveData.timingData?.lines ?? {};

                // Process each driver's timing data
                final linesData = data['Lines'] as Map<String, dynamic>;
                linesData.forEach((racingNumber, driverData) {
                  if (driverData is Map<String, dynamic>) {
                    // Create or update the driver's timing data
                    final currentDriverData = currentLines[racingNumber];

                    // Process sectors if available
                    List<Sector> updatedSectors = [];
                    if (driverData.containsKey('Sectors') &&
                        driverData['Sectors'] is List) {
                      final sectorsData = driverData['Sectors'] as List;
                      for (int i = 0; i < sectorsData.length; i++) {
                        final sectorData = sectorsData[i];
                        if (sectorData is Map<String, dynamic>) {
                          // Create updated sector with segments if available
                          List<Segment> updatedSegments = [];
                          if (sectorData.containsKey('Segments') &&
                              sectorData['Segments'] is List) {
                            final segmentsData = sectorData['Segments'] as List;
                            for (var segmentData in segmentsData) {
                              if (segmentData is Map<String, dynamic>) {
                                updatedSegments.add(Segment(
                                  status: segmentData['Status'] ?? 0,
                                ));
                              }
                            }
                          }

                          updatedSectors.add(Sector(
                            stopped: sectorData['Stopped'] ?? false,
                            value: sectorData['Value'] ?? '',
                            status: sectorData['Status'] ?? 0,
                            overallFastest:
                                sectorData['OverallFastest'] ?? false,
                            personalFastest:
                                sectorData['PersonalFastest'] ?? false,
                            previousValue: sectorData['PreviousValue'] ?? '',
                            segments: updatedSegments,
                          ));
                        }
                      }
                    } else if (currentDriverData != null) {
                      // Keep existing sectors if new data doesn't have them
                      updatedSectors = currentDriverData.sectors;
                    }

                    // Process speeds if available
                    Speeds updatedSpeeds;
                    if (driverData.containsKey('Speeds') &&
                        driverData['Speeds'] is Map) {
                      final speedsData =
                          driverData['Speeds'] as Map<String, dynamic>;

                      // Create individual speed components
                      I1 i1 = I1(
                          value: '',
                          status: 0,
                          overallFastest: false,
                          personalFastest: false);
                      I1 i2 = I1(
                          value: '',
                          status: 0,
                          overallFastest: false,
                          personalFastest: false);
                      I1 fl = I1(
                          value: '',
                          status: 0,
                          overallFastest: false,
                          personalFastest: false);
                      I1 st = I1(
                          value: '',
                          status: 0,
                          overallFastest: false,
                          personalFastest: false);

                      // Update I1 speed if available
                      if (speedsData.containsKey('I1') &&
                          speedsData['I1'] is Map) {
                        final i1Data = speedsData['I1'] as Map<String, dynamic>;
                        i1 = I1(
                          value: i1Data['Value'] ?? '',
                          status: i1Data['Status'] ?? 0,
                          overallFastest: i1Data['OverallFastest'] ?? false,
                          personalFastest: i1Data['PersonalFastest'] ?? false,
                        );
                      } else if (currentDriverData?.speeds?.i1 != null) {
                        i1 = currentDriverData!.speeds!.i1;
                      }

                      // Update I2 speed if available
                      if (speedsData.containsKey('I2') &&
                          speedsData['I2'] is Map) {
                        final i2Data = speedsData['I2'] as Map<String, dynamic>;
                        i2 = I1(
                          value: i2Data['Value'] ?? '',
                          status: i2Data['Status'] ?? 0,
                          overallFastest: i2Data['OverallFastest'] ?? false,
                          personalFastest: i2Data['PersonalFastest'] ?? false,
                        );
                      } else if (currentDriverData?.speeds?.i2 != null) {
                        i2 = currentDriverData!.speeds!.i2;
                      }

                      // Update FL speed if available
                      if (speedsData.containsKey('FL') &&
                          speedsData['FL'] is Map) {
                        final flData = speedsData['FL'] as Map<String, dynamic>;
                        fl = I1(
                          value: flData['Value'] ?? '',
                          status: flData['Status'] ?? 0,
                          overallFastest: flData['OverallFastest'] ?? false,
                          personalFastest: flData['PersonalFastest'] ?? false,
                        );
                      } else if (currentDriverData?.speeds?.fl != null) {
                        fl = currentDriverData!.speeds!.fl;
                      }

                      // Update ST speed if available
                      if (speedsData.containsKey('ST') &&
                          speedsData['ST'] is Map) {
                        final stData = speedsData['ST'] as Map<String, dynamic>;
                        st = I1(
                          value: stData['Value'] ?? '',
                          status: stData['Status'] ?? 0,
                          overallFastest: stData['OverallFastest'] ?? false,
                          personalFastest: stData['PersonalFastest'] ?? false,
                        );
                      } else if (currentDriverData?.speeds?.st != null) {
                        st = currentDriverData!.speeds!.st;
                      }

                      updatedSpeeds = Speeds(i1: i1, i2: i2, fl: fl, st: st);
                    } else if (currentDriverData?.speeds != null) {
                      updatedSpeeds = currentDriverData!.speeds!;
                    } else {
                      // Create empty speeds if no data available
                      updatedSpeeds = Speeds(
                        i1: I1(
                            value: '',
                            status: 0,
                            overallFastest: false,
                            personalFastest: false),
                        i2: I1(
                            value: '',
                            status: 0,
                            overallFastest: false,
                            personalFastest: false),
                        fl: I1(
                            value: '',
                            status: 0,
                            overallFastest: false,
                            personalFastest: false),
                        st: I1(
                            value: '',
                            status: 0,
                            overallFastest: false,
                            personalFastest: false),
                      );
                    }

                    // Process IntervalToPositionAhead if available
                    IntervalToPositionAhead? updatedInterval;
                    if (driverData.containsKey('IntervalToPositionAhead') &&
                        driverData['IntervalToPositionAhead']
                            is Map<String, dynamic>) {
                      final intervalData = driverData['IntervalToPositionAhead']
                          as Map<String, dynamic>;
                      updatedInterval = IntervalToPositionAhead(
                        value: intervalData['Value'] ?? '',
                        catching: intervalData['Catching'] ?? false,
                      );
                    } else if (currentDriverData?.intervalToPositionAhead !=
                        null) {
                      updatedInterval =
                          currentDriverData!.intervalToPositionAhead;
                    }

                    // Process BestLapTime if available
                    PersonalBestLapTime updatedBestLap;
                    if (driverData.containsKey('BestLapTime') &&
                        driverData['BestLapTime'] is Map) {
                      final bestLapData =
                          driverData['BestLapTime'] as Map<String, dynamic>;
                      updatedBestLap = PersonalBestLapTime(
                        value: bestLapData['Value'] ?? '',
                        lap: bestLapData['Lap'] ?? 0,
                      );
                    } else if (currentDriverData?.bestLapTime != null) {
                      updatedBestLap = currentDriverData!.bestLapTime;
                    } else {
                      updatedBestLap = PersonalBestLapTime(value: '', lap: 0);
                    }

                    // Process LastLapTime if available
                    I1 updatedLastLap;
                    if (driverData.containsKey('LastLapTime') &&
                        driverData['LastLapTime'] is Map) {
                      final lastLapData =
                          driverData['LastLapTime'] as Map<String, dynamic>;
                      updatedLastLap = I1(
                        value: lastLapData['Value'] ?? '-:--.---',
                        status: lastLapData['Status'] ?? 0,
                        overallFastest: lastLapData['OverallFastest'] ?? false,
                        personalFastest:
                            lastLapData['PersonalFastest'] ?? false,
                      );
                    } else if (currentDriverData?.lastLapTime != null) {
                      updatedLastLap = currentDriverData!.lastLapTime;
                    } else {
                      updatedLastLap = I1(
                        value: '-:--.---',
                        status: 0,
                        overallFastest: false,
                        personalFastest: false,
                      );
                    }

                    // Create the updated TimingDataDriver object
                    TimingDataDriver updatedDriver = TimingDataDriver(
                      gapToLeader: driverData['GapToLeader'] ??
                          (currentDriverData?.gapToLeader ?? ''),
                      intervalToPositionAhead: updatedInterval,
                      line:
                          driverData['Line'] ?? (currentDriverData?.line ?? 0),
                      position: driverData['Position'] ??
                          (currentDriverData?.position ?? ''),
                      showPosition: driverData['ShowPosition'] ??
                          (currentDriverData?.showPosition ?? true),
                      racingNumber: driverData['RacingNumber'] ??
                          (currentDriverData?.racingNumber ?? ''),
                      retired: driverData['Retired'] ??
                          (currentDriverData?.retired ?? false),
                      inPit: driverData['InPit'] ??
                          (currentDriverData?.inPit ?? false),
                      pitOut: driverData['PitOut'] ??
                          (currentDriverData?.pitOut ?? false),
                      stopped: driverData['Stopped'] ??
                          (currentDriverData?.stopped ?? false),
                      status: driverData['Status'] ??
                          (currentDriverData?.status ?? 0),
                      sectors: updatedSectors,
                      speeds: updatedSpeeds,
                      bestLapTime: updatedBestLap,
                      lastLapTime: updatedLastLap,
                      numberOfLaps: driverData['NumberOfLaps'] ??
                          (currentDriverData?.numberOfLaps ?? 0),
                      numberOfPitStops: driverData['NumberOfPitStops'] ??
                          (currentDriverData?.numberOfPitStops ?? 0),
                    );

                    // Update the driver in our map
                    currentLines[racingNumber] = updatedDriver;
                  }
                });

                // Create updated TimingData object
                TimingData updatedTimingData = TimingData(
                  lines: currentLines,
                  withheld: data['Withheld'] ?? false,
                );

                // Update the timing data in the live data object
                currentLiveData.timingData = updatedTimingData;
              }

              return liveDataList;
            }
            return liveDataList;
          }).then((liveDataList) {
            if (liveDataList.isEmpty) {
              throw Exception("Live data list is empty");
            }
            return liveDataList;
            // _liveDataController.add(liveDataList);
          });
        }
      });
    } else {
      print('Received non-map timing data: ${data.runtimeType}, cannot update');
    }
  }

  void _updateWeatherData(dynamic data) {
    if (data is Map<String, dynamic>) {
      print('Updating weather data with: ${data.keys.toList()}');
      if (data.isEmpty) {
        print('Received empty weather data, skipping update');
        return;
      }

      setState(() {
        if (_liveDataFuture != null) {
          _liveDataFuture = _liveDataFuture!.then((liveDataList) {
            if (liveDataList.isNotEmpty) {
              final currentLiveData = liveDataList[0];

              // Create a new WeatherData with updated values
              WeatherData updatedWeatherData = WeatherData(
                airTemp: data.containsKey('AirTemp')
                    ? data['AirTemp']
                    : currentLiveData.weatherData!.airTemp,
                humidity: data.containsKey('Humidity')
                    ? data['Humidity']
                    : currentLiveData.weatherData!.humidity,
                pressure: data.containsKey('Pressure')
                    ? data['Pressure']
                    : currentLiveData.weatherData!.pressure,
                rainfall: data.containsKey('Rainfall')
                    ? data['Rainfall']
                    : currentLiveData.weatherData!.rainfall,
                trackTemp: data.containsKey('TrackTemp')
                    ? data['TrackTemp']
                    : currentLiveData.weatherData!.trackTemp,
                windDirection: data.containsKey('WindDirection')
                    ? data['WindDirection']
                    : currentLiveData.weatherData!.windDirection,
                windSpeed: data.containsKey('WindSpeed')
                    ? data['WindSpeed']
                    : currentLiveData.weatherData!.windSpeed,
              );

              // Update the weather data in the current live data object
              currentLiveData.weatherData = updatedWeatherData;

              return liveDataList;
            }
            return liveDataList;
          });
        }
      });
    } else {
      print(
          'Received non-map weather data: ${data.runtimeType}, cannot update');
    }
  }

  void _updateSessionInfo(dynamic data) {
    if (data is Map<String, dynamic>) {
      print('Updating session info with: ${data.keys.toList()}');
      if (data.isEmpty) {
        print('Received empty session info data, skipping update');
        return;
      }

      setState(() {
        if (_liveDataFuture != null) {
          _liveDataFuture = _liveDataFuture!.then((liveDataList) {
            if (liveDataList.isNotEmpty) {
              final currentLiveData = liveDataList[0];
              final currentSession = currentLiveData.sessionInfo!;

              // Update Meeting information
              Meeting updatedMeeting = Meeting(
                key: data.containsKey('Meeting') &&
                        data['Meeting'].containsKey('Key')
                    ? data['Meeting']['Key']
                    : currentSession.meeting.key,
                name: data.containsKey('Meeting') &&
                        data['Meeting'].containsKey('Name')
                    ? data['Meeting']['Name']
                    : currentSession.meeting.name,
                officialName: data.containsKey('Meeting') &&
                        data['Meeting'].containsKey('OfficialName')
                    ? data['Meeting']['OfficialName']
                    : currentSession.meeting.officialName,
                location: data.containsKey('Meeting') &&
                        data['Meeting'].containsKey('Location')
                    ? data['Meeting']['Location']
                    : currentSession.meeting.location,
                // Update Country and Circuit if they exist in the data
                country: data.containsKey('Meeting') &&
                        data['Meeting'].containsKey('Country')
                    ? Country(
                        key: data['Meeting']['Country']['Key'] ??
                            currentSession.meeting.country?.key,
                        code: data['Meeting']['Country']['Code'] ??
                            currentSession.meeting.country?.code,
                        name: data['Meeting']['Country']['Name'] ??
                            currentSession.meeting.country?.name,
                      )
                    : currentSession.meeting.country,
                circuit: data.containsKey('Meeting') &&
                        data['Meeting'].containsKey('Circuit')
                    ? Circuit(
                        key: data['Meeting']['Circuit']['Key'] ??
                            currentSession.meeting.circuit?.key,
                        shortName: data['Meeting']['Circuit']['ShortName'] ??
                            currentSession.meeting.circuit?.shortName,
                      )
                    : currentSession.meeting.circuit,
              );

              // Update Archive Status
              ArchiveStatus updatedArchiveStatus = ArchiveStatus(
                status: data.containsKey('ArchiveStatus') &&
                        data['ArchiveStatus'].containsKey('Status')
                    ? data['ArchiveStatus']['Status']
                    : currentSession.archiveStatus.status,
              );

              // Create updated SessionInfo
              SessionInfo updatedSessionInfo = SessionInfo(
                meeting: updatedMeeting,
                archiveStatus: updatedArchiveStatus,
                key: data.containsKey('Key') ? data['Key'] : currentSession.key,
                type: data.containsKey('Type')
                    ? data['Type']
                    : currentSession.type,
                name: data.containsKey('Name')
                    ? data['Name']
                    : currentSession.name,
                startDate: data.containsKey('StartDate')
                    ? data['StartDate']
                    : currentSession.startDate,
                endDate: data.containsKey('EndDate')
                    ? data['EndDate']
                    : currentSession.endDate,
                gmtOffset: data.containsKey('GmtOffset')
                    ? data['GmtOffset']
                    : currentSession.gmtOffset,
                path: data.containsKey('Path')
                    ? data['Path']
                    : currentSession.path,
                kf: data.containsKey('_kf') ? data['_kf'] : currentSession.kf,
              );

              // Update the session info in the current live data object
              currentLiveData.sessionInfo = updatedSessionInfo;

              return liveDataList;
            }
            return liveDataList;
          });
        }
      });
    } else {
      print(
          'Received non-map session info: ${data.runtimeType}, cannot update');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Dashboard'),
        backgroundColor: Colors.red,
        actions: [
          Chip(
            label: Text(_connectionStatus),
            backgroundColor: _isConnected
                ? (_useSimulation ? Colors.amber : Colors.green)
                : Colors.red[300],
            labelStyle: const TextStyle(color: Colors.black),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection status and controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Delay toggle button
                ElevatedButton.icon(
                  icon: Icon(
                    _delayEnabled ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  label: Text(_delayEnabled ? 'Delay ON' : 'Delay OFF'),
                  onPressed: _toggleDelay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _delayEnabled ? Colors.orange : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                // Delay controls with +/- buttons and text input
                if (_delayEnabled) ...[
                  Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Decrease button
                          IconButton(
                            onPressed: _delaySeconds > 0
                                ? () => _updateDelay(_delaySeconds - 5)
                                : null,
                            icon: const Icon(Icons.remove),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.orange.withOpacity(0.2),
                              foregroundColor: Colors.orange,
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Text input field
                          Container(
                            width: 60,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: TextField(
                                controller: TextEditingController(
                                    text: _delaySeconds.toString()),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (value) {
                                  final newDelay =
                                      int.tryParse(value) ?? _delaySeconds;
                                  _updateDelay(
                                      newDelay.clamp(0, 300)); // Max 5 minutes
                                },
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),
                          // Increase button
                          IconButton(
                            onPressed: _delaySeconds < 300
                                ? () => _updateDelay(_delaySeconds + 5)
                                : null,
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.orange.withOpacity(0.2),
                              foregroundColor: Colors.orange,
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Preset buttons
                    ],
                  ),
                ],
              ],
            ),

            // if (_errorMessage.isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.only(top: 8.0),
            //     child: Text(
            //       'Error: $_errorMessage',
            //       style: const TextStyle(color: Colors.red),
            //     ),
            //   ),

            const SizedBox(height: 10),

            // Messages received counter and delay info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages received: $_messageCount',
                  style: const TextStyle(
                      fontSize: 14, fontStyle: FontStyle.italic),
                ),
                if (_delayEnabled) ...[
                  Text(
                    'Queued messages: ${_messageQueue.length}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.orange),
                  ),
                  Text(
                    'Delay: ${_delaySeconds}s',
                    style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.orange),
                  ),
                ],
              ],
            ),
            // Text(
            //   'Note: Currently the data displayed is updated but it is unstable. (Live Data Fetching is only available on my local machine, the NodeJS API will be made public soon [stable])',
            //   style: TextStyle(
            //       fontSize: 12,
            //       fontStyle: FontStyle.italic,
            //       color: Colors.grey),
            // ),

            const SizedBox(height: 16),

            // Main telemetry data display
            Expanded(
              child: _liveDataFuture == null
                  ? const Center(
                      child: Text('No telemetry data received yet'),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          FutureBuilder<List<LiveData>>(
                            future: _liveDataFuture,
                            initialData: [], // Initial empty data
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data!.isNotEmpty) {
                                final liveData = snapshot.data!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // _buildExtrapolatedClock(liveData[0]
                                    //     .extrapolatedClock!
                                    //     .remaining),
                                    SizedBox(height: 10),
                                    // TrackMapWidget(
                                    //   trackJsonAsset:
                                    //       'assets/TrackMaps/Spielberg.json',
                                    //   driverPositions: testDriverPositions,
                                    //   width: 350,
                                    //   height: 200,
                                    // ),
                                    SizedBox(height: 10),
                                    _buildSessionInfoCard(
                                        liveData[0].sessionInfo!),
                                    _buildTrackStatusCard(
                                        liveData[0].trackStatus!),
                                    _buildWeatherCard(liveData[0].weatherData!),

                                    SizedBox(height: 10),
                                    Text('Drivers',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 5),
                                    _buildDriverList(
                                        liveData[0].driverList!.drivers,
                                        liveData[0].timingData!.lines,
                                        liveData[0].timingAppData!.lines),
                                  ],
                                );
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else {
                                return const CircularProgressIndicator();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
              // : SingleChildScrollView(
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         const Text(
              //           'Telemetry Data',
              //           style: TextStyle(
              //             fontSize: 20,
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //         const SizedBox(height: 8),

              //         // Session Info
              //         if (_telemetryData.containsKey('SessionInfo'))
              //           _buildSessionInfoCard(),

              //         // Track Status
              //         if (_telemetryData.containsKey('TrackStatus'))
              //           _buildTrackStatusCard(),

              //         // Weather Data
              //         if (_telemetryData.containsKey('WeatherData'))
              //           _buildWeatherCard(),

              //         // Driver Data
              //         if (_telemetryData.containsKey('TimingData') ||
              //             _telemetryData.containsKey('DriverList'))
              //           _buildDriverDataTable(),
              //       ],
              //     ),
              //   ),
            ),
            // TrackMapWidget(
            //   trackImageAsset: 'assets/TrackMaps/your_track_map.png', // Replace with actual asset
            //   drivers: liveData[0].driverList!.drivers,
            //   width: 350,
            //   height: 200,
            //   coordinateMapper: _mapCoordinates,
            // ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     setState(() {
      //       _telemetryData = {};
      //       _messageCount = 0;
      //     });
      //   },
      //   tooltip: 'Clear data',
      //   child: const Icon(Icons.clear),
      // ),
    );
  }

  Widget _buildSessionInfoCard(SessionInfo session) {
    final sessionInfo = _telemetryData['SessionInfo'];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Name:', session.meeting.name ?? 'Unknown'),
            _buildInfoRow('Type:', '${session.name}' ?? 'Unknown'),
            _buildInfoRow('Status:', session.archiveStatus.status ?? 'Unknown'),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackStatusCard(TrackStatus trackStatus) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Track Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Status:', trackStatus.status),
            _buildInfoRow('Message:', trackStatus.message),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(WeatherData weather) {
    // return Card(
    //   margin: const EdgeInsets.only(bottom: 16),
    //   child: Padding(
    //     padding: const EdgeInsets.all(16.0),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         const Text(
    //           'Weather Conditions',
    //           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    //         ),
    //         const SizedBox(height: 8),
    //         _buildInfoRow('Air Temperature:', '${weather.airTemp}°C'),
    //         _buildInfoRow('Track Temperature:', '${weather.trackTemp}°C'),
    //         _buildInfoRow('Wind Speed:', '${(weather.windSpeed)} m/s'),
    //         _buildInfoRow(
    //             'Weather:', weather.rainfall == '0' ? 'Clear' : 'Rain'),
    //         _buildInfoRow('Humidity:', '${weather.humidity}%'),
    //         _buildInfoRow('Pressure:', '${weather.pressure} hPa'),
    //       ],
    //     ),
    //   ),
    // );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: WeatherInfoCard(
          airTemp: weather.airTemp,
          trackTemp: weather.trackTemp,
          windSpeed: weather.windSpeed,
          humidity: weather.humidity,
          weatherCondition: weather.rainfall == '0' ? 'Clear' : 'Rain'),
    );
  }

  Widget _buildDriverDataTable(LiveData driverData) {
    // return Placeholder(
    //   fallbackHeight: 200,
    //   color: Colors.red,
    // );
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('Pos')),
            DataColumn(label: Text('Driver')),
            DataColumn(label: Text('Last Lap')),
            DataColumn(label: Text('Interval')),
            DataColumn(label: Text('Tyres')),
            DataColumn(label: Text('Pit')),
          ],
          rows: [
            DataRow(cells: [
              DataCell(Center(child: Text('1'))),
              DataCell(Row(
                children: [
                  Container(
                    height: 20,
                    width: 5,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  SizedBox(width: 5),
                  Text('HAM',
                      style:
                          TextStyle(fontSize: 16, fontFamily: 'formula-bold')),
                ],
              )),
              DataCell(Text('1:30.123')),
              DataCell(Center(
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Text(
                      '+ 0.000',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'formula-bold'),
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )),
              DataCell(SvgPicture.asset(
                'assets/tyres/Hard.svg',
                width: 24,
                height: 24,
              )),
              DataCell(Text('1')),
            ])
          ],
          // rows: drivers.map((driver) {
          //   return DataRow(
          //     cells: [
          //       DataCell(Text(driver['Position'].toString())),
          //       DataCell(Text(driver['Name'].toString())),
          //       DataCell(Text(driver['TeamName'].toString())),
          //       DataCell(Text(driver['LastLap'].toString())),
          //       DataCell(Text(driver['BestLap'].toString())),
          //       DataCell(Text(driver['Gap'].toString())),
          //     ],
          //   );
          // }).toList(),
        ),
      ),
    );
  }

  Widget _buildDriverList(
      Map<String, Driver> drivers,
      Map<String, TimingDataDriver> timingData,
      Map<String, TimingAppDataDriver> timingAppData) {
    // Sort drivers by line number (current race position)
    List<MapEntry<String, Driver>> sortedDrivers = drivers.entries.toList()
      ..sort((a, b) => a.value.line.compareTo(b.value.line));

    // Debug log to verify sorting
    print("Sorted drivers by position:");
    for (var driver in sortedDrivers) {
      print(
          "Position ${driver.value.line}: ${driver.value.tla} (${driver.key})");
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: sortedDrivers.length,
      itemBuilder: (context, index) {
        final entry = sortedDrivers[index];
        final String racingNumber = entry.key;
        final Driver driver = entry.value;

        final TimingDataDriver timing = timingData[racingNumber]!;
        final TimingAppDataDriver timingApp = timingAppData[racingNumber]!;

        // Get interval value with proper handling based on position, not index
        String intervalText = "";
        if (driver.line == 1) {
          // Check if this is the race leader by position
          // Leader (show LEADER or P1 instead of interval)
          intervalText = "Leader";
        } else {
          // Get interval to position ahead
          intervalText =
              timing.intervalToPositionAhead?.value ?? timing.gapToLeader;
        }

        String tyrePath(String tyreCompound) {
          String tyre = '';
          if (tyreCompound == '') {
            return tyre = 'assets/tyres/unknown.svg'; // Default to Hard tyre
          } else if (tyreCompound == 'HARD') {
            return tyre = 'assets/tyres/Hard.svg';
          } else if (tyreCompound == 'MEDIUM') {
            return tyre = 'assets/tyres/Medium.svg';
          } else if (tyreCompound == 'SOFT') {
            return tyre = 'assets/tyres/Soft.svg';
          } else if (tyreCompound == 'INTERMEDIATE') {
            return tyre = 'assets/tyres/Intermediate.svg';
          } else {
            return tyre = 'assets/tyres/unknown.svg'; // Default to Hard tyre
          }
        }

        Color teamColor;
        try {
          // Parse team color
          if (driver.teamColour.isNotEmpty && driver.teamColour.length == 6) {
            teamColor = Color(int.parse('0xFF${driver.teamColour}'));
          } else {
            teamColor = Colors.grey;
          }
        } catch (e) {
          print('Error parsing color: ${driver.teamColour} - $e');
          teamColor = Colors.grey;
        }

        // return Padding(
        //   padding: const EdgeInsets.symmetric(vertical: 5),
        //   child: Container(
        //     width: double.infinity,
        //     height: 60,
        //     decoration: BoxDecoration(
        //       borderRadius: BorderRadius.circular(10),
        //       border: timing.lastLapTime.overallFastest
        //           ? Border.all(color: Colors.purple, width: 1)
        //           : Border.all(color: Colors.white, width: 0.5),
        //     ),
        //     child: MaterialButton(
        //       color: Color.fromRGBO(115, 115, 115, 1),
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(10),
        //       ),
        //       onPressed: () {
        //         Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (context) => LiveDetailsPage(
        //                 racingNumber: racingNumber,
        //               ),
        //             ));
        //       },
        //       child: SingleChildScrollView(
        //         scrollDirection: Axis.horizontal,
        //         child: Row(
        //           mainAxisAlignment: MainAxisAlignment.start,
        //           crossAxisAlignment: CrossAxisAlignment.center,
        //           children: [
        //             Text(driver.line.toString(),
        //                 style: TextStyle(
        //                     color: Colors.white,
        //                     fontSize: 25,
        //                     fontWeight: FontWeight.w900)),
        //             SizedBox(width: 20),
        //             Container(
        //               width: 5,
        //               height: 25,
        //               decoration: BoxDecoration(
        //                 color: teamColor,
        //                 borderRadius: BorderRadius.circular(10),
        //               ),
        //             ),
        //             SizedBox(width: 5),
        //             Text(
        //               driver.tla.isNotEmpty ? driver.tla : '???',
        //               style: TextStyle(
        //                 color: Colors.white,
        //                 fontSize: 20,
        //                 fontFamily: 'formula-bold',
        //               ),
        //             ),
        //             SizedBox(width: 50), // Add a minimum spacing
        //             Text(timing.lastLapTime.value,
        //                 style: TextStyle(
        //                   color: Colors.white,
        //                   fontWeight: FontWeight.w900,
        //                   fontSize: 15,
        //                 )),
        //             SizedBox(width: 20),
        //             Container(
        //               width: 70,
        //               height: 30,
        //               decoration: BoxDecoration(
        //                 color: intervalText == "Leader"
        //                     ? Colors.red
        //                     : Colors.green,
        //                 borderRadius: BorderRadius.circular(40),
        //               ),
        //               child: Center(
        //                 child: Padding(
        //                   padding: const EdgeInsets.all(4.0),
        //                   child: Text(intervalText,
        //                       style: TextStyle(
        //                         color: Colors.white,
        //                         fontSize: 15,
        //                         fontWeight: FontWeight.w900,
        //                       )),
        //                 ),
        //               ),
        //             ),
        //             SizedBox(width: 20),
        //             // SvgPicture.asset(
        //             //   tyrePath(timingApp.stints[0].compound ?? 'Unknown'),
        //             //   width: 30,
        //             //   height: 30,
        //             //   placeholderBuilder: (context) =>
        //             //       CircularProgressIndicator(),
        //             // ),
        //             SizedBox(width: 20),
        //             Text(timing.numberOfPitStops.toString(),
        //                 style: TextStyle(
        //                     color: Colors.white,
        //                     fontSize: 25,
        //                     fontWeight: FontWeight.w900)),
        //           ],
        //         ),
        //       ),
        //     ),
        //   ),
        // );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: DriverInfoCard(
            position: driver.line,
            teamColor: teamColor,
            tla: driver.tla.isNotEmpty ? driver.tla : '???',
            interval: intervalText,
            currentLapTime: timing.lastLapTime.value,
            pitStops: timing.numberOfPitStops,
          ),
        );
      },
    );
  }

  // Card(
  //         margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
  //         child: ListTile(
  //           leading: CircleAvatar(
  //             child: Text(driver.line.toString()),
  //             backgroundColor: teamColor,
  //             foregroundColor: Colors.white,
  //           ),
  //           title: Text(
  //             driver.fullName,
  //             style: TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //           subtitle: Text(driver.teamName),
  //           trailing: Container(
  //             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //             decoration: BoxDecoration(
  //               color: index == 0 ? Colors.red : Colors.green,
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //             child: Text(
  //               intervalText,
  //               style: TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.white,
  //                 fontSize: 14,
  //               ),
  //             ),
  //           ),
  //         ),
  //       );

  // Helper method to build preset delay buttons
  Widget _buildPresetButton(int seconds) {
    final isSelected = _delaySeconds == seconds;
    return SizedBox(
      width: 32,
      height: 28,
      child: ElevatedButton(
        onPressed: () => _updateDelay(seconds),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Colors.orange : Colors.orange.withOpacity(0.3),
          foregroundColor: isSelected ? Colors.white : Colors.orange,
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        child: Text('$seconds'),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

Widget _buildExtrapolatedClock(String remainingTime) {
  // Convert the remaining time to a Duration object
  Duration duration;
  try {
    final parts = remainingTime.split(':');
    if (parts.length == 3) {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);
      duration = Duration(hours: hours, minutes: minutes, seconds: seconds);
    } else {
      throw FormatException('Invalid time format');
    }
  } catch (e) {
    duration = Duration.zero; // Default to zero if parsing fails
    print('Error parsing remainingTime: $remainingTime - $e');
  }
  return Text(duration.toString(),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
}

// Add this widget class at the bottom of your file (or in a separate file if you prefer)
class TrackMapWidget extends StatefulWidget {
  final String trackJsonAsset;
  final Map<String, dynamic> driverPositions; // Map of driverNo -> {X, Y, Z}
  final double width;
  final double height;

  const TrackMapWidget({
    super.key,
    required this.trackJsonAsset,
    required this.driverPositions,
    required this.width,
    required this.height,
  });

  @override
  State<TrackMapWidget> createState() => _TrackMapWidgetState();
}

class _TrackMapWidgetState extends State<TrackMapWidget> {
  List<Offset> _trackPoints = [];
  double? minX, maxX, minY, maxY;

  @override
  void initState() {
    super.initState();
    _loadTrack();
  }

  Future<void> _loadTrack() async {
    final jsonStr = await rootBundle.loadString(widget.trackJsonAsset);
    final jsonData = jsonDecode(jsonStr);

    // Parse x and y arrays
    final List xList = jsonData['x'];
    final List yList = jsonData['y'];
    List<Offset> points = [];
    for (int i = 0; i < xList.length && i < yList.length; i++) {
      points.add(
          Offset((xList[i] as num).toDouble(), (yList[i] as num).toDouble()));
    }

    // Find min/max for normalization
    double minX = points.map((e) => e.dx).reduce((a, b) => a < b ? a : b);
    double maxX = points.map((e) => e.dx).reduce((a, b) => a > b ? a : b);
    double minY = points.map((e) => e.dy).reduce((a, b) => a < b ? a : b);
    double maxY = points.map((e) => e.dy).reduce((a, b) => a > b ? a : b);

    setState(() {
      _trackPoints = points;
      this.minX = minX;
      this.maxX = maxX;
      this.minY = minY;
      this.maxY = maxY;
    });
  }

  // Normalizes a point to widget size
  Offset _normalize(Offset pt) {
    if (minX == null || maxX == null || minY == null || maxY == null)
      return Offset.zero;
    double normX = (pt.dx - minX!) / (maxX! - minX!);
    double normY = (pt.dy - minY!) / (maxY! - minY!);
    // Flip Y axis for typical track orientation
    // normY = 1.0 - normY;
    return Offset(normX * widget.width, normY * widget.height);
  }

  // Normalizes driver coordinates
  Offset _normalizeDriver(double x, double y) {
    if (minX == null || maxX == null || minY == null || maxY == null)
      return Offset.zero;
    double normX = (x - minX!) / (maxX! - minX!);
    double normY = (y - minY!) / (maxY! - minY!);
    // normY = 1.0 - normY;
    return Offset(normX * widget.width, normY * widget.height);
  }

  @override
  Widget build(BuildContext context) {
    if (_trackPoints.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: _TrackPainter(
          trackPoints: _trackPoints,
          normalize: _normalize,
          driverPositions: widget.driverPositions,
          normalizeDriver: _normalizeDriver,
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  final List<Offset> trackPoints;
  final Offset Function(Offset pt) normalize;
  final Map<String, dynamic> driverPositions;
  final Offset Function(double x, double y) normalizeDriver;

  _TrackPainter({
    required this.trackPoints,
    required this.normalize,
    required this.driverPositions,
    required this.normalizeDriver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw track path
    if (trackPoints.isNotEmpty) {
      final path = Path()
        ..moveTo(
          normalize(trackPoints[0]).dx,
          normalize(trackPoints[0]).dy,
        );
      for (final pt in trackPoints.skip(1)) {
        final npt = normalize(pt);
        path.lineTo(npt.dx, npt.dy);
      }
      final paint = Paint()
        ..color = Colors.grey.shade800
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
    }

    // Draw drivers with team colour
    driverPositions.forEach((driverNo, entry) {
      final double? x = (entry['X'] as num?)?.toDouble();
      final double? y = (entry['Y'] as num?)?.toDouble();
      if (x == null || y == null) return;
      final Offset pos = normalizeDriver(x, y);

      // Default to red if no teamColour
      Color teamColor = Colors.red;
      if (entry['teamColour'] != null &&
          entry['teamColour'] is String &&
          (entry['teamColour'] as String).length == 6) {
        try {
          teamColor = Color(int.parse('0xFF${entry['teamColour']}'));
        } catch (_) {
          teamColor = Colors.red;
        }
      }

      final paint = Paint()
        ..color = teamColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 8, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: driverNo,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, pos + const Offset(-10, -18));
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Example usage for testing (in your build method):
// final testPositions = <String, dynamic>{
//   "1": {"X": 1479, "Y": -940, "Z": 7312},
//   "4": {"X": 1200, "Y": -1014, "Z": 7307},
//   // ...etc
// };
// TrackMapWidget(
//   trackJsonAsset: 'assets/TrackMaps/Spielberg.json',
//   driverPositions: testPositions,
//   width: 350,
//   height: 200,
// );

// Example driver positions for testing
final Map<String, dynamic> testDriverPositions = {
  "1": {"Status": "OnTrack", "X": 1479, "Y": -940, "Z": 7312},
  "4": {"Status": "OnTrack", "X": 1200, "Y": -1014, "Z": 7307},
  "5": {"Status": "OnTrack", "X": 1489, "Y": -938, "Z": 7312},
  "6": {"Status": "OnTrack", "X": -585, "Y": -1493, "Z": 7301},
  "10": {"Status": "OnTrack", "X": 1452, "Y": -947, "Z": 7313},
  "12": {"Status": "OnTrack", "X": 1426, "Y": -954, "Z": 7313},
  "14": {"Status": "OnTrack", "X": 70, "Y": -1317, "Z": 7313},
  "16": {"Status": "OnTrack", "X": 1136, "Y": -1031, "Z": 7312},
  "18": {"Status": "OnTrack", "X": -40, "Y": -1347, "Z": 7312},
  "22": {"Status": "OnTrack", "X": 292, "Y": -1258, "Z": 7312},
  "23": {"Status": "OnTrack", "X": -860, "Y": -1567, "Z": 7312},
  "27": {"Status": "OnTrack", "X": -981, "Y": -1598, "Z": 7312},
  "30": {"Status": "OnTrack", "X": 1560, "Y": -920, "Z": 7313},
  "31": {"Status": "OnTrack", "X": -484, "Y": -1466, "Z": 7311},
  "43": {"Status": "OnTrack", "X": -204, "Y": -1391, "Z": 7307},
  "44": {"Status": "OnTrack", "X": 1558, "Y": -920, "Z": 7312},
  "55": {"Status": "OnTrack", "X": -898, "Y": -1577, "Z": 7312},
  "63": {"Status": "OnTrack", "X": 1489, "Y": -938, "Z": 7312},
  "81": {"Status": "OnTrack", "X": 1147, "Y": -1028, "Z": 7312},
  "87": {"Status": "OnTrack", "X": -436, "Y": -1453, "Z": 7312},
};
