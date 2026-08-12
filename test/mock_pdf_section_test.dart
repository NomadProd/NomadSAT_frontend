import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Utils/homework_pdf.dart';
import 'package:flutter_web/Widgets/homework_pdf_section.dart';

HomeworkDocument _sampleMockDocument() {
  return const HomeworkDocument(
    url: 'https://res.cloudinary.com/demo/raw/upload/sat_mock_3_full.pdf',
    filename: 'sat_mock_3_full.pdf',
    contentType: 'application/pdf',
    sizeBytes: 3456789,
    uploadedAt: '2026-08-12T12:00:00Z',
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

HomeworkPdfSection _mockSection({
  HomeworkDocument? document,
  required String role,
  bool uploading = false,
  String? message,
  bool messageIsError = false,
  PlatformFile? pendingFile,
}) {
  return HomeworkPdfSection(
    document: document,
    pendingFile: pendingFile,
    canManage: canManageHomeworkPdf(role),
    uploading: uploading,
    message: message,
    messageIsError: messageIsError,
    title: 'Mock Test Document',
    emptyFilename: 'No test document uploaded yet',
    uploadLabel: 'Upload PDF',
    sectionKey: 'mock-pdf',
    onPick: () {},
    onRemove: document != null ? () {} : null,
    onOpen: document != null ? () {} : null,
  );
}

void main() {
  test('SessionInfo parses mock_document separately from homework_document', () {
    final session = SessionInfo.fromJson({
      'session_id': 456,
      'class_id': 10,
      'teacher_id': null,
      'date': '2026-08-12',
      'start_time': '09:00:00',
      'end_time': '12:00:00',
      'session_type': 'mock',
      'subject': null,
      'topic': 'SAT Mock',
      'academic_plan_item_id': null,
      'academic_plan_item_ids': <int>[],
      'lesson_notes': null,
      'mock_document': {
        'url': 'https://res.cloudinary.com/demo/raw/upload/sat_mock_3_full.pdf',
        'filename': 'sat_mock_3_full.pdf',
        'content_type': 'application/pdf',
        'size_bytes': 3456789,
        'uploaded_at': '2026-08-12T12:00:00Z',
      },
    });

    expect(session.sessionType, 'mock');
    expect(session.mockDocument?.filename, 'sat_mock_3_full.pdf');
    expect(session.mockDocument?.sizeBytes, 3456789);
  });

  test('legacy mock sessions without mock_document still parse', () {
    final session = SessionInfo.fromJson({
      'session_id': 456,
      'class_id': 10,
      'date': '2026-08-12',
      'session_type': 'mock',
    });

    expect(session.mockDocument, isNull);
  });

  testWidgets('admin sees upload controls on a mock session', (tester) async {
    await tester.pumpWidget(_wrap(_mockSection(role: 'admin')));

    expect(find.byKey(const Key('mock-pdf-upload')), findsOneWidget);
    expect(find.text('Upload PDF'), findsOneWidget);
    expect(find.byKey(const Key('mock-pdf-remove')), findsNothing);
    expect(find.text('No test document uploaded yet'), findsOneWidget);
  });

  testWidgets('mentor sees replace and delete controls on a mock session', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(_mockSection(document: _sampleMockDocument(), role: 'mentor')),
    );

    expect(find.byKey(const Key('mock-pdf-replace')), findsOneWidget);
    expect(find.byKey(const Key('mock-pdf-remove')), findsOneWidget);
    expect(find.byKey(const Key('mock-pdf-open')), findsOneWidget);
    expect(find.text('Replace PDF'), findsOneWidget);
    expect(find.text('Remove PDF'), findsOneWidget);
  });

  testWidgets('teacher sees the mock document as read-only', (tester) async {
    await tester.pumpWidget(
      _wrap(_mockSection(document: _sampleMockDocument(), role: 'teacher')),
    );

    expect(find.byKey(const Key('mock-pdf-upload')), findsNothing);
    expect(find.byKey(const Key('mock-pdf-replace')), findsNothing);
    expect(find.byKey(const Key('mock-pdf-remove')), findsNothing);
    expect(find.byKey(const Key('mock-pdf-open')), findsOneWidget);
    expect(find.text('Open PDF'), findsOneWidget);
  });

  testWidgets('student sees the mock document as read-only', (tester) async {
    await tester.pumpWidget(
      _wrap(_mockSection(document: _sampleMockDocument(), role: 'student')),
    );

    expect(find.byKey(const Key('mock-pdf-upload')), findsNothing);
    expect(find.byKey(const Key('mock-pdf-replace')), findsNothing);
    expect(find.byKey(const Key('mock-pdf-remove')), findsNothing);
    expect(find.text('Open PDF'), findsOneWidget);
  });

  testWidgets('student empty state is neutral when no document exists', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_mockSection(role: 'student')));

    expect(find.text('No test document uploaded yet'), findsOneWidget);
    expect(find.byKey(const Key('mock-pdf-open')), findsNothing);
    expect(find.byKey(const Key('mock-pdf-upload')), findsNothing);
  });

  test('file picker rejects non-PDF files client-side', () {
    expect(
      validateHomeworkPdfSelection(
        filename: 'notes.docx',
        sizeBytes: 1024,
        extension: 'docx',
      ),
      homeworkPdfLimitMessage,
    );
  });

  testWidgets('upload progress and structured backend errors display', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        _mockSection(
          role: 'admin',
          uploading: true,
          pendingFile: PlatformFile(
            name: 'sat_mock_3_full.pdf',
            size: 2048,
            bytes: Uint8List.fromList(const [1, 2, 3]),
          ),
          message: formatHomeworkPdfValidationError({
            'error': 'INVALID_PDF',
            'filename': 'fake.pdf',
            'detail': 'The uploaded file is not a valid PDF',
          }),
          messageIsError: true,
        ),
      ),
    );

    expect(find.byKey(const Key('mock-pdf-progress')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('mock-pdf-message')), findsOneWidget);
    expect(find.text('The uploaded file is not a valid PDF'), findsOneWidget);
  });

  testWidgets('mobile layout has no horizontal overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(
        _mockSection(
          document: const HomeworkDocument(
            url: 'https://res.cloudinary.com/demo/raw/upload/very_long.pdf',
            filename:
                'very_long_sat_mock_test_document_name_that_should_wrap.pdf',
            contentType: 'application/pdf',
            sizeBytes: 1234567,
          ),
          role: 'admin',
        ),
        width: 320,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('mock-pdf-section')), findsOneWidget);
  });

  testWidgets('desktop layout remains usable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(
        _mockSection(document: _sampleMockDocument(), role: 'mentor'),
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
