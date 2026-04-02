import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/session.dart';
import '../config/theme_controller.dart';

class ParkingHistoryScreen extends StatefulWidget {
  final bool isAdmin;
  const ParkingHistoryScreen({super.key, required this.isAdmin});

  @override
  State<ParkingHistoryScreen> createState() => _ParkingHistoryScreenState();
}

class _ParkingHistoryScreenState extends State<ParkingHistoryScreen> {
  final TextEditingController _zoneController = TextEditingController();
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  @override
  void dispose() {
    _zoneController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _fetchHistory() async {
    Uri uri;
    if (widget.isAdmin) {
      final zone = _zoneController.text.trim();
      uri = Uri.parse('$BASE_URL/parking_history/admin').replace(
        queryParameters: zone.isEmpty ? null : {'zone': zone},
      );
    } else {
      final username = await SessionStore.getUsername();
      if (username == null || username.isEmpty) return [];
      uri = Uri.parse('$BASE_URL/parking_history').replace(
        queryParameters: {'username': username},
      );
    }

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode != 200) {
      return [];
    }

    final body = jsonDecode(response.body);
    if (body is List<dynamic>) return body;
    return [];
  }

  void _reload() {
    setState(() {
      _historyFuture = _fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'ประวัติการเข้าจอด (แอดมิน)' : 'ประวัติการเข้าจอด'),
        centerTitle: true,
        actions: [
          const ThemeModeToggleButton(),
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.isAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _zoneController,
                      decoration: const InputDecoration(
                        labelText: 'กรองตามโซน',
                        hintText: 'เช่น Zone A',
                        prefixIcon: Icon(Icons.map),
                      ),
                      onSubmitted: (_) => _reload(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.search),
                    label: const Text('ค้นหา'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rows = snapshot.data ?? [];
                if (rows.isEmpty) {
                  return const Center(child: Text('ยังไม่มีประวัติการเข้าจอด'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = rows[index] as Map<String, dynamic>;
                    final username = (item['username'] ?? '-').toString();
                    final zone = (item['zone_name'] ?? '-').toString();
                    final cameraName = (item['camera_name'] ?? '-').toString();
                    final eventType = (item['event_type'] ?? '-').toString();
                    final createdAt = (item['created_at'] ?? '-').toString();

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.directions_car),
                        title: Text('$cameraName ($zone)'),
                        subtitle: Text('ผู้ใช้: $username\nเหตุการณ์: $eventType\nเวลา: $createdAt'),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
