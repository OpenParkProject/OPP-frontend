import 'dart:convert';

import 'package:http/http.dart' as http;

import '../DartModels/userModel.dart'; // 包含 LoginRegisterModel 和 UserModel
import 'config.dart';

Future<LoginRegisterModel?> loginUser({
  required String username,
  required String password,
}) async {
  final uri = Uri.parse('$baseUrl/login');

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': username, 'password': password}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final loginData = LoginRegisterModel.fromJson(data);

    // 保存 token
    globalAccessToken = loginData.accessToken;

    return loginData;
  } else {
    throw Exception('Login Failed: ${response.statusCode} - ${response.body}');
  }
}
