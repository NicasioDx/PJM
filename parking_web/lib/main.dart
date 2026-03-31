import 'package:flutter/material.dart';
import 'screens/add_camera.dart';
import 'screens/camera_list.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'config/session.dart';

void main() {
  runApp(const ParkingAIApp());
}

class ParkingAIApp extends StatelessWidget {
  const ParkingAIApp({super.key});

  Route<dynamic> _buildRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: settings);
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen(), settings: settings);
      case '/add':
        return MaterialPageRoute(
          builder: (_) => const RequireAuth(child: AddCameraScreen()),
          settings: settings,
        );
      case '/list':
        return MaterialPageRoute(
          builder: (_) => const RequireAuth(child: CameraListScreen()),
          settings: settings,
        );
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking AI System',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      initialRoute: '/login',
      onGenerateRoute: _buildRoute,
      // หน้า LiveView เราจะใช้ Navigator.push แบบส่งค่าแทน
    );
  }
}

class RequireAuth extends StatelessWidget {
  final Widget child;
  const RequireAuth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SessionStore.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isLoggedIn = snapshot.data ?? false;
        if (!isLoggedIn) {
          return const LoginScreen();
        }
        return child;
      },
    );
  }
}
