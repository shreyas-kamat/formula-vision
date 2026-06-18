import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/data/models/live_data.model.dart';

void main() {
  group('CarTelemetry.fromJson', () {
    test('parses the API broadcast shape (capitalised keys)', () {
      final t = CarTelemetry.fromJson({
        'RPM': 11500,
        'Speed': 312,
        'Gear': 8,
        'Throttle': 100,
        'Brake': 0,
        'DRS': 12,
      });

      expect(t.rpm, 11500);
      expect(t.speed, 312);
      expect(t.gear, 8);
      expect(t.throttle, 100);
      expect(t.brake, 0);
      expect(t.isDrsActive, isTrue); // 12 == active
    });

    test('DRS off / closed states are not active', () {
      expect(CarTelemetry.fromJson({'DRS': 0}).isDrsActive, isFalse);
      expect(CarTelemetry.fromJson({'DRS': 1}).isDrsActive, isFalse);
      expect(CarTelemetry.fromJson({'DRS': 8}).isDrsActive, isFalse); // eligible
      expect(CarTelemetry.fromJson({'DRS': 10}).isDrsActive, isTrue);
      expect(CarTelemetry.fromJson({'DRS': 14}).isDrsActive, isTrue);
    });

    test('tolerates string/double numbers and missing fields', () {
      final t = CarTelemetry.fromJson({'Speed': '305', 'RPM': 9000.0});
      expect(t.speed, 305);
      expect(t.rpm, 9000);
      expect(t.gear, 0);
      expect(t.brake, 0);
    });
  });
}
