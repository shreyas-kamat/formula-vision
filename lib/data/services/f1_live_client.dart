import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../functions/f1_decompress.function.dart';
import 'f1_clock_extrapolator.dart';

/// On-device F1 live-timing client.
///
/// Connects directly to F1's SignalR Core endpoint from the phone, removing the
/// dependence on the backend relay. Because the phone uses a residential IP,
/// this also sidesteps F1's datacenter-IP blocking that breaks the server path.
///
/// This is a Dart port of the backend's `f1ApiService.js` + the CarData.z /
/// Position.z decompression (`dataProcessingService.js`) + the clock countdown
/// (`clockService.js`). It emits exactly the message shapes the dashboard's
/// existing pipeline already consumes:
///   * [onSnapshot] receives the initial `R` topic snapshot (feed into
///     `fetchLiveData`).
///   * [onFeed] receives `{ M: [ { H, M, A:[...] } ] }` delta messages (feed
///     into `_processTelemetryData`).
class F1LiveClient {
  F1LiveClient({
    required this.onSnapshot,
    required this.onFeed,
    this.onStatus,
    this.onError,
  });

  /// Initial topic snapshot, equivalent to the backend `/initialData` `R` body.
  final void Function(Map<String, dynamic> snapshot) onSnapshot;

  /// A `{ M: [...] }` delta message, ready for `_processTelemetryData`.
  final void Function(Map<String, dynamic> message) onFeed;

  /// Human-readable status updates for the UI.
  final void Function(String status)? onStatus;

  final void Function(Object error)? onError;

  // SignalR Core JSON protocol delimits messages with the ASCII record
  // separator (0x1e).
  static const String _recordSeparator = '\u001e';

  static const String _baseHttp = 'https://livetiming.formula1.com';
  static const String _baseWs = 'wss://livetiming.formula1.com';

  // Topics proven to be served by F1's SignalR Core endpoint (the f1-dash set).
  static const List<String> _topics = [
    'Heartbeat',
    'CarData.z',
    'Position.z',
    'ExtrapolatedClock',
    'TimingStats',
    'TimingAppData',
    'WeatherData',
    'TrackStatus',
    'SessionStatus',
    'DriverList',
    'RaceControlMessages',
    'SessionInfo',
    'SessionData',
    'LapCount',
    'TimingData',
    'TeamRadio',
    'ChampionshipPrediction',
  ];

  WebSocket? _socket;
  StreamSubscription? _sub;
  Timer? _keepAlive;
  Timer? _reconnectTimer;
  bool _handshakeComplete = false;
  bool _closing = false;
  late final F1ClockExtrapolator _clock = F1ClockExtrapolator(_emitClock);

  bool get isConnected => _socket != null;

  /// Negotiate + connect. Throws if negotiation fails so callers can fall back
  /// to the backend path.
  Future<void> start() async {
    _closing = false;
    onStatus?.call('Negotiating...');
    debugPrint('[F1LiveClient] start: negotiating...');
    final result = await _negotiate();
    debugPrint(
        '[F1LiveClient] negotiated: tokenLen=${result.token.length} cookie=${result.cookie.isNotEmpty}');
    await _connect(result.token, result.cookie);
    debugPrint('[F1LiveClient] start: websocket open, awaiting snapshot');
  }

  /// Tear down the connection and stop all timers. No reconnect afterwards.
  Future<void> stop() async {
    _closing = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopKeepAlive();
    _clock.dispose();
    await _sub?.cancel();
    _sub = null;
    await _socket?.close();
    _socket = null;
  }

  // --- Negotiation ---------------------------------------------------------

