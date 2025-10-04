import 'package:flutter/material.dart';

class DriverInfoCard extends StatelessWidget {
  final int position;
  final Color teamColor;
  final String tla;
  final String interval;
  final String bestLapTime;
  final String currentLapTime;
  final String bestLapTime;
  final int pitStops;
  final String sessionType; // Add session type parameter

  const DriverInfoCard({
    super.key,
    required this.position,
    required this.teamColor,
    required this.tla,
    required this.interval,
    required this.bestLapTime,
    required this.currentLapTime,
    required this.bestLapTime,
    required this.pitStops,
    required this.sessionType,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if this is a race session where we should show interval
    final bool isRaceSession = sessionType.toLowerCase().contains('race') ||
        sessionType.toLowerCase().contains('sprint');

    return Container(
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
                    teamColor.withOpacity(0.8),
                    teamColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  position.toString(),
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
              color: teamColor,
            ),
            // Driver info with left-right layout
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // TLA (now included in scrollable content)
                      Text(
                        tla,
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
                            currentLapTime.isNotEmpty
                                ? currentLapTime
                                : '--:--.---',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Roboto Mono',
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 0),
                          // Current Lap Time  (Smaller)
                          Text(
                            bestLapTime.isNotEmpty ? bestLapTime : '--:--.---',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Roboto Mono',
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            bestLapTime,
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              // fontWeight: FontWeight.w600,
                              fontFamily: 'Roboto Mono',
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
                                color: interval == "Leader"
                                    ? Colors.red[700]
                                    : Colors.green[700],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                interval,
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
                                // color: Colors.orange[600]!,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                pitStops.toString(),
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
                      const SizedBox(width: 16), // Extra space at the end
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
