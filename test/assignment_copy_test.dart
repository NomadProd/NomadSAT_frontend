import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Utils/assignment_copy.dart';

void main() {
  test('admin can copy any assignment', () {
    expect(
      canCopyAssignment(
        role: 'admin',
        sessionTeacherId: 99,
        currentUserId: 1,
      ),
      isTrue,
    );
  });

  test('mentor can copy any assignment', () {
    expect(
      canCopyAssignment(
        role: 'mentor',
        sessionTeacherId: 99,
        currentUserId: 2,
      ),
      isTrue,
    );
  });

  test('teacher can copy only their own session assignments', () {
    expect(
      canCopyAssignment(
        role: 'teacher',
        sessionTeacherId: 700,
        currentUserId: 700,
      ),
      isTrue,
    );
    expect(
      canCopyAssignment(
        role: 'teacher',
        sessionTeacherId: 900,
        currentUserId: 700,
      ),
      isFalse,
    );
  });

  test('student cannot copy assignments', () {
    expect(
      canCopyAssignment(
        role: 'student',
        sessionTeacherId: 700,
        currentUserId: 400,
      ),
      isFalse,
    );
  });

  testWidgets('copy controls are omitted when the role cannot copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: canCopyAssignment(
                role: 'student',
                sessionTeacherId: 1,
                currentUserId: 2,
              )
              ? OutlinedButton(
                  key: const Key('copy-assignment'),
                  onPressed: () {},
                  child: const Text('Copy'),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.byKey(const Key('copy-assignment')), findsNothing);
    expect(find.text('Copy'), findsNothing);
  });

  testWidgets('teacher copy controls appear only for owned sessions', (
    tester,
  ) async {
    Widget copyButtons({required bool canCopy}) {
      return Column(
        children: [
          if (canCopy)
            OutlinedButton(
              key: const Key('copy-assignment'),
              onPressed: () {},
              child: const Text('Copy'),
            ),
          if (canCopy)
            OutlinedButton(
              key: const Key('copy-to-class'),
              onPressed: () {},
              child: const Text('Copy to class'),
            ),
        ],
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: copyButtons(
            canCopy: canCopyAssignment(
              role: 'teacher',
              sessionTeacherId: 700,
              currentUserId: 700,
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('copy-assignment')), findsOneWidget);
    expect(find.byKey(const Key('copy-to-class')), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: copyButtons(
            canCopy: canCopyAssignment(
              role: 'teacher',
              sessionTeacherId: 900,
              currentUserId: 700,
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('copy-assignment')), findsNothing);
    expect(find.byKey(const Key('copy-to-class')), findsNothing);
  });
}
