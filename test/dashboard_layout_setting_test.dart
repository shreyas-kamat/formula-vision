import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/components/driver_row_card_expanded.dart';
import 'package:formulavision/data/services/app_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Dashboard layout setting', () {
    test('defaults to compact', () async {
      expect(await AppSettings.getDashboardLayout(),
          AppSettings.dashboardLayoutCompact);
    });

    test('persists expanded after setDashboardLayout', () async {
      await AppSettings.setDashboardLayout(AppSettings.dashboardLayoutExpanded);
      expect(await AppSettings.getDashboardLayout(),
          AppSettings.dashboardLayoutExpanded);
    });
  });

  group('DriverRowCardExpanded', () {
    testWidgets('shows the labelled card columns', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DriverRowCardExpanded(
              position: 1,
              name: 'VER',
              currentLapTime: '1:37.426',
              bestLapTime: '1:37.280',
              interval: 'Leader',
              teamColor: Colors.blue,
              tireCompound: 'SOFT',
              pitStops: 0,
              sessionType: 'Race',
              stintLaps: 13,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('LAP TIME'), findsOneWidget);
      expect(find.text('INTERVAL'), findsOneWidget);
      expect(find.text('TYRE'), findsOneWidget);
      expect(find.text('L13'), findsOneWidget);
    });
  });
}
