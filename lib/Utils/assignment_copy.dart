bool canCopyAssignment({
  required String? role,
  required int? sessionTeacherId,
  required int? currentUserId,
}) {
  final normalized = (role ?? '').trim().toLowerCase();
  if (normalized == 'admin' || normalized == 'mentor') return true;
  if (normalized == 'teacher') {
    return sessionTeacherId != null &&
        currentUserId != null &&
        sessionTeacherId == currentUserId;
  }
  return false;
}
