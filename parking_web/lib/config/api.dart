const String BASE_URL = String.fromEnvironment(
  'PARKING_API_BASE_URL',
  defaultValue: 'https://terraqueous-plantar-phebe.ngrok-free.dev',
);

// ในเครื่องเว็บ frontend ที่ใช้ ngrok ให้สลับเป็น URL ของ backend ngrok:
// https://terraqueous-plantar-phebe.ngrok-free.dev
// หรือถ้าในเครื่องเดียวกันลองเป็น http://10.0.0.2:8000
