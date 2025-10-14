import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/quiz_result.dart';

class QuizResultDB {
  static final QuizResultDB instance = QuizResultDB._init();
  static Database? _database;

  QuizResultDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quiz_results.db');
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

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE quiz_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic TEXT NOT NULL,
        subject TEXT NOT NULL,
        score INTEGER NOT NULL,
        total INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertResult(QuizResult result) async {
    final db = await instance.database;
    return await db.insert('quiz_results', result.toMap());
  }

  Future<List<QuizResult>> fetchResults() async {
    final db = await instance.database;
    final maps = await db.query('quiz_results', orderBy: 'createdAt DESC');
    return maps.map((m) => QuizResult.fromMap(m)).toList();
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}


