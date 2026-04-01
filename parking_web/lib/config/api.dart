const String _RAW_BASE_URL = String.fromEnvironment(
  'PARKING_API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

final String BASE_URL = _RAW_BASE_URL.replaceFirst(RegExp(r'/+$'), '');
