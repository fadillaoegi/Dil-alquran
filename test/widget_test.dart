import 'package:dilalquran/modules/data/models/juz_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Juz boundary data should contain 30 juz', () {
    expect(juzBoundaries.length, 30);
    expect(juzBoundaries.first.number, 1);
    expect(juzBoundaries.last.number, 30);
  });
}
