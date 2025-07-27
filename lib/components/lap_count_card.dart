import 'package:flutter/material.dart';

class LapCountCard extends StatelessWidget {
  final int currentLap;
  final int totalLaps;
  final String sessionType;

  const LapCountCard({
    super.key,
    required this.currentLap,
    required this.totalLaps,
    required this.sessionType,
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
              // Header with session type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sessionType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Icon(
                    Icons.flag_outlined,
                    color: Colors.red[400],
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Lap count display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Current lap (large number)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LAP',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        currentLap.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Formula1',
                          height: 0.9,
                        ),
                      ),
                    ],
                  ),

                  // Divider
                  Container(
                    width: 2,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.red[400],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),

                  // Total laps
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'OF',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        totalLaps.toString(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Formula1',
                          height: 0.9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PROGRESS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.red[400],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[700],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.red[400]!,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