  Future<({String token, String cookie})> _negotiate() async {
    final dio = Dio(BaseOptions(
      headers: const {
        'User-Agent': 'BestHTTP',
        'Accept-Encoding': 'gzip,identity',
      },
      // Fail fast on networks that can't reach F1 (e.g. DNS that won't resolve
      // livetiming.formula1.com) so the dashboard falls back to the backend
      // quickly instead of hanging on the OS resolver.
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      validateStatus: (_) => true,
    ));
    final url = '$_baseHttp/signalrcore/negotiate?negotiateVersion=1';
    String cookie = '';

    // Browser-like CORS preflight captures the initial AWSALBCORS cookie.
    try {
      final optionsResp =
          await dio.request(url, options: Options(method: 'OPTIONS'));
      debugPrint('[F1LiveClient] negotiate OPTIONS -> ${optionsResp.statusCode}');
      cookie = _extractAlbCookie(optionsResp.headers.map['set-cookie']) ?? cookie;
    } catch (e) {
      // OPTIONS is best-effort; the POST below still works without it.
      debugPrint('[F1LiveClient] negotiate OPTIONS failed: $e');
    }

    final postResp = await dio.post(
      url,
      options: Options(headers: cookie.isNotEmpty ? {'Cookie': cookie} : null),
    );
    debugPrint(
        '[F1LiveClient] negotiate POST -> ${postResp.statusCode} bodyType=${postResp.data.runtimeType}');
    cookie = _extractAlbCookie(postResp.headers.map['set-cookie']) ?? cookie;

    final body = postResp.data;
    final token = body is Map
        ? (body['connectionToken'] ?? body['ConnectionToken'])
        : null;
    if (token is! String || token.isEmpty) {
      throw Exception('negotiate() did not return a connectionToken');
    }
    return (token: token, cookie: cookie);
  }

  /// Pull the AWS load-balancer cookies (AWSALB / AWSALBCORS) out of a
  /// set-cookie header list into a single Cookie value.
  String? _extractAlbCookie(List<String>? setCookie) {
    if (setCookie == null || setCookie.isEmpty) return null;
    final cookies = <String>[];
    for (final c in setCookie) {
      final first = c.split(';').first;
      if (RegExp(r'^AWSALB(CORS)?=').hasMatch(first)) {
        cookies.add(first);
      }
    }
    return cookies.isEmpty ? null : cookies.join('; ');
  }

  // --- Connection ----------------------------------------------------------

  Future<void> _connect(String token, String cookie) async {
    _handshakeComplete = false;
    final url = '$_baseWs/signalrcore?id=${Uri.encodeComponent(token)}';
    final headers = <String, dynamic>{
      'User-Agent': 'BestHTTP',
      'Accept-Encoding': 'gzip,identity',
    };
    if (cookie.isNotEmpty) headers['Cookie'] = cookie;

    debugPrint('[F1LiveClient] connecting ws: $url');
    _socket = await WebSocket.connect(url, headers: headers);
    debugPrint('[F1LiveClient] ws connected, sending handshake');
    onStatus?.call('Connected');

    // Begin the SignalR handshake. Subscribe runs once the server acks it.
    _socket!.add('{"protocol":"json","version":1}$_recordSeparator');

    _sub = _socket!.listen(
      _handleRaw,
      onError: (Object e) {
        onError?.call(e);
      },
      onDone: _onDone,
      cancelOnError: false,
    );
  }

