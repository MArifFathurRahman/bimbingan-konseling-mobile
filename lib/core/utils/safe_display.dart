String safeDisplayName(String? raw, String fallback) {
  if (raw == null || raw.trim().isEmpty) return fallback;
  final trimmed = raw.trim();
  if (trimmed.length > 24 && !trimmed.contains(' ')) return fallback;
  return trimmed;
}

String getInitials(String name) {
  if (name.trim().isEmpty) return '?';
  final parts = name.trim().split(' ');
  if (parts.length >= 2 &&
      parts[0].isNotEmpty &&
      parts[1].isNotEmpty) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return parts[0][0].toUpperCase();
}
