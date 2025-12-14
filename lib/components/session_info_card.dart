import 'package:flutter/material.dart';

class SessionInfoCard extends StatelessWidget {
  final String raceName;
  final String sessionName;
  final String sessionType;
  final String location;
  final String country;
  final String circuit;
  final String status;

  const SessionInfoCard({
    super.key,
    required this.raceName,
    required this.sessionName,
    required this.sessionType,
    required this.location,
    required this.country,
    required this.circuit,
    required this.status,
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
        child: Column(
          children: [
            // Session header with subtle accent
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey[850]!,
                    Colors.grey[800]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  left: BorderSide(
                    color: const Color(0xFFE10600).withOpacity(0.6),
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getSessionIcon(sessionType),
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          raceName.isNotEmpty
                              ? raceName.toUpperCase()
                              : 'FORMULA 1',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          sessionName.isNotEmpty
                              ? sessionName.toUpperCase()
                              : sessionType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Session details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Location and Country info
                  Row(
                    children: [
                      // Location section
                      Expanded(
                        child: _buildInfoSection(
                          'LOCATION',
                          location.isNotEmpty ? location : 'Unknown',
                          Icons.location_on,
                          Colors.orange[300]!,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Country section
                      Expanded(
                        child: _buildInfoSection(
                          'COUNTRY',
                          country.isNotEmpty ? country : 'Unknown',
                          Icons.flag,
                          Colors.blue[300]!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper method to get session-specific icon
  IconData _getSessionIcon(String sessionType) {
    switch (sessionType.toLowerCase()) {
      case 'race':
        return Icons.flag;
      case 'qualifying':
        return Icons.timer;
      case 'practice':
        return Icons.directions_car;
      case 'sprint':
        return Icons.speed;
      default:
        return Icons.sports_motorsports;
    }
  }

  // Helper method to get color based on status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'live':
      case 'active':
        return Colors.green;
      case 'finished':
      case 'complete':
        return Colors.blue;
      case 'delayed':
      case 'postponed':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
