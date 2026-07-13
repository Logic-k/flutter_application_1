import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show visibleForTesting, kReleaseMode;
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
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      singleInstance: !isTest,
    );
  }

  // ── 비밀번호 해시 유틸 ────────────────────────────────────────
  // 평문 비밀번호는 저장하지 않고 salt + SHA-256 해시만 저장한다.

  static String generateSalt() {
    final rand = Random.secure();
    return List.generate(
      16,
      (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static String hashPassword(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  /// row에 평문 'password'가 있으면 해시/솔트 컬럼으로 대체한다.
  static Map<String, dynamic> _withHashedPassword(Map<String, dynamic> row) {
    final pw = row['password'];
    if (pw is! String || pw.isEmpty) return row;
    final salt = generateSalt();
    return {
      ...row,
      'password': null,
      'password_hash': hashPassword(pw, salt),
      'password_salt': salt,
    };
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        name TEXT,
        password TEXT,
        password_hash TEXT,
        password_salt TEXT,
        session_token TEXT,
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

    // Diary entries table
    await db.execute('''
      CREATE TABLE diary_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        content TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(user_id, date),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // FINGER 건강 기록 (수면·혈압·혈당·식이) — 하루 1건 upsert
    await db.execute(_healthLogsDdl);

    // admin·데모 계정은 개발/데모 빌드에서만 시드한다 (릴리스 빌드 제외)
    if (!kReleaseMode) {
      // admin 계정 (자동화 테스트용)
      await db.insert('users', _withHashedPassword({
        'username': 'admin',
        'name': '관리자',
        'password': 'admin',
        'goal': 'prevention',
        'age': 65,
        'weight': 70.0,
        'has_completed_onboarding': 1,
        'pedometer_enabled': 1,
      }));

      // 데모 계정 시드
      await _seedDemoAccounts(db);
    }
  }

  Future<void> _seedDemoAccounts(Database db) async {
    final now = DateTime.now();

    // ── 계정 1: 김민준 (건강한 사람 — 치매 예방 우수) ──────────────────
    final int minjunId = await db.insert('users', _withHashedPassword({
      'username': 'kim_minjun',
      'name': '김민준',
      'password': 'demo1234',
      'goal': 'prevention',
      'age': 68,
      'weight': 63.0,
      'blood_type': 'A',
      'medications': '없음',
      'emergency_contact': '010-1234-5678',
      'has_completed_onboarding': 1,
      'pedometer_enabled': 1,
    }));

    // 30일치 훈련 점수 (index 0 = 29일 전, index 29 = 오늘)
    // memory: 0-100 스케일 그대로 삽입
    // calculation/logic/attention: 아래 배열은 0-10 스케일이며
    //   _insertTrainingScores에서 ×10 하여 0-100으로 저장 (전 카테고리 0-100 통일)
    // 완만한 우상향 추세 + 자연스러운 등락
    const minjunScores = [
      // [memory, calculation, logic, attention]  — day 0 (29일 전)
      [80.0, 7.8, 8.0, 7.5],
      [82.0, 7.9, 8.1, 7.6],
      [81.0, 8.0, 8.0, 7.5],
      [83.0, 7.8, 8.2, 7.7],
      [80.0, 8.1, 8.1, 7.6],
      [84.0, 7.9, 8.3, 7.8],
      [82.0, 8.2, 8.0, 7.5],
      [85.0, 8.0, 8.2, 7.9],
      [83.0, 8.1, 8.3, 7.7],
      [81.0, 7.9, 8.1, 7.6],
      // day 10~19
      [83.0, 8.2, 8.3, 7.8],
      [85.0, 8.3, 8.4, 7.9],
      [84.0, 8.2, 8.3, 7.8],
      [86.0, 8.4, 8.5, 8.0],
      [85.0, 8.3, 8.4, 7.9],
      [87.0, 8.5, 8.6, 8.1],
      [84.0, 8.2, 8.3, 7.8],
      [86.0, 8.4, 8.5, 8.0],
      [85.0, 8.3, 8.4, 8.1],
      [88.0, 8.6, 8.7, 8.3],
      // day 20~29
      [87.0, 8.5, 8.6, 8.2],
      [88.0, 8.6, 8.7, 8.3],
      [87.0, 8.5, 8.6, 8.2],
      [89.0, 8.7, 8.8, 8.4],
      [88.0, 8.6, 8.7, 8.3],
      [90.0, 8.8, 8.9, 8.5],
      [88.0, 8.6, 8.7, 8.3],
      [91.0, 8.8, 9.0, 8.6],
      [90.0, 8.9, 8.9, 8.5],
      [92.0, 9.0, 9.1, 8.7],
    ];
    await _insertTrainingScores(db, minjunId, minjunScores, now, hour: 10);

    // 30일치 걷기 — 주중 높음(7500~10200), 주말 낮음(6500~8000)
    const minjunSteps = [
      7200, 9100, 8500, 9300, 8700, 7500, 6800, // week 1
      9000, 8800, 8600, 9400, 8900, 7800, 7100, // week 2
      9200, 8700, 9000, 9500, 9100, 7900, 6900, // week 3
      9300, 8900, 9100, 9800, 9400, 7700, 7300, // week 4
      8800, 9100,                                // +2일
    ];
    await _insertDailySteps(db, minjunId, minjunSteps, now);

    // 20일치 일기 (30일 중 10일 건너뜀 — 자연스러운 공백 포함)
    // 일기 있는 날 인덱스: 0,1,2,4,5,7,8,9,11,12,14,15,16,18,19,21,22,24,25,27
    const minjunDiaryDays = [
      0, 1, 2, 4, 5, 7, 8, 9, 11, 12, 14, 15, 16, 18, 19, 21, 22, 24, 25, 27
    ];
    const minjunDiaries = [
      '오늘 아침 일찍 일어나 공원에서 30분 걸었다. 바람이 시원하고 기분이 좋았다. 훈련 게임도 한 판 했는데 그림 스도쿠가 생각보다 재미있다.',
      '오후에 마트에 다녀왔다. 장을 보면서 아내가 좋아하는 과일을 샀다. 저녁 식사 후 산책도 했더니 만 보가 넘었다.',
      '병원에서 정기 검진을 받았다. 의사 선생님이 요즘 꾸준히 운동하고 있어서 좋아 보인다고 하셨다. 앱 덕분인 것 같다.',
      '손자가 학교 성적표를 들고 왔다. 수학을 잘해서 내가 구구단 게임을 가르쳐 줬다. 함께 하니 더 재미있었다.',
      '오늘은 구름이 많아 산책을 짧게 했다. 대신 훈련 게임을 두 가지나 했다. 규칙 찾기 게임에서 높은 점수가 나왔다.',
      '오랜만에 친구들과 점심을 먹었다. 예전 이야기를 하다 보니 시간이 금방 지나갔다. 많이 웃었더니 기분이 좋다.',
      '아침 체조 후 앱에서 AI 챗봇과 이야기를 나눴다. 오늘 기분과 어제 있었던 일을 말했더니 칭찬을 해줬다. 뿌듯했다.',
      '날씨가 맑아서 뒷산까지 걸었다. 경치가 아름다웠다. 돌아오는 길에 이웃 어르신을 만나 잠시 이야기를 나눴다.',
      '오늘은 집에서 쉬었다. TV를 보다가 퀴즈 프로그램이 나왔는데 훈련 덕분에 예전보다 잘 맞추는 것 같다.',
      '며칠 전부터 연습했던 수열 게임을 드디어 다 맞혔다. 작은 성취지만 뿌듯하다.',
      '주말에 아들 가족이 왔다. 손녀가 많이 컸다. 함께 공원을 걸으니 오늘 걸음수가 유독 많이 나왔다.',
      '아침에 일어나 어제 걸음수를 확인했다. 목표를 달성하니 기분이 좋다. 오늘도 열심히 걸어야겠다.',
      '오늘따라 기억력 게임에서 실수가 많았다. 조금 피곤한 것 같다. 일찍 자야겠다.',
      '어제 충분히 쉬었더니 오늘은 훈련 점수가 잘 나왔다. 컨디션 관리가 중요하다는 걸 다시 느꼈다.',
      '이웃 어르신과 함께 동네 복지관 프로그램에 참여했다. 노래도 배우고 즐거운 시간이었다.',
      '오늘은 일기를 쓰면서 한 달 동안 꾸준히 훈련을 했다는 게 새삼 뿌듯하게 느껴졌다.',
      '아침 산책 중에 꽃이 피기 시작한 것을 발견했다. 봄이 오는 걸 보니 마음이 따뜻해졌다. 사진을 찍어 아들한테 보냈다.',
      '손자와 영상통화를 했다. 멀리 살아서 자주 못 보지만 화면으로라도 보니 기분이 좋다.',
      '오늘 임상 리포트를 생성해봤다. 지난 한 달 동안의 기록이 한눈에 보이니 꾸준히 노력한 것이 느껴졌다. 의사 선생님께 가져갈 생각이다.',
      '매일 훈련과 걷기를 하고 있다. 처음엔 귀찮기도 했는데 이제는 습관이 된 것 같다. 뇌도 근육처럼 쓸수록 좋아지나 보다.',
    ];
    for (int k = 0; k < minjunDiaryDays.length; k++) {
      final dayIdx = minjunDiaryDays[k];
      final date = now.subtract(Duration(days: 29 - dayIdx));
      final dateStr = date.toIso8601String().split('T')[0];
      final ts = '${dateStr}T20:00:00.000';
      await db.insert('diary_entries', {
        'user_id': minjunId,
        'date': dateStr,
        'content': minjunDiaries[k],
        'created_at': ts,
        'updated_at': ts,
      });
    }

    // 25일치 활성 사용자 기록 (30일 중 5일 빠짐)
    for (int i = 0; i < 30; i++) {
      if (i == 3 || i == 6 || i == 10 || i == 20 || i == 23) continue;
      final dateStr =
          now.subtract(Duration(days: 29 - i)).toIso8601String().split('T')[0];
      await db.insert('daily_active_users', {
        'user_id': minjunId,
        'date': dateStr,
      });
    }

    // ── 계정 2: 박순자 (위험한 사람 — 치매 위험 경고) ─────────────────
    final int sonjaId = await db.insert('users', _withHashedPassword({
      'username': 'park_sonja',
      'name': '박순자',
      'password': 'demo1234',
      'goal': 'concern',
      'age': 76,
      'weight': 56.0,
      'blood_type': 'B',
      'medications': '혈압약, 수면제',
      'emergency_contact': '010-9876-5432',
      'has_completed_onboarding': 1,
      'pedometer_enabled': 1,
    }));

    // 30일치 훈련 점수 — 전반적으로 낮음
    // memory: 0-100 스케일 (20~35점)
    // calculation/logic/attention: 0-10 스케일 배열 → 삽입 시 ×10 (20~34점)
    const sonjaScores = [
      [28.0, 2.8, 2.3, 2.6],
      [20.0, 2.0, 1.5, 2.0],
      [26.0, 2.5, 2.1, 2.4],
      [23.0, 2.3, 1.8, 2.2],
      [30.0, 2.9, 2.4, 2.7],
      [25.0, 2.4, 1.9, 2.3],
      [28.0, 2.7, 2.2, 2.6],
      [22.0, 2.1, 1.6, 2.1],
      [27.0, 2.6, 2.2, 2.5],
      [24.0, 2.2, 1.8, 2.2],
      [29.0, 2.8, 2.3, 2.6],
      [21.0, 2.0, 1.5, 2.0],
      [25.0, 2.4, 2.0, 2.3],
      [23.0, 2.2, 1.7, 2.1],
      [31.0, 3.0, 2.5, 2.8],
      [26.0, 2.5, 2.0, 2.4],
      [29.0, 2.8, 2.3, 2.6],
      [22.0, 2.1, 1.6, 2.0],
      [27.0, 2.6, 2.1, 2.4],
      [24.0, 2.3, 1.9, 2.2],
      [32.0, 3.1, 2.5, 2.8],
      [25.0, 2.4, 2.0, 2.3],
      [28.0, 2.7, 2.2, 2.5],
      [21.0, 2.0, 1.5, 1.9],
      [30.0, 2.9, 2.4, 2.7],
      [24.0, 2.3, 1.8, 2.2],
      [27.0, 2.6, 2.1, 2.4],
      [22.0, 2.1, 1.6, 2.0],
      [31.0, 3.0, 2.4, 2.7],
      [28.0, 2.8, 2.2, 2.6],
    ];
    await _insertTrainingScores(db, sonjaId, sonjaScores, now, hour: 14);

    // 30일치 걷기 — 매우 적음 (600~1500보)
    const sonjaSteps = [
       950,  600, 1100,  800, 1500,  900, 1200,
       700, 1100,  850, 1300,  950, 1400,  650,
      1000,  750, 1200,  900, 1350,  800, 1100,
       600,  950,  700, 1250,  850, 1400,  750,
      1050,  900,
    ];
    await _insertDailySteps(db, sonjaId, sonjaSteps, now);
  }

  static const _scoreCategories = ['memory', 'calculation', 'logic', 'attention'];

  // 하루 1회씩 [memory, calculation, logic, attention] 점수를 삽입
  // (index 0 = 가장 오래된 날, 마지막 index = 오늘)
  // memory(index 0)는 0-100 스케일 그대로, 나머지는 0-10 배열을 ×10 하여
  // 저장 스케일을 0-100으로 통일한다.
  Future<void> _insertTrainingScores(
    Database db,
    int userId,
    List<List<double>> scores,
    DateTime now, {
    required int hour,
  }) async {
    for (int i = 0; i < scores.length; i++) {
      final date = now.subtract(Duration(days: scores.length - 1 - i));
      final dateStr =
          '${date.toIso8601String().split('T')[0]}T$hour:${(i % 60).toString().padLeft(2, '0')}:00.000';
      for (int c = 0; c < _scoreCategories.length; c++) {
        final raw = scores[i][c];
        await db.insert('training_scores', {
          'user_id': userId,
          'category': _scoreCategories[c],
          'score': c == 0 ? raw : raw * 10.0,
          'created_at': dateStr,
        });
      }
    }
  }

  Future<void> _insertDailySteps(
      Database db, int userId, List<int> stepsPerDay, DateTime now) async {
    for (int i = 0; i < stepsPerDay.length; i++) {
      final dateStr = now
          .subtract(Duration(days: stepsPerDay.length - 1 - i))
          .toIso8601String()
          .split('T')[0];
      final steps = stepsPerDay[i];
      await db.insert('daily_steps', {
        'user_id': userId,
        'steps': steps,
        'calories': (steps * 0.04).roundToDouble(),
        'distance': (steps * 0.0008).roundToDouble(),
        'date': dateStr,
      });
    }
  }

  // FINGER 건강 기록 테이블 DDL (onCreate/onUpgrade 공용)
  static const String _healthLogsDdl = '''
    CREATE TABLE IF NOT EXISTS health_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      sleep_hours REAL,
      sleep_quality INTEGER,
      systolic INTEGER,
      diastolic INTEGER,
      glucose REAL,
      diet_score INTEGER,
      memo TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      UNIQUE(user_id, date),
      FOREIGN KEY (user_id) REFERENCES users (id)
    )
  ''';

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
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS diary_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          content TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          UNIQUE(user_id, date),
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE users ADD COLUMN name TEXT');
    }
    if (oldVersion < 7) {
      // 1) 점수 스케일 통일: 기존 0-10 스케일(calculation/logic/attention)을
      //    0-100으로 승격. (memory는 원래 0-100이라 대상에서 제외.
      //    score <= 10 조건은 구버전 데이터 판별용 — 신규 데이터는 항상 0-100)
      await db.execute('''
        UPDATE training_scores SET score = score * 10
        WHERE category IN ('calculation', 'logic', 'attention') AND score <= 10
      ''');

      // 2) 비밀번호 평문 저장 폐기: 해시/솔트/세션토큰 컬럼 추가 후
      //    기존 평문 비밀번호를 해시로 이전하고 평문은 삭제
      await db.execute('ALTER TABLE users ADD COLUMN password_hash TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN password_salt TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN session_token TEXT');
      final rows = await db.query(
        'users',
        columns: ['id', 'password'],
        where: 'password IS NOT NULL',
      );
      for (final row in rows) {
        final salt = generateSalt();
        await db.update(
          'users',
          {
            'password': null,
            'password_hash': hashPassword(row['password'] as String, salt),
            'password_salt': salt,
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }
    if (oldVersion < 8) {
      await db.execute(_healthLogsDdl);
    }
  }

  Future<void> resetUserMeasurementData(int userId) async {
    Database db = await database;
    await db.delete('training_scores', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('daily_steps', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('checklist', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('health_logs', where: 'user_id = ?', whereArgs: [userId]);
  }

  // --- FINGER 건강 기록 (Health Log) Operations ---

  /// 하루 1건 기준으로 저장(있으면 갱신). date는 'yyyy-MM-dd' 형식.
  Future<void> upsertHealthLog({
    required int userId,
    required String date,
    double? sleepHours,
    int? sleepQuality,
    int? systolic,
    int? diastolic,
    double? glucose,
    int? dietScore,
    String? memo,
  }) async {
    final db = await database;
    final nowIso = DateTime.now().toIso8601String();
    final existing = await db.query(
      'health_logs',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
      limit: 1,
    );
    final values = <String, dynamic>{
      'user_id': userId,
      'date': date,
      'sleep_hours': sleepHours,
      'sleep_quality': sleepQuality,
      'systolic': systolic,
      'diastolic': diastolic,
      'glucose': glucose,
      'diet_score': dietScore,
      'memo': memo,
      'updated_at': nowIso,
    };
    if (existing.isEmpty) {
      values['created_at'] = nowIso;
      await db.insert('health_logs', values);
    } else {
      await db.update(
        'health_logs',
        values,
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, date],
      );
    }
  }

  /// 특정 날짜 기록 조회 (없으면 null)
  Future<Map<String, dynamic>?> getHealthLog(int userId, String date) async {
    final db = await database;
    final rows = await db.query(
      'health_logs',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  /// 최근 N일 기록을 날짜 오름차순으로 반환 (추세 차트용)
  Future<List<Map<String, dynamic>>> getRecentHealthLogs(
      int userId, int days) async {
    final db = await database;
    final since = DateTime.now()
        .subtract(Duration(days: days - 1))
        .toIso8601String()
        .split('T')[0];
    return db.query(
      'health_logs',
      where: 'user_id = ? AND date >= ?',
      whereArgs: [userId, since],
      orderBy: 'date ASC',
    );
  }

  // --- User Operations ---
  Future<int> insertUser(Map<String, dynamic> row) async {
    Database db = await database;
    // 평문 비밀번호는 저장 전 해시/솔트로 변환된다.
    return await db.insert('users', _withHashedPassword(row));
  }

  /// username으로 조회 후 salt+SHA-256 해시를 검증한다.
  /// 구버전(평문) 행은 검증 성공 시 즉시 해시로 업그레이드한다.
  Future<Map<String, dynamic>?> getUser(String username, String password) async {
    Database db = await database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (results.isEmpty) return null;
    final user = results.first;

    final hash = user['password_hash'] as String?;
    final salt = user['password_salt'] as String?;
    if (hash != null && salt != null) {
      return hashPassword(password, salt) == hash ? user : null;
    }

    // 레거시 평문 행 (마이그레이션 이전 데이터 방어)
    if (user['password'] == password) {
      final newSalt = generateSalt();
      await db.update(
        'users',
        {
          'password': null,
          'password_hash': hashPassword(password, newSalt),
          'password_salt': newSalt,
        },
        where: 'id = ?',
        whereArgs: [user['id']],
      );
      return user;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    Database db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// 자동 로그인용: username + 세션 토큰으로 사용자 조회
  Future<Map<String, dynamic>?> getUserBySessionToken(
      String username, String token) async {
    if (token.isEmpty) return null;
    Database db = await database;
    final results = await db.query(
      'users',
      where: 'username = ? AND session_token = ?',
      whereArgs: [username, token],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> setSessionToken(int userId, String? token) async {
    Database db = await database;
    await db.update(
      'users',
      {'session_token': token},
      where: 'id = ?',
      whereArgs: [userId],
    );
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

  Future<Map<String, dynamic>?> getTodaySteps(int userId) async {
    Database db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final rows = await db.query(
      'daily_steps',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, today],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
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
    return await db.rawQuery('''
      SELECT category, score
      FROM training_scores
      WHERE user_id = ?
      AND id IN (
        SELECT MAX(id) FROM training_scores WHERE user_id = ? GROUP BY category
      )
    ''', [userId, userId]);
  }

  /// 오늘 훈련을 수행한 인지 영역(카테고리) 수. 홈 화면 "훈련 현황"용.
  Future<int> getTodayTrainingCount(int userId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final res = await db.rawQuery('''
      SELECT COUNT(DISTINCT category) as cnt
      FROM training_scores
      WHERE user_id = ? AND date(created_at) = ?
    ''', [userId, today]);
    return Sqflite.firstIntValue(res) ?? 0;
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

  /// 최근 7일 주간 활성 사용자 수(WAU).
  /// user-day 행이 아니라 고유 사용자 수를 센다.
  Future<int> getWeeklyActiveUsers() async {
    final db = await database;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final res = await db.rawQuery(
      'SELECT COUNT(DISTINCT user_id) as cnt FROM daily_active_users WHERE date >= ?',
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

  // --- Diary Operations ---

  Future<void> upsertDiary(int userId, String date, String content) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.rawInsert('''
      INSERT INTO diary_entries (user_id, date, content, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(user_id, date) DO UPDATE SET
        content = excluded.content,
        updated_at = excluded.updated_at
    ''', [userId, date, content, now, now]);
  }

  Future<Map<String, dynamic>?> getDiary(int userId, String date) async {
    final db = await database;
    final rows = await db.query(
      'diary_entries',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<List<String>> getDiaryDatesForMonth(int userId, String yearMonth) async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT date FROM diary_entries WHERE user_id = ? AND date LIKE ? ORDER BY date ASC",
      [userId, '$yearMonth%'],
    );
    return rows.map((r) => r['date'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getAllDiaries(int userId) async {
    final db = await database;
    return await db.query(
      'diary_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  Future<void> deleteOldDiaries(int userId) async {
    final db = await database;
    // 보관 기간은 개인정보 처리방침 고지(최대 3년)와 일치시킨다.
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 365 * 3))
        .toIso8601String()
        .split('T')[0];
    await db.delete(
      'diary_entries',
      where: 'user_id = ? AND date < ?',
      whereArgs: [userId, cutoff],
    );
  }

  /// 날짜별로 묶인 세션 히스토리 반환 (임상 리포트 추이 차트용)
  /// 반환 형식: [{dateString: {category: avgScore}}, ...]  (오름차순, 최대 8세션)
  Future<List<Map<String, Map<String, double>>>> getScoreHistoryGroupedBySession(
      int userId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT date(created_at) AS session_date, category, AVG(score) AS avg_score
      FROM training_scores
      WHERE user_id = ?
      GROUP BY session_date, category
      ORDER BY session_date ASC
    ''', [userId]);

    // group by session_date
    final Map<String, Map<String, double>> grouped = {};
    for (final row in rows) {
      final date = row['session_date'] as String;
      final category = row['category'] as String;
      final score = (row['avg_score'] as num).toDouble();
      grouped.putIfAbsent(date, () => {})[category] = score;
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final recent = sortedKeys.length > 8
        ? sortedKeys.sublist(sortedKeys.length - 8)
        : sortedKeys;

    return recent.map((k) => {k: grouped[k]!}).toList();
  }
}
