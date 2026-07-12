import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:formulavision/data/functions/f1_decompress.function.dart';
import 'package:formulavision/data/functions/live_data.function.dart';
import 'package:formulavision/data/models/live_data.model.dart';
import 'package:formulavision/data/services/app_settings_service.dart';
import 'package:formulavision/data/services/f1_live_client.dart';

/// Helper to queue delta messages with the time they were received so the
/// optional broadcast delay can replay them later.
class _DelayedMessage {
  final dynamic data;
  final DateTime receivedAt;

  _DelayedMessage(this.data, this.receivedAt);
}

/// Single shared source of truth for the live-timing feed.
///
/// Owns the one [F1LiveClient] (with backend SSE fallback), holds the current
/// [LiveData], applies snapshot + delta updates, and exposes a broadcast
/// [stream] plus a synchronous [current] getter so any number of pages (the
/// dashboard, the home page) render the already-received snapshot immediately
/// instead of each opening their own connection and waiting on deltas.
///
/// Updates are applied in place and emitted on a coalesced ~90ms timer so the
/// high-frequency CarData/Position feed produces ~10 rebuilds/sec rather than
/// one per message.
class LiveDataService {
  LiveDataService._();
  static final LiveDataService instance = LiveDataService._();

  // --- Public state --------------------------------------------------------

  final StreamController<List<LiveData>> _controller =
      StreamController<List<LiveData>>.broadcast();
  Stream<List<LiveData>> get stream => _controller.stream;

  List<LiveData> _current = [];

  /// The latest live-data list, or `null` if the snapshot hasn't arrived yet.
  /// Use as `initialData` for stream builders so they paint on the first frame.
  List<LiveData>? get current => _current.isEmpty ? null : _current;

  final ValueNotifier<String> connectionStatus =
      ValueNotifier<String>('Disconnected');
  final ValueNotifier<String> errorMessage = ValueNotifier<String>('');
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  /// Per-driver position change since the previous timing cycle: 'up', 'down'
  /// or 'same'. Read by the driver rows to animate gained/lost places.
  Map<String, int> _previousPositions = {};
  final Map<String, int> _currentPositions = {};
  final Map<String, String> _positionChanges = {};
  Map<String, String> get positionChanges => _positionChanges;
  Map<String, int> get currentPositions => _currentPositions;

  /// Emits the newly-arrived race control messages so the UI can toast / play
  /// the alert sound. Kept out of the data model so the service stays UI-free.
  final StreamController<List<Message>> _raceControlAlerts =
      StreamController<List<Message>>.broadcast();
  Stream<List<Message>> get raceControlAlerts => _raceControlAlerts.stream;
  int _lastSeenRaceControlCount = 0;
  bool _raceControlSeeded = false;

  // --- Delay (broadcast delay) controls ------------------------------------

  int _delaySeconds = 0;
  bool _delayEnabled = false;
  int get delaySeconds => _delaySeconds;
  bool get delayEnabled => _delayEnabled;
  final Queue<_DelayedMessage> _messageQueue = Queue<_DelayedMessage>();
  Timer? _delayTimer;

  // --- Internals -----------------------------------------------------------

  F1LiveClient? _f1Client;
  StreamSubscription? _sseSubscription;
  http.Client? _sseHttpClient;
  String _feedSource = AppSettings.feedSourceOnDevice;

  int _refCount = 0;
  Future<void>? _starting;

  bool _dirty = false;
  Timer? _emitTimer;

  static const bool _useSimulation = false;

  // --- Lifecycle -----------------------------------------------------------

  /// Attach a consumer. The first attach starts the feed; the connection stays
  /// up while at least one page is attached. Safe to call repeatedly.
  Future<void> attach() async {
    _refCount++;
    if (_refCount == 1 && _f1Client == null && _sseSubscription == null) {
      _starting = _initialize();
    }
    await _starting;
  }

  /// Detach a consumer. The last detach tears the feed down.
  Future<void> detach() async {
    if (_refCount > 0) _refCount--;
    if (_refCount == 0) {
      await _shutdown();
    }
  }

  Future<void> _shutdown() async {
    await _f1Client?.stop();
    _f1Client = null;
    await _sseSubscription?.cancel();
    _sseSubscription = null;
    _sseHttpClient?.close();
    _sseHttpClient = null;
    _delayTimer?.cancel();
    _delayTimer = null;
    _emitTimer?.cancel();
    _emitTimer = null;
    _messageQueue.clear();
    _starting = null;
    isConnected.value = false;
    connectionStatus.value = 'Disconnected';
  }

