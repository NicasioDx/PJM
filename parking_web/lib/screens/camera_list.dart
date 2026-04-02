import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'live_view.dart';
import '../config/api.dart';
import '../config/session.dart';
import '../config/theme_controller.dart';

class CameraListScreen extends StatefulWidget {
  const CameraListScreen({super.key});
  @override
  State<CameraListScreen> createState() => _CameraListScreenState();
}

class _CameraListScreenState extends State<CameraListScreen> {
  String _role = 'customer';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await SessionStore.getRole();
    if (!mounted) return;
    setState(() {
      _role = role;
    });
  }

  bool get _isAdmin => _role.toLowerCase() == 'admin';

  Future<List> _fetchCameras() async {
    final response = await http.get(
      Uri.parse('$BASE_URL/get_cameras'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<void> _logout() async {
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'รายการกล้องทั้งหมด (แอดมิน)' : 'รายการกล้องของลูกค้า'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                _isAdmin ? '/admin/history' : '/history',
              );
            },
            icon: const Icon(Icons.history),
            tooltip: 'ประวัติการเข้าจอด',
          ),
          const ThemeModeToggleButton(),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('ออกจากระบบ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List>(
        future: _fetchCameras(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final cameras = snapshot.data!;
          if (cameras.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'ยังไม่มีกล้องที่เพิ่ม',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text(
                    _isAdmin ? 'กดปุ่ม + เพื่อเพิ่มกล้องใหม่' : 'ยังไม่มีกล้องที่พร้อมใช้งาน',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: cameras.length,
            itemBuilder: (context, index) {
              final cam = cameras[index];
              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Icon(Icons.videocam, color: Colors.white),
                  ),
                  title: Text(
                    cam['camera_name'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("โซน: ${cam['zone_name'] ?? 'ทั่วไป'} | IP: ${cam['ip_address']}"),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LiveViewScreen(
                          cameraId: cam['id'],
                          ip: cam['ip_address'],
                          name: cam['camera_name'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/add'),
              tooltip: 'เพิ่มกล้องใหม่',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
