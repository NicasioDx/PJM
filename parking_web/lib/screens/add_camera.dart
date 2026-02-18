import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddCameraScreen extends StatefulWidget {
  @override
  _AddCameraScreenState createState() => _AddCameraScreenState();
}

class _AddCameraScreenState extends State<AddCameraScreen> {
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  String? _previewImageBase64;
  bool _isStreaming = false; 
  bool _isRequesting = false; 

  // 1. ฟังก์ชันควบคุมการเปิด-ปิด Stream
  void _toggleStream() {
    if (_isStreaming) {
      setState(() {
        _isStreaming = false;
        _previewImageBase64 = null;
      });
    } else {
      setState(() => _isStreaming = true);
      _startStreamingLoop(); 
    }
  }

  // 2. ฟังก์ชัน Loop: ดึงภาพเสร็จ 1 เฟรม แล้วค่อยรอจังหวะดึงเฟรมถัดไป
  Future<void> _startStreamingLoop() async {
    while (_isStreaming) {
      if (!_isRequesting) {
        await _getSingleFrame();
      }
      // รอ 100ms เพื่อให้ UI ลื่นไหลและไม่กิน CPU
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  // 3. ฟังก์ชันดึงภาพทีละเฟรมจาก Backend (เหลือตัวเดียวที่ถูกต้อง)
  Future<void> _getSingleFrame() async {
    if (!mounted) return;
    _isRequesting = true;
    
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/preview_camera'), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "ip": _ipController.text,
          "username": _userController.text,
          "password": _passController.text,
        }),
      ).timeout(Duration(seconds: 4));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' && _isStreaming) {
          setState(() {
            _previewImageBase64 = result['image'];
          });
        }
      }
    } catch (e) {
      print("Stream Error: $e");
    } finally {
      _isRequesting = false;
    }
  }

  @override
  void dispose() {
    _isStreaming = false; // หยุด Loop เมื่อปิดหน้าจอ
    _nameController.dispose();
    _ipController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("เพิ่มกล้องใหม่", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey[200],
              padding: EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(_nameController, "ชื่อกล้อง"),
                  _buildTextField(_ipController, "IP Address"),
                  _buildTextField(_userController, "Username"),
                  _buildTextField(_passController, "Password", isPassword: true),
                  SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _toggleStream,
                      icon: Icon(_isStreaming ? Icons.stop : Icons.videocam),
                      label: Text(_isStreaming ? "Stop Test" : "Test Connection"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF5C6BC0),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                children: [
                  Text("Preview กล้อง", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _previewImageBase64 != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              base64Decode(_previewImageBase64!),
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          )
                        : Center(child: Text("ไม่มีสัญญาณภาพ", style: TextStyle(color: Colors.white))),
                  ),
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton("บันทึก", Colors.green, Icons.check, () {
                         // TODO: เรียกฟังก์ชัน save
                      }),
                      SizedBox(width: 20),
                      _buildActionButton("ยกเลิก", Colors.red[800]!, Icons.close, () {
                        Navigator.pop(context);
                      }),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isPassword = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
          suffixIcon: Icon(Icons.cancel_outlined, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}