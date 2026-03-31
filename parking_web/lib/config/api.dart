const String _RAW_BASE_URL = String.fromEnvironment(
  'PARKING_API_BASE_URL',
  defaultValue: 'https://terraqueous-plantar-phebe.ngrok-free.dev',  // ← ngrok backend
);

final String BASE_URL = _RAW_BASE_URL.replaceFirst(RegExp(r'/+$'), '');