  Future<void> _initialize() async {
    _feedSource = await AppSettings.getFeedSource();

    // Default: connect directly to F1 on-device. Fall back to the backend relay
    // if negotiation fails (e.g. a network that blocks the F1 endpoint).
    if (_feedSource == AppSettings.feedSourceOnDevice) {
      final ok = await _startOnDeviceFeed();
      if (ok) return;
      _feedSource = AppSettings.feedSourceBackend;
    }

    await _fetchInitialData();
    if (connectionStatus.value == 'Initial data loaded' && !isConnected.value) {
      await _connectSSE();
    }
  }

  // --- On-device feed ------------------------------------------------------

  Future<bool> _startOnDeviceFeed() async {
    final client = F1LiveClient(
      onSnapshot: _handleSnapshot,
      onFeed: (message) {
        // Deltas are only meaningful once the snapshot has built the base
        // live-data object; drop any that arrive before it.
        if (_current.isEmpty) return;
        _processTelemetryData(message);
      },
      onStatus: (status) => connectionStatus.value = status,
      onError: (error) => errorMessage.value = error.toString(),
    );

    try {
      // Fail fast so we fall back to the backend quickly instead of blocking if
      // F1's endpoint is unreachable on this network.
      await client.start().timeout(const Duration(seconds: 8));
      _f1Client = client;
      debugPrint('[LiveDataService] on-device feed connected');
      return true;
    } catch (e) {
      debugPrint('[LiveDataService] on-device feed failed, falling back: $e');
      await client.stop();
      errorMessage.value = 'On-device feed failed: $e';
      return false;
    }
  }

  /// Build the base live-data object from the snapshot and emit immediately,
  /// then decompress the Position.z / CarData.z payloads off the main isolate
  /// and merge them in. Without this the track map and telemetry would sit
  /// empty until the first delta arrived.
  void _handleSnapshot(Map<String, dynamic> snapshot) async {
    final built = await fetchLiveData(snapshot);
    _current = built;
    connectionStatus.value = 'Live (on-device)';
    isConnected.value = true;
    errorMessage.value = '';
    _initializePositionTracking();
    _emitNow();

    // Seed positions + telemetry from the compressed snapshot topics. When no
    // session is running these are usually absent, so the track map will sit on
    // "Waiting for car positions…" until live position telemetry starts.
    final trackStatus = snapshot['TrackStatus'];
    final sessionStatus = snapshot['SessionStatus'];
    final lapCount = snapshot['LapCount'];
    debugPrint('[LiveDataService] snapshot TrackStatus=$trackStatus '
        'SessionStatus=$sessionStatus LapCount=$lapCount');
    final posZ = snapshot['Position.z'];
    debugPrint('[LiveDataService] snapshot Position.z '
        'present=${posZ is String && posZ.isNotEmpty}');
    if (posZ is String && posZ.isNotEmpty) {
      compute(decodePositionZ, posZ).then((position) {
        final entries = position?['Entries'];
        debugPrint('[LiveDataService] seeded positions, entries='
            '${entries is List ? entries.length : 'none'}');
        if (position != null) _updatePositionData(position);
      });
    }
    final carZ = snapshot['CarData.z'];
    debugPrint('[LiveDataService] snapshot CarData.z '
        'present=${carZ is String && carZ.isNotEmpty}');
    if (carZ is String && carZ.isNotEmpty) {
      compute(decodeCarDataZ, carZ).then((carData) {
        if (carData != null) _updateCarData(carData);
      });
    }
  }

  // --- Backend fallback (initial data + SSE) -------------------------------

  Future<void> _fetchInitialData() async {
    connectionStatus.value = 'Fetching initial data...';
    errorMessage.value = '';
    try {
      final apiUrl = await AppSettings.getApiUrl();
      final response = await http.get(
        Uri.parse('$apiUrl/initialData'),
        headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _current = await fetchLiveData(data['R']);
        _initializePositionTracking();
        _emitNow();
        connectionStatus.value = 'Initial data loaded';
      } else {
        connectionStatus.value = 'Failed to fetch initial data';
        errorMessage.value = 'HTTP Status: ${response.statusCode}';
      }
    } catch (e) {
      connectionStatus.value = 'Error fetching initial data';
      errorMessage.value = e.toString();
    }
  }

