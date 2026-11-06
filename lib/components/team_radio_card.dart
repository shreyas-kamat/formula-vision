import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:formulavision/components/dashboard_style.dart';
import 'package:formulavision/data/models/live_data.model.dart';

/// Newest team radio clips with inline playback. Owns its own [AudioPlayer]
/// (separate from the race-control alert sound in the dashboard).
class TeamRadioCard extends StatefulWidget {
  final TeamRadio? teamRadio;
  final Map<String, Driver> drivers;
  // SessionInfo.path (ends with '/'), prefixed to each capture path.
  final String sessionPath;

  const TeamRadioCard({
    super.key,
    required this.teamRadio,
    required this.drivers,
    required this.sessionPath,
  });

  @override
  State<TeamRadioCard> createState() => _TeamRadioCardState();
}

class _TeamRadioCardState extends State<TeamRadioCard> {
  static const int _collapsedRows = 3;
  static const int _maxRows = 8;
  static const String _staticBase =
      'https://livetiming.formula1.com/static/';

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _completeSub;
  String? _playingPath;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingPath = null);
    });
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  List<RadioCapture> _newestCaptures() {
    final captures = [...?widget.teamRadio?.captures];
    DateTime parse(RadioCapture c) => DateTime.tryParse(c.utc) ?? DateTime(0);
    captures.sort((a, b) => parse(b).compareTo(parse(a)));
    return captures.take(_maxRows).toList();
  }

  String _urlFor(RadioCapture capture) =>
      '$_staticBase${widget.sessionPath}${capture.path}';

  Future<void> _togglePlay(RadioCapture capture) async {
    try {
      if (_playingPath == capture.path) {
        await _player.stop();
        if (mounted) setState(() => _playingPath = null);
        return;
      }
      await _player.stop();
      if (mounted) setState(() => _playingPath = capture.path);
      await _player.play(UrlSource(_urlFor(capture)));
    } catch (e) {
      debugPrint('[TeamRadioCard] playback failed: $e');
      if (mounted) {
        setState(() => _playingPath = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't play this team radio clip")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _newestCaptures();
    if (rows.isEmpty || widget.sessionPath.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = _showAll ? rows : rows.take(_collapsedRows).toList();
    final bool canToggle = rows.length > _collapsedRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('TEAM RADIO', style: DashStyle.sectionTitle),
            const Spacer(),
            Text('LATEST',
                style: DashStyle.label.copyWith(color: DashStyle.textLabel)),
          ],
        ),
        const SizedBox(height: 8),
        Divider(height: 1, thickness: 1, color: DashStyle.divider),
        for (final capture in visible) _buildRow(capture),
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
                _showAll ? 'Show less' : 'Show more',
                style:
                    DashStyle.label.copyWith(color: DashStyle.textSecondary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRow(RadioCapture capture) {
    final driver = widget.drivers[capture.racingNumber];
    final label = (driver?.tla.isNotEmpty ?? false)
        ? driver!.tla
        : (capture.racingNumber.isNotEmpty ? capture.racingNumber : '???');
    final color = _teamColor(driver?.teamColour);
    final isPlaying = _playingPath == capture.path;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: DashStyle.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: DashStyle.stripeW,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 10),
          Text(
            _localTime(capture.utc),
            style: TextStyle(
              color: DashStyle.textSecondary,
              fontSize: 12,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: isPlaying ? 'Stop' : 'Play',
            visualDensity: VisualDensity.compact,
            iconSize: 22,
            icon: Icon(
              isPlaying
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline,
              color: isPlaying ? DashStyle.brandRed : Colors.white70,
            ),
            onPressed: () => _togglePlay(capture),
          ),
        ],
      ),
    );
  }

  String _localTime(String utc) {
    final time = DateTime.tryParse(utc)?.toLocal();
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  Color _teamColor(String? hex) {
    if (hex != null && hex.length == 6) {
      final parsed = int.tryParse('FF$hex', radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return Colors.grey;
  }
}
