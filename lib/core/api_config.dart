const String baseUrl = 'https://portal.grjoffice.com';

/// Builds a full URL for relative media/avatar paths from the API.
String mediaUrl(String? path) {
  if (path == null) return '';
  final trimmed = path.trim();
  if (trimmed.isEmpty || trimmed == 'null') return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final normalized = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  return '$baseUrl/$normalized';
}
