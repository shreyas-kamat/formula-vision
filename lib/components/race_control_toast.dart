import 'package:flutter/material.dart';
import 'package:formulavision/data/models/live_data.model.dart';

/// Helpers for surfacing race control messages as toasts and deciding which
/// of them are "important" enough to also trigger the alert sound.
class RaceControlToast {
  /// Categories that always count as important.
  static const Set<String> _importantCategories = {
    'flag',
    'safetycar',
    'penalty',
    'investigation',
  };

  /// Flags that count as important even when the category is generic.
  static const Set<String> _importantFlags = {
    'red',
    'safety car',
    'vsc',
    'virtual safety car',
    'double yellow',
    'chequered',
  };

  /// Whether this message should trigger the alert sound.
  static bool isImportant(Message message) {
    final category = message.category.toLowerCase().replaceAll(' ', '');
    if (_importantCategories.contains(category)) return true;

    final flag = message.flag?.toLowerCase();
    if (flag != null && _importantFlags.contains(flag)) return true;

    return false;
  }

  /// Colour used for the toast accent, based on flag/category.
  static Color _accentColor(Message message) {
    final flag = message.flag?.toLowerCase();
    switch (flag) {
      case 'red':
        return Colors.red.shade700;
      case 'yellow':
      case 'double yellow':
        return Colors.amber.shade700;
      case 'green':
      case 'clear':
        return Colors.green.shade700;
      case 'blue':
        return Colors.blue.shade700;
      case 'chequered':
        return Colors.black87;
      case 'white':
        return Colors.blueGrey.shade600;
    }

    switch (message.category.toLowerCase()) {
      case 'penalty':
        return Colors.deepOrange.shade700;
      case 'safetycar':
      case 'safety car':
        return Colors.amber.shade800;
      case 'investigation':
        return Colors.orange.shade700;
      default:
        return Colors.blueGrey.shade700;
    }
  }

  static IconData _icon(Message message) {
    switch (message.category.toLowerCase()) {
      case 'flag':
        return Icons.flag_rounded;
      case 'penalty':
        return Icons.gavel_rounded;
      case 'safetycar':
      case 'safety car':
        return Icons.directions_car_rounded;
      case 'investigation':
        return Icons.search_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  /// Builds a styled floating SnackBar for a race control message, matching the
  /// app's existing toast style (rounded, icon, coloured accent).
  static SnackBar buildSnackBar(Message message) {
    final accent = _accentColor(message);
    return SnackBar(
      backgroundColor: accent.withValues(alpha: 0.92),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 4),
      content: Row(
        children: [
          Icon(_icon(message), color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.category.isNotEmpty
                      ? 'RACE CONTROL · ${message.category.toUpperCase()}'
                      : 'RACE CONTROL',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'formula',
                    fontSize: 10,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'formula',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
