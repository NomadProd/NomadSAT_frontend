import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Models/class_models.dart';

void main() {
  final u = UserInfo(
    userId: 140,
    name: 'Abai',
    surname: 'Maketov',
    role: 'student',
  );

  test('matchesSearch: name either order, ID prefix, case-insensitive', () {
    expect(u.matchesSearch(''), isTrue);
    expect(u.matchesSearch('  abai mak '), isTrue);
    expect(u.matchesSearch('MAKETOV ABAI'), isTrue);
    expect(u.matchesSearch('14'), isTrue);
    expect(u.matchesSearch('140'), isTrue);
    expect(u.matchesSearch('40'), isFalse);
    expect(u.matchesSearch('adiya'), isFalse);
  });
}
