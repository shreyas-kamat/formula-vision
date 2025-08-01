import 'package:flutter/material.dart';

class TrackStatusCard extends StatelessWidget {
  final String status;
  final String message;

  const TrackStatusCard({
    super.key,
    required this.status,
    required this.message,
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
            // Header with subtle accent
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
                    color: _getStatusIndicatorColor(status).withOpacity(0.8),
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'TRACK STATUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  // Live status indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusIndicatorColor(status),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              _getStatusIndicatorColor(status).withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Track status details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Current status section
                  Expanded(
                    child: _buildStatusSection(
                      'CURRENT STATUS',
                      status.toUpperCase(),
                      Icons.flag_circle,
                      _getStatusIndicatorColor(status),
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    // Status message section
                    Expanded(
                      flex: 2,
                      child: _buildStatusSection(
                        'INFORMATION',
                        message,
                        Icons.info_outline,
                        Colors.blue[300]!,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(
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
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: label == 'CURRENT STATUS' ? iconColor : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
            maxLines: label == 'INFORMATION' ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper method to get status-specific icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'green':
      case 'clear':
        return Icons.check_circle;
      case 'yellow':
      case 'caution':
        return Icons.warning;
      case 'red':
      case 'stopped':
        return Icons.stop_circle;
      case 'safety car':
      case 'sc':
        return Icons.directions_car;
      case 'virtual safety car':
      case 'vsc':
        return Icons.security;
      default:
        return Icons.flag;
    }
  }

  // Helper method to get indicator color based on status
  Color _getStatusIndicatorColor(String status) {
    switch (status.toLowerCase()) {
      case 'green':
      case 'clear':
        return Colors.green;
      case 'yellow':
      case 'caution':
        return Colors.amber;
      case 'red':
      case 'stopped':
        return Colors.red;
      case 'safety car':
      case 'sc':
        return Colors.orange;
      case 'virtual safety car':
      case 'vsc':
        return Colors.blue;
      default:
        return Colors.white;
    }
  }
}
