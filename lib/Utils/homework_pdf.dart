bool canManageHomeworkPdf(String? role) {
  final normalized = (role ?? '').trim().toLowerCase();
  return normalized == 'admin' || normalized == 'mentor';
}

const int maxHomeworkPdfBytes = 50 * 1024 * 1024;
const String homeworkPdfLimitMessage = 'Only PDF files up to 50 MB are allowed';
const String homeworkPdfOpenErrorMessage =
    'Unable to open this homework PDF. Please try again.';

String? validateHomeworkPdfSelection({
  required String filename,
  required int sizeBytes,
  String? extension,
}) {
  final ext = (extension ?? _extensionOf(filename)).toLowerCase();
  if (ext != 'pdf') {
    return homeworkPdfLimitMessage;
  }
  if (sizeBytes > maxHomeworkPdfBytes) {
    return homeworkPdfLimitMessage;
  }
  return null;
}

String formatHomeworkPdfValidationError(Map<String, dynamic> data) {
  final error = data['error']?.toString();
  final detail = data['detail']?.toString();
  switch (error) {
    case 'INVALID_FILE_TYPE':
    case 'INVALID_PDF':
    case 'FILE_TOO_LARGE':
      if (detail != null && detail.isNotEmpty) return detail;
      return homeworkPdfLimitMessage;
    default:
      if (detail != null && detail.isNotEmpty) return detail;
      return 'Validation failed';
  }
}

String _extensionOf(String filename) {
  if (!filename.contains('.')) return '';
  return filename.split('.').last;
}
