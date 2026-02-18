import 'package:flutter/material.dart';
import 'screens/add_camera.dart';
import 'screens/camera_list.dart';
import 'screens/live_view.dart';

void main() {
  runApp(const ParkingAIApp());
}

class ParkingAIApp extends StatelessWidget {
  const ParkingAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking AI System',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      // ตั้งค่าหน้าแรกเป็นหน้า "รายชื่อกล้อง" (ถ้าไม่มีข้อมูลค่อยกดเพิ่ม)
      initialRoute: '/list', 
      routes: {
        '/add': (context) => const AddCameraScreen(),
        '/list': (context) => const CameraListScreen(),
      },
      // หน้า LiveView เราจะใช้ Navigator.push แบบส่งค่าแทน
    );
  }
}