import 'dart:convert';
import 'dart:io';

void main() {
  // Test the cleanName parsing logic
  testCleanName();
}

void testCleanName() {
  final testCases = [
    "F1: FP1 (Australian Grand Prix)",
    "F1: FP2 (Australian Grand Prix)",
    "F1: Qualifying (Australian Grand Prix)",
    "F1: Grand Prix (Australian Grand Prix)",
    "F1: Sprint Qualifying (Chinese Grand Prix)",
    "F1: Sprint (Chinese Grand Prix)",
  ];

  for (final testCase in testCases) {
    final cleanName = getCleanName(testCase);
    print('$testCase -> $cleanName');
  }
}

String getCleanName(String summary) {
  final prefixes = ['🏎 FORMULA 1 ', '⏱️ FORMULA 1 ', '🏁 FORMULA 1 '];
  String name = summary;

  // Handle 2025 format with emojis
  for (var prefix in prefixes) {
    if (name.startsWith(prefix)) {
      name = name.substring(prefix.length);
      break;
    }
  }

  // Handle 2026 format: "F1: FP1 (Australian Grand Prix)"
  if (name.startsWith('F1: ') && name.contains(' (') && name.endsWith(')')) {
    final start = name.indexOf('(') + 1;
    final end = name.indexOf(')');
    return name.substring(start, end);
  }

  // Get the grand prix name without the event type (2025 format)
  if (name.contains(' - ')) {
    final parts = name.split(' - ');
    return parts[0];
  }

  return name;
}
