class QuizResult {
  final int? id;
  final String topic;
  final String subject;
  final int score;
  final int total;
  final DateTime createdAt;

  QuizResult({
    this.id,
    required this.topic,
    required this.subject,
    required this.score,
    required this.total,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'topic': topic,
        'subject': subject,
        'score': score,
        'total': total,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QuizResult.fromMap(Map<String, dynamic> map) => QuizResult(
        id: map['id'] as int?,
        topic: map['topic'] as String,
        subject: map['subject'] as String,
        score: map['score'] as int,
        total: map['total'] as int,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}


