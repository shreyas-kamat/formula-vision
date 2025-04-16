import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formulavision/data/functions/live_data.function.dart';
import 'package:formulavision/data/models/live_data.model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1 Live Telemetry',
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

  // Server URL - update this with your server address
  final String _serverUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  @override
  void dispose() {
    _disconnectFromServer();
    super.dispose();
  }

  Future<void> fetchInitialData() async {
    setState(() {
      _connectionStatus = "Fetching initial data...";
      _errorMessage = "";
    });

    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/initialData'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Initial: $data');
        // Check if data contains SessionInfo
        setState(() {
          _liveDataFuture = fetchLiveData(data);
        });
        if (data.containsKey('SessionInfo')) {
          setState(() {
            _sessionInfoFuture = fetchSessionInfo(data['SessionInfo']);
          });
        }

        // Check if data contains WeatherData
        if (data.containsKey('WeatherData')) {
          setState(() {
            _weatherDataFuture = fetchWeatherData(data['WeatherData']);
          });
        }

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
      _connectionStatus = "Connecting...";
      _errorMessage = "";
    });

    try {
      // Negotiate connection with simulation parameter
      final response = await http.get(
        Uri.parse('$_serverUrl/negotiate?simulation=${_useSimulation}'),
      );

      if (response.statusCode == 200) {
        // Connect to either WebSocket or SSE based on _useSSE flag
        if (_useSSE) {
          await _connectSSE();
        } else {
          await _connectWebSocket();
        }
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
          '$_serverUrl/events${_useSimulation ? '?simulation=true' : ''}';
      print('Connecting to SSE endpoint: $sseUrl');

      // Create a client that doesn't automatically close the connection
      final client = http.Client();

      // Connect to the SSE endpoint with appropriate headers
      final request = http.Request('GET', Uri.parse(sseUrl));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        throw Exception(
            'Failed to connect to SSE endpoint: ${streamedResponse.statusCode}');
      }

      setState(() {
        _isConnected = true;
        _connectionStatus = _useSimulation
            ? "Connected SSE (Simulation)"
            : "Connected SSE (Live)";
      });

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
          setState(() {
            _isConnected = false;
            _connectionStatus = "SSE connection error";
            _errorMessage = error.toString();
          });
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

  Future<void> _connectWebSocket() async {
    try {
      // Connect to our server's WebSocket endpoint
      final wsUrl =
          'ws://${Uri.parse(_serverUrl).host}:${Uri.parse(_serverUrl).port}/';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      setState(() {
        _isConnected = true;
        _connectionStatus = _useSimulation
            ? "Connected WS (Simulation)"
            : "Connected WS (Live)";
      });

      // Subscribe to F1 data streams
      _channel!.sink.add(jsonEncode({
        "H": "Streaming",
        "M": "Subscribe",
        "A": [
          ["WeatherData", "SessionInfo"]
        ],
        "I": 1
      }));

      // Listen for messages
      _channel!.stream.listen(
        (message) {
          // Don't wrap this in setState - we'll do it inside processTelemetryData
          _messageCount++;
          try {
            print('Received WS message: $message');
            final data = jsonDecode(message);
            _processTelemetryData(data);
          } catch (e) {
            print("Error processing WS message: $e");
            setState(() {}); // Just update the message count
          }
        },
        onError: (error) {
          setState(() {
            _isConnected = false;
            _connectionStatus = "WebSocket error";
            _errorMessage = error.toString();
          });
        },
        onDone: () {
          setState(() {
            _isConnected = false;
            _connectionStatus = "WebSocket disconnected";
          });
        },
      );
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionStatus = "WebSocket connection error";
        _errorMessage = e.toString();
      });
    }
  }

  void _disconnectFromServer() {
    // Close WebSocket connection if active
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }

    // Cancel SSE subscription if active
    if (_sseSubscription != null) {
      _sseSubscription!.cancel();
      _sseSubscription = null;
    }

    setState(() {
      _isConnected = false;
      _connectionStatus = "Disconnected";
    });
  }

  Future<void> _toggleSimulation() async {
    if (_isConnected) {
      _disconnectFromServer();
    }

    setState(() {
      _useSimulation = !_useSimulation;
    });

    await _connectToServer();
  }

  // Add method to toggle between SSE and WebSocket
  Future<void> _toggleConnectionType() async {
    if (_isConnected) {
      _disconnectFromServer();
    }

    setState(() {
      _useSSE = !_useSSE;
    });

    await _connectToServer();
  }

  void _processTelemetryData(dynamic data) {
    // Handle empty data case
    print('Processing telemetry data: ${data.runtimeType}');
    print('Data keys: ${data.keys.toList()}');

    // Process the incoming data
    if (data is Map) {
      // SignalR connection init message (has "C" key)
      if (data.containsKey('C')) {
        print('Received SignalR connection message with ID: ${data['C']}');
        // This is just a connection message, not actual data
        return;
      }
      if (data.containsKey('R')) {
        print('Received Initial Data: ${data['R']}');
        // Process Initial Data and Store Locally
        if (data['R'].containsKey('SessionInfo')) {
          setState(() {
            _sessionInfoFuture = fetchSessionInfo(data['R']['SessionInfo']);
          });
          print(_sessionInfoFuture.toString());
        } else {
          print('No SessionInfo found in initial data');
        }
        return;
      }

      // Handle different types of messages
      if (data.containsKey('M') && data['M'] is List) {
        print('Found M array with ${data['M'].length} messages');
        if (data['M'].containsKey('WeatherData')) {
          _updateTelemetryData(data['M']['WeatherData']);
        } else if (data['M'].containsKey('SessionInfo')) {
          _updateTelemetryData(data['M']['SessionInfo']);
        } else if (data['M'].containsKey('TimingData')) {
          _updateTelemetryData(data['M']['TimingData']);
        } else if (data['M'].containsKey('DriverList')) {
          _updateTelemetryData(data['M']['DriverList']);
        } else {
          print('No relevant data found in M array');
        }
      } else {
        // If data doesn't match expected format, log it for debugging
        print('Received data in unexpected format: $data');
      }
    }
  }

  void _updateTelemetryData(dynamic data) {
    if (data is Map) {
      print('Updating telemetry data with: ${data.keys.toList()}');

      // Avoid unnecessary setState if data is empty
      if (data.isEmpty) {
        print('Received empty data map, skipping update');
        return;
      }

      setState(() {
        // Update specific sections of telemetry data based on the received data
        if (data.containsKey('SessionInfo')) {
          _sessionInfoFuture = fetchSessionInfo(data['SessionInfo']);
          print('Updated SessionInfo with new data');
        }
        if (data.containsKey('WeatherData')) {
          _weatherDataFuture = fetchWeatherData(data['WeatherData']);
          print('Updated WeatherData with new data');
        }
        // Add more data type handlers as needed

        // Update the general telemetry data store with new values
        data.forEach((key, value) {
          _telemetryData[key] = value;
        });
      });
    } else {
      print('Received non-map data: ${data.runtimeType}, cannot update');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('F1 Live Telemetry'),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: Icon(_isConnected ? Icons.stop : Icons.play_arrow),
                  label: Text(_isConnected ? 'Disconnect' : 'Connect'),
                  onPressed:
                      _isConnected ? _disconnectFromServer : _connectToServer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon:
                      Icon(_useSimulation ? Icons.toggle_on : Icons.toggle_off),
                  label: Text(_useSimulation ? 'Simulation' : 'Live Data'),
                  onPressed: _toggleSimulation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _useSimulation ? Colors.amber : Colors.blue,
                    foregroundColor: Colors.black,
                  ),
                ),
                // Add a button to toggle between SSE and WebSocket
                ElevatedButton.icon(
                  icon: Icon(_useSSE ? Icons.http : Icons.web),
                  label: Text(_useSSE ? 'SSE' : 'WS'),
                  onPressed: _toggleConnectionType,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _useSSE ? Colors.purple : Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Error: $_errorMessage',
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 16),

            // Messages received counter
            Text(
              'Messages received: $_messageCount',
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            Text(
              'Note: Currently the timings are not updated, they are just fetched once. Development in Progress.',
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey),
            ),

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
                          FutureBuilder(
                              future: _liveDataFuture,
                              builder: (_, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else if (snapshot.hasData) {
                                  final liveData =
                                      snapshot.data as List<LiveData>;
                                  return Column(
                                    children: [
                                      _buildSessionInfoCard(
                                          liveData[0].sessionInfo!),
                                      _buildTrackStatusCard(
                                          liveData[0].trackStatus!),
                                      _buildWeatherCard(
                                          liveData[0].weatherData!),
                                      buildDriverGrid(
                                          liveData[0].driverList!.drivers,
                                          liveData[0].timingData!.lines),
                                    ],
                                  );
                                } else {
                                  return const Text(
                                      'No session info available');
                                }
                              }),
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
            _buildInfoRow('Type:', session.type ?? 'Unknown'),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weather Conditions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Air Temperature:', '${weather.airTemp}°C'),
            _buildInfoRow('Track Temperature:', '${weather.trackTemp}°C'),
            _buildInfoRow('Wind Speed:', '${weather.windSpeed} km/h'),
            _buildInfoRow(
                'Weather:', weather.rainfall == '0' ? 'Clear' : 'Rain'),
            _buildInfoRow('Humidity:', '${weather.humidity}%'),
            _buildInfoRow('Pressure:', '${weather.pressure} hPa'),
          ],
        ),
      ),
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

  Widget buildDriverGrid(
      Map<String, Driver> drivers, Map<String, TimingDataDriver> timingData) {
    // Sort drivers by line number (current race position)
    List<MapEntry<String, Driver>> sortedDrivers = drivers.entries.toList()
      ..sort((a, b) => a.value.line.compareTo(b.value.line));

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: sortedDrivers.length,
      itemBuilder: (context, index) {
        final entry = sortedDrivers[index];
        final String racingNumber = entry.key;
        final Driver driver = entry.value;
        final TimingDataDriver timing = timingData[racingNumber]!;

        // Get interval value with proper handling
        String intervalText = "";
        if (index == 0) {
          // Leader (show LEADER or P1 instead of interval)
          intervalText = "LEADER";
        } else {
          // Get interval to position ahead
          intervalText =
              timing.intervalToPositionAhead?.value ?? timing.gapToLeader;
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

        return Card(
          margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(driver.line.toString()),
              backgroundColor: teamColor,
              foregroundColor: Colors.white,
            ),
            title: Text(
              driver.fullName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(driver.teamName),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: index == 0 ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                intervalText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
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
