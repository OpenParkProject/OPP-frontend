import 'dart:convert';

import 'package:http/http.dart' as http;

import '../DartModels/userModel.dart'; // 包含 LoginRegisterModel 和 UserModel
import 'config.dart';

Future<LoginRegisterModel?> registerUser({
  required String name,
  required String surname,
  required String username,
  required String email,
  required String password,
  String role = 'driver',
}) async {
  final uri = Uri.parse('$baseUrl/register');

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': name,
      'surname': surname,
      'username': username,
      'email': email,
      'password': password,
      'role': role,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final registerData = LoginRegisterModel.fromJson(data);

    // 保存 token
    globalAccessToken = registerData.accessToken;

    return registerData;
  } else {
    throw Exception(
      'Register Failed: ${response.statusCode} - ${response.body}',
    );
  }
}