  void _onDone() {
    _stopKeepAlive();
    _socket = null;
    if (_closing) return;
    onStatus?.call('Disconnected, reconnecting...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _reconnect);
  }

  Future<void> _reconnect() async {
    try {
      final result = await _negotiate();
      await _connect(result.token, result.cookie);
    } catch (e) {
      onError?.call(e);
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 30), _reconnect);
    }
  }

  // --- Message handling ----------------------------------------------------

  // A single WS frame may pack several record-separator-delimited JSON objects.
  void _handleRaw(dynamic raw) {
    final text = raw is String ? raw : utf8.decode(raw as List<int>);
    for (final part in text.split(_recordSeparator)) {
      if (part.isEmpty) continue;
      Map<String, dynamic> msg;
      try {
        final decoded = jsonDecode(part);
        if (decoded is! Map<String, dynamic>) continue;
        msg = decoded;
      } catch (_) {
        continue;
      }
      _handleParsed(msg);
    }
  }

  void _handleParsed(Map<String, dynamic> msg) {
    // First message after the handshake send is the handshake response:
    // {} on success, { error } on failure.
    if (!_handshakeComplete) {
      _handshakeComplete = true;
      final error = msg['error'];
      if (error != null) {
        debugPrint('[F1LiveClient] handshake error: $error');
        onError?.call(Exception('SignalR handshake error: $error'));
        return;
      }
      debugPrint('[F1LiveClient] handshake ack, subscribing');
      _subscribe();
      _startKeepAlive();
      return;
    }

    switch (msg['type']) {
      case 1: // Invocation (streaming feed update)
        final args = msg['arguments'];
        if (msg['target'] == 'feed' && args is List && args.isNotEmpty) {
          final topic = args[0];
          final data = args.length > 1 ? args[1] : null;
          final ts = args.length > 2 ? args[2] : null;
          _handleFeed(topic, data, ts);
        }
        break;
      case 3: // Completion (result of Subscribe = snapshot)
        final result = msg['result'];
        if (result is Map<String, dynamic>) {
          _handleSnapshot(result);
        }
        break;
      default: // type 6 ping and anything else: ignore
        break;
    }
  }

  void _handleSnapshot(Map<String, dynamic> result) {
    debugPrint(
        '[F1LiveClient] snapshot received: ${result.keys.length} topics ${result.keys.take(20).toList()}');
    // Kick off the clock countdown from the snapshot if present.
    final clock = result['ExtrapolatedClock'];
    if (clock is Map<String, dynamic>) {
      _clock.updateFromF1Clock(clock);
    }
    onSnapshot(result);
  }

  void _handleFeed(dynamic topic, dynamic data, dynamic ts) {
    if (topic == 'CarData.z' && data is String) {
      compute(decodeCarDataZ, data).then((formatted) {
        if (formatted != null) {
          onFeed(_feedObject({'CarData': formatted}));
        }
      });
      return;
    }
    if (topic == 'Position.z' && data is String) {
      compute(decodePositionZ, data).then((position) {
        if (position != null) {
          onFeed(_feedObject({'PositionData': position}));
        }
      });
      return;
    }
    if (topic == 'ExtrapolatedClock' && data is Map<String, dynamic>) {
      // The clock extrapolator re-emits this (and ticks) via _emitClock.
      _clock.updateFromF1Clock(data);
      return;
    }
    // Everything else passes through in the legacy topic-first shape that the
    // dashboard's _processTelemetryData switch already understands.
    onFeed({
      'M': [
        {'H': 'Streaming', 'M': 'feed', 'A': [topic, data, ts]}
      ]
    });
  }

  void _emitClock(Map<String, dynamic> clock) {
    onFeed(_feedObject({'ExtrapolatedClock': clock}));
  }

  /// Wrap a single object-form update (`{ CarData: {...} }`) in the feed
  /// envelope the dashboard consumes.
  Map<String, dynamic> _feedObject(Map<String, dynamic> update) => {
        'M': [
          {
            'H': 'Streaming',
            'M': 'feed',
            'A': [update]
          }
        ]
      };

  void _subscribe() {
    final frame = jsonEncode({
      'type': 1,
      'invocationId': '1',
      'target': 'Subscribe',
      'arguments': [_topics],
    });
    _socket?.add('$frame$_recordSeparator');
    onStatus?.call('Subscribed');
  }

  void _startKeepAlive() {
    _stopKeepAlive();
    _keepAlive = Timer.periodic(const Duration(seconds: 15), (_) {
      _socket?.add('{"type":6}$_recordSeparator');
    });
  }

  void _stopKeepAlive() {
    _keepAlive?.cancel();
    _keepAlive = null;
  }
}
