import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/quiz_services.dart';

class QuizPage extends StatefulWidget {
  final String topic;
  const QuizPage({Key? key, required this.topic}) : super(key: key);

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

  void _loadQuiz() async {
    try {
      final questions = await QuizService.generateQuiz(widget.topic);
      setState(() {
        _questions = questions;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _answerQuestion(String selectedOption) {
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

    if (_quizFinished) {
      return Scaffold(
        body: Center(
          child: Text(
            "Quiz Complete!\nScore: $_score / ${_questions.length}",
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
          children: [
            Text(
              "Question ${_currentIndex + 1} of ${_questions.length}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              question.question,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...question.options.map((option) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton(
                    onPressed: () => _answerQuestion(option),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
