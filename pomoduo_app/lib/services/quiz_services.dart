import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import '../models/question.dart';

class QuizService {
  /// Automatically choose backend URL based on platform
  static String get baseUrl {
    // Try localhost first, then LAN IP
    const localhost = '127.0.0.1:5001';
    const lanIp = '192.168.29.45:5001';

    if (kIsWeb) return 'http://$lanIp';
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://$localhost';
      case TargetPlatform.android:
        return 'http://10.0.2.2:5001'; // Android emulator
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:5001'; // iOS simulator
      default:
        return 'http://$localhost';
    }
  }

  /// Local fallback questions when backend is unavailable
  static Map<String, List<Map<String, dynamic>>> _localQuestions = {
    "C Programming": [
      {
        "question": "What is the size of int in C?",
        "options": ["2 bytes", "4 bytes", "8 bytes", "Depends on compiler"],
        "answer": "Depends on compiler"
      },
      {
        "question": "Which of the following is a valid C variable name?",
        "options": ["int", "_value", "2name", "float"],
        "answer": "_value"
      },
      {
        "question": "What is the output of printf(\"%d\", sizeof('A'));",
        "options": ["1", "4", "8", "2"],
        "answer": "4"
      },
      {
        "question": "Which operator is used to access structure members?",
        "options": ["->", ".", "*", "&"],
        "answer": "."
      },
      {
        "question": "What does malloc() function return?",
        "options": ["void pointer", "int pointer", "char pointer", "float pointer"],
        "answer": "void pointer"
      }
    ],
    "COA": [
      {
        "question": "What does ALU stand for?",
        "options": ["Arithmetic Logic Unit", "Array Logic Unit", "Application Logic Unit", "None"],
        "answer": "Arithmetic Logic Unit"
      },
      {
        "question": "What is cache memory used for?",
        "options": ["Long-term storage", "Speeding up access", "Storing graphics", "None"],
        "answer": "Speeding up access"
      },
      {
        "question": "What is the function of the control unit?",
        "options": ["Data processing", "Instruction decoding", "Memory management", "All of the above"],
        "answer": "All of the above"
      },
      {
        "question": "Which register holds the address of the next instruction?",
        "options": ["Program Counter", "Accumulator", "Index Register", "Status Register"],
        "answer": "Program Counter"
      },
      {
        "question": "What is the purpose of virtual memory?",
        "options": ["Increase RAM speed", "Extend logical memory", "Store OS files", "Cache management"],
        "answer": "Extend logical memory"
      }
    ],
    "DSGT": [
      {
        "question": "What is the primary goal of a data structure?",
        "options": ["To store data", "To organize and access data efficiently", "To compile code", "To debug programs"],
        "answer": "To organize and access data efficiently"
      },
      {
        "question": "Which of these is a linear data structure?",
        "options": ["Tree", "Graph", "Stack", "Hash Table"],
        "answer": "Stack"
      },
      {
        "question": "What is the time complexity of binary search?",
        "options": ["O(n)", "O(log n)", "O(n²)", "O(1)"],
        "answer": "O(log n)"
      },
      {
        "question": "Which data structure follows LIFO principle?",
        "options": ["Queue", "Stack", "Array", "Linked List"],
        "answer": "Stack"
      },
      {
        "question": "What is the advantage of using a hash table?",
        "options": ["Easy implementation", "Fast average-case lookup", "Memory efficient", "Sorted data"],
        "answer": "Fast average-case lookup"
      }
    ]
  };

  /// Generate quiz for a given topic
  static Future<List<Question>> generateQuiz(String topic) async {
    // Try to get questions from backend first
    List<Question> questions = await _getQuestionsFromBackend(topic);
    
    // If backend fails or returns empty, use local fallback
    if (questions.isEmpty) {
      print("🔄 Backend unavailable, using local questions for topic: $topic");
      questions = _getLocalQuestions(topic);
    }
    
    return questions;
  }

  /// Try to get questions from backend
  static Future<List<Question>> _getQuestionsFromBackend(String topic) async {
    final uri = Uri.parse("$baseUrl/generate_quiz");
    print("📡 Sending quiz request to $uri with topic: $topic");

    try {
      // HTTP request with shorter timeout for faster fallback
      final response = await http
          .post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"topic": topic}),
          )
          .timeout(const Duration(seconds: 3));

      print("📩 Response status: ${response.statusCode}");
      print("🧾 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data == null || data['quiz'] == null || data['quiz'] is! List) {
          print("⚠️ Invalid quiz data format from backend");
          return [];
        }

        final quizJson = data['quiz'] as List<dynamic>;
        if (quizJson.isEmpty) {
          print("⚠️ No quiz questions returned for topic: $topic");
          return [];
        }

        return quizJson.map((q) => Question.fromJson(q)).toList();
      } else {
        print("❌ Server returned non-200 status: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("🚨 Backend connection failed: $e");
      return [];
    }
  }

  /// Get local fallback questions
  static List<Question> _getLocalQuestions(String topic) {
    final questions = _localQuestions[topic] ?? [];
    
    if (questions.isEmpty) {
      print("⚠️ No local questions available for topic: $topic");
      // Return general questions if specific topic not found
      return _getLocalQuestions("C Programming");
    }
    
    // Shuffle and limit to 5 questions
    final shuffled = List<Map<String, dynamic>>.from(questions);
    shuffled.shuffle();
    final limited = shuffled.take(5).toList();
    
    print("✅ Using ${limited.length} local questions for topic: $topic");
    return limited.map((q) => Question.fromJson(q)).toList();
  }
}