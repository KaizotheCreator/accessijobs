import 'dart:convert';
import 'package:http/http.dart' as http;

class NLPService {
  static const String baseUrl = "https://fastapi-m1su.onrender.com";

   /// Fetch personalized job recommendations
  static Future<List<Map<String, dynamic>>> getPersonalizedJobs(String userId) async {
    final url = Uri.parse("$baseUrl/recommend-jobs");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data["recommendations"]);
    } else {
      throw Exception("Error fetching personalized jobs: ${response.body}");
    }
  }

  /// Search jobs using NLP
  static Future<List<dynamic>> searchJobs(String query) async {
    final url = Uri.parse('$baseUrl/search');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"query": query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["results"] ?? [];
      } else {
        throw Exception(
            "Failed to search jobs: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Error searching jobs: $e");
    }
  }
}
