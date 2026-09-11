// Mirrors the backend gates on /sessions so the UI offers exactly what the API
// accepts: POST/PATCH allow teacher (scoped to their own classes), DELETE and
// anything touching a review session are admin/mentor only.

bool canManageSessions(String? role) {
  final normalized = (role ?? '').trim().toLowerCase();
  return normalized == 'admin' ||
      normalized == 'mentor' ||
      normalized == 'teacher';
}

bool canManageReviewSessions(String? role) {
  final normalized = (role ?? '').trim().toLowerCase();
  return normalized == 'admin' || normalized == 'mentor';
}
