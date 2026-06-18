import 'dart:convert';
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:formulavision/data/services/app_settings_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formulavision/components/driver_row_card.dart';
import 'package:formulavision/components/race_control_toast.dart';
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

  // Race control message alerts
  final AudioPlayer _rcAudioPlayer = AudioPlayer();
  int _lastSeenRaceControlCount = 0;
  bool _raceControlSeeded = false;
  bool _raceControlSoundEnabled = true;

  // Track map display settings
  bool _trackMapEnabled = true;
  String _trackMapDisplayMode = AppSettings.trackMapModeCard;
  bool _trackMapExpanded = true; // Card-mode expand/collapse state

  // Debug-only: replay a recorded Position.z sample so the track map can be
  // verified offline. Overlays positions onto whatever base data is present
  // (live or simulated). Flip to true to enable.
  static const bool _debugTrackReplay = false;
  Timer? _replayTimer;
  List<dynamic> _replayFrames = [];
  int _replayIndex = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
    _loadRaceControlSoundSetting();
    _loadTrackMapSettings();
    _maybeStartTrackReplay();
    final data = decompressCarData();
    print(data);
  }

  Future<void> _maybeStartTrackReplay() async {
    if (!_debugTrackReplay) return;
    try {
      final jsonStr =
          await rootBundle.loadString('assets/test/position_replay.json');
      final data = jsonDecode(jsonStr);
      _replayFrames = (data['frames'] as List?) ?? [];
      final intervalMs = (data['frameIntervalMs'] as num?)?.toInt() ?? 250;
      if (_replayFrames.isEmpty) return;
      _replayTimer?.cancel();
      _replayTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
        if (!mounted || _replayFrames.isEmpty) return;
        final frame = _replayFrames[_replayIndex % _replayFrames.length];
        _replayIndex++;
        _updatePositionData(Map<String, dynamic>.from(frame as Map));
      });
    } catch (e) {
      print('Track replay failed: $e');
    }
  }

  Future<void> _loadRaceControlSoundSetting() async {
    final enabled = await AppSettings.isRaceControlSoundEnabled();
    if (mounted) {
      setState(() => _raceControlSoundEnabled = enabled);
    }
  }

  Future<void> _loadTrackMapSettings() async {
    final enabled = await AppSettings.isTrackMapEnabled();
    final mode = await AppSettings.getTrackMapDisplayMode();
    if (mounted) {
      setState(() {
        _trackMapEnabled = enabled;
        _trackMapDisplayMode = mode;
      });
    }
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
    _replayTimer?.cancel(); // Stop debug position replay if running
    _messageQueue.clear(); // Clear any queued messages
    _liveDataController.close(); // Close the StreamController
    _rcAudioPlayer.dispose(); // Release the alert audio player
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
      final apiUrl = await AppSettings.getApiUrl();
      final response = await http.get(
        Uri.parse('$apiUrl/initialData'),
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
          // Seed race control marker so historical messages don't toast.
          _lastSeenRaceControlCount =
              liveData.raceControlMessages?.messages.length ?? 0;
          _raceControlSeeded = true;
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
      final apiUrl = await AppSettings.getApiUrl();
      final response = await http.get(
        Uri.parse('$apiUrl/negotiate?simulation=$_useSimulation'),
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
      final apiUrl = await AppSettings.getApiUrl();
      final sseUrl =
          '$apiUrl/events${_useSimulation ? '?simulation=true' : ''}';
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

            // Position data arrives in object form:
            //   A[0] == { PositionData: { Entries: [...] } }
            if (messageObject['A'][0] is Map &&
                messageObject['A'][0].containsKey('PositionData')) {
              final positionData = messageObject['A'][0]['PositionData'];
              setState(() {
                _updatePositionData(positionData);
              });
              print('PositionData Updated Successfully from new format');
              continue;
            }

            // Car telemetry arrives in object form:
            //   A[0] == { CarData: { Timestamp, Cars: { "44": {...} } } }
            if (messageObject['A'][0] is Map &&
                messageObject['A'][0].containsKey('CarData')) {
              final carData = messageObject['A'][0]['CarData'];
              setState(() {
                _updateCarData(carData);
              });
              print('CarData Updated Successfully from new format');
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

                case 'TimingAppData':
                  setState(() {
                    _updateTimingAppData(updated);
                  });
                  print('TimingAppData Updated Successfully');
                  break;

                case 'RaceControlMessages':
                  setState(() {
                    _updateRaceControlMessages(updated);
                  });
                  print('RaceControlMessages Updated Successfully');
                  break;

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

                case 'PositionData':
                case 'Position.z':
                  setState(() {
                    _updatePositionData(updated);
                  });
                  print('PositionData Updated Successfully');
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

  /// Merges incoming sector data (List or index-keyed Map) into [sectors],
  /// preserving fields and segments that aren't present in the delta.
  void _mergeSectors(List<Sector> sectors, dynamic raw) {
    void applySector(int index, Map<String, dynamic> sjson) {
      final Sector? prev = index < sectors.length ? sectors[index] : null;
      final List<Segment> segments =
          prev != null ? List<Segment>.from(prev.segments) : <Segment>[];
      if (sjson.containsKey('Segments')) {
        _mergeSegments(segments, sjson['Segments']);
      }
      final merged = Sector(
        stopped: sjson['Stopped'] ?? prev?.stopped ?? false,
        value: sjson['Value'] ?? prev?.value ?? '',
        status: sjson['Status'] ?? prev?.status ?? 0,
        overallFastest: sjson['OverallFastest'] ?? prev?.overallFastest ?? false,
        personalFastest:
            sjson['PersonalFastest'] ?? prev?.personalFastest ?? false,
        previousValue: sjson['PreviousValue'] ?? prev?.previousValue ?? '',
        segments: segments,
      );
      if (index < sectors.length) {
        sectors[index] = merged;
      } else {
        while (sectors.length < index) {
          sectors.add(Sector(
            stopped: false,
            value: '',
            status: 0,
            overallFastest: false,
            personalFastest: false,
            segments: const [],
          ));
        }
        sectors.add(merged);
      }
    }

    if (raw is List) {
      for (int i = 0; i < raw.length; i++) {
        if (raw[i] is Map) applySector(i, Map<String, dynamic>.from(raw[i]));
      }
    } else if (raw is Map) {
      raw.forEach((k, v) {
        final idx = int.tryParse(k.toString());
        if (idx != null && v is Map) {
          applySector(idx, Map<String, dynamic>.from(v));
        }
      });
    }
  }

  /// Merges incoming segment data (List or index-keyed Map) into [segments].
  void _mergeSegments(List<Segment> segments, dynamic raw) {
    void applySegment(int index, Map<String, dynamic> sjson) {
      final status = sjson['Status'] ??
          (index < segments.length ? segments[index].status : 0);
      if (index < segments.length) {
        segments[index] = Segment(status: status);
      } else {
        while (segments.length < index) {
          segments.add(Segment(status: 0));
        }
        segments.add(Segment(status: status));
      }
    }

    if (raw is List) {
      for (int i = 0; i < raw.length; i++) {
        if (raw[i] is Map) applySegment(i, Map<String, dynamic>.from(raw[i]));
      }
    } else if (raw is Map) {
      raw.forEach((k, v) {
        final idx = int.tryParse(k.toString());
        if (idx != null && v is Map) {
          applySegment(idx, Map<String, dynamic>.from(v));
        }
      });
    }
  }

  /// Merges incoming TimingAppData (tyre stints) into the live data. The feed
  /// sends stints either as a List (snapshot) or a Map keyed by stint index
  /// (delta), so we merge by index to preserve prior stints.
  void _updateTimingAppData(dynamic data) {
    if (data is! Map<String, dynamic>) return;
    if (data.isEmpty || data['Lines'] is! Map) return;
    if (_liveDataFuture == null) return;

    _liveDataFuture = _liveDataFuture!.then((liveDataList) {
      if (liveDataList.isEmpty) return liveDataList;
      final currentLiveData = liveDataList[0];
      final Map<String, TimingAppDataDriver> currentLines =
          Map<String, TimingAppDataDriver>.from(
              currentLiveData.timingAppData?.lines ?? {});

      final linesData = data['Lines'] as Map<String, dynamic>;
      linesData.forEach((racingNumber, driverData) {
        if (driverData is! Map<String, dynamic>) return;
        final existing = currentLines[racingNumber];
        final List<Stint> mergedStints =
            existing != null ? List<Stint>.from(existing.stints) : <Stint>[];

        void applyStint(int index, Map<String, dynamic> sjson) {
          final prev = index < mergedStints.length ? mergedStints[index] : null;
          final merged = Stint(
            totalLaps: sjson['TotalLaps'] ?? prev?.totalLaps,
            compound: sjson['Compound'] ?? prev?.compound,
            isNew: sjson['New'] ?? prev?.isNew,
          );
          if (index < mergedStints.length) {
            mergedStints[index] = merged;
          } else {
            while (mergedStints.length < index) {
              mergedStints.add(Stint());
            }
            mergedStints.add(merged);
          }
        }

        final stintsRaw = driverData['Stints'];
        if (stintsRaw is List) {
          for (int i = 0; i < stintsRaw.length; i++) {
            if (stintsRaw[i] is Map) {
              applyStint(i, Map<String, dynamic>.from(stintsRaw[i]));
            }
          }
        } else if (stintsRaw is Map) {
          stintsRaw.forEach((k, v) {
            final idx = int.tryParse(k.toString());
            if (idx != null && v is Map) {
              applyStint(idx, Map<String, dynamic>.from(v));
            }
          });
        }

        currentLines[racingNumber] = TimingAppDataDriver(
          racingNumber: driverData['RacingNumber'] ??
              existing?.racingNumber ??
              racingNumber,
          stints: mergedStints,
          line: driverData['Line'] ?? existing?.line ?? 0,
          gridPos: driverData['GridPos'] ?? existing?.gridPos ?? '',
        );
      });

      currentLiveData.timingAppData = TimingAppData(lines: currentLines);
      return liveDataList;
    }).then((liveDataList) {
      if (!_liveDataController.isClosed) {
        _liveDataController.add(liveDataList);
      }
      return liveDataList;
    });
  }

  /// Merges incoming race control messages and triggers a toast (and, for
  /// important categories, the alert sound) for any newly-arrived message.
  void _updateRaceControlMessages(dynamic data) {
    if (data is! Map<String, dynamic>) return;
    final incoming = RaceControlMessages.fromJson(data);
    if (incoming.messages.isEmpty) return;
    if (_liveDataFuture == null) return;

    _liveDataFuture = _liveDataFuture!.then((liveDataList) {
      if (liveDataList.isEmpty) return liveDataList;
      final currentLiveData = liveDataList[0];
      final existing =
          currentLiveData.raceControlMessages?.messages ?? <Message>[];

      final List<Message> merged = List<Message>.from(existing);
      for (final m in incoming.messages) {
        final dup =
            merged.any((e) => e.utc == m.utc && e.message == m.message);
        if (!dup) merged.add(m);
      }
      currentLiveData.raceControlMessages =
          RaceControlMessages(messages: merged);

      if (!_raceControlSeeded) {
        _lastSeenRaceControlCount = merged.length;
        _raceControlSeeded = true;
      } else if (merged.length > _lastSeenRaceControlCount) {
        final newMessages = merged.sublist(_lastSeenRaceControlCount);
        _lastSeenRaceControlCount = merged.length;
        _alertRaceControl(newMessages);
      }
      return liveDataList;
    }).then((liveDataList) {
      if (!_liveDataController.isClosed) {
        _liveDataController.add(liveDataList);
      }
      return liveDataList;
    });
  }

  void _alertRaceControl(List<Message> messages) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    bool playSound = false;
    for (final m in messages) {
      messenger?.showSnackBar(RaceControlToast.buildSnackBar(m));
      if (RaceControlToast.isImportant(m)) playSound = true;
    }
    if (playSound && _raceControlSoundEnabled) {
      _playRaceControlSound();
    }
  }

  Future<void> _playRaceControlSound() async {
    try {
      await _rcAudioPlayer.stop();
      await _rcAudioPlayer.play(AssetSource('TeamRadioF1FX.wav'));
    } catch (e) {
      print('Error playing race control sound: $e');
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

                // Snapshot positions from the previous update cycle so that
                // _updatePositionChanges() compares this cycle against the last
                // (single source of truth = live timing position).
                _previousPositions = Map.from(_currentPositions);

                // Process each driver's timing data
                final linesData = data['Lines'] as Map<String, dynamic>;
                linesData.forEach((racingNumber, driverData) {
                  if (driverData is Map<String, dynamic>) {
                    // Create or update the driver's timing data
                    final currentDriverData = currentLines[racingNumber];

                    // Process sectors if available. The feed sends Sectors and
                    // their Segments either as a List (snapshot) or a Map keyed
                    // by index (delta), so we merge by index into the existing
                    // sectors/segments to preserve mini-sector progress.
                    List<Sector> updatedSectors = currentDriverData != null
                        ? List<Sector>.from(currentDriverData.sectors)
                        : <Sector>[];
                    if (driverData.containsKey('Sectors')) {
                      _mergeSectors(updatedSectors, driverData['Sectors']);
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

                    // Live timing position is the single source of truth for
                    // ordering. _previousPositions was snapshotted above, so we
                    // only write the new current position here.
                    final newLine =
                        driverData['Line'] ?? (currentDriverData?.line ?? 0);
                    _currentPositions[racingNumber] = newLine;

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

  /// Merge incoming car telemetry into the live data object, keyed by racing
  /// number, then re-emit so driver rows rebuild.
  void _updateCarData(dynamic data) {
    if (data is! Map) {
      print('Received non-map car data: ${data.runtimeType}, cannot update');
      return;
    }
    final cars = data['Cars'];
    if (cars is! Map || cars.isEmpty) return;

    setState(() {
      if (_liveDataFuture != null) {
        _liveDataFuture = _liveDataFuture!.then((liveDataList) {
          if (liveDataList.isNotEmpty) {
            final currentLiveData = liveDataList[0];
            final updated =
                Map<String, CarTelemetry>.from(currentLiveData.carData);
            cars.forEach((racingNumber, channels) {
              if (channels is Map) {
                updated[racingNumber.toString()] = CarTelemetry.fromJson(
                    Map<String, dynamic>.from(channels));
              }
            });
            currentLiveData.carData = updated;
          }
          return liveDataList;
        }).then((liveDataList) {
          if (!_liveDataController.isClosed) {
            _liveDataController.add(liveDataList);
          }
          return liveDataList;
        });
      }
    });
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

  // Track outline colour: neutral grey when the track is clear, otherwise the
  // status colour (yellow / safety car / red / VSC).
  Color _trackLineColor(String? status) {
    if (status == null ||
        status == '1' ||
        status.toLowerCase() == 'track clear') {
      return Colors.grey.shade500;
    }
    return _getTrackStatusColor(status);
  }

  // The live track map, fed by its own stream subscription so high-frequency
  // Position.z updates repaint just the map.
  Widget _buildLiveMap(LiveData fallback) {
    return StreamBuilder<List<LiveData>>(
      stream: liveDataStream,
      initialData: [fallback],
      builder: (context, snapshot) {
        final data = (snapshot.hasData && snapshot.data!.isNotEmpty)
            ? snapshot.data![0]
            : fallback;
        final positionData = data.positionData;
        if (positionData == null || positionData.cars.isEmpty) {
          return const Center(
            child: Text(
              'Waiting for car positions…',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        return LiveTrackMapWidget(
          positionData: positionData,
          drivers: data.driverList?.drivers ?? {},
          circuitShortName: data.sessionInfo?.meeting.circuit.shortName ?? '',
          trackColor: _trackLineColor(data.trackStatus?.status),
        );
      },
    );
  }

  // Collapsible inline track-map card (card display mode).
  Widget _buildTrackMapCard(LiveData data) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _trackMapExpanded = !_trackMapExpanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined,
                      color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Track Map',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Icon(
                    _trackMapExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: _buildLiveMap(data),
              ),
            ),
            crossFadeState: _trackMapExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // Schedule-page-style pill tab bar used by the full-view track map mode.
  Widget _buildTrackMapTabBar() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.white.withValues(alpha: 0.4),
              Colors.white.withValues(alpha: 0.8),
              Colors.white.withValues(alpha: 0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: TabBar(
            labelColor: Colors.white,
            dividerColor: Colors.transparent,
            tabAlignment: TabAlignment.center,
            padding: EdgeInsets.zero,
            unselectedLabelColor: Colors.redAccent,
            indicator: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(30.0),
            ),
            labelPadding: EdgeInsets.zero,
            tabs: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Tab(
                  child: Text('DRIVERS',
                      style: TextStyle(fontFamily: 'formula-bold')),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Tab(
                  child: Text('TRACK MAP',
                      style: TextStyle(fontFamily: 'formula-bold')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the weather + drivers list section reused by both display modes.
  Widget _buildDriversSection(List<LiveData> liveData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeatherCard(liveData[0].weatherData!),
        const SizedBox(height: 10),
        const Text('Drivers',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        _buildDriverList(
          liveData[0].driverList!.drivers,
          liveData[0].timingData!.lines,
          liveData[0].timingAppData?.lines ?? {},
          liveData[0].sessionInfo!,
          liveData[0].carData,
        ),
      ],
    );
  }

  // Main dashboard content: switches between the inline card and the
  // dedicated tabbed full-view based on the user's track-map settings.
  Widget _buildDashboardMainContent(List<LiveData> liveData) {
    final data = liveData[0];

    if (_trackMapEnabled &&
        _trackMapDisplayMode == AppSettings.trackMapModeFullView) {
      final height = MediaQuery.of(context).size.height * 0.72;
      return SizedBox(
        height: height,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              _buildTrackMapTabBar(),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      child: _buildDriversSection(liveData),
                    ),
                    _buildLiveMap(data),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Card mode (or map disabled).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildWeatherCard(data.weatherData!),
        const SizedBox(height: 10),
        if (_trackMapEnabled) ...[
          _buildTrackMapCard(data),
          const SizedBox(height: 10),
        ],
        const Text('Drivers',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        _buildDriverList(
          data.driverList!.drivers,
          data.timingData!.lines,
          data.timingAppData?.lines ?? {},
          data.sessionInfo!,
          data.carData,
        ),
      ],
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
                                              return _buildDashboardMainContent(
                                                  liveData);
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
      SessionInfo sessionInfo,
      Map<String, CarTelemetry> carData) {
    // Sort drivers by line number (current race position)
    List<MapEntry<String, Driver>> sortedDrivers = drivers.entries.toList()
      ..sort((a, b) => (_currentPositions[a.key] ?? a.value.line)
          .compareTo(_currentPositions[b.key] ?? b.value.line));

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

        // Live position is the single source of truth for ordering/labels.
        final int livePos = _currentPositions[racingNumber] ?? driver.line;

        // Get interval value with proper handling based on position, not index
        String intervalText = "";
        if (livePos == 1) {
          // Leader (show LEADER instead of interval)
          intervalText = "Leader";
        } else if (sessionInfo.type.toLowerCase() == 'qualifying') {
          // For qualifying: Calculate time difference from driver above
          final driverAbovePosition = livePos - 1;
          MapEntry<String, Driver>? driverAbove;

          for (var entry in sortedDrivers) {
            final entryPos =
                _currentPositions[entry.key] ?? entry.value.line;
            if (entryPos == driverAbovePosition) {
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

        // Get tyre/stint info from timing app data if available
        String tireCompound = '';
        int stintLaps = 0;
        bool isNewTyre = true;
        List<Stint> stints = const [];
        if (timingAppData.containsKey(racingNumber) &&
            timingAppData[racingNumber]!.stints.isNotEmpty) {
          stints = timingAppData[racingNumber]!.stints;
          final currentStint = stints.last;
          tireCompound = currentStint.compound ?? '';
          stintLaps = currentStint.totalLaps ?? 0;
          isNewTyre = (currentStint.isNew ?? 'true').toLowerCase() == 'true';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: DriverRowCard(
            key: ValueKey(racingNumber),
            position: _currentPositions[racingNumber] ?? driver.line,
            name: driver.tla.isNotEmpty ? driver.tla : '???',
            currentLapTime: timing.lastLapTime.value,
            bestLapTime: timing.bestLapTime.value,
            interval: intervalText,
            teamColor: teamColor,
            tireCompound: tireCompound,
            pitStops: timing.numberOfPitStops,
            positionChange: _positionChanges[racingNumber] ?? 'same',
            sessionType: sessionInfo.type,
            stintLaps: stintLaps,
            isNewTyre: isNewTyre,
            stints: stints,
            sectors: timing.sectors,
            telemetry: carData[racingNumber],
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

// Live Track Map Widget that shows driver positions in real-time.
//
// Cars are interpolated between successive Position.z updates so they glide
// rather than jump, the track is drawn aspect-correct with the Y axis flipped
// to a conventional orientation, the outline is tinted by track status, and
// off-track / pitting cars are dimmed.
class LiveTrackMapWidget extends StatefulWidget {
  final PositionData positionData;
  final Map<String, Driver> drivers;
  final String circuitShortName;
  final Color trackColor;

  const LiveTrackMapWidget({
    super.key,
    required this.positionData,
    required this.drivers,
    required this.circuitShortName,
    this.trackColor = const Color(0xFF9E9E9E),
  });

  @override
  State<LiveTrackMapWidget> createState() => _LiveTrackMapWidgetState();
}

class _LiveTrackMapWidgetState extends State<LiveTrackMapWidget>
    with SingleTickerProviderStateMixin {
  List<Offset> _trackPoints = [];
  double? minX, maxX, minY, maxY;
  // Rotation (from the track JSON) applied to both the outline and the cars so
  // the circuit is shown in a conventional orientation.
  double _rotationRad = 0;
  Offset _rotCenter = Offset.zero;

  late final AnimationController _controller;

  // Rotates [p] around [center] by [rad] radians.
  static Offset rotateAround(Offset p, Offset center, double rad) {
    if (rad == 0) return p;
    final dx = p.dx - center.dx;
    final dy = p.dy - center.dy;
    final cos = math.cos(rad);
    final sin = math.sin(rad);
    return Offset(
      center.dx + dx * cos - dy * sin,
      center.dy + dx * sin + dy * cos,
    );
  }
  // Interpolation endpoints keyed by racing number.
  Map<String, Offset> _fromPositions = {};
  Map<String, Offset> _toPositions = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _toPositions = _extractPositions(widget.positionData);
    _fromPositions = Map.of(_toPositions);
    _controller.value = 1.0;
    _loadTrack();
  }

  @override
  void didUpdateWidget(LiveTrackMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload track if circuit changes
    if (oldWidget.circuitShortName != widget.circuitShortName) {
      _loadTrack();
    }

    final newPositions = _extractPositions(widget.positionData);
    if (!_positionsEqual(newPositions, _toPositions)) {
      // Whatever is currently on screen becomes the start of the next tween.
      _fromPositions = _currentPositions();
      _toPositions = newPositions;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, Offset> _extractPositions(PositionData data) {
    final Map<String, Offset> result = {};
    data.cars.forEach((number, car) {
      result[number] = Offset(car.x, car.y);
    });
    return result;
  }

  bool _positionsEqual(Map<String, Offset> a, Map<String, Offset> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null) return false;
      if ((other.dx - entry.value.dx).abs() > 0.5 ||
          (other.dy - entry.value.dy).abs() > 0.5) {
        return false;
      }
    }
    return true;
  }

  // Positions as currently rendered (lerp at the controller's current value).
  Map<String, Offset> _currentPositions() {
    final t = _controller.value;
    final Map<String, Offset> result = {};
    final keys = {..._fromPositions.keys, ..._toPositions.keys};
    for (final key in keys) {
      final from = _fromPositions[key];
      final to = _toPositions[key];
      if (from != null && to != null) {
        result[key] = Offset.lerp(from, to, t)!;
      } else {
        result[key] = (to ?? from)!;
      }
    }
    return result;
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

      // Parse x and y arrays plus the circuit's rotation (degrees).
      final List xList = jsonData['x'];
      final List yList = jsonData['y'];
      final double rotationDeg =
          (jsonData['rotation'] as num?)?.toDouble() ?? 0.0;

      List<Offset> rawPoints = [];
      for (int i = 0; i < xList.length && i < yList.length; i++) {
        rawPoints.add(
            Offset((xList[i] as num).toDouble(), (yList[i] as num).toDouble()));
      }

      if (rawPoints.isNotEmpty) {
        final double rotationRad = rotationDeg * math.pi / 180.0;
        // Rotate around the raw centre; the cars are later rotated about the
        // same point so they stay aligned with the outline.
        final rMinX = rawPoints.map((e) => e.dx).reduce((a, b) => math.min(a, b));
        final rMaxX = rawPoints.map((e) => e.dx).reduce((a, b) => math.max(a, b));
        final rMinY = rawPoints.map((e) => e.dy).reduce((a, b) => math.min(a, b));
        final rMaxY = rawPoints.map((e) => e.dy).reduce((a, b) => math.max(a, b));
        final center = Offset((rMinX + rMaxX) / 2, (rMinY + rMaxY) / 2);

        final rotated = rawPoints
            .map((p) => rotateAround(p, center, rotationRad))
            .toList();

        double minX = rotated.map((e) => e.dx).reduce((a, b) => math.min(a, b));
        double maxX = rotated.map((e) => e.dx).reduce((a, b) => math.max(a, b));
        double minY = rotated.map((e) => e.dy).reduce((a, b) => math.min(a, b));
        double maxY = rotated.map((e) => e.dy).reduce((a, b) => math.max(a, b));

        if (mounted) {
          setState(() {
            _trackPoints = rotated;
            _rotationRad = rotationRad;
            _rotCenter = center;
            this.minX = minX;
            this.maxX = maxX;
            this.minY = minY;
            this.maxY = maxY;
          });
        }
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
            bounds: Rect.fromLTRB(minX!, minY!, maxX!, maxY!),
            rotationRad: _rotationRad,
            rotCenter: _rotCenter,
            drivers: widget.drivers,
            statuses: {
              for (final e in widget.positionData.cars.entries)
                e.key: e.value.status,
            },
            fromPositions: _fromPositions,
            toPositions: _toPositions,
            trackColor: widget.trackColor,
            animation: _controller,
          ),
        );
      },
    );
  }
}

class _LiveTrackPainter extends CustomPainter {
  final List<Offset> trackPoints;
  final Rect bounds;
  final double rotationRad;
  final Offset rotCenter;
  final Map<String, Driver> drivers;
  final Map<String, String> statuses;
  final Map<String, Offset> fromPositions;
  final Map<String, Offset> toPositions;
  final Color trackColor;
  final Animation<double> animation;

  _LiveTrackPainter({
    required this.trackPoints,
    required this.bounds,
    required this.rotationRad,
    required this.rotCenter,
    required this.drivers,
    required this.statuses,
    required this.fromPositions,
    required this.toPositions,
    required this.trackColor,
    required this.animation,
  }) : super(repaint: animation);

  static const double _pad = 18.0;

  // Projects a track-space point into canvas space: uniform scale to preserve
  // aspect ratio, centered, with the Y axis flipped (track is y-up, canvas is
  // y-down). The same transform is applied to the outline and the cars so they
  // stay aligned.
  Offset _project(Offset p, Size size) {
    final spanX = bounds.width.abs() < 1e-6 ? 1.0 : bounds.width;
    final spanY = bounds.height.abs() < 1e-6 ? 1.0 : bounds.height;
    final availW = math.max(1.0, size.width - _pad * 2);
    final availH = math.max(1.0, size.height - _pad * 2);
    final scale = math.min(availW / spanX, availH / spanY);
    final drawnW = spanX * scale;
    final drawnH = spanY * scale;
    final originX = _pad + (availW - drawnW) / 2;
    final originY = _pad + (availH - drawnH) / 2;
    final x = originX + (p.dx - bounds.left) * scale;
    final y = originY + (bounds.bottom - p.dy) * scale;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Track outline: dark base stroke + status-tinted line on top.
    if (trackPoints.isNotEmpty) {
      final path = Path();
      final first = _project(trackPoints.first, size);
      path.moveTo(first.dx, first.dy);
      for (final pt in trackPoints.skip(1)) {
        final p = _project(pt, size);
        path.lineTo(p.dx, p.dy);
      }
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withOpacity(0.45)
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = trackColor
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    // Cars, interpolated between the previous and latest positions.
    final t = animation.value;
    final keys = {...fromPositions.keys, ...toPositions.keys};
    for (final number in keys) {
      final from = fromPositions[number];
      final to = toPositions[number];
      final Offset? raw = (from != null && to != null)
          ? Offset.lerp(from, to, t)
          : (to ?? from);
      if (raw == null) continue;

      final driver = drivers[number];
      final pos = _project(
        _LiveTrackMapWidgetState.rotateAround(raw, rotCenter, rotationRad),
        size,
      );

      Color teamColor = Colors.red;
      final tc = driver?.teamColour;
      if (tc != null && tc.isNotEmpty && tc.length == 6) {
        try {
          teamColor = Color(int.parse('0xFF$tc'));
        } catch (_) {
          teamColor = Colors.red;
        }
      }

      // Dim cars that are not actively on track (pits, retired, off track).
      final onTrack = (statuses[number] ?? 'OnTrack') == 'OnTrack';
      final opacity = onTrack ? 1.0 : 0.3;

      canvas.drawCircle(
        pos,
        6,
        Paint()
          ..color = teamColor.withOpacity(opacity)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        pos,
        6,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );

      final label = (driver?.tla.isNotEmpty ?? false) ? driver!.tla : number;
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white.withOpacity(opacity),
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, pos + Offset(-textPainter.width / 2, -18));
    }
  }

  @override
  bool shouldRepaint(covariant _LiveTrackPainter oldDelegate) {
    return oldDelegate.trackPoints != trackPoints ||
        oldDelegate.toPositions != toPositions ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.bounds != bounds;
  }
}
