import 'package:flutter/material.dart';
import 'package:formulavision/data/models/live_data.model.dart';

/// A compact, F1-style "lap coverage" bar that renders the sectors of a
/// driver's current lap as groups of mini-segment cells which stretch to fill
/// the available width — so the row reads as a true lap-coverage progress bar
/// rather than a row of fixed dashes.
///
/// When [showTimes] is true, each sector's completed time is shown beneath its
/// group (used when the driver row is expanded).
///
/// Colour mapping follows the F1 SignalR mini-sector status codes
/// (matching slowlydev/f1-dash):
///   0     -> not yet driven (grey)
///   2048  -> driven, not a best (yellow)
///   2049  -> personal best (green)
///   2051  -> overall fastest (purple)
///   2052  -> set / yellow variant (yellow)
///   2064  -> in pit / pit lane (blue)
class MiniSectorBar extends StatelessWidget {
  final List<Sector> sectors;

  /// When true, render the per-sector time labels beneath the segment groups.
  final bool showTimes;

  /// Height of each mini-segment cell.
  final double segmentHeight;

  const MiniSectorBar({
    super.key,
    required this.sectors,
    this.showTimes = false,
    this.segmentHeight = 6,
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

  /// A sector's width weight is its segment count, so longer sectors render
  /// wider — keeping the bar proportional to the real track layout.
  int _flexFor(Sector sector) =>
      sector.segments.isEmpty ? 1 : sector.segments.length;

  @override
  Widget build(BuildContext context) {
    if (sectors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Segment groups, stretched across the full width.
        Row(
          children: [
            for (int i = 0; i < sectors.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                flex: _flexFor(sectors[i]),
                child: _segmentRow(sectors[i]),
              ),
            ],
          ],
        ),
        if (showTimes) ...[
          const SizedBox(height: 7),
          Row(
            children: [
              for (int i = 0; i < sectors.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  flex: _flexFor(sectors[i]),
                  child: _timeLabel(i, sectors[i]),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _segmentRow(Sector sector) {
    final segments = sector.segments;
    if (segments.isEmpty) {
      // No segment detail yet — a single placeholder fills the group.
      return _cell(MiniSectorBar.segmentColor(0));
    }
    return Row(
      children: [
        for (int s = 0; s < segments.length; s++) ...[
          if (s > 0) const SizedBox(width: 2),
          Expanded(child: _cell(MiniSectorBar.segmentColor(segments[s].status))),
        ],
      ],
    );
  }

  Widget _cell(Color color) {
    return Container(
      height: segmentHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _timeLabel(int index, Sector sector) {
    final hasValue = sector.value.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'S${index + 1}',
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            hasValue ? sector.value : '--.---',
            style: TextStyle(
              color: hasValue
                  ? MiniSectorBar.sectorTimeColor(sector)
                  : Colors.white24,
              fontSize: 12,
              fontFamily: 'Roboto Mono',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
