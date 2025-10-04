import 'package:flutter/material.dart';

class AnimatedDriverInfoCard extends StatefulWidget {
  final int position;
  final Color teamColor;
  final String tla;
  final String interval;
  final String bestLapTime;
  final String currentLapTime;
  final int pitStops;
  final String sessionType;
  final String positionChange; // 'up', 'down', or 'same'

  const AnimatedDriverInfoCard({
    super.key,
    required this.position,
    required this.teamColor,
    required this.tla,
    required this.interval,
    required this.bestLapTime,
    required this.currentLapTime,
    required this.pitStops,
    required this.sessionType,
    required this.positionChange,
  });

  @override
  State<AnimatedDriverInfoCard> createState() => _AnimatedDriverInfoCardState();
}

class _AnimatedDriverInfoCardState extends State<AnimatedDriverInfoCard>
    with TickerProviderStateMixin {
  late AnimationController _positionChangeController;
  late Animation<double> _positionChangeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation for position change indicator (up/down arrow)
    _positionChangeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _positionChangeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _positionChangeController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedDriverInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if position change has occurred
    if (oldWidget.positionChange != widget.positionChange) {
      if (widget.positionChange == 'up' || widget.positionChange == 'down') {
        // Start position change animation
        _positionChangeController.forward().then((_) {
          // Fade out the indicator after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _positionChangeController.reverse();
            }
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _positionChangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if this is a race session where we should show interval
    final bool isRaceSession =
        widget.sessionType.toLowerCase().contains('race') ||
            widget.sessionType.toLowerCase().contains('sprint');

    return AnimatedBuilder(
      animation:
          _positionChangeController, // Only animate the position change indicator
      builder: (context, child) {
        return Stack(
          children: [
            Container(
              width: double.infinity,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey[900]!,
                    Colors.grey[800]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    // Position indicator with team color (fixed)
                    Container(
                      width: 65,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.teamColor.withOpacity(0.8),
                            widget.teamColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.position.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Formula1',
                          ),
                        ),
                      ),
                    ),
                    // Vertical team color stripe (fixed)
                    Container(
                      width: 4,
                      height: double.infinity,
                      color: widget.teamColor,
                    ),
                    // Driver info (scrollable)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              // TLA
                              Text(
                                widget.tla,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 24),

                              // Lap Times (Best and Current combined)
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'LAP TIME',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Best Lap Time (Bigger)
                                  Text(
                                    widget.bestLapTime.isNotEmpty
                                        ? widget.bestLapTime
                                        : '--:--.---',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Roboto Mono',
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 0),
                                  // Current Lap Time  (Smaller)
                                  Text(
                                    widget.currentLapTime,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Roboto Mono',
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),

                              // Interval (only for race sessions)
                              if (isRaceSession) ...[
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'INTERVAL',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: widget.interval == "Leader"
                                            ? Colors.red[700]
                                            : Colors.green[700],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        widget.interval,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                              ],

                              // Pit stops
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'PIT',
                                    style: TextStyle(
                                      color: Colors.grey,
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
                              const SizedBox(
                                  width: 16), // Extra space at the end
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Position change indicator (up/down arrow)
            if (widget.positionChange != 'same')
              Positioned(
                right: 8,
                top: 8,
                child: FadeTransition(
                  opacity: _positionChangeAnimation,
                  child: ScaleTransition(
                    scale: _positionChangeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: widget.positionChange == 'up'
                            ? Colors.green.withOpacity(0.9)
                            : Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.positionChange == 'up'
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
