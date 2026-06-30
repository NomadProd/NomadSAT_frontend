import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/screens/student/homework_submit_screen.dart';

/// Backward-compatible entry point used by existing navigation.
class HomeworkDetailPage extends HomeworkSubmitScreen {
  const HomeworkDetailPage({
    super.key,
    required super.title,
    required super.className,
    required super.deadline,
    required super.sessionType,
    required super.assignment,
    super.result,
  });
}
