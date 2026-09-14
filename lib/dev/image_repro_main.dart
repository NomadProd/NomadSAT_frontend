// Throwaway harness for the stale-question-image bug. Delete when done.
//
//   flutter run -d chrome -t lib/dev/image_repro_main.dart
//
// Before the fix: the caption changes on Next, the picture does not.
// After the fix:  the picture changes on every Next.
//
// A widget test cannot show this -- the bug lives in the HTML <img> platform
// view that WebHtmlElementStrategy.prefer mounts, which only exists in a browser.
import 'package:flutter/material.dart';
import 'package:flutter_web/Widgets/exam_question_figure.dart';

/// Three real, distinct practice-test images (test 2, Math module 1).
const _urls = [
  'https://res.cloudinary.com/dnykba68r/image/upload/v1789186322/practice_test_questions/practice_102_43a8965b.png',
  'https://res.cloudinary.com/dnykba68r/image/upload/v1789186474/practice_test_questions/practice_102_30d408b9.png',
  'https://res.cloudinary.com/dnykba68r/image/upload/v1789186574/practice_test_questions/practice_102_a96da397.png',
];

void main() => runApp(const _ReproApp());

class _ReproApp extends StatefulWidget {
  const _ReproApp();

  @override
  State<_ReproApp> createState() => _ReproAppState();
}

class _ReproAppState extends State<_ReproApp> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Question image repro',
      home: Scaffold(
        appBar: AppBar(title: const Text('Question image repro')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Question ${_index + 1} of ${_urls.length}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _urls[_index].split('/').last,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 16),
                // The same const key the exam passes -- that key is the bug, so
                // the repro has to keep it.
                ExamQuestionFigure(
                  key: const Key('diagnostic-question-image'),
                  url: _urls[_index],
                  alt: 'Question image',
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () =>
                      setState(() => _index = (_index + 1) % _urls.length),
                  child: const Text('Next question'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
