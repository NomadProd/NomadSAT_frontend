import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Utils/homework_pdf.dart';
import 'package:flutter_web/Widgets/homework_pdf_section.dart';

HomeworkDocument _sampleDocument() {
  return const HomeworkDocument(
    url: 'https://res.cloudinary.com/demo/raw/upload/algebra_homework.pdf',
    filename: 'algebra_homework.pdf',
    contentType: 'application/pdf',
    sizeBytes: 2456789,
    uploadedAt: '2026-08-10T12:00:00Z',
  );
}

Widget _wrap(Widget child, {double width = 900}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

void main() {
  test('admin and mentor can manage homework PDFs', () {
    expect(canManageHomeworkPdf('admin'), isTrue);
    expect(canManageHomeworkPdf('mentor'), isTrue);
    expect(canManageHomeworkPdf('ADMIN'), isTrue);
  });

  test('teacher and student cannot manage homework PDFs', () {
    expect(canManageHomeworkPdf('teacher'), isFalse);
    expect(canManageHomeworkPdf('student'), isFalse);
    expect(canManageHomeworkPdf(null), isFalse);
  });

  test('file picker validation rejects non-PDF files', () {
    expect(
      validateHomeworkPdfSelection(
        filename: 'notes.docx',
        sizeBytes: 1024,
        extension: 'docx',
      ),
      homeworkPdfLimitMessage,
    );
  });

  test('file picker validation rejects files larger than 50 MB', () {
    expect(
      validateHomeworkPdfSelection(
        filename: 'huge.pdf',
        sizeBytes: maxHomeworkPdfBytes + 1,
        extension: 'pdf',
      ),
      homeworkPdfLimitMessage,
    );
  });

  test('file picker validation accepts a valid PDF', () {
    expect(
      validateHomeworkPdfSelection(
        filename: 'algebra_homework.pdf',
        sizeBytes: 1024,
        extension: 'pdf',
      ),
      isNull,
    );
  });

  test('structured backend validation errors are displayed clearly', () {
    expect(
      formatHomeworkPdfValidationError({
        'error': 'INVALID_FILE_TYPE',
        'filename': 'document.docx',
        'detail': 'Only PDF files are allowed',
      }),
      'Only PDF files are allowed',
    );
    expect(
      formatHomeworkPdfValidationError({
        'error': 'FILE_TOO_LARGE',
        'filename': 'large_homework.pdf',
        'max_mb': 50,
        'detail': 'The PDF must not exceed 50 MB',
      }),
      'The PDF must not exceed 50 MB',
    );
    expect(
      formatHomeworkPdfValidationError({
        'error': 'INVALID_PDF',
        'filename': 'fake.pdf',
        'detail': 'The uploaded file is not a valid PDF',
      }),
      'The uploaded file is not a valid PDF',
    );
  });

  test('AssignmentInfo parses homework_document and keeps task_link', () {
    final assignment = AssignmentInfo.fromJson({
      'assignment_id': 123,
      'session_id': 1,
      'student_id': 9,
      'slot_index': 1,
      'title': 'Homework 1',
      'instruction': 'Do page 4',
      'task_link': 'https://example.com/legacy-task',
      'due_date': '2026-08-12',
      'due_time': '18:30:00',
      'photo_required': true,
      'homework_document': {
        'url': 'https://res.cloudinary.com/demo/raw/upload/algebra_homework.pdf',
        'filename': 'algebra_homework.pdf',
        'content_type': 'application/pdf',
        'size_bytes': 2456789,
        'uploaded_at': '2026-08-10T12:00:00Z',
      },
    });

    expect(assignment.taskLink, 'https://example.com/legacy-task');
    expect(assignment.homeworkDocument?.filename, 'algebra_homework.pdf');
    expect(assignment.homeworkDocument?.sizeBytes, 2456789);
  });

  test('legacy assignments without homework_document still parse', () {
    final assignment = AssignmentInfo.fromJson({
      'assignment_id': 5,
      'session_id': 1,
      'student_id': 9,
      'task_link': 'https://example.com/legacy-task',
      'photo_required': false,
    });

    expect(assignment.taskLink, 'https://example.com/legacy-task');
    expect(assignment.homeworkDocument, isNull);
  });

  testWidgets('admin sees upload controls', (tester) async {
    await tester.pumpWidget(
      _wrap(
        HomeworkPdfSection(
          document: null,
          canManage: canManageHomeworkPdf('admin'),
          onPick: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('homework-pdf-upload')), findsOneWidget);
    expect(find.text('Upload homework PDF'), findsOneWidget);
    expect(find.byKey(const Key('homework-pdf-remove')), findsNothing);
  });

  testWidgets('mentor sees upload and replace controls', (tester) async {
    await tester.pumpWidget(
      _wrap(
        HomeworkPdfSection(
          document: _sampleDocument(),
          canManage: canManageHomeworkPdf('mentor'),
          onPick: () {},
          onRemove: () {},
          onOpen: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('homework-pdf-replace')), findsOneWidget);
    expect(find.byKey(const Key('homework-pdf-remove')), findsOneWidget);
    expect(find.byKey(const Key('homework-pdf-open')), findsOneWidget);
  });

  testWidgets('teacher does not see upload or delete controls', (tester) async {
    await tester.pumpWidget(
      _wrap(
        HomeworkPdfSection(
          document: _sampleDocument(),
          canManage: canManageHomeworkPdf('teacher'),
          onOpen: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('homework-pdf-upload')), findsNothing);
    expect(find.byKey(const Key('homework-pdf-replace')), findsNothing);
    expect(find.byKey(const Key('homework-pdf-remove')), findsNothing);
    expect(find.byKey(const Key('homework-pdf-open')), findsOneWidget);
  });

  testWidgets('student does not see upload or delete controls', (tester) async {
    await tester.pumpWidget(
      _wrap(
        HomeworkPdfSection(
          document: _sampleDocument(),
          canManage: canManageHomeworkPdf('student'),
          onOpen: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('homework-pdf-upload')), findsNothing);
    expect(find.byKey(const Key('homework-pdf-remove')), findsNothing);
    expect(find.text('Open PDF'), findsOneWidget);
  });

  testWidgets('frontend displays existing PDF metadata', (tester) async {
    await tester.pumpWidget(
      _wrap(
        HomeworkPdfSection(
          document: _sampleDocument(),
          canManage: false,
          onOpen: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('homework-pdf-filename')), findsOneWidget);
    expect(find.text('algebra_homework.pdf'), findsOneWidget);
    expect(find.textContaining('MB'), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
  });

  testWidgets('frontend displays upload progress', (tester) async {
    await tester.pumpWidget(
      _wrap(
        HomeworkPdfSection(
          document: null,
          pendingFile: PlatformFile(
            name: 'pending.pdf',
            size: 2048,
            bytes: Uint8List.fromList(const [1, 2, 3]),
          ),
          canManage: true,
          uploading: true,
          onPick: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('homework-pdf-progress')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('frontend displays structured backend validation errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        HomeworkPdfSection(
          document: null,
          canManage: true,
          message: formatHomeworkPdfValidationError({
            'error': 'INVALID_PDF',
            'filename': 'fake.pdf',
            'detail': 'The uploaded file is not a valid PDF',
          }),
          messageIsError: true,
          onPick: () {},
        ),
      ),
    );

    expect(
      find.byKey(const Key('homework-pdf-message')),
      findsOneWidget,
    );
    expect(find.text('The uploaded file is not a valid PDF'), findsOneWidget);
  });

  testWidgets('mobile layout has no horizontal overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(
        HomeworkPdfSection(
          document: const HomeworkDocument(
            url: 'https://res.cloudinary.com/demo/raw/upload/very_long.pdf',
            filename:
                'very_long_algebra_homework_document_name_that_should_wrap.pdf',
            contentType: 'application/pdf',
            sizeBytes: 1234567,
          ),
          canManage: true,
          onPick: () {},
          onRemove: () {},
          onOpen: () {},
        ),
        width: 320,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('homework-pdf-section')), findsOneWidget);
  });

  testWidgets('desktop layout remains usable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(
        HomeworkPdfSection(
          document: _sampleDocument(),
          canManage: true,
          onPick: () {},
          onRemove: () {},
          onOpen: () {},
        ),
        width: 720,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Replace PDF'), findsOneWidget);
    expect(find.text('Open PDF'), findsOneWidget);
    expect(find.text('Remove PDF'), findsOneWidget);
  });
}
