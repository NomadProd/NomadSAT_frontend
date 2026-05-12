import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:flutter_web/Services/api_config.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Services/auth_service.dart';

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// Colours (mirrors class_detail_page.dart constants)
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
const _kPrimary = Color(0xFF1A4AF0);
const _kBg = Color(0xFFF0F4FF);
const _kBorder = Color(0xFFD7E3FF);
const _kPanelBg = Color(0xFFF4F7FF);
const _kTextDark = Color(0xFF0D1B3E);
const _kTextMid = Color(0xFF4A5A7A);
const _kTextLight = Color(0xFF9AAAC6);
const _kSuccess = Color(0xFF1B873F);
const _kSuccessBg = Color(0xFFE8F5E9);
const _kWarning = Color(0xFFBF6000);
const _kWarningBg = Color(0xFFFFF3E0);

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// Model
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class AcademicPlanEntry {
  final int sessionId;
  final int? planItemId;
  final String? subject;
  final String sessionType;
  final String lesson;
  final DateTime date;
  final String topic;
  final String plan;
  final String? fact; // null = not yet completed

  const AcademicPlanEntry({
    this.sessionId = 0,
    this.planItemId,
    this.subject,
    this.sessionType = '',
    required this.lesson,
    required this.date,
    required this.topic,
    required this.plan,
    this.fact,
  });

  bool get isCompleted => fact != null && fact!.trim().isNotEmpty;
  bool get isMock => lesson.toLowerCase().contains('mock');
}

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// Service - replace _fetchVerbal / _fetchMath with real API calls later
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class AcademicPlanService {
  final String baseUrl = ApiConfig.baseUrl;
  final http.Client _client = BrowserClient()..withCredentials = true;

  // ignore: unused_element
  Future<List<AcademicPlanEntry>> fetchVerbal(int classId) async =>
      _fetchEntries(classId, 'verbal');

  // ignore: unused_element
  Future<List<AcademicPlanEntry>> fetchMath(int classId) async =>
      _fetchEntries(classId, 'math');

  Future<List<AcademicPlanEntry>> _fetchEntries(
    int classId,
    String subject,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/classes/$classId/lesson-notes'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load academic plan');
    }

    final List data = decodeJsonResponse(response);
    final entries = <AcademicPlanEntry>[];
    for (final raw in data) {
      final sessionType = raw['session_type']?.toString().toLowerCase() ?? '';
      final planItems =
          raw['academic_plan_items'] as List<dynamic>? ?? const [];

      for (final plan in planItems) {
        final planSubject = plan['subject']?.toString().toLowerCase() ?? '';
        final matchesSubject =
            planSubject == subject ||
            sessionType == subject ||
            sessionType == 'mock';
        if (!matchesSubject) continue;
        entries.add(_entryFromJson(raw, subject, plan));
      }

      final shouldAddPlaceholder =
          planItems.isEmpty &&
          (sessionType == subject || sessionType == 'mock');
      if (shouldAddPlaceholder) {
        entries.add(_entryFromJson(raw, subject, null));
      }
    }

    entries.sort((a, b) => a.date.compareTo(b.date));

    return entries;
  }

  AcademicPlanEntry _entryFromJson(
    dynamic json,
    String fallbackSubject,
    dynamic plan,
  ) {
    final subject =
        plan?['subject']?.toString() ??
        _capitalizePlan(json['session_type']?.toString() ?? fallbackSubject);
    final sessionType = json['session_type']?.toString() ?? '';
    final isMock = sessionType.toLowerCase() == 'mock';
    final normalizedSubject = subject.trim().isEmpty
        ? fallbackSubject
        : subject;

    return AcademicPlanEntry(
      sessionId: json['session_id'] ?? 0,
      planItemId: plan?['id'] as int?,
      subject: plan?['subject']?.toString(),
      sessionType: sessionType,
      lesson: isMock ? 'Mock Exam' : _capitalizePlan(normalizedSubject),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      topic:
          plan?['general_topic']?.toString() ?? json['topic']?.toString() ?? '',
      plan:
          plan?['plan_text']?.toString() ??
          json['topic']?.toString() ??
          'No academic plan selected for this session.',
      fact: json['lesson_notes']?.toString(),
    );
  }

  Future<Map<String, dynamic>> updateSessionAcademicPlan({
    required int sessionId,
    int? planItemId,
    String? subject,
    String? generalTopic,
    String? planText,
    String? lessonNotes,
    String? date,
  }) async {
    if (planItemId == null) {
      return createSessionAcademicPlan(
        sessionId: sessionId,
        subject: subject,
        generalTopic: generalTopic,
        planText: planText,
        lessonNotes: lessonNotes,
        date: date,
      );
    }

    try {
      final response = await _client.patch(
        Uri.parse(
          '$baseUrl/sessions/$sessionId/academic-plan-items/$planItemId',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subject': subject,
          'general_topic': generalTopic,
          'plan_text': planText,
          'lesson_notes': lessonNotes,
          'date': date,
        }),
      );

      final data = decodeJsonResponse(response);
      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ??
            data['detail'] ??
            'Failed to update academic plan',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> createSessionAcademicPlan({
    required int sessionId,
    String? subject,
    String? generalTopic,
    String? planText,
    String? lessonNotes,
    String? date,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/sessions/$sessionId/academic-plan-items'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subject': subject,
          'general_topic': generalTopic,
          'plan_text': planText,
          'lesson_notes': lessonNotes,
          'date': date,
        }),
      );

      final data = decodeJsonResponse(response);
      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ?? data['detail'] ?? 'Failed to add academic plan',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteSessionAcademicPlan(
    int sessionId, {
    int? planItemId,
  }) async {
    if (planItemId == null) {
      return {
        'success': false,
        'message': 'Academic plan item not found for this row.',
      };
    }

    try {
      final response = await _client.delete(
        Uri.parse(
          '$baseUrl/sessions/$sessionId/academic-plan-items/$planItemId',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      final data = decodeJsonResponse(response);
      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ??
            data['detail'] ??
            'Failed to delete academic plan',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  // в”Ђв”Ђ Verbal data (from Raider_-_Academic_Plan.xlsx - sheet Verbal) в”Ђв”Ђ
  static final _verbalData = <AcademicPlanEntry>[
    AcademicPlanEntry(
      lesson: 'Verbal-1',
      date: DateTime(2026, 4, 6),
      topic: 'Standard English Conventions',
      plan: 'Oneprep:\n1. Boundaries (medium) 1-21\n2. Boundaries (hard) 1-21',
      fact: 'Completed',
    ),
    AcademicPlanEntry(
      lesson: 'Verbal-2',
      date: DateTime(2026, 4, 8),
      topic: 'Standard English Conventions',
      plan: 'Basics of grammar',
      fact: 'Completed',
    ),
    AcademicPlanEntry(
      lesson: 'Verbal-3',
      date: DateTime(2026, 4, 10),
      topic: 'Standard English Conventions',
      plan:
          'Oneprep:\n1. Form, Structure, and Sense (easy) approx. 10\n'
          '2. Form, Structure, and Sense (medium) approx. 10\n'
          '3. Form, Structure, and Sense (hard) approx. 10',
      fact: 'Completed',
    ),
    AcademicPlanEntry(
      lesson: 'MOCK-1 Review',
      date: DateTime(2026, 4, 11),
      topic: 'MOCKs',
      plan: 'BB6',
      fact: 'Completed',
    ),
    AcademicPlanEntry(
      lesson: 'MOCK-2 Review',
      date: DateTime(2026, 4, 12),
      topic: 'MOCKs',
      plan: 'BB7',
      fact: 'Completed',
    ),
    AcademicPlanEntry(
      lesson: 'Verbal-4',
      date: DateTime(2026, 4, 13),
      topic: 'Expression of Ideas',
      plan:
          'Oneprep:\n1. Rhetorical Synthesis (easy) approx. 8\n'
          '2. Rhetorical Synthesis (medium) approx. 8\n'
          '3. Rhetorical Synthesis (hard) approx. 8',
      fact: 'Completed',
    ),
    AcademicPlanEntry(
      lesson: 'Verbal-5',
      date: DateTime(2026, 4, 15),
      topic: 'Information and Ideas',
      plan:
          'Oneprep:\n1. Central Ideas and Details (easy) 1-15\n'
          '2. Central Ideas and Details (medium) 1-10',
      fact: 'Completed',
    ),
    AcademicPlanEntry(
      lesson: 'Verbal-6',
      date: DateTime(2026, 4, 17),
      topic: 'Information and Ideas',
      plan:
          'Oneprep:\n1. Inferences (easy) approx. 8\n'
          '2. Inferences (medium) approx. 8\n'
          '3. Inferences (hard) approx. 8',
      fact: 'Completed',
    ),
    AcademicPlanEntry(
      lesson: 'MOCK-3 Review',
      date: DateTime(2026, 4, 18),
      topic: 'MOCKs',
      plan: 'BB11',
      fact: 'Completed',
    ),
    AcademicPlanEntry(
      lesson: 'MOCK-4 Review',
      date: DateTime(2026, 4, 19),
      topic: 'MOCKs',
      plan: 'TBD',
    ),
    AcademicPlanEntry(
      lesson: 'Verbal-7',
      date: DateTime(2026, 4, 20),
      topic: 'Craft and Structure',
      plan:
          'Oneprep:\n1. Cross-Text Connections (easy) approx. 8\n'
          '2. Cross-Text Connections (medium) approx. 8\n'
          '3. Cross-Text Connections (hard) approx. 8',
    ),
    AcademicPlanEntry(
      lesson: 'Verbal-8',
      date: DateTime(2026, 4, 22),
      topic: 'Craft and Structure',
      plan:
          'Oneprep:\n1. Text Structure and Purpose (easy) approx. 8\n'
          '2. Text Structure and Purpose (medium) approx. 8\n'
          '3. Text Structure and Purpose (hard) approx. 8',
    ),
    AcademicPlanEntry(
      lesson: 'Verbal-9',
      date: DateTime(2026, 4, 24),
      topic: 'Craft and Structure',
      plan:
          'Oneprep:\n1. Words in Context (easy) approx. 8\n'
          '2. Words in Context (medium) approx. 8\n'
          '3. Words in Context (hard) approx. 8',
    ),
    AcademicPlanEntry(
      lesson: 'MOCK-5 Review',
      date: DateTime(2026, 4, 25),
      topic: 'MOCKs',
      plan: 'TBD',
    ),
    AcademicPlanEntry(
      lesson: 'MOCK-6 Review',
      date: DateTime(2026, 4, 26),
      topic: 'MOCKs',
      plan: 'TBD',
    ),
    AcademicPlanEntry(
      lesson: 'Verbal-10',
      date: DateTime(2026, 4, 27),
      topic: 'MOCKs',
      plan: 'BB+ past-paper March 2026',
    ),
    AcademicPlanEntry(
      lesson: 'Verbal-11',
      date: DateTime(2026, 4, 29),
      topic: 'MOCKs',
      plan: 'BB+ prediction May 2026',
    ),
    AcademicPlanEntry(
      lesson: 'Verbal-12',
      date: DateTime(2026, 5, 1),
      topic: 'MOCKs',
      plan: 'BB+ prediction May 2026',
    ),
  ];

  // в”Ђв”Ђ Math data (from Raider_-_Academic_Plan.xlsx - sheet Math) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  static final _mathData = <AcademicPlanEntry>[
    AcademicPlanEntry(
      lesson: 'Math-1',
      date: DateTime(2026, 4, 7),
      topic: 'Algebra',
      plan:
          'Trial materials:\n1. Math 1 - Linear & Modeling Problems (easy) 1-15',
      fact:
          'Trial materials:\n1. Math 1 - Linear & Modeling Problems (easy) 1-8\n'
          'Oneprep:\n1. Linear equations in one variable (easy & medium & hard) 1-10\n'
          '2. Linear equations in one variable (medium & hard) 1-8',
    ),
    AcademicPlanEntry(
      lesson: 'Math-2',
      date: DateTime(2026, 4, 9),
      topic: 'Algebra',
      plan:
          'Oneprep:\n1. Linear functions (medium) 1-20\n'
          '2. Linear equations in two variables (medium) 1-15',
      fact:
          'Oneprep:\n1. Linear functions (medium) 1-20\n'
          '2. Linear equations in two variables (medium) 1-15\n'
          '3. Linear functions (hard) 1-9\n'
          '4. Linear equations in two variables (hard) 8-26',
    ),
    AcademicPlanEntry(
      lesson: 'MOCK-1 Review',
      date: DateTime(2026, 4, 11),
      topic: 'MOCKs',
      plan: 'BB6',
      fact: 'Completed',
    ),
    AcademicPlanEntry(
      lesson: 'MOCK-2 Review',
      date: DateTime(2026, 4, 12),
      topic: 'MOCKs',
      plan: 'BB7',
      fact: 'Completed',
    ),
    AcademicPlanEntry(
      lesson: 'Math-3',
      date: DateTime(2026, 4, 14),
      topic: 'Notes & Strategy',
      plan: '1. Desmos hacks\n2. Shortcut strategies (TBD)',
    ),
    AcademicPlanEntry(
      lesson: 'Math-4',
      date: DateTime(2026, 4, 16),
      topic: 'Problem-Solving - Data Analysis - Advanced Math',
      plan:
          'PrepPros book:\n1. Chapter 30. Word Problems\n'
          '2. Chapter 31. Solving for Constants',
      fact: 'Completed',
    ),
    AcademicPlanEntry(
      lesson: 'Math-5',
      date: DateTime(2026, 4, 18),
      topic: 'Problem-Solving - Data Analysis - Algebra',
      plan:
          'PrepPros book:\n1. Chapter 23. Ratios and Proportions\n'
          '2. Chapter 9. Percentages\n'
          '3. Chapter 32. Systems of Equations\n'
          '(going through weak topics)',
      fact: 'Completed',
    ),
    AcademicPlanEntry(
      lesson: 'Math-6',
      date: DateTime(2026, 4, 19),
      topic: 'Geometry - Trigonometry - Problem-Solving',
      plan:
          'SATashkent Math book:\n1. Geometry and Trigonometry\n'
          '2. Statistics\n(going through weak topics)',
    ),
    AcademicPlanEntry(
      lesson: 'Math-7',
      date: DateTime(2026, 4, 21),
      topic: 'Advanced Math',
      plan:
          'SATashkent Math book:\n'
          '1. Doing as much as possible in Advanced Math\n'
          '(going through weak topics)',
    ),
    AcademicPlanEntry(
      lesson: 'Math-8',
      date: DateTime(2026, 4, 23),
      topic: 'Algebra',
      plan: 'PrepPros book:\n1. Chapter 35\n(going through weak topics)',
    ),
    AcademicPlanEntry(
      lesson: 'Math-9',
      date: DateTime(2026, 4, 25),
      topic: 'MOCKs & Tasks',
      plan: 'BB+ past-paper March 2026 + Hardest SAT Questions',
    ),
    AcademicPlanEntry(
      lesson: 'Math-10',
      date: DateTime(2026, 4, 26),
      topic: 'MOCKs & Tasks',
      plan: 'BB+ past-paper March 2026 + Hardest SAT Questions',
    ),
    AcademicPlanEntry(
      lesson: 'Math-11',
      date: DateTime(2026, 4, 28),
      topic: 'MOCKs',
      plan: 'BB+ prediction May 2026',
    ),
    AcademicPlanEntry(
      lesson: 'Math-12',
      date: DateTime(2026, 4, 30),
      topic: 'MOCKs',
      plan: 'BB+ prediction May 2026 + Breakdown',
    ),
  ];
}

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// Page
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class AcademicPlanPage extends StatefulWidget {
  final int classId;
  final String className;
  const AcademicPlanPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<AcademicPlanPage> createState() => _AcademicPlanPageState();
}

class _AcademicPlanPageState extends State<AcademicPlanPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _service = AcademicPlanService();
  final _authService = AuthService();

  List<AcademicPlanEntry>? _verbal, _math;
  bool _loading = true;
  bool _canEditPlan = false;
  bool _canDeletePlan = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _service.fetchVerbal(widget.classId),
      _service.fetchMath(widget.classId),
      _authService.fetchMe(),
    ]);
    if (!mounted) return;
    final role = ((results[2] as dynamic).role as String).toLowerCase();
    setState(() {
      _verbal = results[0] as List<AcademicPlanEntry>;
      _math = results[1] as List<AcademicPlanEntry>;
      _canEditPlan = role == 'admin' || role == 'mentor' || role == 'teacher';
      _canDeletePlan = role == 'admin';
      _loading = false;
    });
  }

  DateTime get _today =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  int _completedCount(List<AcademicPlanEntry> entries) =>
      entries.where((e) => e.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    final verbalEntries = _sortedEntriesByDate(_verbal ?? []);
    final mathEntries = _sortedEntriesByDate(_math ?? []);

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _AcademicPlanHeader(
            className: widget.className,
            onBack: () => Navigator.of(context).pop(),
            verbalCompleted: _completedCount(verbalEntries),
            verbalTotal: verbalEntries.length,
            mathCompleted: _completedCount(mathEntries),
            mathTotal: mathEntries.length,
            tabController: _tab,
            isAdmin: _canEditPlan,
            onEditVerbal: () => _openSubjectPlanManager(
              context,
              subject: 'verbal',
              entries: verbalEntries,
            ),
            onEditMath: () => _openSubjectPlanManager(
              context,
              subject: 'math',
              entries: mathEntries,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _kPrimary),
                  )
                : TabBarView(
                    controller: _tab,
                    children: [
                      _PlanTab(
                        entries: verbalEntries,
                        today: _today,
                        isAdmin: _canEditPlan,
                        canDelete: _canDeletePlan,
                        onChanged: _load,
                        service: _service,
                      ),
                      _PlanTab(
                        entries: mathEntries,
                        today: _today,
                        isAdmin: _canEditPlan,
                        canDelete: _canDeletePlan,
                        onChanged: _load,
                        service: _service,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSubjectPlanManager(
    BuildContext context, {
    required String subject,
    required List<AcademicPlanEntry> entries,
  }) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => _SubjectPlanManagerDialog(
        subject: subject,
        entries: entries,
        service: _service,
        canDelete: _canDeletePlan,
      ),
    );

    if (changed == true) {
      await _load();
    }
  }
}

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// Header
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _AcademicPlanHeader extends StatelessWidget {
  final String className;
  final VoidCallback onBack;
  final int verbalCompleted, verbalTotal, mathCompleted, mathTotal;
  final TabController tabController;
  final bool isAdmin;
  final VoidCallback? onEditVerbal;
  final VoidCallback? onEditMath;

  const _AcademicPlanHeader({
    required this.className,
    required this.onBack,
    required this.verbalCompleted,
    required this.verbalTotal,
    required this.mathCompleted,
    required this.mathTotal,
    required this.tabController,
    required this.isAdmin,
    required this.onEditVerbal,
    required this.onEditMath,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: _kPrimary,
      boxShadow: [
        BoxShadow(
          color: Color(0x441A4AF0),
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned.fill(child: _BrandPatternSmall()),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CircleBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
                    const SizedBox(width: 14),
                    _LogoBox(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Academic Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          Text(
                            className,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.72),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _ProgressChip(
                      label: 'Verbal',
                      completed: verbalCompleted,
                      total: verbalTotal,
                      color: const Color(0xFFCE93D8),
                      actionLabel: isAdmin ? 'Edit plan' : null,
                      onAction: onEditVerbal,
                    ),
                    const SizedBox(width: 10),
                    _ProgressChip(
                      label: 'Math',
                      completed: mathCompleted,
                      total: mathTotal,
                      color: const Color(0xFF80CBC4),
                      actionLabel: isAdmin ? 'Edit plan' : null,
                      onAction: onEditMath,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.55),
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Verbal'),
                    Tab(text: 'Math'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProgressChip extends StatelessWidget {
  final String label;
  final int completed, total;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ProgressChip({
    required this.label,
    required this.completed,
    required this.total,
    required this.color,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini arc progress
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 3.5,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Text(
                  '${(pct * 100).round()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$completed / $total lessons',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.34)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// Plan tab - timeline list
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _PlanTab extends StatelessWidget {
  final List<AcademicPlanEntry> entries;
  final DateTime today;
  final bool isAdmin;
  final bool canDelete;
  final Future<void> Function() onChanged;
  final AcademicPlanService service;

  const _PlanTab({
    required this.entries,
    required this.today,
    required this.isAdmin,
    required this.canDelete,
    required this.onChanged,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('No plan data', style: TextStyle(color: _kTextMid)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      itemCount: entries.length,
      itemBuilder: (ctx, i) {
        final entry = entries[i];
        final eDate = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        final isToday = eDate == today;
        final isPast = eDate.isBefore(today);
        final isUpcoming = eDate.isAfter(today);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PlanEntryCard(
            entry: entry,
            isToday: isToday,
            isPast: isPast,
            isUpcoming: isUpcoming,
            index: i,
            isAdmin: isAdmin,
            canDelete: canDelete,
            onChanged: onChanged,
            service: service,
          ),
        );
      },
    );
  }
}

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// Entry card
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _PlanEntryCard extends StatefulWidget {
  final AcademicPlanEntry entry;
  final bool isToday, isPast, isUpcoming;
  final int index;
  final bool isAdmin;
  final bool canDelete;
  final Future<void> Function() onChanged;
  final AcademicPlanService service;

  const _PlanEntryCard({
    required this.entry,
    required this.isToday,
    required this.isPast,
    required this.isUpcoming,
    required this.index,
    required this.isAdmin,
    required this.canDelete,
    required this.onChanged,
    required this.service,
  });

  @override
  State<_PlanEntryCard> createState() => _PlanEntryCardState();
}

class _PlanEntryCardState extends State<_PlanEntryCard> {
  bool _expanded = false;

  Future<void> _openEditDialog() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => _AcademicPlanEditDialog(
        entry: widget.entry,
        service: widget.service,
        canDelete: widget.canDelete,
      ),
    );

    if (changed == true) {
      await widget.onChanged();
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto-expand today's card
    _expanded = widget.isToday;
  }

  Color get _accentColor {
    if (widget.isToday) return _kPrimary;
    if (widget.entry.isCompleted) return _kSuccess;
    if (widget.isPast)
      return const Color(0xFFEF6C00); // orange = past/no record
    return _kTextLight;
  }

  Color get _bg {
    if (widget.isToday) return const Color(0xFFEBF1FF);
    if (widget.entry.isCompleted) return _kSuccessBg;
    if (widget.isPast && !widget.entry.isCompleted) return _kWarningBg;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final d = e.date;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr = '${d.day} ${months[d.month - 1]} ${d.year}';
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayStr = days[d.weekday - 1];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.isToday
              ? _kPrimary.withOpacity(0.6)
              : widget.entry.isCompleted
              ? _kSuccess.withOpacity(0.3)
              : _kBorder,
          width: widget.isToday ? 2 : 1,
        ),
        boxShadow: widget.isToday
            ? [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                const BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        children: [
          // в”Ђв”Ђ Header row в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: _accentColor.withOpacity(0.3)),
                    ),
                    child: Icon(
                      widget.isToday
                          ? Icons.today_rounded
                          : widget.entry.isCompleted
                          ? Icons.check_circle_rounded
                          : widget.isPast
                          ? Icons.history_rounded
                          : Icons.schedule_rounded,
                      color: _accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Lesson info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (widget.isToday) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _kPrimary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'TODAY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                e.lesson,
                                style: TextStyle(
                                  color: _kTextDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  decoration: widget.entry.isCompleted
                                      ? TextDecoration.none
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          e.topic,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: _kTextLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$dayStr - $dateStr',
                              style: const TextStyle(
                                color: _kTextLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isAdmin)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: OutlinedButton(
                            onPressed: _openEditDialog,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kPrimary,
                              side: const BorderSide(color: _kBorder),
                              minimumSize: const Size(0, 30),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Edit'),
                          ),
                        ),
                      _StatusBadge(
                        label: widget.isToday
                            ? 'In progress'
                            : widget.entry.isCompleted
                            ? 'Done'
                            : widget.isPast
                            ? 'Past'
                            : 'Upcoming',
                        color: _accentColor,
                      ),
                      const SizedBox(height: 6),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: _kTextLight,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // в”Ђв”Ђ Expandable body в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFFDDE6FF)),
                  const SizedBox(height: 12),
                  // Plan section
                  _PlanSection(
                    label: 'PLAN',
                    text: e.plan,
                    iconColor: _kPrimary,
                    bgColor: const Color(0xFFEEF3FF),
                    borderColor: const Color(0xFFD0DCFF),
                  ),
                  // Fact section (only if completed and fact differs from plan)
                  if (e.isCompleted) ...[
                    const SizedBox(height: 10),
                    _PlanSection(
                      label: 'COMPLETED',
                      text: e.fact == 'Completed'
                          ? 'Lesson completed as planned вњ“'
                          : e.fact!,
                      iconColor: _kSuccess,
                      bgColor: _kSuccessBg,
                      borderColor: _kSuccess.withOpacity(0.25),
                    ),
                  ],
                  if (widget.isPast && !e.isCompleted) ...[
                    const SizedBox(height: 10),
                    _PlanSection(
                      label: 'STATUS',
                      text: 'No completion record for this lesson.',
                      iconColor: _kWarning,
                      bgColor: _kWarningBg,
                      borderColor: _kWarning.withOpacity(0.25),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanSection extends StatelessWidget {
  final String label, text;
  final Color iconColor, bgColor, borderColor;

  const _PlanSection({
    required this.label,
    required this.text,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: iconColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            color: _kTextDark,
            fontSize: 13,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _AcademicPlanEditDialog extends StatefulWidget {
  final AcademicPlanEntry entry;
  final AcademicPlanService service;
  final bool canDelete;

  const _AcademicPlanEditDialog({
    required this.entry,
    required this.service,
    required this.canDelete,
  });

  @override
  State<_AcademicPlanEditDialog> createState() =>
      _AcademicPlanEditDialogState();
}

class _AcademicPlanEditDialogState extends State<_AcademicPlanEditDialog> {
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _topicCtrl;
  late final TextEditingController _planCtrl;
  late final TextEditingController _notesCtrl;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _subjectCtrl = TextEditingController(
      text: widget.entry.subject ?? _normalizeSubject(widget.entry.sessionType),
    );
    _dateCtrl = TextEditingController(text: _dateForApi(widget.entry.date));
    _topicCtrl = TextEditingController(text: widget.entry.topic);
    _planCtrl = TextEditingController(text: widget.entry.plan);
    _notesCtrl = TextEditingController(text: widget.entry.fact ?? '');
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _dateCtrl.dispose();
    _topicCtrl.dispose();
    _planCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await widget.service.updateSessionAcademicPlan(
      sessionId: widget.entry.sessionId,
      planItemId: widget.entry.planItemId,
      subject: _subjectCtrl.text.trim().isEmpty
          ? null
          : _subjectCtrl.text.trim().toLowerCase(),
      generalTopic: _topicCtrl.text.trim(),
      planText: _planCtrl.text.trim(),
      lessonNotes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
      date: _dateCtrl.text.trim().isEmpty ? null : _dateCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message']?.toString() ?? 'Saved')),
    );

    if (result['success'] == true) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _pickDate() async {
    final initial =
        DateTime.tryParse(_dateCtrl.text.trim()) ?? widget.entry.date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _dateCtrl.text = _dateForApi(picked));
  }

  Future<void> _delete() async {
    if (widget.entry.planItemId == null) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _deleting = true);
    final result = await widget.service.deleteSessionAcademicPlan(
      widget.entry.sessionId,
      planItemId: widget.entry.planItemId,
    );
    if (!mounted) return;
    setState(() => _deleting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message']?.toString() ?? 'Deleted')),
    );

    if (result['success'] == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _deleting;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Academic Plan',
                  style: TextStyle(
                    color: _kTextDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.entry.lesson,
                  style: const TextStyle(
                    color: _kTextMid,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 520;

                    final subjectField = TextField(
                      controller: _subjectCtrl,
                      enabled: !busy,
                      decoration: _fieldDeco(
                        'Subject',
                        hint: 'verbal, math, mock',
                      ),
                    );

                    final dateField = TextField(
                      controller: _dateCtrl,
                      readOnly: true,
                      enabled: !busy,
                      onTap: busy ? null : _pickDate,
                      decoration: _fieldDeco(
                        'Assigned date',
                        hint: 'YYYY-MM-DD',
                      ),
                    );

                    if (narrow) {
                      return Column(
                        children: [
                          subjectField,
                          const SizedBox(height: 12),
                          dateField,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: subjectField),
                        const SizedBox(width: 12),
                        Expanded(child: dateField),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),
                TextField(
                  controller: _topicCtrl,
                  enabled: !busy,
                  decoration: _fieldDeco('General topic'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _planCtrl,
                  enabled: !busy,
                  minLines: 5,
                  maxLines: 8,
                  decoration: _fieldDeco('Plan text'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesCtrl,
                  enabled: !busy,
                  minLines: 4,
                  maxLines: 7,
                  decoration: _fieldDeco('Lesson notes'),
                ),
                const SizedBox(height: 18),

                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    if (widget.canDelete)
                      TextButton(
                        onPressed: busy || widget.entry.planItemId == null
                            ? null
                            : _delete,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFC62828),
                        ),
                        child: _deleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Delete'),
                      ),
                    ElevatedButton(
                      onPressed: busy ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanSessionPickerDialog extends StatelessWidget {
  final String subject;
  final List<AcademicPlanEntry> sessions;

  const _PlanSessionPickerDialog({
    required this.subject,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final sortedSessions = _sortedEntriesByDate(sessions);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 520),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose ${_capitalizePlan(subject)} Session',
              style: const TextStyle(
                color: _kTextDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pick the class session/day that should receive the new plan row.',
              style: TextStyle(color: _kTextMid, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sortedSessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = sortedSessions[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(entry),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.lesson,
                            style: const TextStyle(
                              color: _kTextDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatPlanDate(entry.date)}${entry.topic.isEmpty ? '' : ' * ${entry.topic}'}',
                            style: const TextStyle(
                              color: _kTextMid,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectPlanManagerDialog extends StatefulWidget {
  final String subject;
  final List<AcademicPlanEntry> entries;
  final AcademicPlanService service;
  final bool canDelete;

  const _SubjectPlanManagerDialog({
    required this.subject,
    required this.entries,
    required this.service,
    required this.canDelete,
  });

  @override
  State<_SubjectPlanManagerDialog> createState() =>
      _SubjectPlanManagerDialogState();
}

class _SubjectPlanManagerDialogState extends State<_SubjectPlanManagerDialog> {
  bool _changed = false;

  List<AcademicPlanEntry> _sessionChoices() {
    final uniqueBySession = <int, AcademicPlanEntry>{};
    for (final entry in _sortedEntriesByDate(widget.entries)) {
      uniqueBySession.putIfAbsent(entry.sessionId, () => entry);
    }
    return uniqueBySession.values.toList();
  }

  Future<void> _editEntry(AcademicPlanEntry entry) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => _AcademicPlanEditDialog(
        entry: entry,
        service: widget.service,
        canDelete: widget.canDelete,
      ),
    );

    if (!mounted) return;
    if (changed == true) {
      setState(() => _changed = true);
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _deleteEntry(AcademicPlanEntry entry) async {
    if (entry.planItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This session does not have a plan row yet.'),
        ),
      );
      return;
    }

    final result = await widget.service.deleteSessionAcademicPlan(
      entry.sessionId,
      planItemId: entry.planItemId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message']?.toString() ?? 'Deleted')),
    );
    if (result['success'] == true) {
      setState(() => _changed = true);
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _addNew() async {
    final sessions = _sessionChoices();
    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available session to add a new plan.'),
        ),
      );
      return;
    }

    final selectedSession = await showDialog<AcademicPlanEntry>(
      context: context,
      builder: (context) =>
          _PlanSessionPickerDialog(subject: widget.subject, sessions: sessions),
    );

    if (!mounted || selectedSession == null) return;

    await _editEntry(
      AcademicPlanEntry(
        sessionId: selectedSession.sessionId,
        subject: widget.subject,
        sessionType: selectedSession.sessionType,
        lesson: selectedSession.lesson,
        date: selectedSession.date,
        topic: selectedSession.topic,
        plan: '',
        fact: selectedSession.fact,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _sortedEntriesByDate(widget.entries);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 760,
        constraints: const BoxConstraints(maxHeight: 640),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_capitalizePlan(widget.subject)} Plan',
                        style: const TextStyle(
                          color: _kTextDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Manage dates, topics, plan text, and linked notes.',
                        style: TextStyle(color: _kTextMid, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _addNew,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add new'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Text(
                        'No plan rows found.',
                        style: TextStyle(color: _kTextMid),
                      ),
                    )
                  : ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _kBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.planItemId == null
                                          ? entry.lesson
                                          : '${entry.lesson}  *  Plan #${entry.planItemId}',
                                      style: const TextStyle(
                                        color: _kTextDark,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_formatPlanDate(entry.date)}${entry.topic.isEmpty ? '' : ' * ${entry.topic}'}',
                                      style: const TextStyle(
                                        color: _kTextMid,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: () => _editEntry(entry),
                                child: const Text('Edit'),
                              ),
                              if (widget.canDelete)
                                TextButton(
                                  onPressed: () => _deleteEntry(entry),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFC62828),
                                  ),
                                  child: const Text('Delete'),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(_changed),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// Lightweight logo & pattern (re-implemented to avoid cross-library
// private class access)
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _LogoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.3)),
    ),
    child: const Padding(
      padding: EdgeInsets.all(8),
      child: Image(
        image: AssetImage('assets/brand/turan_symbol.png'),
        fit: BoxFit.contain,
      ),
    ),
  );
}

class _BrandPatternSmall extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(painter: _LeafPainter(), child: const SizedBox.expand()),
  );
}

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    const step = 80.0;
    for (double y = -step; y < size.height + step; y += step) {
      for (double x = -step; x < size.width + step; x += step) {
        final seed = ((x ~/ step) * 31 + (y ~/ step) * 17) % 7;
        final ox = (seed % 3) * 8.0, oy = ((seed * 5) % 4) * 7.0;
        final rot = seed * 0.9;
        final r = 18.0;
        canvas.save();
        canvas.translate(x + ox, y + oy);
        canvas.rotate(rot);
        canvas.drawPath(
          Path()
            ..moveTo(0, -r)
            ..cubicTo(r * 0.9, -r * 0.9, r * 0.9, r * 0.4, 0, r)
            ..cubicTo(-r * 0.4, r * 0.4, -r * 0.4, -r * 0.4, 0, -r),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LeafPainter _) => false;
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(19),
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

String _capitalizePlan(String v) =>
    v.isEmpty ? v : v[0].toUpperCase() + v.substring(1).toLowerCase();

List<AcademicPlanEntry> _sortedEntriesByDate(List<AcademicPlanEntry> entries) {
  final sorted = [...entries];
  sorted.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return a.sessionId.compareTo(b.sessionId);
  });
  return sorted;
}

bool _isPlaceholderPlan(String value) {
  final text = value.trim();
  return text.isEmpty || text == 'No academic plan selected for this session.';
}

String _dateForApi(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _formatPlanDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

InputDecoration _fieldDeco(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kPrimary, width: 1.5),
    ),
    filled: true,
    fillColor: _kPanelBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

String _normalizeSubject(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized == 'verbal' || normalized == 'math' || normalized == 'mock') {
    return normalized;
  }
  return normalized.isEmpty ? 'verbal' : normalized;
}
