import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  });

  @override
  State<DriverRowCard> createState() => _DriverRowCardState();
}

class _DriverRowCardState extends State<DriverRowCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _positionAnimation;

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
      case 'INTERMEDIATE':
        return 'assets/tyres/intermediate.svg';
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black26.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

                // Tire Type
                // if (widget.tireCompound.isNotEmpty)
                //   SizedBox(
                //     width: 40,
                //     height: 40,
                //     child: SvgPicture.asset(
                //       _getTirePath(widget.tireCompound),
                //       placeholderBuilder: (context) =>
                //           const CircularProgressIndicator(),
                //     ),
                //   )
                // else
                //   const SizedBox(width: 40, height: 40),
                // const SizedBox(width: 10),

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
