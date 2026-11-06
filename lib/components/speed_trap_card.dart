import 'package:flutter/material.dart';
import 'package:formulavision/components/dashboard_style.dart';
import 'package:formulavision/data/models/live_data.model.dart';

/// Top speed-trap leaderboard built from the TimingStats feed ('ST' best speed).
class SpeedTrapCard extends StatefulWidget {
  final TimingStats? stats;
  final Map<String, Driver> drivers;

  const SpeedTrapCard({
    super.key,
    required this.stats,
    required this.drivers,
  });

  @override
  State<SpeedTrapCard> createState() => _SpeedTrapCardState();
}

class _SpeedTrapCardState extends State<SpeedTrapCard> {
  static const int _collapsedRows = 3;
  static const int _maxRows = 10;

  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final rows = _topSpeeds();
    if (rows.isEmpty) return const SizedBox.shrink();

    final visible = _showAll ? rows : rows.take(_collapsedRows).toList();
    final bool canToggle = rows.length > _collapsedRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('SPEED TRAP', style: DashStyle.sectionTitle),
            const Spacer(),
            Text('km/h',
                style: DashStyle.label.copyWith(color: DashStyle.textLabel)),
          ],
        ),
        const SizedBox(height: 8),
        Divider(height: 1, thickness: 1, color: DashStyle.divider),
        for (int i = 0; i < visible.length; i++)
          _buildRow(visible[i], isFastest: i == 0),
        if (canToggle)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: const Size(0, 40),
                alignment: Alignment.centerLeft,
              ),
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(
                _showAll ? 'Show less' : 'Show all',
                style:
                    DashStyle.label.copyWith(color: DashStyle.textSecondary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRow(_SpeedRow row, {required bool isFastest}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: DashStyle.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: DashStyle.stripeW,
            height: 18,
            decoration: BoxDecoration(
              color: row.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            row.speedText,
            style: DashStyle.data.copyWith(
              color: isFastest ? DashStyle.overallFastest : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<_SpeedRow> _topSpeeds() {
    final lines = widget.stats?.lines;
    if (lines == null || lines.isEmpty) return const [];

    final ranked = <_SpeedRow>[];
    for (final line in lines.entries) {
      final entry = line.value;
      final st = entry.bestSpeeds['ST'];
      if (st == null) continue;
      final speed = double.tryParse(st.value.trim());
      if (speed == null) continue;

      // Lines are keyed by racing number; a delta-created entry may lack the
      // RacingNumber field itself.
      final number =
          entry.racingNumber.isNotEmpty ? entry.racingNumber : line.key;
      final driver = widget.drivers[number];
      ranked.add(_SpeedRow(
        speed: speed,
        speedText: st.value.trim(),
        label: (driver?.tla.isNotEmpty ?? false) ? driver!.tla : number,
        color: _teamColor(driver?.teamColour),
      ));
    }

    ranked.sort((a, b) => b.speed.compareTo(a.speed));
    return ranked.take(_maxRows).toList();
  }

  Color _teamColor(String? hex) {
    if (hex != null && hex.length == 6) {
      final parsed = int.tryParse('FF$hex', radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return Colors.grey;
  }
}

class _SpeedRow {
  final double speed;
  final String speedText;
  final String label;
  final Color color;

  const _SpeedRow({
    required this.speed,
    required this.speedText,
    required this.label,
    required this.color,
  });
}
