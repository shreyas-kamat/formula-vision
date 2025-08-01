import 'package:flutter/material.dart';

class LapCountCard extends StatelessWidget {
  final int currentLap;
  final int totalLaps;
  final String sessionType;
  final String? extrapolatedClock; // Format: "HH:MM:SS"
  final bool isClockExtrapolating;

  const LapCountCard({
    super.key,
    required this.currentLap,
    required this.totalLaps,
    required this.sessionType,
    this.extrapolatedClock,
    this.isClockExtrapolating = false,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress percentage
    final double progress = totalLaps > 0 ? currentLap / totalLaps : 0.0;

    return Container(
      width: double.infinity,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main content: [Clock] [Completion %] [Laps/Total]
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Extrapolated Clock Section
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isClockExtrapolating
                              ? 'TIME REMAINING'
                              : 'SESSION TIME',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          extrapolatedClock ?? '--:--:--',
                          style: TextStyle(
                            color: isClockExtrapolating
                                ? Colors.red[400]
                                : Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Formula1',
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vertical Divider
                  Container(
                    width: 1.5,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),

                  // Completion Percentage Section
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'COMPLETE',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(progress * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Formula1',
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vertical Divider
                  Container(
                    width: 1.5,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),

                  // Laps Section
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'LAPS',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: currentLap.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Formula1',
                                  height: 1.0,
                                ),
                              ),
                              TextSpan(
                                text: '/',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                              ),
                              TextSpan(
                                text: totalLaps.toString(),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar (visual indicator)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[700],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.red[400]!,
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompactLapCountCard extends StatelessWidget {
  final int currentLap;
  final int totalLaps;
  final String sessionType;
  final String? extrapolatedClock; // Format: "HH:MM:SS"
  final bool isClockExtrapolating;
  final bool showLapCount; // Whether to show lap count and completion

  const CompactLapCountCard({
    super.key,
    required this.currentLap,
    required this.totalLaps,
    required this.sessionType,
    this.extrapolatedClock,
    this.isClockExtrapolating = false,
    this.showLapCount = true, // Default to true for backward compatibility
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress percentage
    final double progress = totalLaps > 0 ? currentLap / totalLaps : 0.0;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[900]!,
            Colors.grey[800]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Extrapolated Clock
          Text(
            extrapolatedClock ?? '--:--:--',
            style: TextStyle(
              color: isClockExtrapolating ? Colors.red[400] : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'Formula1',
            ),
          ),

          // Show lap count and completion only if showLapCount is true
          if (showLapCount) ...[
            // Completion percentage
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Lap count
            Row(
              children: [
                Text(
                  currentLap.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Formula1',
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  '/',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  totalLaps.toString(),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
