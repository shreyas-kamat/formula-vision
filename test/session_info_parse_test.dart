import 'package:flutter_test/flutter_test.dart';
import 'package:formulavision/data/models/live_data.model.dart';

void main() {
  test('Meeting.fromJson reads F1 capitalised keys', () {
    final m = Meeting.fromJson({
      'Key': 1290,
      'Name': 'Spanish Grand Prix',
      'Location': 'Madrid',
      'Country': {'Key': 1, 'Code': 'ESP', 'Name': 'Spain'},
      'Circuit': {'Key': 153, 'ShortName': 'Madring'},
    });
    expect(m.key, 1290);
    expect(m.circuit.key, 153);
    expect(m.circuit.shortName, 'Madring');
  });

  test('Meeting.fromJson still reads legacy lowercase keys', () {
    final m = Meeting.fromJson({
      'key': 7,
      'Name': 'X',
      'circuit': {'key': 49, 'shortName': 'Shanghai'},
    });
    expect(m.key, 7);
    expect(m.circuit.key, 49);
    expect(m.circuit.shortName, 'Shanghai');
  });
}
