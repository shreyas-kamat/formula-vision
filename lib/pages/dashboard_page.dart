import 'dart:convert';
import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formulavision/components/driver_row_card.dart';
import 'package:formulavision/components/race_timer_bar.dart';
import 'package:formulavision/components/weather_info_card.dart';
import 'package:formulavision/components/track_status_card.dart';
import 'package:formulavision/data/functions/cardata.function.dart';
import 'package:formulavision/data/functions/live_data.function.dart';
import 'package:formulavision/data/models/live_data.model.dart';
// import 'package:shared_preferences/shared_preferences.dart';
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
  final Map<String, dynamic> _telemetryData = {};
  Future<List<SessionInfo>>? _sessionInfoFuture;
  Future<List<WeatherData>>? _weatherDataFuture;
  Future<List<LiveData>>? _liveDataFuture;
  bool _isConnected = false;
  String _connectionStatus = "Disconnected";
  String _errorMessage = "";
  int _messageCount = 0;
  final bool _useSimulation = false;
  final bool _useSSE = true; // Add flag to use SSE instead of WebSockets

  // Delay-related variables
  int _delaySeconds = 0; // User-defined delay in seconds
  final Queue<_DelayedMessage> _messageQueue = Queue<_DelayedMessage>();
  Timer? _delayTimer;
  bool _delayEnabled = false;

  final _liveDataController = StreamController<List<LiveData>>.broadcast();
  Stream<List<LiveData>> get liveDataStream => _liveDataController.stream;

  // Position tracking for animations
  Map<String, int> _previousPositions = {};
  final Map<String, int> _currentPositions = {};
  final Map<String, String> _positionChanges = {}; // 'up', 'down', or 'same'
  bool _isHeaderPinned = true; // Track if header is pinned
  bool _isRaceTimerPinned = false; // Track if race timer bar is pinned

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
      // final prefs = await SharedPreferences.getInstance();
      // final String? token = prefs.getString('jwt_token');
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/initialData'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Initial: $data');
        // Check if data contains SessionInfo
        setState(() {
          _liveDataFuture = fetchLiveData(data['R']);
        });

        // Initialize position tracking with initial data
        _initializePositionTracking();

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

  void _initializePositionTracking() {
    if (_liveDataFuture != null) {
      _liveDataFuture!.then((liveDataList) {
        if (liveDataList.isNotEmpty) {
          final liveData = liveDataList[0];
          if (liveData.driverList?.drivers != null) {
            liveData.driverList!.drivers.forEach((racingNumber, driver) {
              _currentPositions[racingNumber] = driver.line;
              _previousPositions[racingNumber] = driver.line;
              _positionChanges[racingNumber] = 'same';
            });
          }
        }
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
            '${dotenv.env['API_URL']}/negotiate?simulation=$_useSimulation'),
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
      // final prefs = await SharedPreferences.getInstance();
      // final String? token = prefs.getString('jwt_token');
      // Connect to the SSE endpoint with appropriate headers
      final request = http.Request('GET', Uri.parse(sseUrl));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.headers['Content-Type'] = 'application/json; charset=UTF-8';
      // if (token != null) {
      //   request.headers['Authorization'] = 'Bearer $token';
      // }

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
          print('Processing message object: $messageObject');
          if (messageObject is Map &&
              messageObject.containsKey('A') &&
              messageObject['A'] is List &&
              messageObject['A'].isNotEmpty) {
            // Check if this is the new format with ExtrapolatedClock as an object
            if (messageObject['A'][0] is Map &&
                messageObject['A'][0].containsKey('ExtrapolatedClock')) {
              print('Found ExtrapolatedClock in new format');
              final clockData = messageObject['A'][0]['ExtrapolatedClock'];
              setState(() {
                _updateExtrapolatedClock(clockData);
              });
              print('ExtrapolatedClock Updated Successfully from new format');
              continue;
            }

            final messageType = messageObject['A'][0];
            print('Message type: $messageType');

            if (messageObject['A'].length > 1) {
              final updated = messageObject['A'][1];
              final timestamp =
                  messageObject['A'].length > 2 ? messageObject['A'][2] : null;

              print(
                  'Processing $messageType update with timestamp: $timestamp');
              print('Updated data: $updated');

              // Handle each message type appropriately
              switch (messageType) {
                case 'ExtrapolatedClock':
                  print('ExtrapolatedClock data received: $updated');
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

                case 'LapCount':
                  setState(() {
                    _updateLapCount(updated);
                  });
                  print('LapCount Updated Successfully');
                  break;

                default:
                  print('No handler for message type: $messageType');
              }
            } else {
              print('Message data is not a Map:');
            }
          } else {
            print('Message does not contain valid "A" array structure');
          }
        }
      }
    }
    // After processing all updates in a batch
    if (!_liveDataController.isClosed) {
      _liveDataFuture!.then((liveDataList) {
        _liveDataController.add(liveDataList);
      });
    }
  }

  void _updateExtrapolatedClock(dynamic data) {
    print('_updateExtrapolatedClock called with data: $data');
    if (data is Map<String, dynamic>) {
      print('Updating extrapolated clock with: ${data.keys.toList()}');
      if (data.isEmpty) {
        print('Received empty extrapolated clock data, skipping update');
        return;
      }

      setState(() {
        if (_liveDataFuture != null) {
          _liveDataFuture = _liveDataFuture!.then((liveDataList) {
            print(
                'Updating extrapolated clock in live data list of size: ${liveDataList.length}');
            if (liveDataList.isNotEmpty) {
              final currentLiveData = liveDataList[0];

              // Create a new ExtrapolatedClock with updated values
              ExtrapolatedClock updatedClock = ExtrapolatedClock(
                utc: data.containsKey('Utc')
                    ? data['Utc']
                    : currentLiveData.extrapolatedClock?.utc ?? '',
                remaining: data.containsKey('Remaining')
                    ? data['Remaining']
                    : currentLiveData.extrapolatedClock?.remaining ?? '',
                extrapolating: data.containsKey('Extrapolating')
                    ? data['Extrapolating']
                    : currentLiveData.extrapolatedClock?.extrapolating ?? false,
              );

              print(
                  'Created updated clock: UTC=${updatedClock.utc}, Remaining=${updatedClock.remaining}, Extrapolating=${updatedClock.extrapolating}');

              // Update the extrapolated clock in the current live data object
              currentLiveData.extrapolatedClock = updatedClock;

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
          }).then((liveDataList) {
            // Add updated data to stream
            if (!_liveDataController.isClosed) {
              _liveDataController.add(liveDataList);
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

          // Store current positions before updating
          _previousPositions = Map.from(_currentPositions);

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

            // Update current position tracking
            _currentPositions[racingNumber] = updatedDriver.line;
          }

          // Calculate position changes
          _updatePositionChanges();

          // Create a new DriverList
          DriverList updatedDriverList = DriverList(
            drivers: currentDrivers,
          );

          // Update the driver list in the current live data object
          currentLiveData.driverList = updatedDriverList;

          return liveDataList;
        }).then((liveDataList) {
          // Add updated data to stream
          if (!_liveDataController.isClosed) {
            _liveDataController.add(liveDataList);
          }
          return liveDataList;
        });
      });
    } else {
      print(
          'Received non-map driver list data: ${data.runtimeType}, cannot update');
    }
  }

  void _updatePositionChanges() {
    _positionChanges.clear();

    for (var racingNumber in _currentPositions.keys) {
      final currentPos = _currentPositions[racingNumber] ?? 0;
      final previousPos = _previousPositions[racingNumber] ?? currentPos;

      if (previousPos > currentPos) {
        _positionChanges[racingNumber] =
            'up'; // Lower number = higher position = moved up
      } else if (previousPos < currentPos) {
        _positionChanges[racingNumber] =
            'down'; // Higher number = lower position = moved down
      } else {
        _positionChanges[racingNumber] = 'same';
      }
    }

    print('Position changes: $_positionChanges');
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
                      } else if (currentDriverData?.speeds.i1 != null) {
                        i1 = currentDriverData!.speeds.i1;
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
                      } else if (currentDriverData?.speeds.i2 != null) {
                        i2 = currentDriverData!.speeds.i2;
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
                      } else if (currentDriverData?.speeds.fl != null) {
                        fl = currentDriverData!.speeds.fl;
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
                      } else if (currentDriverData?.speeds.st != null) {
                        st = currentDriverData!.speeds.st;
                      }

                      updatedSpeeds = Speeds(i1: i1, i2: i2, fl: fl, st: st);
                    } else if (currentDriverData?.speeds != null) {
                      updatedSpeeds = currentDriverData!.speeds;
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

                    // Track position changes for timing data updates
                    final newLine =
                        driverData['Line'] ?? (currentDriverData?.line ?? 0);
                    final previousLine =
                        _currentPositions[racingNumber] ?? newLine;

                    if (previousLine != newLine) {
                      _previousPositions[racingNumber] = previousLine;
                      _currentPositions[racingNumber] = newLine;
                    }

                    // Update the driver in our map
                    currentLines[racingNumber] = updatedDriver;
                  }
                });

                // Create updated TimingData object
                TimingData updatedTimingData = TimingData(
                  lines: currentLines,
                  withheld: data['Withheld'] ?? false,
                );

                // Update position changes after all timing data is processed
                _updatePositionChanges();

                // Update the timing data in the live data object
                currentLiveData.timingData = updatedTimingData;
              }

              return liveDataList;
            }
            return liveDataList;
          }).then((liveDataList) {
            // Add updated data to stream
            if (!_liveDataController.isClosed) {
              _liveDataController.add(liveDataList);
            }
            return liveDataList;
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
                    ? data['AirTemp']?.toString() ??
                        currentLiveData.weatherData!.airTemp
                    : currentLiveData.weatherData!.airTemp,
                humidity: data.containsKey('Humidity')
                    ? data['Humidity']?.toString() ??
                        currentLiveData.weatherData!.humidity
                    : currentLiveData.weatherData!.humidity,
                pressure: data.containsKey('Pressure')
                    ? data['Pressure']?.toString() ??
                        currentLiveData.weatherData!.pressure
                    : currentLiveData.weatherData!.pressure,
                rainfall: data.containsKey('Rainfall')
                    ? data['Rainfall']?.toString() ??
                        currentLiveData.weatherData!.rainfall
                    : currentLiveData.weatherData!.rainfall,
                trackTemp: data.containsKey('TrackTemp')
                    ? data['TrackTemp']?.toString() ??
                        currentLiveData.weatherData!.trackTemp
                    : currentLiveData.weatherData!.trackTemp,
                windDirection: data.containsKey('WindDirection')
                    ? data['WindDirection']?.toString() ??
                        currentLiveData.weatherData!.windDirection
                    : currentLiveData.weatherData!.windDirection,
                windSpeed: data.containsKey('WindSpeed')
                    ? data['WindSpeed']?.toString() ??
                        currentLiveData.weatherData!.windSpeed
                    : currentLiveData.weatherData!.windSpeed,
              );

              // Update the weather data in the current live data object
              currentLiveData.weatherData = updatedWeatherData;

              return liveDataList;
            }
            return liveDataList;
          }).then((liveDataList) {
            // Add updated data to stream
            if (!_liveDataController.isClosed) {
              _liveDataController.add(liveDataList);
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
                            currentSession.meeting.country.key,
                        code: data['Meeting']['Country']['Code'] ??
                            currentSession.meeting.country.code,
                        name: data['Meeting']['Country']['Name'] ??
                            currentSession.meeting.country.name,
                      )
                    : currentSession.meeting.country,
                circuit: data.containsKey('Meeting') &&
                        data['Meeting'].containsKey('Circuit')
                    ? Circuit(
                        key: data['Meeting']['Circuit']['Key'] ??
                            currentSession.meeting.circuit.key,
                        shortName: data['Meeting']['Circuit']['ShortName'] ??
                            currentSession.meeting.circuit.shortName,
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
          }).then((liveDataList) {
            // Add updated data to stream
            if (!_liveDataController.isClosed) {
              _liveDataController.add(liveDataList);
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

  void _updateLapCount(dynamic data) {
    if (data is Map<String, dynamic>) {
      print('Updating lap count with: ${data.keys.toList()}');
      if (data.isEmpty) {
        print('Received empty lap count data, skipping update');
        return;
      }

      setState(() {
        if (_liveDataFuture != null) {
          _liveDataFuture = _liveDataFuture!.then((liveDataList) {
            if (liveDataList.isNotEmpty) {
              final currentLiveData = liveDataList[0];

              // Create a new LapCount with updated values
              LapCount updatedLapCount = LapCount(
                currentLap: data.containsKey('CurrentLap')
                    ? data['CurrentLap']
                    : currentLiveData.lapCount?.currentLap ?? 0,
                totalLaps: data.containsKey('TotalLaps')
                    ? data['TotalLaps']
                    : currentLiveData.lapCount?.totalLaps ?? 0,
              );

              // Update the lap count in the current live data object
              currentLiveData.lapCount = updatedLapCount;

              return liveDataList;
            }
            return liveDataList;
          }).then((liveDataList) {
            // Add updated data to stream
            if (!_liveDataController.isClosed) {
              _liveDataController.add(liveDataList);
            }
            return liveDataList;
          });
        }
      });
    } else {
      print(
          'Received non-map lap count data: ${data.runtimeType}, cannot update');
    }
  }

  void _updatePositionData(dynamic data) {
    if (data is Map<String, dynamic>) {
      print('Updating position data with: ${data.keys.toList()}');
      if (data.isEmpty) {
        print('Received empty position data, skipping update');
        return;
      }

      setState(() {
        if (_liveDataFuture != null) {
          _liveDataFuture = _liveDataFuture!.then((liveDataList) {
            if (liveDataList.isNotEmpty) {
              final currentLiveData = liveDataList[0];

              // Create a new PositionData with updated values
              PositionData updatedPositionData = PositionData.fromJson(data);

              // Update the position data in the current live data object
              currentLiveData.positionData = updatedPositionData;

              return liveDataList;
            }
            return liveDataList;
          }).then((liveDataList) {
            // Add updated data to stream
            if (!_liveDataController.isClosed) {
              _liveDataController.add(liveDataList);
            }
            return liveDataList;
          });
        }
      });
    } else {
      print(
          'Received non-map position data: ${data.runtimeType}, cannot update');
    }
  }

  Widget _buildExpandableTimerButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _delayEnabled ? Colors.orange : Colors.amber,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: IconButton(
          onPressed: () {
            _showDelayModal(context);
          },
          icon: const Icon(Icons.timer),
          color: Colors.black,
          iconSize: 24,
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  void _showDelayModal(BuildContext context) {
    int tempDelay = _delaySeconds;
    bool tempDelayEnabled = _delayEnabled;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1e1e1e),
              title: const Text(
                'Adjust Delay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Delay enabled toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Enable Delay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: tempDelayEnabled,
                          onChanged: (value) {
                            setModalState(() {
                              tempDelayEnabled = value;
                            });
                          },
                          activeThumbColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Delay value display with +/- buttons
                  Opacity(
                    opacity: tempDelayEnabled ? 1.0 : 0.5,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: tempDelayEnabled
                            ? Colors.grey[900]
                            : Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: tempDelayEnabled ? Colors.orange : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Delay Duration',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: TextEditingController(
                                    text: tempDelay.toString(),
                                  ),
                                  enabled: tempDelayEnabled,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: (value) {
                                    final newDelay =
                                        int.tryParse(value) ?? tempDelay;
                                    setModalState(() {
                                      tempDelay = newDelay.clamp(0, 300);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                's',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // +/- buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: tempDelayEnabled && tempDelay > 0
                                    ? () {
                                        setModalState(() {
                                          tempDelay--;
                                        });
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  disabledBackgroundColor: Colors.grey[700],
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '−',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              ElevatedButton(
                                onPressed: tempDelayEnabled && tempDelay < 300
                                    ? () {
                                        setModalState(() {
                                          tempDelay++;
                                        });
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  disabledBackgroundColor: Colors.grey[700],
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '+',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _delayEnabled = tempDelayEnabled;
                      _delaySeconds = tempDelay;
                      if (_delayEnabled && _delaySeconds > 0) {
                        _startDelayTimer();
                      } else {
                        _delayTimer?.cancel();
                        _processQueuedMessages();
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper method to get track status display
  String _getTrackStatusDisplay(String? status) {
    switch (status?.toLowerCase()) {
      case '1':
      case 'track clear':
        return 'Track Clear';
      case '2':
      case 'yellow flag':
        return 'Yellow Flag';
      case '3':
      case 'safety car':
        return 'Safety Car';
      case '4':
      case 'red flag':
        return 'Red Flag';
      case '5':
      case 'vsc':
      case 'virtual safety car':
        return 'VSC';
      default:
        return status ?? 'Track Clear';
    }
  }

  // Helper method to get track status color
  Color _getTrackStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case '1':
      case 'track clear':
        return Colors.green;
      case '2':
      case 'yellow flag':
        return Colors.yellow;
      case '3':
      case 'safety car':
        return Colors.orange;
      case '4':
      case 'red flag':
        return Colors.red;
      case '5':
      case 'vsc':
      case 'virtual safety car':
        return Colors.yellow[700] ?? Colors.yellow;
      default:
        return Colors.green;
    }
  }

  // Header widget to avoid repetition
  Widget _buildHeaderWidget(
      SessionInfo? sessionInfo, TrackStatus? trackStatus) {
    final meetingName = sessionInfo?.meeting.name ?? 'Grand Prix';
    final sessionType = sessionInfo?.type ?? 'Session';
    final trackStatusDisplay = _getTrackStatusDisplay(trackStatus?.status);
    final trackStatusColor = _getTrackStatusColor(trackStatus?.status);

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.15,
        children: [
          SlidableAction(
            onPressed: (context) {
              setState(() {
                _isHeaderPinned = !_isHeaderPinned;
              });
            },
            icon: _isHeaderPinned ? Icons.lock : Icons.lock_open,
            foregroundColor: Colors.orange,
            backgroundColor: Colors.transparent,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meetingName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'formula-bold',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // const SizedBox(height: 4),
                // Session Type with Live Badge
                Row(
                  children: [
                    Text(
                      sessionType,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: trackStatusColor.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: trackStatusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            trackStatusDisplay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildExpandableTimerButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Connection indicator bar
          Container(
            width: double.infinity,
            height: 8,
            color: _isConnected
                ? (_useSimulation ? Colors.amber : Colors.green)
                : Colors.red,
          ),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER - Always on top when pinned
                    if (_isHeaderPinned)
                      FutureBuilder<List<LiveData>>(
                        future: _liveDataFuture,
                        initialData: [],
                        builder: (context, snapshot) {
                          if (snapshot.hasData &&
                              snapshot.data!.isNotEmpty &&
                              snapshot.data![0].sessionInfo != null) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildHeaderWidget(
                                    snapshot.data![0].sessionInfo,
                                    snapshot.data![0].trackStatus),
                                const SizedBox(height: 16),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    if (!_isHeaderPinned) const SizedBox(height: 0),

                    // RACE TIMER and CONTENT - Managed together
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // RACE TIMER - Pinned when _isRaceTimerPinned is true
                          if (_isRaceTimerPinned)
                            FutureBuilder<List<LiveData>>(
                              future: _liveDataFuture,
                              initialData: [],
                              builder: (context, snapshot) {
                                if (snapshot.hasData &&
                                    snapshot.data!.isNotEmpty &&
                                    snapshot.data![0].extrapolatedClock !=
                                        null) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12.0),
                                    child: Slidable(
                                      endActionPane: ActionPane(
                                        motion: const ScrollMotion(),
                                        extentRatio: 0.15,
                                        children: [
                                          SlidableAction(
                                            onPressed: (context) {
                                              setState(() {
                                                _isRaceTimerPinned =
                                                    !_isRaceTimerPinned;
                                              });
                                            },
                                            icon: _isRaceTimerPinned
                                                ? Icons.lock
                                                : Icons.lock_open,
                                            foregroundColor: Colors.orange,
                                            backgroundColor: Colors.transparent,
                                          ),
                                        ],
                                      ),
                                      child: RaceTimerBar(
                                        remaining: snapshot.data![0]
                                            .extrapolatedClock!.remaining,
                                        currentLap: snapshot
                                            .data![0].lapCount?.currentLap,
                                        totalLaps: snapshot
                                            .data![0].lapCount?.totalLaps,
                                        sessionType:
                                            snapshot.data![0].sessionInfo!.name,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),

                          // Main scrollable content
                          Expanded(
                            child: StreamBuilder<List<LiveData>>(
                              stream: liveDataStream,
                              initialData: _liveDataFuture != null ? [] : null,
                              builder: (context, snapshot) {
                                if (_liveDataFuture == null) {
                                  return const Center(
                                    child:
                                        Text('No telemetry data received yet'),
                                  );
                                }

                                if (snapshot.hasData &&
                                    snapshot.data!.isNotEmpty) {
                                  return SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        // HEADER - Scrolls with content when unpinned
                                        if (!_isHeaderPinned) ...[
                                          FutureBuilder<List<LiveData>>(
                                            future: _liveDataFuture,
                                            initialData: [],
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData &&
                                                  snapshot.data!.isNotEmpty &&
                                                  snapshot.data![0]
                                                          .sessionInfo !=
                                                      null) {
                                                return Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    _buildHeaderWidget(
                                                        snapshot.data![0]
                                                            .sessionInfo,
                                                        snapshot.data![0]
                                                            .trackStatus),
                                                    const SizedBox(height: 16),
                                                  ],
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ], // RACE TIMER - Scrolls with content when unpinned
                                        if (!_isRaceTimerPinned)
                                          FutureBuilder<List<LiveData>>(
                                            future: _liveDataFuture,
                                            initialData: [],
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData &&
                                                  snapshot.data!.isNotEmpty &&
                                                  snapshot.data![0]
                                                          .extrapolatedClock !=
                                                      null) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 12.0),
                                                  child: Slidable(
                                                    endActionPane: ActionPane(
                                                      motion:
                                                          const ScrollMotion(),
                                                      extentRatio: 0.15,
                                                      children: [
                                                        SlidableAction(
                                                          onPressed: (context) {
                                                            setState(() {
                                                              _isRaceTimerPinned =
                                                                  !_isRaceTimerPinned;
                                                            });
                                                          },
                                                          icon:
                                                              _isRaceTimerPinned
                                                                  ? Icons.lock
                                                                  : Icons
                                                                      .lock_open,
                                                          foregroundColor:
                                                              Colors.orange,
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                        ),
                                                      ],
                                                    ),
                                                    child: RaceTimerBar(
                                                      remaining: snapshot
                                                          .data![0]
                                                          .extrapolatedClock!
                                                          .remaining,
                                                      currentLap: snapshot
                                                          .data![0]
                                                          .lapCount
                                                          ?.currentLap,
                                                      totalLaps: snapshot
                                                          .data![0]
                                                          .lapCount
                                                          ?.totalLaps,
                                                      sessionType: snapshot
                                                          .data![0]
                                                          .sessionInfo!
                                                          .name,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),

                                        // Main content
                                        FutureBuilder<List<LiveData>>(
                                          future: _liveDataFuture,
                                          initialData: [],
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData &&
                                                snapshot.data!.isNotEmpty) {
                                              final liveData = snapshot.data!;
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  _buildWeatherCard(
                                                      liveData[0].weatherData!),
                                                  SizedBox(height: 10),
                                                  Text('Drivers',
                                                      style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  SizedBox(height: 5),
                                                  _buildDriverList(
                                                      liveData[0]
                                                          .driverList!
                                                          .drivers,
                                                      liveData[0]
                                                          .timingData!
                                                          .lines,
                                                      liveData[0]
                                                              .timingAppData
                                                              ?.lines ??
                                                          {},
                                                      liveData[0].sessionInfo!),
                                                ],
                                              );
                                            } else if (snapshot.hasError) {
                                              return Text(
                                                  'Error: ${snapshot.error}');
                                            } else {
                                              return const CircularProgressIndicator();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                } else if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                } else {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackStatusCard(TrackStatus trackStatus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TrackStatusCard(
        status: trackStatus.status,
        message: trackStatus.message,
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
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
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
      Map<String, TimingAppDataDriver> timingAppData,
      SessionInfo sessionInfo) {
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

        // Get interval value with proper handling based on position, not index
        String intervalText = "";
        if (driver.line == 1) {
          // Leader (show LEADER instead of interval)
          intervalText = "Leader";
        } else if (sessionInfo.type.toLowerCase() == 'qualifying') {
          // For qualifying: Calculate time difference from driver above
          final driverAbovePosition = driver.line - 1;
          MapEntry<String, Driver>? driverAbove;

          for (var entry in sortedDrivers) {
            if (entry.value.line == driverAbovePosition) {
              driverAbove = entry;
              break;
            }
          }

          if (driverAbove != null) {
            final driverAboveRacingNumber = driverAbove.key;
            final driverAboveTiming = timingData[driverAboveRacingNumber];

            // Parse best lap times
            String currentBestTime = timing.bestLapTime.value;
            String aboveBestTime = driverAboveTiming?.bestLapTime.value ?? '';

            // Calculate time difference if both times are available
            if (currentBestTime.isNotEmpty &&
                aboveBestTime.isNotEmpty &&
                currentBestTime != '--:--.---' &&
                aboveBestTime != '--:--.---') {
              // Parse lap times to milliseconds
              final currentMs = _parseTimeToMilliseconds(currentBestTime);
              final aboveMs = _parseTimeToMilliseconds(aboveBestTime);

              if (currentMs > 0 && aboveMs > 0) {
                final diffMs = currentMs - aboveMs;
                intervalText = _formatMillisecondsToTime(diffMs);
              } else {
                intervalText = '';
              }
            } else {
              intervalText = '';
            }
          }
        } else {
          // Get interval to position ahead
          intervalText =
              timing.intervalToPositionAhead?.value ?? timing.gapToLeader;
        }

        // Parse team color
        Color teamColor;
        try {
          if (driver.teamColour.isNotEmpty && driver.teamColour.length == 6) {
            teamColor = Color(int.parse('0xFF${driver.teamColour}'));
          } else {
            teamColor = Colors.grey;
          }
        } catch (e) {
          print('Error parsing color: ${driver.teamColour} - $e');
          teamColor = Colors.grey;
        }

        // Get tire compound from timing app data if available
        String tireCompound = '';
        if (timingAppData.containsKey(racingNumber) &&
            timingAppData[racingNumber]!.stints.isNotEmpty) {
          tireCompound =
              timingAppData[racingNumber]!.stints.last.compound ?? '';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: DriverRowCard(
            key: ValueKey(racingNumber),
            position: driver.line,
            name: driver.tla.isNotEmpty ? driver.tla : '???',
            currentLapTime: timing.lastLapTime.value,
            bestLapTime: timing.bestLapTime.value,
            interval: intervalText,
            teamColor: teamColor,
            tireCompound: tireCompound,
            pitStops: timing.numberOfPitStops,
            positionChange: _positionChanges[racingNumber] ?? 'same',
            sessionType: sessionInfo.type,
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

  // Helper method to parse lap time string to milliseconds
  int _parseTimeToMilliseconds(String timeStr) {
    try {
      // Format: "1:23.456" or "m:ss.sss"
      final parts = timeStr.split(':');
      if (parts.length != 2) return 0;

      final minutes = int.parse(parts[0]);
      final secondParts = parts[1].split('.');
      if (secondParts.length != 2) return 0;

      final seconds = int.parse(secondParts[0]);
      final milliseconds = int.parse(secondParts[1]);

      return (minutes * 60 * 1000) + (seconds * 1000) + milliseconds;
    } catch (e) {
      return 0;
    }
  }

  // Helper method to format milliseconds to lap time string
  String _formatMillisecondsToTime(int ms) {
    try {
      if (ms < 0) {
        // Handle negative time difference (shouldn't happen in qualifying)
        return '';
      }

      final totalSeconds = ms ~/ 1000;
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      final milliseconds = ms % 1000;

      // Only show minutes if there are any
      if (minutes > 0) {
        return '+$minutes:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}';
      } else {
        return '+$seconds.${milliseconds.toString().padLeft(3, '0')}';
      }
    } catch (e) {
      return '';
    }
  }

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

// Live Track Map Widget that shows driver positions in real-time
class LiveTrackMapWidget extends StatefulWidget {
  final PositionData positionData;
  final Map<String, Driver> drivers;
  final String circuitShortName;

  const LiveTrackMapWidget({
    super.key,
    required this.positionData,
    required this.drivers,
    required this.circuitShortName,
  });

  @override
  State<LiveTrackMapWidget> createState() => _LiveTrackMapWidgetState();
}

class _LiveTrackMapWidgetState extends State<LiveTrackMapWidget> {
  List<Offset> _trackPoints = [];
  double? minX, maxX, minY, maxY;

  @override
  void initState() {
    super.initState();
    _loadTrack();
  }

  @override
  void didUpdateWidget(LiveTrackMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload track if circuit changes
    if (oldWidget.circuitShortName != widget.circuitShortName) {
      _loadTrack();
    }
  }

  Future<void> _loadTrack() async {
    try {
      // Map circuit names to track files
      final trackFile = _getTrackFile(widget.circuitShortName);
      if (trackFile == null) {
        print('Track file not found for circuit: ${widget.circuitShortName}');
        return;
      }

      final jsonStr =
          await rootBundle.loadString('assets/TrackMaps/$trackFile');
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
      if (points.isNotEmpty) {
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
    } catch (e) {
      print('Error loading track: $e');
    }
  }

  String? _getTrackFile(String circuitShortName) {
    // Map circuit short names to track JSON files
    final Map<String, String> trackFiles = {
      'Spielberg': 'Spielberg.json',
      'Silverstone': 'Silverstone.json',
      'Monaco': 'Monte-Carlo.json',
      'Hungaroring': 'Hungaroring.json',
      'Spa': 'Spa-Francorchamps.json',
      'Zandvoort': 'Zandvoort.json',
      'Monza': 'Monza.json',
      'Marina Bay': 'Singapore.json',
      'Suzuka': 'Suzuka.json',
      'COTA': 'Austin.json',
      'Mexico City': 'Mexico.json',
      'Interlagos': 'Interlagos.json',
      'Las Vegas': 'Las-Vegas.json',
      'Qatar': 'Losail.json',
      'Yas Marina': 'Yas-Marina.json',
      'Bahrain': 'Sakhir.json',
      'Jeddah': 'Jeddah.json',
      'Melbourne': 'Melbourne.json',
      'Imola': 'Imola.json',
      'Miami': 'Miami.json',
      'Barcelona': 'Catalunya.json',
      'Montreal': 'Montreal.json',
      'Baku': 'Baku.json',
      'Azerbaijan': 'Baku.json', // Add Azerbaijan mapping
      'Red Bull Ring': 'Spielberg.json',
      'Circuit de Spa-Francorchamps': 'Spa-Francorchamps.json',
      'Autodromo Nazionale di Monza': 'Monza.json',
      // Add more mappings as needed
    };

    print('Looking for track file for circuit: "$circuitShortName"');
    final trackFile = trackFiles[circuitShortName];
    if (trackFile != null) {
      print('Found track file: $trackFile');
    } else {
      print('No track file found for: "$circuitShortName"');
      print('Available circuits: ${trackFiles.keys.toList()}');
    }

    return trackFile;
  }

  // Normalizes a point to widget size
  Offset _normalize(Offset pt, double width, double height) {
    if (minX == null || maxX == null || minY == null || maxY == null)
      return Offset.zero;
    double normX = (pt.dx - minX!) / (maxX! - minX!);
    double normY = (pt.dy - minY!) / (maxY! - minY!);
    return Offset(normX * width, normY * height);
  }

  // Normalizes driver coordinates
  Offset _normalizeDriver(double x, double y, double width, double height) {
    if (minX == null || maxX == null || minY == null || maxY == null)
      return Offset.zero;
    double normX = (x - minX!) / (maxX! - minX!);
    double normY = (y - minY!) / (maxY! - minY!);
    return Offset(normX * width, normY * height);
  }

  @override
  Widget build(BuildContext context) {
    if (_trackPoints.isEmpty) {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _LiveTrackPainter(
            trackPoints: _trackPoints,
            positionData: widget.positionData,
            drivers: widget.drivers,
            normalize: _normalize,
            normalizeDriver: _normalizeDriver,
          ),
        );
      },
    );
  }
}

class _LiveTrackPainter extends CustomPainter {
  final List<Offset> trackPoints;
  final PositionData positionData;
  final Map<String, Driver> drivers;
  final Offset Function(Offset pt, double width, double height) normalize;
  final Offset Function(double x, double y, double width, double height)
      normalizeDriver;

  _LiveTrackPainter({
    required this.trackPoints,
    required this.positionData,
    required this.drivers,
    required this.normalize,
    required this.normalizeDriver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw track path
    if (trackPoints.isNotEmpty) {
      final path = Path()
        ..moveTo(
          normalize(trackPoints[0], size.width, size.height).dx,
          normalize(trackPoints[0], size.width, size.height).dy,
        );

      for (final pt in trackPoints.skip(1)) {
        final npt = normalize(pt, size.width, size.height);
        path.lineTo(npt.dx, npt.dy);
      }

      final trackPaint = Paint()
        ..color = Colors.grey.shade600
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, trackPaint);
    }

    // Draw drivers with team colours
    positionData.cars.forEach((racingNumber, carPosition) {
      final driver = drivers[racingNumber];
      if (driver == null) return;

      final Offset pos = normalizeDriver(
          carPosition.x, carPosition.y, size.width, size.height);

      // Parse team color
      Color teamColor;
      try {
        if (driver.teamColour.isNotEmpty && driver.teamColour.length == 6) {
          teamColor = Color(int.parse('0xFF${driver.teamColour}'));
        } else {
          teamColor = Colors.red;
        }
      } catch (e) {
        teamColor = Colors.red;
      }

      // Draw driver circle
      final paint = Paint()
        ..color = teamColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 6, paint);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pos, 6, borderPaint);

      // Draw driver TLA/number
      final textPainter = TextPainter(
        text: TextSpan(
          text: driver.tla.isNotEmpty ? driver.tla : racingNumber,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Position text above the driver circle
      textPainter.paint(canvas, pos + Offset(-textPainter.width / 2, -18));
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
