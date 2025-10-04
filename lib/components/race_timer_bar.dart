import 'package:flutter/material.dart';

class RaceTimerBar extends StatelessWidget {
  final String remaining;
  final int? currentLap;
  final int? totalLaps;
  final String sessionType;

  const RaceTimerBar({
    super.key,
    required this.remaining,
    this.currentLap,
    this.totalLaps,
    required this.sessionType,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if this is a race/sprint session
    final isRaceOrSprint = _isRaceOrSprintSession(sessionType);

    // Calculate completion percentage for race/sprint sessions
    double? completionPercentage;
    if (isRaceOrSprint &&
        currentLap != null &&
        totalLaps != null &&
        totalLaps! > 0) {
      completionPercentage = (currentLap! / totalLaps!) * 100;
    }

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red[900]!,
            Colors.red[700]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Timer section
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'TIME',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(remaining),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Roboto Mono',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Completion percentage (only for race/sprint)
            if (isRaceOrSprint && completionPercentage != null) ...[
              Container(
                width: 1,
                height: 30,
                color: Colors.white24,
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'COMPLETE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${completionPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Roboto Mono',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Lap count (only for race/sprint)
            if (isRaceOrSprint && currentLap != null && totalLaps != null) ...[
              Container(
                width: 1,
                height: 30,
                color: Colors.white24,
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'LAP',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: currentLap.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Roboto Mono',
                            ),
                          ),
                          TextSpan(
                            text: '/${totalLaps.toString()}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Roboto Mono',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isRaceOrSprintSession(String sessionType) {
    final lowerType = sessionType.toLowerCase();
    return lowerType.contains('race') || lowerType.contains('sprint');
  }

  String _formatTime(String timeString) {
    // Handle different time formats
    if (timeString.isEmpty || timeString == '00:00:00') {
      return '--:--';
    }

    // Check if it's already in the format HH:MM:SS or MM:SS
    if (timeString.contains(':')) {
      final parts = timeString.split(':');
      if (parts.length == 3) {
        // HH:MM:SS format
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2]) ?? 0;

        if (hours > 0) {
          return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        } else {
          return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        }
      } else if (parts.length == 2) {
        // MM:SS format
        return timeString;
      }
    }

    return timeString;
  }
}

// Compact version for smaller spaces
class CompactRaceTimerBar extends StatelessWidget {
  final String remaining;
  final int? currentLap;
  final int? totalLaps;
  final String sessionType;

  const CompactRaceTimerBar({
    super.key,
    required this.remaining,
    this.currentLap,
    this.totalLaps,
    required this.sessionType,
  });

  @override
  Widget build(BuildContext context) {
    final isRaceOrSprint = _isRaceOrSprintSession(sessionType);
    double? completionPercentage;

    if (isRaceOrSprint &&
        currentLap != null &&
        totalLaps != null &&
        totalLaps! > 0) {
      completionPercentage = (currentLap! / totalLaps!) * 100;
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red[900]!,
            Colors.red[700]!,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Timer
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTime(remaining),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Roboto Mono',
                  ),
                ),
              ],
            ),

            // Show completion and lap for race/sprint only
            if (isRaceOrSprint) ...[
              // Completion percentage
              if (completionPercentage != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${completionPercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

              // Lap count
              if (currentLap != null && totalLaps != null)
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: currentLap.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: '/${totalLaps.toString()}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isRaceOrSprintSession(String sessionType) {
    final lowerType = sessionType.toLowerCase();
    return lowerType.contains('race') || lowerType.contains('sprint');
  }

  String _formatTime(String timeString) {
    if (timeString.isEmpty || timeString == '00:00:00') {
      return '--:--';
    }

    if (timeString.contains(':')) {
      final parts = timeString.split(':');
      if (parts.length == 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2]) ?? 0;

        if (hours > 0) {
          return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        } else {
          return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        }
      } else if (parts.length == 2) {
        return timeString;
      }
    }

    return timeString;
  }
}
