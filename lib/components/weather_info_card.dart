import 'package:flutter/material.dart';

class WeatherInfoCard extends StatelessWidget {
  final String airTemp;
  final String trackTemp;
  final String windSpeed;
  final String humidity;
  final String weatherCondition; // 'Clear', 'Rain', 'Cloudy', etc.

  const WeatherInfoCard({
    super.key,
    required this.airTemp,
    required this.trackTemp,
    required this.windSpeed,
    required this.humidity,
    required this.weatherCondition,
  });

  @override
  Widget build(BuildContext context) {
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
              // Weather header with condition icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TRACK CONDITIONS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  _buildWeatherIcon(weatherCondition),
                ],
              ),
              const SizedBox(height: 16),

              // Weather metrics in a horizontal scrollable area
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Air temperature
                    _buildWeatherMetric(
                      'AIR TEMP',
                      '$airTemp°C',
                      Icons.thermostat_outlined,
                      Colors.orange[300]!,
                    ),
                    const SizedBox(width: 16),

                    // Track temperature
                    _buildWeatherMetric(
                      'TRACK TEMP',
                      '$trackTemp°C',
                      Icons.terrain_outlined,
                      Colors.red[400]!,
                    ),
                    const SizedBox(width: 16),

                    // Wind speed
                    _buildWeatherMetric(
                      'WIND',
                      '$windSpeed m/s',
                      Icons.air_outlined,
                      Colors.blue[300]!,
                    ),
                    const SizedBox(width: 16),

                    // Humidity
                    _buildWeatherMetric(
                      'HUMIDITY',
                      '$humidity%',
                      Icons.water_drop_outlined,
                      Colors.blue[600]!,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherMetric(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto Mono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherIcon(String condition) {
    IconData iconData;
    Color iconColor;

    switch (condition.toLowerCase()) {
      case 'rain':
        iconData = Icons.umbrella_rounded;
        iconColor = Colors.blue;
        break;
      case 'cloudy':
        iconData = Icons.cloud_rounded;
        iconColor = Colors.grey[300]!;
        break;
      case 'partly cloudy':
        iconData = Icons.cloud_queue_rounded;
        iconColor = Colors.grey[400]!;
        break;
      case 'thunderstorm':
        iconData = Icons.flash_on_rounded;
        iconColor = Colors.amber;
        break;
      case 'clear':
      default:
        iconData = Icons.wb_sunny_rounded;
        iconColor = Colors.amber;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            iconData,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            condition,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
