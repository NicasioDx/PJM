import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class LiveViewScreen extends StatefulWidget {
  final String ip, user, pass, name;
  const LiveViewScreen({super.key, required this.ip, required this.user, required this.pass, required this.name});

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  String? _base64Image;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) => _fetchFrame());
  }

  Future<void> _fetchFrame() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/get_frame'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"ip": widget.ip, "username": widget.user, "password": widget.pass}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() { _base64Image = data['image']; });
        }
      }
    } catch (e) { print("Fetch error: $e"); }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live: ${widget.name}")),
      body: Center(
        child: _base64Image != null 
          ? Image.memory(base64Decode(_base64Image!), gaplessPlayback: true)
          : const CircularProgressIndicator(),
      ),
    );
  }
}