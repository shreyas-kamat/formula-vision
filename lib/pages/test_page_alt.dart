import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:formulavision/data/models/live_data.model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  Map<String, dynamic>? f1Data;
  bool isLoading = true;
  String? errorMessage;
  bool _isConnected = false;
  int _messageCount = 0;
  bool _timeoutReached = false;
  String _lastHeartbeat = 'None';
  F1DataModel? _dataModel;
  WebSocketChannel? _channel;

  // Server URL
  final String _serverUrl =
      'ws://10.0.2.2:3000'; // Update this with your actual WebSocket server URL

  @override
  void initState() {
    super.initState();
    _dataModel = F1DataModel();
    _connectToWebSocket();
    super.initState();
    _connectToWebSocket();

    // Set a timeout to show data even if no message has been received
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && isLoading) {
        setState(() {
          _timeoutReached = true;
          isLoading = false;
          f1Data = {"R": {}, "I": "0"};
        });
        print("Connection timeout reached - showing empty UI");
      }
    });
  }

  @override
  void dispose() {
    _disconnectFromWebSocket();
    super.dispose();
  }

  void _connectToWebSocket() {
    try {
      print("Attempting to connect to WebSocket at $_serverUrl");
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));

      // Subscribe to data we're interested in - adding Heartbeat
      _channel!.sink.add(jsonEncode({
        "H": "Streaming",
        "M": "Subscribe",
        "A": [
          ["Heartbeat", "WeatherData", "SessionInfo"]
        ],
        "I": 1
      }));

      print("WebSocket subscription message sent with Heartbeat");

      // Listen for messages
      _channel!.stream.listen(
        (message) {
          setState(() {
            _messageCount++;
          });

          try {
            print('Received raw message: $message');
            final data = jsonDecode(message);

            // Send all data to the model for processing
            _dataModel?.updateData(data);

            // Update the UI state with the latest heartbeat from the model
            final heartbeat = _dataModel?.state.heartbeat?.utc;
            if (heartbeat != null && heartbeat.isNotEmpty) {
              setState(() {
                _lastHeartbeat = heartbeat;
              });
              print('Heartbeat updated from model: $_lastHeartbeat');
            }

            // Show the UI after receiving first message
            if (isLoading) {
              setState(() {
                isLoading = false;
              });
            }
          } catch (e) {
            print("Error processing message: $e");
            // Show the UI even if we can't parse the message
            if (isLoading) {
              setState(() {
                isLoading = false;
              });
            }
          }
        },
        onError: (error) {
          print("WebSocket error: $error");
          setState(() {
            _isConnected = false;
            errorMessage = 'WebSocket error: $error';
            isLoading = false;
          });
        },
        onDone: () {
          print("WebSocket connection closed");
          setState(() {
            _isConnected = false;
            if (isLoading) {
              errorMessage =
                  'WebSocket connection closed without receiving data';
              isLoading = false;
            }
          });
        },
      );

      setState(() {
        _isConnected = true;
        print("WebSocket connected state set to true");
      });
    } catch (e) {
      print("Failed to connect to WebSocket: $e");
      setState(() {
        errorMessage = 'Failed to connect to WebSocket: $e';
        isLoading = false;
      });
    }
  }

  void _disconnectFromWebSocket() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
      print("WebSocket connection closed manually");
    }
    setState(() {
      _isConnected = false;
    });
  }

  // void _processWebSocketData(dynamic data) {
  //   print("Processing data of type: ${data.runtimeType}");

  //   // Process the incoming data
  //   if (data is Map) {
  //     // SignalR connection init message (has "C" key)
  //     if (data.containsKey('C')) {
  //       print('Received SignalR connection message with ID: ${data['C']}');

  //       // Important - even if we just got a connection message, show the UI
  //       if (isLoading) {
  //         setState(() {
  //           isLoading = false;
  //           f1Data = {"R": {}, "I": _messageCount.toString()};
  //         });
  //       }
  //       return; // This is just a connection message, not actual data
  //     }

  //     // Handle different types of messages
  //     if (data.containsKey('M') && data['M'] is List) {
  //       print('Found M array with ${data['M'].length} messages');

  //       for (var message in data['M']) {
  //         if (message is Map) {
  //           print('Message type: ${message['H']}/${message['M']}');

  //           if (message.containsKey('A')) {
  //             final args = message['A'];
  //             print('Message args type: ${args.runtimeType}');

  //             // Handle heartbeat specifically
  //             if (message['H'] == 'Streaming' && message['M'] == 'heartbeat') {
  //               if (args is List && args.isNotEmpty && args[0] is String) {
  //                 setState(() {
  //                   _lastHeartbeat = args[0];
  //                 });
  //                 print('Heartbeat received: $_lastHeartbeat');
  //               }
  //             }
  //             // Handle feed message format
  //             else if (message['H'] == 'Streaming' && message['M'] == 'feed') {
  //               if (args is List && args.isNotEmpty) {
  //                 print('Feed args length: ${args.length}');

  //                 if (args[0] is Map) {
  //                   print(
  //                       'Feed data found with keys: ${args[0].keys.toList()}');
  //                   _updateF1Data(args[0]);
  //                 } else if (args[0] is String &&
  //                     args.length > 1 &&
  //                     args[1] is Map) {
  //                   // Handle named feed data
  //                   print('Named feed data: ${args[0]}');
  //                   Map<String, dynamic> namedData = {args[0]: args[1]};
  //                   _updateF1Data(namedData);
  //                 }
  //               }
  //             }
  //           }
  //         }
  //       }
  //     }
  //   }
  // }

  void _updateF1Data(Map<String, dynamic> newData) {
    setState(() {
      // First time receiving data
      if (f1Data == null) {
        f1Data = {"R": newData};
        isLoading = false;
        print('First data received, isLoading set to false');
      } else {
        // Update existing data
        if (f1Data!.containsKey('R')) {
          f1Data!['R'] = {...f1Data!['R'] as Map<String, dynamic>, ...newData};
        } else {
          f1Data!['R'] = newData;
        }
      }

      // Add the message ID
      f1Data!['I'] = _messageCount.toString();

      print('Updated F1 data. Keys: ${f1Data!['R'].keys.toList()}');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // Loading state remains the same
      return Scaffold(
        appBar: AppBar(
          title: const Text('F1 Live Data'),
          backgroundColor: Colors.red[900],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.red),
              const SizedBox(height: 16),
              const Text('Connecting to F1 data stream...'),
              const SizedBox(height: 24),
              Text(
                  'Connection status: ${_isConnected ? 'Connected' : 'Connecting...'}'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = false;
                    f1Data = {"R": {}, "I": "0"};
                  });
                },
                child: const Text('Skip Loading'),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      // Error state remains the same
      return Scaffold(
        appBar: AppBar(
          title: const Text('F1 Data'),
          backgroundColor: Colors.red[900],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    errorMessage = null;
                    isLoading = true;
                  });
                  _connectToWebSocket();
                },
                child: const Text('Retry Connection'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    errorMessage = null;
                    isLoading = false;
                    f1Data = {"R": {}, "I": "0"};
                  });
                },
                child: const Text('Continue Without Data'),
              ),
            ],
          ),
        ),
      );
    }

    // Get data from the model instead of raw JSON
    final liveData = _dataModel!.state;

    // For raw JSON display
    final jsonData = f1Data ?? {"message": "No raw data available"};

    return Scaffold(
      appBar: AppBar(
        title: const Text('F1 Live Data'),
        backgroundColor: Colors.red[900],
        actions: [
          Chip(
            label: Text(_isConnected ? 'Connected' : 'Disconnected'),
            backgroundColor: _isConnected ? Colors.green : Colors.red[300],
            labelStyle: const TextStyle(color: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection status
            _buildConnectionStatusCard(liveData),

            // No data message if there's no data yet
            if (liveData.sessionInfo == null && liveData.weatherData == null)
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, size: 48, color: Colors.amber),
                        SizedBox(height: 16),
                        Text(
                          'No data received yet',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'The connection is established but no data has been received. This may happen if there is no active F1 session.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Grand Prix Card - Only shown if data exists
            if (liveData.sessionInfo?.meeting != null)
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liveData.sessionInfo!.meeting.officialName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.location_on,
                        '${liveData.sessionInfo!.meeting.location}, ${liveData.sessionInfo!.meeting.country.name}',
                      ),
                      _buildInfoRow(
                        Icons.stadium,
                        'Circuit: ${liveData.sessionInfo!.meeting.circuit.shortName}',
                      ),
                    ],
                  ),
                ),
              ),

            // Session Details Card
            if (liveData.sessionInfo != null)
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liveData.sessionInfo!.type,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Date: ${_formatDate(liveData.sessionInfo!.startDate)}',
                      ),
                      _buildInfoRow(
                        Icons.access_time,
                        'Time: ${_formatTime(liveData.sessionInfo!.startDate)} - ${_formatTime(liveData.sessionInfo!.endDate)}',
                      ),
                      _buildInfoRow(
                        Icons.public,
                        'Timezone: GMT${liveData.sessionInfo!.gmtOffset}',
                      ),
                      _buildInfoRow(
                        Icons.check_circle,
                        'Status: ${liveData.sessionInfo!.archiveStatus.status}',
                      ),
                    ],
                  ),
                ),
              ),

            // Weather Data Card
            if (liveData.weatherData != null)
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weather Conditions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.thermostat,
                        'Air Temperature: ${liveData.weatherData!.airTemp}°C',
                      ),
                      _buildInfoRow(
                        Icons.assignment,
                        'Track Temperature: ${liveData.weatherData!.trackTemp}°C',
                      ),
                      _buildInfoRow(
                        Icons.air,
                        'Wind Speed: ${liveData.weatherData!.windSpeed} km/h',
                      ),
                      _buildInfoRow(
                        Icons.explore,
                        'Wind Direction: ${liveData.weatherData!.windDirection}',
                      ),
                      _buildInfoRow(
                        Icons.water_drop,
                        'Humidity: ${liveData.weatherData!.humidity}%',
                      ),
                      _buildInfoRow(
                        Icons.speed,
                        'Pressure: ${liveData.weatherData!.pressure} hPa',
                      ),
                      _buildInfoRow(
                        Icons.umbrella,
                        'Rainfall: ${liveData.weatherData!.rainfall}',
                      ),
                    ],
                  ),
                ),
              ),

            // Raw JSON Data Display (kept for debugging)
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Raw JSON Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      width: double.infinity,
                      child: Text(
                        const JsonEncoder.withIndent('  ').convert(jsonData),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Driver List if available
            if (liveData.driverList != null)
              _buildDriverListCard(liveData.driverList!),

            // Track Status if available
            if (liveData.trackStatus != null)
              _buildTrackStatusCard(liveData.trackStatus!),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            f1Data = {"R": {}, "I": "0"};
            _messageCount = 0;
            _lastHeartbeat = 'None';
          });
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.clear),
        tooltip: 'Clear data',
      ),
    );
  }

  Widget _buildConnectionStatusCard(LiveData f1State) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'WebSocket Connection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: _isConnected
                      ? _disconnectFromWebSocket
                      : () {
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          _connectToWebSocket();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected ? Colors.red : Colors.green,
                  ),
                  child: Text(_isConnected ? 'Disconnect' : 'Connect'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Messages received: $_messageCount'),
            Text('Last heartbeat: ${f1State.heartbeat?.utc ?? _lastHeartbeat}'),
            if (_timeoutReached)
              const Text(
                'Note: Timeout was reached, data may be incomplete',
                style: TextStyle(color: Colors.orange),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.red[800]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  String _formatTime(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  Widget _buildDriverListCard(DriverList driverList) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Drivers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...driverList.drivers.entries.map((entry) {
              final driver = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      color: Color(
                          int.parse('0xFF${driver.teamColour.substring(1)}')),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      driver.racingNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        driver.fullName,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    Text(
                      driver.teamName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackStatusCard(TrackStatus trackStatus) {
    Color statusColor;
    IconData statusIcon;

    switch (trackStatus.status.toLowerCase()) {
      case 'green':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'yellow':
        statusColor = Colors.yellow;
        statusIcon = Icons.warning;
        break;
      case 'red':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'sc':
      case 'safety car':
        statusColor = Colors.orange;
        statusIcon = Icons.directions_car;
        break;
      case 'vsc':
      case 'virtual safety car':
        statusColor = Colors.amber;
        statusIcon = Icons.remove_circle;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Track Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(statusIcon, size: 28, color: statusColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trackStatus.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      if (trackStatus.message.isNotEmpty)
                        Text(
                          trackStatus.message,
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
