import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../models/live_data.model.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  final F1DataModel _dataModel;
  bool _isConnected = false;
  static const String _websocketUrl =
      "wss://livetiming.formula1.com/signalr/connect";

  WebSocketService(this._dataModel);

  bool get isConnected => _isConnected;

  void connect() {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(
            '$_websocketUrl?transport=webSockets&clientProtocol=1.5&connectionToken='),
      );

      _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Send initial connection message
      _sendInitialMessage();

      // Start ping timer to keep connection alive
      _pingTimer =
          Timer.periodic(const Duration(seconds: 30), (_) => _sendPing());

      _isConnected = true;
    } catch (e) {
      print('WebSocket connection error: $e');
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _isConnected = false;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _channel = null;
  }

  void _onData(dynamic data) {
    try {
      final jsonData = jsonDecode(data as String);
      _dataModel.updateData(jsonData);
    } catch (e) {
      print('Error processing websocket data: $e');
    }
  }

  void _onError(error) {
    print('WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _onDone() {
    print('WebSocket connection closed');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), connect);
  }

  void _sendInitialMessage() {
    final message = json.encode({"protocol": "json", "version": 1});
    _channel?.sink.add(message);

    // Send subscribe message after a short delay
    Timer(const Duration(milliseconds: 300), () {
      final subscribeMsg = json.encode({
        "H": "Streaming",
        "M": "Subscribe",
        "A": [
          ["Heartbeat", "WeatherData", "SessionData"]
        ],
        "I": 1
      });
      _channel?.sink.add(subscribeMsg);
    });
  }

  void _sendPing() {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(json.encode({"type": 6}));
    }
  }
}
