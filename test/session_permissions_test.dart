import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Utils/session_permissions.dart';

void main() {
  test('tutors can manage sessions, students cannot', () {
    for (final role in ['admin', 'mentor', 'teacher', 'Teacher', ' TEACHER ']) {
      expect(canManageSessions(role), isTrue, reason: role);
    }
    for (final role in ['student', '', null]) {
      expect(canManageSessions(role), isFalse, reason: '$role');
    }
  });

  test('review sessions stay admin and mentor only', () {
    expect(canManageReviewSessions('admin'), isTrue);
    expect(canManageReviewSessions('mentor'), isTrue);
    expect(canManageReviewSessions('teacher'), isFalse);
    expect(canManageReviewSessions('student'), isFalse);
    expect(canManageReviewSessions(null), isFalse);
  });
}
