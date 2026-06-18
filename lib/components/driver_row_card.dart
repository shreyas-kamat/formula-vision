import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formulavision/components/mini_sector_bar.dart';
import 'package:formulavision/data/models/live_data.model.dart';

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
  final List<Stint> stints; // Full stint history for the expandable panel
  final List<Sector> sectors; // Current lap sectors for the mini-sector bar

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
    return SlideTransition(
      position: _positionAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black26.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row (tap to expand stint history) ────────────────────
            InkWell(
              onTap: widget.stints.isEmpty
                  ? null
                  : () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                // Position Circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: widget.teamColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      widget.position.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name
                SizedBox(
                  width: 60,
                  child: Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),

                // Lap Time
                Column(
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
                    // Current Lap Time (Bigger)
                    Text(
                      widget.currentLapTime.isNotEmpty
                          ? widget.currentLapTime
                          : '--:--.---',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Roboto Mono',
                        letterSpacing: 0.5,
                      ),
                    ),
                    // Best Lap Time (Smaller)
                    Text(
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
                  ],
                ),
                const SizedBox(width: 12),

                // Interval Badge (for Race, Sprint, and Qualifying sessions)
                if (widget.sessionType.toLowerCase() == 'race' ||
                    widget.sessionType.toLowerCase() == 'sprint' ||
                    widget.sessionType.toLowerCase() == 'qualifying')
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.sessionType.toLowerCase() == 'qualifying'
                            ? 'DIFF'
                            : 'INTERVAL',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getIntervalBadgeColor(),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getIntervalText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 12),

                // Lap Coverage (mini-sectors)
                if (widget.sectors.isNotEmpty) ...[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LAP COVERAGE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      MiniSectorBar(sectors: widget.sectors),
                    ],
                  ),
                  const SizedBox(width: 14),
                ],

                // Tire Type
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'TYRE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: SvgPicture.asset(
                        _getTirePath(widget.tireCompound),
                        placeholderBuilder: (context) =>
                            const SizedBox(width: 36, height: 36),
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
                const SizedBox(width: 12),

                // Pit Stops
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'PIT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[850],
                        border: Border.all(
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.pitStops.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.stints.isNotEmpty) ...[
                  const SizedBox(width: 8),
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
              ),
            ),

            // ── Expandable stint history ────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _expanded && widget.stints.isNotEmpty
                  ? _buildStintHistory()
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStintHistory() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Colors.white24, height: 16),
          const Text(
            'STINT HISTORY',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
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
