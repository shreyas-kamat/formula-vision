import 'package:flutter/material.dart';

/// Shared visual tokens for the live dashboard (timing tower + race feed).
class DashStyle {
  static const textPrimary = Colors.white;
  static final textSecondary = Colors.white.withValues(alpha: 0.62);
  static final textLabel = Colors.white.withValues(alpha: 0.5);
  static final divider = Colors.white.withValues(alpha: 0.08);
  static const personalBest = Color(0xFF22C55E); // F1 green
  static const overallFastest = Color(0xFFA855F7); // F1 purple
  static const brandRed = Color(0xFFB32020);

  static const label = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2);
  static const data = TextStyle(
      fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Roboto Mono');
  static const sectionTitle = TextStyle(
      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.4);

  // Timing tower column widths, shared by LeaderboardHeader and DriverRowCard.
  static const double stripeW = 3;
  static const double posW = 30;
  static const double gapW = 78;
  static const double lastW = 86;
  static const double tyreW = 54;
  static const double chevronW = 20;
}
