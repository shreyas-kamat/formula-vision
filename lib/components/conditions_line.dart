import 'package:flutter/material.dart';
import 'package:formulavision/components/dashboard_style.dart';
import 'package:formulavision/data/models/live_data.model.dart';

/// One-line track conditions strip shown above the timing tower.
class ConditionsLine extends StatelessWidget {
  final WeatherData? weather;

  const ConditionsLine({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final w = weather;
    if (w == null) return const SizedBox.shrink();

    final bool dry = w.rainfall.isEmpty || w.rainfall == '0';

    final items = <Widget>[
      _item(
        dry ? Icons.wb_sunny_outlined : Icons.water_drop_outlined,
        dry ? Colors.amber : Colors.lightBlue,
        null,
        dry ? 'Clear' : 'Rain',
      ),
      if (w.airTemp.isNotEmpty)
        _item(Icons.thermostat_outlined, DashStyle.textSecondary, 'Air',
            '${w.airTemp}°'),
      if (w.trackTemp.isNotEmpty)
        _item(Icons.landscape_outlined, DashStyle.textSecondary, 'Track',
            '${w.trackTemp}°'),
      if (w.windSpeed.isNotEmpty)
        _item(Icons.air, DashStyle.textSecondary, 'Wind',
            '${w.windSpeed} m/s'),
      if (w.humidity.isNotEmpty)
        _item(Icons.water_outlined, DashStyle.textSecondary, 'Hum',
            '${w.humidity}%'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: items,
      ),
    );
  }

  Widget _item(IconData icon, Color iconColor, String? prefix, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 4),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 12),
            children: [
              if (prefix != null)
                TextSpan(
                  text: '$prefix ',
                  style: TextStyle(color: DashStyle.textSecondary),
                ),
              TextSpan(
                text: value,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
