import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formulavision/components/dashboard_style.dart';
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
  final String?
      racingNumber; // Driver number, used to open the live speedometer
  final bool knockedOut; // Eliminated in an earlier qualifying segment
  final bool inDropZone; // Currently below the qualifying elimination line
  final String? trackState; // 'PIT', 'OUT LAP', 'RET', 'STOP', 'ELIM' or null

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
    this.knockedOut = false,
    this.inDropZone = false,
    this.trackState,
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

  @override
  Widget build(BuildContext context) {
    // The row expands to reveal sector times and the telemetry HUD. Stint
    // history lives in a separate modal opened by tapping the tyre.
    final bool canExpand =
        widget.sectors.isNotEmpty || widget.telemetry != null;
    final bool showInterval = widget.sessionType.toLowerCase() == 'race' ||
        widget.sessionType.toLowerCase() == 'sprint' ||
        widget.sessionType.toLowerCase() == 'qualifying';

    final bool dimmed = widget.knockedOut || widget.trackState == 'RET';

    final String intervalText = _getIntervalText();
    // Leader / pole read as a plain uppercase word, not a number.
    final bool isLeaderLabel =
        const {'LEADER', 'POLE'}.contains(intervalText.toUpperCase());
    final bool isPb = widget.currentLapTime.isNotEmpty &&
        widget.currentLapTime == widget.bestLapTime;

    return SlideTransition(
      position: _positionAnimation,
      child: Opacity(
        opacity: dimmed ? 0.45 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: widget.inDropZone
                ? Colors.red.shade900.withValues(alpha: 0.18)
                : Colors.transparent,
            border: Border(bottom: BorderSide(color: DashStyle.divider)),
          ),
          child: InkWell(
            onTap:
                canExpand ? () => setState(() => _expanded = !_expanded) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Main row: one line per driver ─────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      4, 10, 4, widget.sectors.isNotEmpty ? 6 : 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Team stripe
                      Container(
                        width: DashStyle.stripeW,
                        height: 28,
                        decoration: BoxDecoration(
                          color: widget.teamColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Position
                      SizedBox(
                        width: DashStyle.posW,
                        child: Text(
                          '${widget.position}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),

                      // Name (+ track-state chip), ellipsised before the
                      // numeric columns are squeezed
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            if (widget.trackState != null) ...[
                              const SizedBox(width: 6),
                              _buildTrackStateChip(widget.trackState!),
                            ],
                          ],
                        ),
                      ),

                      // Gap / interval (no badge; leader and pole read as text)
                      if (showInterval)
                        SizedBox(
                          width: DashStyle.gapW,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isLeaderLabel
                                    ? intervalText.toUpperCase()
                                    : intervalText,
                                style: isLeaderLabel
                                    ? DashStyle.label
                                        .copyWith(color: DashStyle.textSecondary)
                                    : DashStyle.data
                                        .copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                        ),

                      // Last lap (green when it is the driver's personal best)
                      SizedBox(
                        width: DashStyle.lastW,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.currentLapTime.isNotEmpty
                                  ? widget.currentLapTime
                                  : '--:--.---',
                              style: DashStyle.data.copyWith(
                                color: isPb
                                    ? DashStyle.personalBest
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Tyre — tap to open stint history modal
                      SizedBox(
                        width: DashStyle.tyreW,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.stints.isEmpty
                              ? null
                              : () => _showStintHistory(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: SvgPicture.asset(
                                  _getTirePath(widget.tireCompound),
                                  placeholderBuilder: (context) =>
                                      const SizedBox(width: 22, height: 22),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${widget.stintLaps}${widget.isNewTyre ? '' : 'u'}',
                                    style: DashStyle.data.copyWith(
                                      fontSize: 12,
                                      color: DashStyle.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Expand affordance
                      SizedBox(
                        width: DashStyle.chevronW,
                        child: canExpand
                            ? Icon(
                                _expanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                color: Colors.white38,
                                size: 18,
                              )
                            : null,
                      ),
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
                      if (widget.sectors.isNotEmpty && !_expanded)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                              DashStyle.stripeW + 14, 0, 4, 8),
                          child: MiniSectorBar(
                            sectors: widget.sectors,
                            showTimes: false,
                            compact: true,
                          ),
                        ),
                      if (_expanded)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                              DashStyle.stripeW + 14, 4, 4, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'BEST',
                                    style: DashStyle.label
                                        .copyWith(color: DashStyle.textLabel),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.bestLapTime.isNotEmpty
                                        ? widget.bestLapTime
                                        : '--:--.---',
                                    style: DashStyle.data.copyWith(
                                        color: DashStyle.personalBest),
                                  ),
                                  const Spacer(),
                                  if (widget.pitStops > 0)
                                    Text(
                                      '${widget.pitStops} ${widget.pitStops == 1 ? 'STOP' : 'STOPS'}',
                                      style: DashStyle.label.copyWith(
                                          color: DashStyle.textSecondary),
                                    ),
                                ],
                              ),
                              if (widget.sectors.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                MiniSectorBar(
                                  sectors: widget.sectors,
                                  showTimes: true,
                                ),
                              ],
                              // Telemetry HUD revealed on expand
                              if (widget.telemetry != null) ...[
                                const Divider(
                                    color: Colors.white24,
                                    height: 1,
                                    thickness: 1),
                                const SizedBox(height: 8),
                                TelemetryHud(telemetry: widget.telemetry),
                                if (widget.racingNumber != null) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          _openSpeedometer(context),
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
      ),
    );
  }

  Color _trackStateColor(String state) {
    switch (state) {
      case 'PIT':
        return Colors.blue.shade700;
      case 'OUT LAP':
        return Colors.amber.shade800;
      case 'STOP':
        return Colors.red.shade700;
      default: // RET, ELIM
        return Colors.grey.shade700;
    }
  }

  Widget _buildTrackStateChip(String state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _trackStateColor(state),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        state,
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
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
                '${stint.totalLaps ?? 0} laps · ${isNew ? 'new' : 'used'}',
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

/// Column header for the timing tower. Its columns line up with DriverRowCard.
class LeaderboardHeader extends StatelessWidget {
  final bool showInterval;
  final bool isQualifying;

  const LeaderboardHeader({
    super.key,
    required this.showInterval,
    required this.isQualifying,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = DashStyle.label.copyWith(color: DashStyle.textLabel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Row(
            children: [
              const SizedBox(width: DashStyle.stripeW + 10),
              SizedBox(
                width: DashStyle.posW,
                child: Text('POS', style: labelStyle),
              ),
              Expanded(child: Text('DRIVER', style: labelStyle)),
              if (showInterval)
                SizedBox(
                  width: DashStyle.gapW,
                  child: Text(
                    isQualifying ? 'GAP' : 'INT',
                    textAlign: TextAlign.right,
                    style: labelStyle,
                  ),
                ),
              SizedBox(
                width: DashStyle.lastW,
                child: Text(
                  'LAST',
                  textAlign: TextAlign.right,
                  style: labelStyle,
                ),
              ),
              SizedBox(
                width: DashStyle.tyreW,
                child: Text(
                  'TYRE',
                  textAlign: TextAlign.center,
                  style: labelStyle,
                ),
              ),
              const SizedBox(width: DashStyle.chevronW),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: DashStyle.divider),
      ],
    );
  }
}
