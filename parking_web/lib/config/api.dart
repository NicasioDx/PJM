const String _RAW_BASE_URL = String.fromEnvironment(
  'PARKING_API_BASE_URL',
  defaultValue: 'https://revocable-ventrally-sergio.ngrok-free.dev',
);

final String BASE_URL = _RAW_BASE_URL.replaceFirst(RegExp(r'/+$'), '');
