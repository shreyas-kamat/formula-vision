import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formulavision/components/mini_sector_bar.dart';
import 'package:formulavision/components/telemetry_hud.dart';
import 'package:formulavision/data/models/live_data.model.dart';
import 'package:formulavision/pages/live_details_page.dart';

class DriverRowCard extends StatefulWidget {
  final int position;
  final String name;
  final String currentLapTime;
  final String bestLapTime;
  final String interval;
  final Color teamColor;
  final String tireCompound;
  final int pitStops;
  final String? positionChange; // 'up', 'down', or 'same'
  final String
      sessionType; // Session type: 'Race', 'Sprint', 'Qualifying', etc.
  final int stintLaps; // Laps completed on the current tyre set
  final bool isNewTyre; // Whether the current stint started on new tyres
  final List<Stint> stints; // Full stint history (shown in the tyre-tap modal)
  final List<Sector> sectors; // Current lap sectors for the mini-sector bar
  final CarTelemetry? telemetry; // Live car telemetry for the HUD
  final String? racingNumber; // Driver number, used to open the live speedometer

  const DriverRowCard({
    super.key,
    required this.position,
    required this.name,
    required this.currentLapTime,
    required this.bestLapTime,
    required this.interval,
    required this.teamColor,
    required this.tireCompound,
    required this.pitStops,
    this.positionChange,
    this.sessionType = '',
    this.stintLaps = 0,
    this.isNewTyre = true,
    this.stints = const [],
    this.sectors = const [],
    this.telemetry,
    this.racingNumber,
  });

  @override
  State<DriverRowCard> createState() => _DriverRowCardState();
}

