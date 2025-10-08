import 'package:flutter/material.dart';

class Question {
  final String question;
  final List<String> options;
  final int correctIndex;

  Question({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class QuizPage extends StatefulWidget {
  final String topic;

  const QuizPage({super.key, required this.topic});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _generateMockQuiz(widget.topic);
  }

  void _generateMockQuiz(String topic) {
    // MOCK quiz data — in Phase 3 we'll replace with AI-generated questions
    _questions = [
      Question(
        question: "What is a basic concept of $topic?",
        options: ["Option A", "Option B", "Option C", "Option D"],
        correctIndex: 0,
      ),
      Question(
        question: "How does $topic work?",
        options: ["Option A", "Option B", "Option C", "Option D"],
        correctIndex: 1,
      ),
      Question(
        question: "Which is a key advantage of $topic?",
        options: ["Option A", "Option B", "Option C", "Option D"],
        correctIndex: 2,
      ),
      Question(
        question: "What is a challenge in $topic?",
        options: ["Option A", "Option B", "Option C", "Option D"],
        correctIndex: 3,
      ),
      Question(
        question: "Which example best explains $topic?",
        options: ["Option A", "Option B", "Option C", "Option D"],
        correctIndex: 0,
      ),
    ];
  }

  void _answerQuestion(int selectedIndex) {
    if (selectedIndex == _questions[_currentQuestionIndex].correctIndex) {
      _score++;
    }
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      _showQuizResults();
    }
  }

  void _showQuizResults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Quiz Complete"),
        content: Text("Your score: $_score / ${_questions.length}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Back to HomePage
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestionIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text("Quiz on ${widget.topic}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Question ${_currentQuestionIndex + 1} / ${_questions.length}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              question.question,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...List.generate(
              question.options.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ElevatedButton(
                  onPressed: () => _answerQuestion(index),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: Text(question.options[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}