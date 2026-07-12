import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:formulavision/data/services/app_settings_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formulavision/components/connecting_indicator.dart';
import 'package:formulavision/components/driver_row_card.dart';
import 'package:formulavision/components/race_control_toast.dart';
import 'package:formulavision/components/race_timer_bar.dart';
import 'package:formulavision/components/weather_info_card.dart';
import 'package:formulavision/components/track_status_card.dart';
import 'package:formulavision/data/models/live_data.model.dart';
import 'package:formulavision/data/services/live_data_service.dart';

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
  // Live data is owned by the shared LiveDataService so the dashboard and the
  // home page render from one connection. These fields mirror only what the
  // build needs; the service holds the source of truth.
  final bool _useSimulation = false;

  bool _isConnected = false;
  String _connectionStatus = "Disconnected";

  // Set once the first snapshot arrives; drives the header/timer FutureBuilders.
  Future<List<LiveData>>? _liveDataFuture;
  StreamSubscription<List<LiveData>>? _liveSub;
  StreamSubscription<List<Message>>? _rcSub;

  Stream<List<LiveData>> get liveDataStream => LiveDataService.instance.stream;

  // Per-driver ordering + change arrows are computed by the service.
  Map<String, int> get _currentPositions =>
      LiveDataService.instance.currentPositions;
  Map<String, String> get _positionChanges =>
      LiveDataService.instance.positionChanges;

  // Broadcast-delay mirror for the delay modal UI.
  int _delaySeconds = 0;
  bool _delayEnabled = false;

  bool _isHeaderPinned = true; // Track if header is pinned
  bool _isRaceTimerPinned = false; // Track if race timer bar is pinned

  // Race control message alerts
  final AudioPlayer _rcAudioPlayer = AudioPlayer();
  bool _raceControlSoundEnabled = true;

  // Track map display settings
  bool _trackMapEnabled = true;
  String _trackMapDisplayMode = AppSettings.trackMapModeCard;
  bool _trackMapExpanded = true; // Card-mode expand/collapse state

  @override
  void initState() {
    super.initState();
    final service = LiveDataService.instance;
    final cur = service.current;
    if (cur != null) _liveDataFuture = Future.value(cur);
    _isConnected = service.isConnected.value;
    _connectionStatus = service.connectionStatus.value;
    _delayEnabled = service.delayEnabled;
    _delaySeconds = service.delaySeconds;
    service.connectionStatus.addListener(_onServiceStatus);
    service.isConnected.addListener(_onServiceStatus);
    _rcSub = service.raceControlAlerts.listen(_alertRaceControl);
    // Rebuild on each emit so the pinned header/timer FutureBuilders refresh
    // alongside the streaming content; the future is set once from the first
    // snapshot and resolves to the in-place-mutated list.
    _liveSub = service.stream.listen((data) {
      if (!mounted) return;
      setState(() { _liveDataFuture ??= Future.value(data); });
    });
    service.attach();
    _loadRaceControlSoundSetting();
    _loadTrackMapSettings();
  }

  void _onServiceStatus() {
    if (!mounted) return;
    setState(() {
      _connectionStatus = LiveDataService.instance.connectionStatus.value;
      _isConnected = LiveDataService.instance.isConnected.value;
    });
  }

  @override
  void dispose() {
    final service = LiveDataService.instance;
    service.connectionStatus.removeListener(_onServiceStatus);
    service.isConnected.removeListener(_onServiceStatus);
    _liveSub?.cancel();
    _rcSub?.cancel();
    service.detach();
    _rcAudioPlayer.dispose(); // Release the alert audio player
    super.dispose();
  }

  void _updateDelay(int seconds) {
    setState(() => _delaySeconds = seconds);
    LiveDataService.instance.setDelaySeconds(seconds);
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

  /// Maps the internal connection status to friendly copy shown under the
  /// start-light gantry while waiting for the first telemetry.
  String _connectingDetail() {
    switch (_connectionStatus) {
      case 'Fetching initial data...':
      case 'Initial data loaded':
        return 'Loading session data';
      case 'Connected':
      case 'Subscribed':
        return 'Subscribing to the feed';
      case 'Failed to fetch initial data':
      case 'Error fetching initial data':
      case 'SSE connection error':
        return 'Connection trouble — retrying';
      default:
        return 'Establishing connection';
    }
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
                    });
                    LiveDataService.instance.setDelayEnabled(tempDelayEnabled);
                    LiveDataService.instance.setDelaySeconds(tempDelay);
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
            onTap: () => setState(() => _trackMapExpanded = !_trackMapExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
  // The live track map is built from car-position telemetry, which only exists
  // while a session is running. Hide it entirely when there are no positions
  // (rather than showing a "Waiting for car positions…" placeholder).
  Widget _buildDashboardMainContent(List<LiveData> liveData) {
    final data = liveData[0];
    const showTrackMap = false; // temporarily disabled

    if (showTrackMap &&
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
        if (showTrackMap) ...[
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
                              initialData: LiveDataService.instance.current,
                              builder: (context, snapshot) {
                                if (_liveDataFuture == null) {
                                  return ConnectingIndicator(
                                    detail: _connectingDetail(),
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
            final entryPos = _currentPositions[entry.key] ?? entry.value.line;
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
            racingNumber: racingNumber,
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
        final rMinX =
            rawPoints.map((e) => e.dx).reduce((a, b) => math.min(a, b));
        final rMaxX =
            rawPoints.map((e) => e.dx).reduce((a, b) => math.max(a, b));
        final rMinY =
            rawPoints.map((e) => e.dy).reduce((a, b) => math.min(a, b));
        final rMaxY =
            rawPoints.map((e) => e.dy).reduce((a, b) => math.max(a, b));
        final center = Offset((rMinX + rMaxX) / 2, (rMinY + rMaxY) / 2);

        final rotated =
            rawPoints.map((p) => rotateAround(p, center, rotationRad)).toList();

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
