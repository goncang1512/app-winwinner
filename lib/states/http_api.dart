import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://api-winwinner.vercel.app';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Header default
  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET
  Future<dynamic> get(String endpoint, {String? token}) async {
    final url = Uri.parse('$baseUrl$endpoint');

    final response = await http.get(url, headers: await _headers());

    return _handleResponse(response);
  }

  // POST
  Future<dynamic> post(String endpoint, dynamic body, {String? token}) async {
    final url = Uri.parse('$baseUrl$endpoint');

    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // PUT
  Future<dynamic> put(String endpoint, dynamic body, {String? token}) async {
    final url = Uri.parse('$baseUrl$endpoint');

    final response = await http.put(
      url,
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // PATCH
  Future<dynamic> patch(String endpoint, dynamic body, {String? token}) async {
    final url = Uri.parse('$baseUrl$endpoint');

    final response = await http.patch(
      url,
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // DELETE
  Future<dynamic> delete(String endpoint, {String? token}) async {
    final url = Uri.parse('$baseUrl$endpoint');

    final response = await http.delete(url, headers: await _headers());

    return _handleResponse(response);
  }

  // Handle Response
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    } else {
      throw Exception({
        'statusCode': statusCode,
        'message': body ?? 'Unknown error',
      });
    }
  }
}
