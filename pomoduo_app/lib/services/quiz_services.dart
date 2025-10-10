import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';

class QuizService {
  static const String baseUrl = "http://YOUR_BACKEND_IP:5000";

  static Future<List<Question>> generateQuiz(String topic) async {
    final response = await http.post(
      Uri.parse("$baseUrl/generate_quiz"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"topic": topic}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final quizJson = data["quiz"] as List<dynamic>;
      return quizJson.map((q) => Question.fromJson(q)).toList();
    } else {
      throw Exception("Failed to fetch quiz");
    }
  }
}