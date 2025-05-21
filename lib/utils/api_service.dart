import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiService {
  static Future<List<T>> getList<T>(
    String url,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final uri = Uri.parse(url);
    final response = await http.get(uri, headers: authHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => fromJson(item)).toList();
    } else {
      throw Exception('GET failed: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<String> postObject<T>(
    String url,
    T model,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final uri = Uri.parse(url);
    final response = await http.post(
      uri,
      headers: authHeaders(),
      body: jsonEncode(toJson(model)),
    );

    if (response.statusCode == 201) {
      return response.body;
    } else {
      throw Exception('POST failed: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<String> patchObject<T>(
    String url,
    String id,
    Map<String, dynamic> updateData,
  ) async {
    final uri = Uri.parse('$url/$id');
    final response = await http.patch(
      uri,
      headers: authHeaders(),
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception(
        'PATCH failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  static Future<String> deleteObject(String url, String id) async {
    final uri = Uri.parse('$url/$id');
    final response = await http.delete(uri, headers: authHeaders());

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception(
        'DELETE failed: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
