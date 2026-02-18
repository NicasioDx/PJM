import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddCameraScreen extends StatefulWidget {
  const AddCameraScreen({super.key});
  @override
  State<AddCameraScreen> createState() => _AddCameraScreenState();
}

class _AddCameraScreenState extends State<AddCameraScreen> {
  final _name = TextEditingController();
  final _ip = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();

  Future<void> _saveCamera() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/add_camera'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "camera_name": _name.text,
          "ip": _ip.text,
          "username": _user.text,
          "password": _pass.text,
        }),
      );
      if (response.statusCode == 200) {
        if (mounted) Navigator.pushReplacementNamed(context, '/list');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เพิ่มกล้องใหม่")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: "ชื่อจุดจอดรถ (เช่น Gate A)")),
            TextField(controller: _ip, decoration: const InputDecoration(labelText: "IP Address")),
            TextField(controller: _user, decoration: const InputDecoration(labelText: "Username (Tapo Account)")),
            TextField(controller: _pass, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveCamera, child: const Text("บันทึกลงฐานข้อมูล"))
          ],
        ),
      ),
    );
  }
}