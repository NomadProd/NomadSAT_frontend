// Parsing of the attempt payload that drives resume.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Models/practice_test.dart';

Map<String, dynamic> _payload(List<Map<String, dynamic>> answers) => {
      'id': 99,
      'test_id': 2,
      'student_id': 42,
      'status': 'in_progress',
      'current_module_id': 8,
      'current_question_id': 123,
      'timer_pause_seconds': 65,
      'answers': answers,
    };

void main() {
  group('PracticeTestAttempt.fromJson', () {
    test('reads a multiple-choice answer', () {
      final attempt = PracticeTestAttempt.fromJson(_payload([
        {'question_id': 1, 'selected_choice': 'B', 'response_text': null},
      ]));
      expect(attempt.answers, {1: 'B'});
    });

    test('reads a grid-in answer from its typed text', () {
      final attempt = PracticeTestAttempt.fromJson(_payload([
        {'question_id': 2, 'selected_choice': null, 'response_text': '2/3'},
      ]));
      expect(attempt.answers, {2: '2/3'},
          reason: 'math grid-ins carry response_text, not a choice key');
    });

    test('skips rows with neither a choice nor text', () {
      final attempt = PracticeTestAttempt.fromJson(_payload([
        {'question_id': 3, 'selected_choice': null, 'response_text': null},
        {'question_id': 4, 'selected_choice': '', 'response_text': ''},
        {'question_id': 5, 'selected_choice': 'A'},
      ]));
      expect(attempt.answers, {5: 'A'},
          reason: 'an empty row is a question the student has not answered, '
              'and must not count towards "answered" on the review');
    });

    test('a missing answers key is not an error', () {
      final payload = _payload([])..remove('answers');
      expect(PracticeTestAttempt.fromJson(payload).answers, isEmpty);
    });

    test('a malformed answers value is not an error', () {
      final payload = _payload([]);
      payload['answers'] = 'nonsense';
      expect(PracticeTestAttempt.fromJson(payload).answers, isEmpty);
    });

    test('carries the fields resume depends on', () {
      final attempt = PracticeTestAttempt.fromJson(_payload([]));
      expect(attempt.currentModuleId, 8);
      expect(attempt.currentQuestionId, 123);
      expect(attempt.timerPauseSeconds, 65);
      expect(attempt.isInProgress, isTrue);
      expect(attempt.isCompleted, isFalse);
    });

    test('a completed attempt reports itself as completed', () {
      final payload = _payload([])..['status'] = 'completed';
      final attempt = PracticeTestAttempt.fromJson(payload);
      expect(attempt.isCompleted, isTrue);
      expect(attempt.isInProgress, isFalse);
    });
  });
}
