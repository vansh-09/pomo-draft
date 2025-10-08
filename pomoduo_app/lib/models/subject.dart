class Subject {
  final int? id;
  final String name;

  Subject({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(id: map['id'], name: map['name']);
  }
}