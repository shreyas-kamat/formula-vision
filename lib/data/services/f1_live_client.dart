import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../functions/f1_decompress.function.dart';
import 'f1_clock_extrapolator.dart';

/// On-device F1 live-timing client.
///
/// Connects directly to F1's **SignalR Core** endpoint (`/signalrcore`, hub
/// "Streaming") from the phone, removing the dependence on the backend relay.
/// Because the phone uses a residential IP, this also sidesteps F1's
/// datacenter-IP blocking that breaks the server path.
///
/// Mirrors the f1-dash `signalr` crate (negotiate → handshake → Subscribe →
/// listen) exactly, including the 17-topic set that yields the compressed
/// `CarData.z` / `Position.z` telemetry streams. Notably it sends **no**
/// keep-alive ping (the server pushes data continuously during a session) — an
/// earlier `{"type":6}` ping was the one deviation from the reference.
///
/// It emits exactly the message shapes the dashboard's existing pipeline already
/// consumes:
///   * [onSnapshot] receives the Subscribe completion result (feed into
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
  static const String _recordSeparator = '';

  static const String _baseHttp = 'https://livetiming.formula1.com';
  static const String _baseWs = 'wss://livetiming.formula1.com';

  // The exact topic set f1-dash subscribes to on /signalrcore. CarData.z /
  // Position.z are the compressed telemetry streams the speedometer + track map
  // need; they arrive as streaming deltas (not in the Subscribe snapshot).
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
  Timer? _reconnectTimer;
  bool _handshakeComplete = false;
  bool _closing = false;
  late final F1ClockExtrapolator _clock = F1ClockExtrapolator(_emitClock);

  // Tracks which feed topics F1 actually streams on this connection so we log
  // each distinct one exactly once (discovery aid for missing telemetry).
  final Set<String> _seenTopics = {};

  bool get isConnected => _socket != null;

  /// Negotiate + connect. Throws if negotiation fails so callers can fall back
  /// to the backend path.
  Future<void> start() async {
    _closing = false;
    onStatus?.call('Negotiating...');
    debugPrint('[F1LiveClient] start: negotiating...');
    final result = await _negotiate();
    debugPrint('[F1LiveClient] negotiated: tokenLen=${result.token.length} '
        'cookie=${result.cookie.isNotEmpty}');
    await _connect(result.token, result.cookie);
    debugPrint('[F1LiveClient] start: websocket open, awaiting snapshot');
  }

  /// Tear down the connection and stop all timers. No reconnect afterwards.
  Future<void> stop() async {
    _closing = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
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
    final negotiateUrl = '$_baseHttp/signalrcore/negotiate';
    String cookie = '';

    // CORS preflight captures the AWSALBCORS sticky-session cookie the hub
    // connection requires (mirrors f1-dash).
    try {
      final optionsResp = await dio.request(negotiateUrl,
          options: Options(method: 'OPTIONS'));
      debugPrint('[F1LiveClient] negotiate OPTIONS -> ${optionsResp.statusCode}');
      cookie =
          _extractAlbCookie(optionsResp.headers.map['set-cookie']) ?? cookie;
    } catch (e) {
      // OPTIONS is best-effort; the POST below still works without it.
      debugPrint('[F1LiveClient] negotiate OPTIONS failed: $e');
    }

    final postResp = await dio.post(
      '$negotiateUrl?negotiateVersion=1',
      options: Options(headers: cookie.isNotEmpty ? {'Cookie': cookie} : null),
    );
    debugPrint('[F1LiveClient] negotiate POST -> ${postResp.statusCode} '
        'bodyType=${postResp.data.runtimeType}');
    cookie = _extractAlbCookie(postResp.headers.map['set-cookie']) ?? cookie;

    final body = postResp.data;
    final Map<String, dynamic>? json = body is Map<String, dynamic>
        ? body
        : (body is String ? _tryJson(body) : null);
    final token = json != null
        ? (json['connectionToken'] ?? json['ConnectionToken'])
        : null;
    if (token is! String || token.isEmpty) {
      throw Exception('negotiate() did not return a connectionToken');
    }
    return (token: token, cookie: cookie);
  }

  Map<String, dynamic>? _tryJson(String s) {
    try {
      final decoded = jsonDecode(s);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
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
    // Disable WebSocket per-message-deflate. dart:io advertises it by default,
    // but f1-dash's tungstenite does not — and F1's CDN appears to drop the
    // large CarData.z / Position.z frames when permessage-deflate is negotiated
    // (small topics like TimingData still get through). Matching tungstenite
    // here is what makes the compressed telemetry topics actually arrive.
    _socket = await WebSocket.connect(
      url,
      headers: headers,
      compression: CompressionOptions.compressionOff,
    );
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
    // Match only the real compressed topics, not the "Position" substring inside
    // TimingData's "IntervalToPositionAhead" (which produced false positives).
    if (text.contains('"CarData.z"') || text.contains('"Position.z"')) {
      debugPrint('[F1LiveClient] RAW frame with CarData.z/Position.z: '
          '${text.substring(0, text.length.clamp(0, 120))}');
    }
    for (final part in text.split(_recordSeparator)) {
      if (part.isEmpty) continue;
      Map<String, dynamic> msg;
      try {
        final decoded = jsonDecode(part);
        if (decoded is! Map<String, dynamic>) continue;
        msg = decoded;
      } catch (e) {
        debugPrint('[F1LiveClient] JSON parse failed: $e on: '
            '${part.substring(0, part.length.clamp(0, 100))}');
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
      return;
    }

    switch (msg['type']) {
      case 1: // Invocation (streaming feed update)
        final args = msg['arguments'];
        final target = msg['target'];
        if (target == 'feed' && args is List && args.isNotEmpty) {
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
    debugPrint('[F1LiveClient] snapshot received: ${result.keys.length} topics '
        '${result.keys.take(20).toList()}');
    // Kick off the clock countdown from the snapshot if present.
    final clock = result['ExtrapolatedClock'];
    if (clock is Map<String, dynamic>) {
      _clock.updateFromF1Clock(clock);
    }
    onSnapshot(result);
  }

  void _handleFeed(dynamic topic, dynamic data, dynamic ts) {
    if (topic is String && _seenTopics.add(topic)) {
      debugPrint('[F1LiveClient] new feed topic: $topic');
    }
    if (topic == 'CarData.z' || topic == 'Position.z') {
      debugPrint('[F1LiveClient] FEED topic=$topic '
          'len=${data is String ? data.length : data.runtimeType}');
    }
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
      'invocationId': DateTime.now().microsecondsSinceEpoch.toString(),
      'target': 'Subscribe',
      'arguments': [_topics],
    });
    _socket?.add('$frame$_recordSeparator');
    onStatus?.call('Subscribed');
  }
}
