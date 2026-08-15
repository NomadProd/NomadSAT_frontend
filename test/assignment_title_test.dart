import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Utils/assignment_title.dart';

void main() {
  test('uses custom title when present', () {
    expect(
      assignmentDisplayTitle(
        title: 'Reading packet',
        sessionType: 'verbal',
        slotIndex: 1,
      ),
      'Reading packet',
    );
  });

  test('uses 1-based slot index without adding one', () {
    expect(
      assignmentDisplayTitle(
        title: null,
        sessionType: 'math',
        slotIndex: 1,
      ),
      'Math homework 1',
    );
  });

  test('labels mock sessions without a slot number', () {
    expect(
      assignmentDisplayTitle(
        title: '',
        sessionType: 'mock',
        slotIndex: 1,
        isMock: true,
      ),
      'Mock submission',
    );
  });
}
