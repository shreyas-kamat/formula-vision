import 'package:flutter/material.dart';
import 'package:formulavision/data/models/live_data.model.dart';

/// A compact, F1-style "lap coverage" bar that renders the three sectors of a
/// driver's current lap as rows of small mini-segment cells, coloured by the
/// segment status pushed in the live timing feed.
///
/// Colour mapping is taken from the F1 SignalR mini-sector status codes
/// (matching slowlydev/f1-dash):
///   0     -> not yet driven (grey)
///   2048  -> driven, not a best (yellow)
///   2049  -> personal best (green)
///   2051  -> overall fastest (purple)
///   2052  -> set / yellow variant (yellow)
///   2064  -> in pit / pit lane (blue)
class MiniSectorBar extends StatelessWidget {
  final List<Sector> sectors;

  /// Width of each individual mini-segment cell.
  final double segmentWidth;

  /// Height of each individual mini-segment cell.
  final double segmentHeight;

  const MiniSectorBar({
    super.key,
    required this.sectors,
    this.segmentWidth = 9,
    this.segmentHeight = 5,
  });

  static Color segmentColor(int status) {
    switch (status) {
      case 2048:
        return const Color(0xFFFBBF24); // amber-400
      case 2049:
        return const Color(0xFF10B981); // emerald-500
      case 2051:
        return const Color(0xFF7C3AED); // violet-600
      case 2052:
        return const Color(0xFFFBBF24); // amber-400
      case 2064:
        return const Color(0xFF3B82F6); // blue-500
      case 0:
      default:
        return const Color(0xFF3F3F46); // zinc-700
    }
  }

  /// Colour for the sector time text based on best-sector flags.
  static Color sectorTimeColor(Sector sector) {
    if (sector.overallFastest) return const Color(0xFF7C3AED); // purple
    if (sector.personalFastest) return const Color(0xFF10B981); // green
    return const Color(0xFFFBBF24); // yellow (a completed, non-best sector)
  }

  @override
  Widget build(BuildContext context) {
    if (sectors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < sectors.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _buildSector(sectors[i]),
        ],
      ],
    );
  }

  Widget _buildSector(Sector sector) {
    final segments = sector.segments;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mini-segment cells
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (segments.isEmpty)
              // No segment detail yet — show a single placeholder cell.
              _cell(MiniSectorBar.segmentColor(0))
            else
              for (int s = 0; s < segments.length; s++) ...[
                if (s > 0) const SizedBox(width: 2),
                _cell(MiniSectorBar.segmentColor(segments[s].status)),
              ],
          ],
        ),
        const SizedBox(height: 3),
        // Sector time
        Text(
          sector.value.isNotEmpty ? sector.value : '--.---',
          style: TextStyle(
            color: sector.value.isNotEmpty
                ? MiniSectorBar.sectorTimeColor(sector)
                : Colors.white38,
            fontSize: 10,
            fontFamily: 'Roboto Mono',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _cell(Color color) {
    return Container(
      width: segmentWidth,
      height: segmentHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
