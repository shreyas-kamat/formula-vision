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
    final statusColor = _getStatusIndicatorColor(status);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header with accent bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(0.08),
                    statusColor.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: statusColor.withOpacity(0.2),
                    width: 2,
                  ),
                  left: BorderSide(
                    color: statusColor.withOpacity(0.6),
                    width: 5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TRACK STATUS',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Live status indicator with pulse effect
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Track status details
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: message.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusBadge(
                          'STATUS',
                          status.toUpperCase(),
                          statusColor,
                        ),
                        const SizedBox(height: 16),
                        _buildMessageSection(message),
                      ],
                    )
                  : _buildStatusBadge(
                      'STATUS',
                      status.toUpperCase(),
                      statusColor,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, String value, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: statusColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSection(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.amber.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.info_outline,
              color: Colors.amber[300],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Additional Information',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey[100],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