class _DriverRowCardState extends State<DriverRowCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _positionAnimation;
  bool _expanded = false;

  void _setupAnimation() {
    // Determine animation direction based on position change
    Offset beginOffset = const Offset(0, 0);
    if (widget.positionChange == 'up') {
      beginOffset = const Offset(0, 0.5); // Slide up
    } else if (widget.positionChange == 'down') {
      beginOffset = const Offset(0, -0.5); // Slide down
    }

    _positionAnimation = Tween<Offset>(
      begin: beginOffset,
      end: const Offset(0, 0),
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _setupAnimation();

    // Start animation if there's a position change
    if (widget.positionChange != null && widget.positionChange != 'same') {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(DriverRowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.positionChange != widget.positionChange &&
        widget.positionChange != null &&
        widget.positionChange != 'same') {
      // Recreate animation with new direction
      _setupAnimation();
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getTirePath(String tyreCompound) {
    if (tyreCompound.isEmpty) {
      return 'assets/tyres/unknown.svg';
    }
    final compound = tyreCompound.toUpperCase();
    switch (compound) {
      case 'HARD':
        return 'assets/tyres/hard.svg';
      case 'MEDIUM':
        return 'assets/tyres/medium.svg';
      case 'SOFT':
        return 'assets/tyres/soft.svg';
      case 'INTER':
      case 'INTERMEDIATE':
        return 'assets/tyres/intermediate.svg';
      case 'WET':
        // No dedicated wet asset bundled; fall back to unknown.
        return 'assets/tyres/unknown.svg';
      default:
        return 'assets/tyres/unknown.svg';
    }
  }

  String _getIntervalText() {
    // For qualifying, show "Pole" for position 1, otherwise show the time difference
    if (widget.sessionType.toLowerCase() == 'qualifying') {
      return widget.position == 1 ? 'POLE' : widget.interval;
    }
    // For race and sprint sessions
    return widget.interval;
  }

  Color? _getIntervalBadgeColor() {
    if (widget.sessionType.toLowerCase() == 'qualifying') {
      // For qualifying: Yellow for pole, green for others
      return widget.position == 1 ? Colors.amber[700] : Colors.green[700];
    }
    // For race and sprint sessions
    return widget.interval == "Leader" ? Colors.red[700] : Colors.green[700];
  }

  @override
  Widget build(BuildContext context) {
    // The row expands to reveal sector times and the telemetry HUD. Stint
    // history lives in a separate modal opened by tapping the tyre.
    final bool canExpand =
        widget.sectors.isNotEmpty || widget.telemetry != null;
    final bool showInterval = widget.sessionType.toLowerCase() == 'race' ||
        widget.sessionType.toLowerCase() == 'sprint' ||
        widget.sessionType.toLowerCase() == 'qualifying';

    return SlideTransition(
      position: _positionAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black26.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: InkWell(
          onTap: canExpand
              ? () => setState(() => _expanded = !_expanded)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row (responsive, no horizontal scroll) ─────────────
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Row(
                  children: [
                    // Position
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: widget.teamColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          widget.position.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Name (yields width on very narrow screens before the
                    // lap time does; stays intact at normal phone widths)
                    Flexible(
                      child: Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Lap time (absorbs slack; scales down before clipping)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LAP TIME',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.currentLapTime.isNotEmpty
                                    ? widget.currentLapTime
                                    : '--:--.---',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Roboto Mono',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.bestLapTime.isNotEmpty
                                    ? widget.bestLapTime
                                    : '--:--.---',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Roboto Mono',
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Interval / diff badge
                    if (showInterval) ...[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.sessionType.toLowerCase() == 'qualifying'
                                ? 'DIFF'
                                : 'INTERVAL',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _getIntervalBadgeColor(),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getIntervalText(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Tyre — tap to open stint history modal
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.stints.isEmpty
                          ? null
                          : () => _showStintHistory(context),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'TYRE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: SvgPicture.asset(
                              _getTirePath(widget.tireCompound),
                              placeholderBuilder: (context) =>
                                  const SizedBox(width: 34, height: 34),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'L${widget.stintLaps}${widget.isNewTyre ? '' : '*'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Roboto Mono',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expand affordance
                    if (canExpand) ...[
                      const SizedBox(width: 4),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: Colors.white54,
                        size: 22,
                      ),
                    ],
                  ],
                ),
              ),

              // ── Lap-coverage strip + expandable detail ────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.sectors.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            16, 12, 16, _expanded ? 4 : 14),
                        child: MiniSectorBar(
                          sectors: widget.sectors,
                          showTimes: _expanded,
                        ),
                      )
                    else
                      const SizedBox(height: 14, width: double.infinity),
                    // Telemetry HUD revealed on expand
                    if (_expanded && widget.telemetry != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Divider(color: Colors.white24, height: 16),
                            TelemetryHud(telemetry: widget.telemetry),
                            if (widget.racingNumber != null) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _openSpeedometer(context),
                                  icon: const Icon(
                                    Icons.speed_rounded,
                                    size: 18,
                                    color: Colors.white70,
                                  ),
                                  label: const Text(
                                    'LIVE SPEEDOMETER',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSpeedometer(BuildContext context) {
    final racingNumber = widget.racingNumber;
    if (racingNumber == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveDetailsPage(
          racingNumber: racingNumber,
          driverName: widget.name,
          teamColor: widget.teamColor,
        ),
      ),
    );
  }

  void _showStintHistory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF15151A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildStintSheet(),
    );
  }

  Widget _buildStintSheet() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 22,
                  decoration: BoxDecoration(
                    color: widget.teamColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${widget.name}  ·  STINT HISTORY',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.pitStops} ${widget.pitStops == 1 ? 'STOP' : 'STOPS'}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto Mono',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 0; i < widget.stints.length; i++)
                  _buildStintChip(widget.stints[i], i + 1),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStintChip(Stint stint, int stintNumber) {
    final compound = stint.compound ?? '';
    final isNew = (stint.isNew ?? 'true').toLowerCase() == 'true';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: SvgPicture.asset(
              _getTirePath(compound),
              placeholderBuilder: (context) =>
                  const SizedBox(width: 26, height: 26),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'S$stintNumber · ${compound.isNotEmpty ? compound : '—'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'formula',
                ),
              ),
              Text(
                'L${stint.totalLaps ?? 0} · ${isNew ? 'New' : 'Used'}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontFamily: 'Roboto Mono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
