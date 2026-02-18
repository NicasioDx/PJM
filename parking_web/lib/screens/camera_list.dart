import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'live_view.dart';

class CameraListScreen extends StatefulWidget {
  const CameraListScreen({super.key});
  @override
  State<CameraListScreen> createState() => _CameraListScreenState();
}

class _CameraListScreenState extends State<CameraListScreen> {
  Future<List> _fetchCameras() async {
    final response = await http.get(Uri.parse('http://localhost:8000/get_cameras'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("รายการกล้องทั้งหมด")),
      body: FutureBuilder<List>(
        future: _fetchCameras(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final cameras = snapshot.data!;
          return ListView.builder(
            itemCount: cameras.length,
            itemBuilder: (context, index) {
              final cam = cameras[index];
              return ListTile(
                leading: const Icon(Icons.videocam, color: Colors.blue),
                title: Text(cam['camera_name']),
                subtitle: Text("IP: ${cam['ip_address']}"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => LiveViewScreen(
                      ip: cam['ip_address'],
                      user: cam['username'],
                      pass: cam['password'],
                      name: cam['camera_name'],
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}