import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class F1LiveTimingService {
  // Stream controllers to broadcast different types of data
  final _timingDataController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _telemetryDataController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _carDataController = StreamController<Map<String, dynamic>>.broadcast();
  final _positionDataController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<String>.broadcast();

  // Timers
  Timer? _pollingTimer;
  Timer? _mockDataTimer;
  final Random _random = Random();

  // Connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Backend configuration
  final String _apiBaseUrl = 'http://10.0.2.2:8000';
  bool _useMockData = false;

  // Mock data - driver information
  final List<Map<String, dynamic>> _drivers = [
    {'number': '1', 'name': 'Max Verstappen', 'team': 'Red Bull Racing'},
    {'number': '11', 'name': 'Sergio Perez', 'team': 'Red Bull Racing'},
    {'number': '16', 'name': 'Charles Leclerc', 'team': 'Ferrari'},
    {'number': '55', 'name': 'Carlos Sainz', 'team': 'Ferrari'},
    {'number': '44', 'name': 'Lewis Hamilton', 'team': 'Mercedes'},
    {'number': '63', 'name': 'George Russell', 'team': 'Mercedes'},
    {'number': '4', 'name': 'Lando Norris', 'team': 'McLaren'},
    {'number': '81', 'name': 'Oscar Piastri', 'team': 'McLaren'},
    {'number': '14', 'name': 'Fernando Alonso', 'team': 'Aston Martin'},
    {'number': '18', 'name': 'Lance Stroll', 'team': 'Aston Martin'},
    {'number': '23', 'name': 'Alexander Albon', 'team': 'Williams'},
    {'number': '2', 'name': 'Logan Sargeant', 'team': 'Williams'},
    {'number': '10', 'name': 'Pierre Gasly', 'team': 'Alpine'},
    {'number': '31', 'name': 'Esteban Ocon', 'team': 'Alpine'},
    {'number': '77', 'name': 'Valtteri Bottas', 'team': 'Sauber'},
    {'number': '24', 'name': 'Zhou Guanyu', 'team': 'Sauber'},
    {'number': '22', 'name': 'Yuki Tsunoda', 'team': 'VCARB'},
    {'number': '3', 'name': 'Daniel Ricciardo', 'team': 'VCARB'},
    {'number': '20', 'name': 'Kevin Magnussen', 'team': 'Haas F1 Team'},
    {'number': '27', 'name': 'Nico Hulkenberg', 'team': 'Haas F1 Team'},
  ];

  // Streams that the UI can listen to
  Stream<Map<String, dynamic>> get timingData => _timingDataController.stream;
  Stream<Map<String, dynamic>> get telemetryData =>
      _telemetryDataController.stream;
  Stream<Map<String, dynamic>> get carData => _carDataController.stream;
  Stream<Map<String, dynamic>> get positionData =>
      _positionDataController.stream;
  Stream<String> get connectionStatus => _connectionStatusController.stream;

  Future<void> initialize({bool useMockData = false}) async {
    try {
      _useMockData = useMockData;

      if (_useMockData) {
        _updateConnectionStatus('Initializing with mock F1 data...');
        _isConnected = true;
        _updateConnectionStatus('Connected to mock F1 data service');

        // Start mock data generation
        _startMockDataGeneration();
      } else {
        _updateConnectionStatus('Connecting to FastF1 backend...');

        // Try to connect to the Python backend
        try {
          // Start the backend service
          final startResponse = await http.get(Uri.parse('$_apiBaseUrl/start'),
              headers: {
                'Content-Type': 'application/json'
              }).timeout(const Duration(seconds: 5));

          if (startResponse.statusCode == 200) {
            _updateConnectionStatus('Connected to FastF1 backend');
            _isConnected = true;

            // Diagnostics
            await _diagnoseBackendConnection();

            // Start polling for data
            _startPolling();
          } else {
            throw Exception(
                'Failed to start backend service: ${startResponse.statusCode}');
          }
        } catch (e) {
          debugPrint('Failed to connect to Python backend: $e');

          // Fall back to mock data
          _useMockData = true;
          _updateConnectionStatus('Falling back to mock data: $e');
          _startMockDataGeneration();
        }
      }
    } catch (e) {
      _isConnected = false;
      _updateConnectionStatus('Connection failed: $e');
      debugPrint('Error initializing F1 LiveTiming service: $e');
      rethrow;
    }
  }

  void _updateConnectionStatus(String status) {
    debugPrint('F1 LiveTiming: $status');
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(status);
    }
  }

  // PYTHON BACKEND METHODS

  void _startPolling() {
    // Cancel existing timer if any
    _pollingTimer?.cancel();
    _mockDataTimer?.cancel();

    // Poll every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchData();
    });

    // Initial fetch
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch all data in one request to minimize network calls
      final response = await http.get(Uri.parse('$_apiBaseUrl/all'), headers: {
        'Content-Type': 'application/json'
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final allData = json.decode(response.body);

        // Distribute data to the appropriate streams
        if (allData.containsKey('timing') &&
            allData['timing'] is Map<String, dynamic>) {
          _timingDataController.add(allData['timing']);
        }

        if (allData.containsKey('telemetry') &&
            allData['telemetry'] is Map<String, dynamic>) {
          _telemetryDataController.add(allData['telemetry']);
          _carDataController
              .add(allData['telemetry']); // Car data is part of telemetry
        }

        if (allData.containsKey('position') &&
            allData['position'] is Map<String, dynamic>) {
          _positionDataController.add(allData['position']);
        }
      } else {
        debugPrint('Error fetching data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      // If we've lost connection, try to switch to mock data
      if (_isConnected && !_useMockData) {
        _updateConnectionStatus(
            'Lost connection to backend, switching to mock data');
        _useMockData = true;
        _startMockDataGeneration();
      }
    }
  }

  Future<void> _diagnoseBackendConnection() async {
    try {
      // Check if backend is returning data
      final response = await http.get(Uri.parse('$_apiBaseUrl/all'),
          headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check data structure
        if (data is Map<String, dynamic>) {
          debugPrint('Backend connection diagnostic:');
          debugPrint('- Response status code: ${response.statusCode}');
          debugPrint('- Contains timing data: ${data.containsKey('timing')}');
          debugPrint(
              '- Contains telemetry data: ${data.containsKey('telemetry')}');
          debugPrint(
              '- Contains position data: ${data.containsKey('position')}');

          // Check if data is empty
          final hasEmptyData = (!data.containsKey('timing') ||
                  data['timing'] is! Map ||
                  (data['timing'] as Map).isEmpty) &&
              (!data.containsKey('telemetry') ||
                  data['telemetry'] is! Map ||
                  (data['telemetry'] as Map).isEmpty) &&
              (!data.containsKey('position') ||
                  data['position'] is! Map ||
                  (data['position'] as Map).isEmpty);

          if (hasEmptyData) {
            debugPrint('WARNING: Backend returned empty data structure');
          }
        } else {
          debugPrint('WARNING: Backend did not return a valid JSON object');
        }
      } else {
        debugPrint('Backend diagnostics failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Backend diagnostics error: $e');
    }
  }

  // MOCK DATA METHODS

  void _startMockDataGeneration() {
    // Cancel existing timers
    _pollingTimer?.cancel();
    _mockDataTimer?.cancel();

    // Generate mock data every 2 seconds
    _mockDataTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _generateMockData();
    });

    // Initial generation
    _generateMockData();
  }

  void _generateMockData() {
    _generateMockTimingData();
    _generateMockPositionData();
    _generateMockTelemetryData();
  }

  void _generateMockTimingData() {
    final Map<String, dynamic> timingData = {
      'SessionStatus': 'Active',
      'SessionInfo': {
        'Type': 'Race',
        'Name': 'Formula 1 Grand Prix',
        'Track': 'Circuit of the Americas',
        'TrackStatus': 'Clear',
        'AirTemp': 25 + _random.nextInt(5),
        'TrackTemp': 35 + _random.nextInt(10),
        'CurrentLap': _random.nextInt(50) + 1,
        'TotalLaps': 58,
      }
    };

    // Generate timing data for each driver
    for (final driver in _drivers) {
      final driverNumber = driver['number'];
      final position = _drivers.indexOf(driver) + 1;

      // Realistic lap times (90-95 seconds)
      final lapTime = 90.0 + _random.nextDouble() * 5.0;
      final bestLapTime = lapTime - (_random.nextDouble() * 2.0);

      timingData[driverNumber] = {
        'DriverNumber': driverNumber,
        'DriverName': driver['name'],
        'TeamName': driver['team'],
        'Position': position,
        'LastLapTime': lapTime.toStringAsFixed(3),
        'BestLapTime': bestLapTime.toStringAsFixed(3),
        'GapToLeader': position == 1
            ? '0.000'
            : (position * (_random.nextDouble() * 1.2 + 0.5))
                .toStringAsFixed(3),
        'IntervalToPositionAhead': position == 1
            ? null
            : (_random.nextDouble() * 2.0).toStringAsFixed(3),
        'Sector1Time': (30.0 + _random.nextDouble() * 2.0).toStringAsFixed(3),
        'Sector2Time': (35.0 + _random.nextDouble() * 2.0).toStringAsFixed(3),
        'Sector3Time': (25.0 + _random.nextDouble() * 2.0).toStringAsFixed(3),
        'InPit': _random.nextInt(20) == 0, // 5% chance of being in pit
        'PitCount': _random.nextInt(3),
        'Retired': false,
        'Laps': _random.nextInt(50) + 1,
      };
    }

    _timingDataController.add(timingData);
  }

  void _generateMockPositionData() {
    final Map<String, dynamic> positionData = {};

    // Define track bounds (simplified oval)
    const trackLength = 5000.0; // 5km track
    const trackWidth = 15.0;

    // Generate position data for each driver
    for (int i = 0; i < _drivers.length; i++) {
      final driver = _drivers[i];
      final driverNumber = driver['number'];

      // Distribute drivers around the track based on position
      final progress = (i / _drivers.length) * 2 * pi;
      final angularVariation =
          _random.nextDouble() * 0.1 - 0.05; // Small random variation

      // Calculate x,y position on an oval track
      final angle = progress + angularVariation;
      final baseRadius = 800.0; // Base radius of the oval
      final ovalFactor = 1.5; // Makes it more oval than circular

      final x = baseRadius * ovalFactor * cos(angle);
      final y = baseRadius * sin(angle);

      // Add small random variations to simulate car movement
      final xVar = _random.nextDouble() * 20 - 10;
      final yVar = _random.nextDouble() * 20 - 10;

      positionData[driverNumber] = {
        'X': x + xVar,
        'Y': y + yVar,
        'Z': 0.0,
        'Status': _random.nextInt(20) == 0 ? 'PitLane' : 'OnTrack',
        'Speed': 100 + _random.nextInt(220), // 100-320 km/h
        'DriverNumber': driverNumber,
        'Date': DateTime.now().toIso8601String(),
      };
    }

    _positionDataController.add(positionData);
  }

  void _generateMockTelemetryData() {
    final Map<String, dynamic> telemetryData = {};

    // Number of data points in the telemetry arrays
    const dataPoints = 20;

    // Generate telemetry data for each driver
    for (var driver in _drivers) {
      final driverNumber = driver['number'];

      // Create arrays for telemetry series
      final List<num> speeds = [];
      final List<num> rpms = [];
      final List<num> gears = [];
      final List<num> throttles = [];
      final List<num> brakes = [];
      final List<num> drs = [];
      final List<String> times = [];

      // Base speed with some randomness for this driver
      final baseSpeed = 100 + _random.nextInt(150);

      // Generate data points with trends (not just random values)
      for (int i = 0; i < dataPoints; i++) {
        final timeOffset = dataPoints - i;
        final timestamp =
            DateTime.now().subtract(Duration(milliseconds: timeOffset * 100));

        // Use trigonometric functions to simulate more realistic patterns
        final speedFactor =
            sin(i / (dataPoints / 3) * pi) * 80; // Create a wave pattern
        final speed = (baseSpeed + speedFactor).clamp(80, 340).toDouble();
        speeds.add(speed.round());

        // RPM correlates with speed
        rpms.add(((speed / 340 * 12000) + (_random.nextDouble() * 500 - 250))
            .round()
            .clamp(6000, 12000));

        // Gear based on speed ranges
        int gear;
        if (speed < 100)
          gear = 1;
        else if (speed < 140)
          gear = 2;
        else if (speed < 180)
          gear = 3;
        else if (speed < 220)
          gear = 4;
        else if (speed < 260)
          gear = 5;
        else if (speed < 300)
          gear = 6;
        else if (speed < 330)
          gear = 7;
        else
          gear = 8;

        // Add some gear variation
        if (_random.nextInt(10) == 0) {
          gear = (gear + (_random.nextBool() ? 1 : -1)).clamp(1, 8);
        }
        gears.add(gear);

        // Throttle and brake are inversely related and follow speed trends
        final deceleration = i > 0 ? speeds[i - 1] - speed : 0;
        double throttleValue;
        double brakeValue;

        if (deceleration > 5) {
          // Braking
          throttleValue = (_random.nextDouble() * 20).roundToDouble();
          brakeValue = (80 + _random.nextDouble() * 20).roundToDouble();
        } else if (deceleration > 0) {
          // Coasting
          throttleValue = (_random.nextDouble() * 50).roundToDouble();
          brakeValue = (_random.nextDouble() * 30).roundToDouble();
        } else {
          // Accelerating
          throttleValue = (80 + _random.nextDouble() * 20).roundToDouble();
          brakeValue = (_random.nextDouble() * 10).roundToDouble();
        }

        throttles.add(throttleValue.round());
        brakes.add(brakeValue.round());

        // DRS based on speed and random activation
        drs.add(speed > 260 && _random.nextInt(5) > 3 ? 1 : 0);

        // Timestamps
        times.add(timestamp.toIso8601String());
      }

      telemetryData[driverNumber] = {
        'Speed': speeds,
        'RPM': rpms,
        'nGear': gears,
        'Throttle': throttles,
        'Brake': brakes,
        'DRS': drs,
        'Time': times,
        'DriverNumber': driverNumber,
      };
    }

    _telemetryDataController.add(telemetryData);
    _carDataController.add(telemetryData);
  }

  // Dispose method to clean up resources
  void dispose() async {
    // Stop the backend service if we're using the Python backend
    if (!_useMockData) {
      try {
        await http
            .get(Uri.parse('$_apiBaseUrl/stop'))
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('Error stopping backend service: $e');
      }
    }

    // Cancel all timers
    _pollingTimer?.cancel();
    _mockDataTimer?.cancel();

    // Close all stream controllers
    _timingDataController.close();
    _telemetryDataController.close();
    _carDataController.close();
    _positionDataController.close();
    _connectionStatusController.close();
  }
}
