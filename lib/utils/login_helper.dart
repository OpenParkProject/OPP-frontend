import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/client.dart';
import '../admin/admin_layout.dart';
import '../controller/controller_layout.dart';
import '../driver/tickets.dart';

Future<void> loginAsUser(
  BuildContext context,
  String username,
  String role, {
  String authPath = "/users/pw",
}) async {
  try {
    final dio = DioClient().dio;
    final response = await dio.get("$authPath/$username");
    final password = response.data['password'];

    final loginRes = await dio.post('/login', data: {
      'username': username,
      'password': password,
    });

    final token = loginRes.data['access_token'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    DioClient().dio.options.headers['Authorization'] = 'Bearer $token';

    if (role == 'admin') {
      final zonesResponse = await dio.get('/zones/me');
      final zoneList = List<Map<String, dynamic>>.from(zonesResponse.data ?? []);
      final zoneIds = zoneList.map((z) => z['id'].toString()).toList();
      final zoneNames = zoneList.map((z) => z['name'].toString()).toList();
      await prefs.setStringList('zone_ids', zoneIds);
      await prefs.setStringList('zone_names', zoneNames);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AdminLayout(username: username)),
        (r) => false,
      );
    } else if (role == 'controller') {
      final zonesResponse = await dio.get('/zones/me');
      final zoneList = List<Map<String, dynamic>>.from(zonesResponse.data ?? []);
      final zoneIds = zoneList.map((z) => z['id'].toString()).toList();
      final zoneNames = zoneList.map((z) => z['name'].toString()).toList();
      await prefs.setStringList('zone_ids', zoneIds);
      await prefs.setStringList('zone_names', zoneNames);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => ControllerLayout(username: username)),
        (r) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => UserTicketsPage()),
        (r) => false,
      );
    }
  } catch (e) {
    debugPrint("Login as $username failed: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Login as $username failed")),
    );
  }
}
