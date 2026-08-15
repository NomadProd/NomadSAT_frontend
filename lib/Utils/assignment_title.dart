String assignmentDisplayTitle({
  required String? title,
  required String sessionType,
  int? slotIndex,
  bool isMock = false,
}) {
  final custom = (title ?? '').trim();
  if (custom.isNotEmpty) return custom;
  if (isMock || sessionType.toLowerCase() == 'mock') return 'Mock submission';
  final type = sessionType.trim();
  final labeledType = type.isEmpty
      ? 'Homework'
      : '${type[0].toUpperCase()}${type.substring(1)}';
  final slot = slotIndex == null ? '' : ' $slotIndex';
  return '$labeledType homework$slot';
}
