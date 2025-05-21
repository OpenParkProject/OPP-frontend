//const String baseUrl = 'http://openpark.com/api/v1';
const String baseUrl = 'http://localhost:3000/posts';

String? globalAccessToken;

Map<String, String> authHeaders() {
  final headers = {'Content-Type': 'application/json'};
  if (globalAccessToken != null) {
    headers['Authorization'] = 'Bearer $globalAccessToken';
  }
  return headers;
}
