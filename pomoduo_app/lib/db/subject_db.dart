import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subject.dart';

class SubjectDB {
  static final SubjectDB instance = SubjectDB._init();
  static Database? _database;

  SubjectDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('subjects.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertSubject(Subject subject) async {
    final db = await instance.database;
    return await db.insert('subjects', subject.toMap());
  }

  Future<List<Subject>> getSubjects() async {
    final db = await instance.database;
    final result = await db.query('subjects', orderBy: 'name ASC');
    return result.map((json) => Subject.fromMap(json)).toList();
  }

  Future<int> deleteSubject(int id) async {
    final db = await instance.database;
    return await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}