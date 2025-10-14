import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/quiz_services.dart';
import '../db/quiz_result_db.dart';
import '../models/quiz_result.dart';

class QuizPage extends StatefulWidget {
  final String topic;
  final String? subject;
  const QuizPage({Key? key, required this.topic, this.subject}) : super(key: key);

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Question> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _loading = true;
  bool _quizFinished = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      print("🧠 Loading quiz for topic: ${widget.topic}");
      final questions = await QuizService.generateQuiz(widget.topic);
      print("📋 Questions fetched: ${questions.length}");

      setState(() {
        _questions = questions;
        _loading = false;
      });
    } catch (e) {
      print("❌ Error loading quiz: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  void _answerQuestion(String selectedOption) {
    if (_questions.isEmpty) return; // Safety guard

    if (selectedOption == _questions[_currentIndex].answer) {
      _score++;
    }

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      setState(() {
        _quizFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 🚨 Prevent RangeError when no questions exist
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Quiz: ${widget.topic}")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.quiz_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                "No questions available for this topic 😕",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Please check your internet connection and try again.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                  });
                  _loadQuiz();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_quizFinished) {
      final int total = _questions.length;
      // Save result
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await QuizResultDB.instance.insertResult(QuizResult(
            topic: widget.topic,
            subject: widget.subject ?? 'MSE',
            score: _score,
            total: total,
            createdAt: DateTime.now(),
          ));
        } catch (_) {}
      });
      return Scaffold(
        appBar: AppBar(title: Text("Quiz Complete")),
        body: Center(
          child: Text(
            "🎯 Score: $_score / $total",
            style: const TextStyle(fontSize: 22),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text("Quiz: ${widget.topic}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Question ${_currentIndex + 1} of ${_questions.length}",
                  style: const TextStyle(fontSize: 18),
                ),
                // Show offline indicator if questions are from local fallback
                if (_questions.isNotEmpty && _questions.length == 5)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off, size: 12, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          "Offline",
                          style: TextStyle(fontSize: 10, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              question.question,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...question.options.map((option) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton(
                    onPressed: () => _answerQuestion(option),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(option, style: const TextStyle(fontSize: 16)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}