  Future<void> _connectSSE() async {
    try {
      final apiUrl = await AppSettings.getApiUrl();
      final sseUrl =
          '$apiUrl/events${_useSimulation ? '?simulation=true' : ''}';
      final client = http.Client();
      _sseHttpClient = client;
      final request = http.Request('GET', Uri.parse(sseUrl));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.headers['Content-Type'] = 'application/json; charset=UTF-8';

      final streamedResponse = await client.send(request);
      if (streamedResponse.statusCode != 200) {
        throw Exception(
            'Failed to connect to SSE endpoint: ${streamedResponse.statusCode}');
      }

      isConnected.value = true;
      connectionStatus.value = 'Connected';
      if (_delayEnabled && _delaySeconds > 0) _startDelayTimer();

      _sseSubscription = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.startsWith('data: ')) {
            try {
              final data = jsonDecode(line.substring(6));
              _processTelemetryData(data);
            } catch (e) {
              debugPrint('[LiveDataService] SSE parse error: $e');
            }
          }
        },
        onError: (error) {
          isConnected.value = false;
          connectionStatus.value = 'SSE connection error';
          errorMessage.value = error.toString();
          client.close();
        },
        onDone: () {
          isConnected.value = false;
          connectionStatus.value = 'SSE disconnected';
          client.close();
        },
      );
    } catch (e) {
      isConnected.value = false;
      connectionStatus.value = 'SSE connection error';
      errorMessage.value = e.toString();
    }
  }

  // --- Delay controls ------------------------------------------------------

  void setDelayEnabled(bool enabled) {
    _delayEnabled = enabled;
    if (!enabled) {
      _processQueuedMessages();
      _delayTimer?.cancel();
    } else if (_delaySeconds > 0) {
      _startDelayTimer();
    }
  }

  void setDelaySeconds(int seconds) {
    _delaySeconds = seconds;
    if (_delayEnabled && seconds > 0) {
      _startDelayTimer();
    } else if (seconds == 0) {
      _processQueuedMessages();
      _delayTimer?.cancel();
    }
  }

  void _startDelayTimer() {
    _delayTimer?.cancel();
    _delayTimer = Timer.periodic(
        const Duration(milliseconds: 100), (_) => _processQueuedMessages());
  }

  void _processQueuedMessages() {
    final now = DateTime.now();
    while (_messageQueue.isNotEmpty) {
      final message = _messageQueue.first;
      if (now.difference(message.receivedAt).inSeconds >= _delaySeconds) {
        _messageQueue.removeFirst();
        _processTelemetryDataImmediate(message.data);
      } else {
        break;
      }
    }
  }

  // --- Emit batching -------------------------------------------------------

  void _scheduleEmit() {
    _dirty = true;
    _emitTimer ??= Timer(const Duration(milliseconds: 90), () {
      _emitTimer = null;
      if (_dirty) _emitNow();
    });
  }

  void _emitNow() {
    _dirty = false;
    if (!_controller.isClosed) _controller.add(_current);
  }

  // --- Delta dispatch ------------------------------------------------------

  void _processTelemetryData(dynamic data) {
    if (_delayEnabled && _delaySeconds > 0) {
      _messageQueue.add(_DelayedMessage(data, DateTime.now()));
    } else {
      _processTelemetryDataImmediate(data);
    }
  }

  void _processTelemetryDataImmediate(dynamic data) {
    if (data is! Map) return;
    if (!data.containsKey('M') || data['M'] is! List) return;

    for (final messageObject in data['M']) {
      if (messageObject is! Map ||
          messageObject['A'] is! List ||
          messageObject['A'].isEmpty) {
        continue;
      }
      final a0 = messageObject['A'][0];

      // Object-form updates from the on-device client.
      if (a0 is Map && a0.containsKey('ExtrapolatedClock')) {
        _updateExtrapolatedClock(a0['ExtrapolatedClock']);
        continue;
      }
      if (a0 is Map && a0.containsKey('PositionData')) {
        _updatePositionData(a0['PositionData']);
        continue;
      }
      if (a0 is Map && a0.containsKey('CarData')) {
        _updateCarData(a0['CarData']);
        continue;
      }

      // Legacy topic-first form: A = [topic, data, timestamp].
      if (messageObject['A'].length > 1) {
        final messageType = a0;
        final updated = messageObject['A'][1];
        switch (messageType) {
          case 'ExtrapolatedClock':
            _updateExtrapolatedClock(updated);
            break;
          case 'WeatherData':
            _updateWeatherData(updated);
            break;
          case 'SessionInfo':
            _updateSessionInfo(updated);
            break;
          case 'TimingData':
            _updateTimingData(updated);
            break;
          case 'TimingAppData':
            _updateTimingAppData(updated);
            break;
          case 'RaceControlMessages':
            _updateRaceControlMessages(updated);
            break;
          case 'DriverList':
            _updateDriverList(updated);
            break;
          case 'TrackStatus':
            _updateTrackStatus(updated);
            break;
          case 'LapCount':
            _updateLapCount(updated);
            break;
          case 'PositionData':
          case 'Position.z':
            _updatePositionData(updated);
            break;
          default:
            break;
        }
      }
    }
  }

  // --- Position tracking ---------------------------------------------------

  void _initializePositionTracking() {
    if (_current.isEmpty) return;
    final liveData = _current[0];
    liveData.driverList?.drivers.forEach((racingNumber, driver) {
      _currentPositions[racingNumber] = driver.line;
      _previousPositions[racingNumber] = driver.line;
      _positionChanges[racingNumber] = 'same';
    });
    // Seed race control marker so historical messages don't toast.
    _lastSeenRaceControlCount =
        liveData.raceControlMessages?.messages.length ?? 0;
    _raceControlSeeded = true;
  }

  void _updatePositionChanges() {
    _positionChanges.clear();
    for (final racingNumber in _currentPositions.keys) {
      final currentPos = _currentPositions[racingNumber] ?? 0;
      final previousPos = _previousPositions[racingNumber] ?? currentPos;
      if (previousPos > currentPos) {
        _positionChanges[racingNumber] = 'up';
      } else if (previousPos < currentPos) {
        _positionChanges[racingNumber] = 'down';
      } else {
        _positionChanges[racingNumber] = 'same';
      }
    }
  }

  // --- Update handlers (mutate _current[0] in place, then schedule emit) ----

  void _updateExtrapolatedClock(dynamic data) {
    if (data is! Map<String, dynamic> || data.isEmpty || _current.isEmpty) {
      return;
    }
    final cur = _current[0];
    cur.extrapolatedClock = ExtrapolatedClock(
      utc: data.containsKey('Utc')
          ? data['Utc']
          : cur.extrapolatedClock?.utc ?? '',
      remaining: data.containsKey('Remaining')
          ? data['Remaining']
          : cur.extrapolatedClock?.remaining ?? '',
      extrapolating: data.containsKey('Extrapolating')
          ? data['Extrapolating']
          : cur.extrapolatedClock?.extrapolating ?? false,
    );
    _scheduleEmit();
  }

  void _updateTrackStatus(dynamic data) {
    if (data is! Map<String, dynamic> || data.isEmpty || _current.isEmpty) {
      return;
    }
    debugPrint('[LiveDataService] TrackStatus: ${data['Status']} ${data['Message']}');
    final cur = _current[0];
    cur.trackStatus = TrackStatus(
      status: data.containsKey('Status')
          ? data['Status']
          : cur.trackStatus?.status ?? '',
      message: data.containsKey('Message')
          ? data['Message']
          : cur.trackStatus?.message ?? '',
    );
    _scheduleEmit();
  }

  void _updateDriverList(dynamic data) {
    if (data is! Map<String, dynamic> || data.isEmpty || _current.isEmpty) {
      return;
    }
    final cur = _current[0];
    final Map<String, Driver> currentDrivers = cur.driverList?.drivers ?? {};

    // Store current positions before updating.
    _previousPositions = Map.from(_currentPositions);

    final driverKeys = data.keys.where((key) => key != '_kf').toList();
    for (final racingNumber in driverKeys) {
      final driverData = data[racingNumber] ?? {};
      final prev = currentDrivers[racingNumber];
      final updatedDriver = Driver(
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
      _currentPositions[racingNumber] = updatedDriver.line;
    }

    _updatePositionChanges();
    cur.driverList = DriverList(drivers: currentDrivers);
    _scheduleEmit();
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
    if (data.isEmpty || data['Lines'] is! Map || _current.isEmpty) return;

    final cur = _current[0];
    final Map<String, TimingAppDataDriver> currentLines =
        Map<String, TimingAppDataDriver>.from(cur.timingAppData?.lines ?? {});

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
        racingNumber:
            driverData['RacingNumber'] ?? existing?.racingNumber ?? racingNumber,
        stints: mergedStints,
        line: driverData['Line'] ?? existing?.line ?? 0,
        gridPos: driverData['GridPos'] ?? existing?.gridPos ?? '',
      );
    });

    cur.timingAppData = TimingAppData(lines: currentLines);
    _scheduleEmit();
  }

  /// Merges incoming race control messages and signals any newly-arrived ones
  /// via [raceControlAlerts] so the UI can toast / play the alert sound.
  void _updateRaceControlMessages(dynamic data) {
    if (data is! Map<String, dynamic> || _current.isEmpty) return;
    final incoming = RaceControlMessages.fromJson(data);
    if (incoming.messages.isEmpty) return;

    final cur = _current[0];
    final existing = cur.raceControlMessages?.messages ?? <Message>[];
    final List<Message> merged = List<Message>.from(existing);
    for (final m in incoming.messages) {
      final dup = merged.any((e) => e.utc == m.utc && e.message == m.message);
      if (!dup) merged.add(m);
    }
    cur.raceControlMessages = RaceControlMessages(messages: merged);

    if (!_raceControlSeeded) {
      _lastSeenRaceControlCount = merged.length;
      _raceControlSeeded = true;
    } else if (merged.length > _lastSeenRaceControlCount) {
      final newMessages = merged.sublist(_lastSeenRaceControlCount);
      _lastSeenRaceControlCount = merged.length;
      if (!_raceControlAlerts.isClosed) {
        _raceControlAlerts.add(newMessages);
      }
    }
    _scheduleEmit();
  }

  void _updateTimingData(dynamic data) {
    if (data is! Map<String, dynamic> || data.isEmpty || _current.isEmpty) {
      return;
    }
    final cur = _current[0];
    if (!data.containsKey('Lines') || data['Lines'] is! Map<String, dynamic>) {
      return;
    }

    final Map<String, TimingDataDriver> currentLines =
        cur.timingData?.lines ?? {};

    // Snapshot positions from the previous cycle so _updatePositionChanges()
    // compares this cycle against the last (single source of truth = position).
    _previousPositions = Map.from(_currentPositions);

    final linesData = data['Lines'] as Map<String, dynamic>;
    linesData.forEach((racingNumber, driverData) {
      if (driverData is! Map<String, dynamic>) return;
      final currentDriverData = currentLines[racingNumber];

      List<Sector> updatedSectors = currentDriverData != null
          ? List<Sector>.from(currentDriverData.sectors)
          : <Sector>[];
      if (driverData.containsKey('Sectors')) {
        _mergeSectors(updatedSectors, driverData['Sectors']);
      }

      Speeds updatedSpeeds;
      if (driverData.containsKey('Speeds') && driverData['Speeds'] is Map) {
        final speedsData = driverData['Speeds'] as Map<String, dynamic>;
        I1 buildSpeed(String key, I1? fallback) {
          if (speedsData[key] is Map) {
            final d = speedsData[key] as Map<String, dynamic>;
            return I1(
              value: d['Value'] ?? '',
              status: d['Status'] ?? 0,
              overallFastest: d['OverallFastest'] ?? false,
              personalFastest: d['PersonalFastest'] ?? false,
            );
          }
          return fallback ??
              I1(
                  value: '',
                  status: 0,
                  overallFastest: false,
                  personalFastest: false);
        }

        updatedSpeeds = Speeds(
          i1: buildSpeed('I1', currentDriverData?.speeds.i1),
          i2: buildSpeed('I2', currentDriverData?.speeds.i2),
          fl: buildSpeed('FL', currentDriverData?.speeds.fl),
          st: buildSpeed('ST', currentDriverData?.speeds.st),
        );
      } else if (currentDriverData?.speeds != null) {
        updatedSpeeds = currentDriverData!.speeds;
      } else {
        I1 empty() => I1(
            value: '', status: 0, overallFastest: false, personalFastest: false);
        updatedSpeeds =
            Speeds(i1: empty(), i2: empty(), fl: empty(), st: empty());
      }

      IntervalToPositionAhead? updatedInterval;
      if (driverData['IntervalToPositionAhead'] is Map<String, dynamic>) {
        final intervalData =
            driverData['IntervalToPositionAhead'] as Map<String, dynamic>;
        updatedInterval = IntervalToPositionAhead(
          value: intervalData['Value'] ?? '',
          catching: intervalData['Catching'] ?? false,
        );
      } else if (currentDriverData?.intervalToPositionAhead != null) {
        updatedInterval = currentDriverData!.intervalToPositionAhead;
      }

      PersonalBestLapTime updatedBestLap;
      if (driverData['BestLapTime'] is Map) {
        final bestLapData = driverData['BestLapTime'] as Map<String, dynamic>;
        updatedBestLap = PersonalBestLapTime(
          value: bestLapData['Value'] ?? '',
          lap: bestLapData['Lap'] ?? 0,
        );
      } else if (currentDriverData?.bestLapTime != null) {
        updatedBestLap = currentDriverData!.bestLapTime;
      } else {
        updatedBestLap = PersonalBestLapTime(value: '', lap: 0);
      }

      I1 updatedLastLap;
      if (driverData['LastLapTime'] is Map) {
        final lastLapData = driverData['LastLapTime'] as Map<String, dynamic>;
        updatedLastLap = I1(
          value: lastLapData['Value'] ?? '-:--.---',
          status: lastLapData['Status'] ?? 0,
          overallFastest: lastLapData['OverallFastest'] ?? false,
          personalFastest: lastLapData['PersonalFastest'] ?? false,
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

      final updatedDriver = TimingDataDriver(
        gapToLeader:
            driverData['GapToLeader'] ?? (currentDriverData?.gapToLeader ?? ''),
        intervalToPositionAhead: updatedInterval,
        line: driverData['Line'] ?? (currentDriverData?.line ?? 0),
        position:
            driverData['Position'] ?? (currentDriverData?.position ?? ''),
        showPosition:
            driverData['ShowPosition'] ?? (currentDriverData?.showPosition ?? true),
        racingNumber: driverData['RacingNumber'] ??
            (currentDriverData?.racingNumber ?? ''),
        retired: driverData['Retired'] ?? (currentDriverData?.retired ?? false),
        inPit: driverData['InPit'] ?? (currentDriverData?.inPit ?? false),
        pitOut: driverData['PitOut'] ?? (currentDriverData?.pitOut ?? false),
        stopped: driverData['Stopped'] ?? (currentDriverData?.stopped ?? false),
        status: driverData['Status'] ?? (currentDriverData?.status ?? 0),
        sectors: updatedSectors,
        speeds: updatedSpeeds,
        bestLapTime: updatedBestLap,
        lastLapTime: updatedLastLap,
        numberOfLaps:
            driverData['NumberOfLaps'] ?? (currentDriverData?.numberOfLaps ?? 0),
        numberOfPitStops: driverData['NumberOfPitStops'] ??
            (currentDriverData?.numberOfPitStops ?? 0),
      );

      _currentPositions[racingNumber] =
          driverData['Line'] ?? (currentDriverData?.line ?? 0);
      currentLines[racingNumber] = updatedDriver;
    });

    _updatePositionChanges();
    cur.timingData =
        TimingData(lines: currentLines, withheld: data['Withheld'] ?? false);
    _scheduleEmit();
  }

  void _updateWeatherData(dynamic data) {
    if (data is! Map<String, dynamic> || data.isEmpty || _current.isEmpty) {
      return;
    }
    final cur = _current[0];
    final prev = cur.weatherData;
    String pick(String key, String fallback) =>
        data.containsKey(key) ? (data[key]?.toString() ?? fallback) : fallback;
    cur.weatherData = WeatherData(
      airTemp: pick('AirTemp', prev?.airTemp ?? ''),
      humidity: pick('Humidity', prev?.humidity ?? ''),
      pressure: pick('Pressure', prev?.pressure ?? ''),
      rainfall: pick('Rainfall', prev?.rainfall ?? ''),
      trackTemp: pick('TrackTemp', prev?.trackTemp ?? ''),
      windDirection: pick('WindDirection', prev?.windDirection ?? ''),
      windSpeed: pick('WindSpeed', prev?.windSpeed ?? ''),
    );
    _scheduleEmit();
  }

  void _updateSessionInfo(dynamic data) {
    if (data is! Map<String, dynamic> || data.isEmpty || _current.isEmpty) {
      return;
    }
    final cur = _current[0];
    final currentSession = cur.sessionInfo;
    if (currentSession == null) return;

    final meetingData = data['Meeting'];
    final hasMeeting = meetingData is Map;
    final updatedMeeting = Meeting(
      key: hasMeeting && meetingData.containsKey('Key')
          ? meetingData['Key']
          : currentSession.meeting.key,
      name: hasMeeting && meetingData.containsKey('Name')
          ? meetingData['Name']
          : currentSession.meeting.name,
      officialName: hasMeeting && meetingData.containsKey('OfficialName')
          ? meetingData['OfficialName']
          : currentSession.meeting.officialName,
      location: hasMeeting && meetingData.containsKey('Location')
          ? meetingData['Location']
          : currentSession.meeting.location,
      country: hasMeeting && meetingData['Country'] is Map
          ? Country(
              key: meetingData['Country']['Key'] ??
                  currentSession.meeting.country.key,
              code: meetingData['Country']['Code'] ??
                  currentSession.meeting.country.code,
              name: meetingData['Country']['Name'] ??
                  currentSession.meeting.country.name,
            )
          : currentSession.meeting.country,
      circuit: hasMeeting && meetingData['Circuit'] is Map
          ? Circuit(
              key: meetingData['Circuit']['Key'] ??
                  currentSession.meeting.circuit.key,
              shortName: meetingData['Circuit']['ShortName'] ??
                  currentSession.meeting.circuit.shortName,
            )
          : currentSession.meeting.circuit,
    );

    final archiveData = data['ArchiveStatus'];
    final updatedArchiveStatus = ArchiveStatus(
      status: archiveData is Map && archiveData.containsKey('Status')
          ? archiveData['Status']
          : currentSession.archiveStatus.status,
    );

    cur.sessionInfo = SessionInfo(
      meeting: updatedMeeting,
      archiveStatus: updatedArchiveStatus,
      key: data.containsKey('Key') ? data['Key'] : currentSession.key,
      type: data.containsKey('Type') ? data['Type'] : currentSession.type,
      name: data.containsKey('Name') ? data['Name'] : currentSession.name,
      startDate: data.containsKey('StartDate')
          ? data['StartDate']
          : currentSession.startDate,
      endDate:
          data.containsKey('EndDate') ? data['EndDate'] : currentSession.endDate,
      gmtOffset: data.containsKey('GmtOffset')
          ? data['GmtOffset']
          : currentSession.gmtOffset,
      path: data.containsKey('Path') ? data['Path'] : currentSession.path,
      kf: data.containsKey('_kf') ? data['_kf'] : currentSession.kf,
    );
    _scheduleEmit();
  }

  void _updateLapCount(dynamic data) {
    if (data is! Map<String, dynamic> || data.isEmpty || _current.isEmpty) {
      return;
    }
    debugPrint('[LiveDataService] LapCount: ${data}');
    final cur = _current[0];
    cur.lapCount = LapCount(
      currentLap: data.containsKey('CurrentLap')
          ? data['CurrentLap']
          : cur.lapCount?.currentLap ?? 0,
      totalLaps: data.containsKey('TotalLaps')
          ? data['TotalLaps']
          : cur.lapCount?.totalLaps ?? 0,
    );
    _scheduleEmit();
  }

  void _updateCarData(dynamic data) {
    if (data is! Map || _current.isEmpty) return;
    final cars = data['Cars'];
    if (cars is! Map || cars.isEmpty) return;
    final cur = _current[0];
    final updated = Map<String, CarTelemetry>.from(cur.carData);
    cars.forEach((racingNumber, channels) {
      if (channels is Map) {
        updated[racingNumber.toString()] =
            CarTelemetry.fromJson(Map<String, dynamic>.from(channels));
      }
    });
    cur.carData = updated;
    debugPrint('[LiveDataService] _updateCarData: '
        '${cars.length} cars in delta, carData now ${updated.length}');
    _scheduleEmit();
  }

  void _updatePositionData(dynamic data) {
    if (data is! Map<String, dynamic> || data.isEmpty || _current.isEmpty) {
      return;
    }
    _current[0].positionData = PositionData.fromJson(data);
    _scheduleEmit();
  }
}
