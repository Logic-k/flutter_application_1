import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  @visibleForTesting
  static String? pathOverride;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  @visibleForTesting
  static void resetForTest() {
    _database = null;
    pathOverride = inMemoryDatabasePath;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path =
        pathOverride ?? join(await getDatabasesPath(), 'memorylink.db');
    // 테스트에서 pathOverride가 설정된 경우 singleInstance를 끄면
    // 각 테스트가 완전히 격리된 인메모리 DB를 사용한다.
    final bool isTest = pathOverride != null;
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      singleInstance: !isTest,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        goal TEXT,
        age INTEGER,
        weight REAL,
        blood_type TEXT,
        medications TEXT,
        emergency_contact TEXT,
        pedometer_enabled INTEGER DEFAULT 0,
        has_completed_onboarding INTEGER DEFAULT 0
      )
    ''');

    // Training scores table
    await db.execute('''
      CREATE TABLE training_scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        category TEXT,
        score REAL,
        created_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Checklist table
    await db.execute('''
      CREATE TABLE checklist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        task_title TEXT,
        is_checked INTEGER DEFAULT 0,
        date TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Daily steps table
    await db.execute('''
      CREATE TABLE daily_steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        steps INTEGER DEFAULT 0,
        calories REAL DEFAULT 0,
        distance REAL DEFAULT 0,
        date TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // DAU tracking table
    await db.execute('''
      CREATE TABLE daily_active_users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        UNIQUE(user_id, date),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Create default 'admin' account for testing
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin',
      'goal': 'prevention',
      'age': 65,
      'weight': 70.0,
      'has_completed_onboarding': 1,
      'pedometer_enabled': 1,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN age INTEGER');
      await db.execute('ALTER TABLE users ADD COLUMN weight REAL');
      await db.execute('ALTER TABLE users ADD COLUMN pedometer_enabled INTEGER DEFAULT 0');
      
      await db.execute('''
        CREATE TABLE daily_steps (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          steps INTEGER DEFAULT 0,
          calories REAL DEFAULT 0,
          distance REAL DEFAULT 0,
          date TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE users ADD COLUMN blood_type TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN medications TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN emergency_contact TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_active_users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          UNIQUE(user_id, date),
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');
    }
  }

  Future<void> resetUserMeasurementData(int userId) async {
    Database db = await database;
    await db.delete('training_scores', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('daily_steps', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('checklist', where: 'user_id = ?', whereArgs: [userId]);
  }

  // --- User Operations ---
  Future<int> insertUser(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('users', row);
  }

  Future<Map<String, dynamic>?> getUser(String username, String password) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUserOnboarding(int userId, bool completed) async {
    Database db = await database;
    return await db.update(
      'users',
      {'has_completed_onboarding': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateUserField(int userId, String field, dynamic value) async {
    Database db = await database;
    return await db.update(
      'users',
      {field: value},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // --- Score Operations ---
  // ... (기존 insertScore, getLatestScores 유지)

  // --- Pedometer Operations ---
  Future<void> updateDailySteps(int userId, int steps, double calories, double distance) async {
    Database db = await database;
    String date = DateTime.now().toIso8601String().split('T')[0];

    List<Map<String, dynamic>> existing = await db.query(
      'daily_steps',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'daily_steps',
        {
          'steps': steps,
          'calories': calories,
          'distance': distance,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert('daily_steps', {
        'user_id': userId,
        'steps': steps,
        'calories': calories,
        'distance': distance,
        'date': date,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklySteps(int userId) async {
    Database db = await database;
    // Get last 7 days of steps
    return await db.query(
      'daily_steps',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 7,
    );
  }
  Future<int> insertScore(int userId, String category, double score) async {
    Database db = await database;
    return await db.insert('training_scores', {
      'user_id': userId,
      'category': category,
      'score': score,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getLatestScores(int userId) async {
    Database db = await database;
    // Get the latest score for each category
    return await db.rawQuery('''
      SELECT category, score 
      FROM training_scores 
      WHERE user_id = ? 
      AND id IN (SELECT MAX(id) FROM training_scores GROUP BY category)
    ''', [userId]);
  }

  Future<List<Map<String, dynamic>>> getScoreHistory(int userId) async {
    Database db = await database;
    return await db.query(
      'training_scores',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
  }

  // --- Checklist Operations ---
  Future<void> updateChecklist(int userId, String title, bool value) async {
    Database db = await database;
    String date = DateTime.now().toIso8601String().split('T')[0];
    
    // Upsert logic
    List<Map<String, dynamic>> existing = await db.query(
      'checklist',
      where: 'user_id = ? AND task_title = ? AND date = ?',
      whereArgs: [userId, title, date],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'checklist',
        {'is_checked': value ? 1 : 0},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert('checklist', {
        'user_id': userId,
        'task_title': title,
        'is_checked': value ? 1 : 0,
        'date': date,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getTodayChecklist(int userId) async {
    Database db = await database;
    String date = DateTime.now().toIso8601String().split('T')[0];
    return await db.query(
      'checklist',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );
  }

  // --- Admin Statistics ---

  Future<void> recordDauIfNeeded(int userId) async {
    final db = await database;
    final date = DateTime.now().toIso8601String().split('T')[0];
    await db.rawInsert(
      'INSERT OR IGNORE INTO daily_active_users (user_id, date) VALUES (?, ?)',
      [userId, date],
    );
  }

  Future<int> getTotalUserCount() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM users');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> getDauCount() async {
    final db = await database;
    final date = DateTime.now().toIso8601String().split('T')[0];
    final res = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM daily_active_users WHERE date = ?',
      [date],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> getNewUsersThisWeek() async {
    final db = await database;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final res = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM daily_active_users WHERE date >= ?',
      [weekAgo.toIso8601String().split('T')[0]],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users', orderBy: 'id DESC');
  }

  Future<Map<String, double>> getAvgScoresByCategory() async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT category, AVG(score) as avg_score FROM training_scores GROUP BY category',
    );
    return {
      for (final row in res)
        row['category'] as String: (row['avg_score'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getAtRiskUsers() async {
    final db = await database;
    final today = DateTime.now();
    final weekStart = today
        .subtract(Duration(days: today.weekday - 1))
        .toIso8601String()
        .split('T')[0];
    final prevWeekStart = today
        .subtract(Duration(days: today.weekday + 6))
        .toIso8601String()
        .split('T')[0];

    final res = await db.rawQuery('''
      SELECT u.id as user_id, u.username, curr.category,
             curr.avg_score as current_avg, prev.avg_score as prev_avg,
             ROUND((curr.avg_score - prev.avg_score) * 100.0 /
               NULLIF(prev.avg_score, 0), 1) as delta_pct
      FROM users u
      JOIN (
        SELECT user_id, category, AVG(score) as avg_score
        FROM training_scores
        WHERE created_at >= ?
        GROUP BY user_id, category
      ) curr ON curr.user_id = u.id
      JOIN (
        SELECT user_id, category, AVG(score) as avg_score
        FROM training_scores
        WHERE created_at >= ? AND created_at < ?
        GROUP BY user_id, category
      ) prev ON prev.user_id = u.id AND prev.category = curr.category
      WHERE (curr.avg_score - prev.avg_score) * 100.0 / NULLIF(prev.avg_score, 0) < -20
      ORDER BY delta_pct ASC
    ''', [weekStart, prevWeekStart, weekStart]);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getScoreHistoryForUser(int userId) async {
    return getScoreHistory(userId);
  }
}
