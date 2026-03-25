import 'package:sqflite/sqflite.dart' show Database, openDatabase, getDatabasesPath, ConflictAlgorithm;
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart' show AppDatabaseException;

/// SQLite 3.x veritabanı yöneticisi.
///
/// Singleton pattern ile uygulama genelinde tek bir bağlantı havuzu kullanılır.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // ── Veritabanı Başlatma ───────────────────────────────────────────────────

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, AppConstants.dbName);

      return await openDatabase(
        path,
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
        // WAL modu: openDatabase parametresiyle etkinleştirilir (API 35+ uyumlu)
        singleInstance: true,
      );
    } catch (e) {
      throw AppDatabaseException('Veritabanı başlatılamadı.', e);
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute(_createUsersTable);
      await txn.execute(_createTasksTable);
      await txn.execute(_createRemindersTable);
      await txn.execute(_createTasksIndex);
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // completed_at: görevin tamamlanma zamanı (1 günlük görünürlük için)
      await db.execute(
        'ALTER TABLE ${AppConstants.tableTasks} ADD COLUMN completed_at TEXT',
      );
    }
  }

  // ── DDL: Tablo Şemaları ───────────────────────────────────────────────────

  static const String _createUsersTable = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableUsers} (
      id          TEXT PRIMARY KEY,
      name        TEXT NOT NULL,
      avatar_path TEXT NOT NULL DEFAULT '',
      pin         TEXT NOT NULL,
      role        TEXT NOT NULL DEFAULT 'member',
      language    TEXT NOT NULL DEFAULT 'tr_TR',
      voice_enabled        INTEGER NOT NULL DEFAULT 1,
      notifications_enabled INTEGER NOT NULL DEFAULT 1,
      tts_speed   REAL NOT NULL DEFAULT 1.0,
      tts_pitch   REAL NOT NULL DEFAULT 1.0,
      created_at  TEXT NOT NULL,
      last_login_at TEXT
    )
  ''';

  static const String _createTasksTable = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableTasks} (
      id           TEXT PRIMARY KEY,
      user_id      TEXT NOT NULL,
      title        TEXT NOT NULL,
      description  TEXT,
      is_completed INTEGER NOT NULL DEFAULT 0,
      completed_at TEXT,
      priority     TEXT NOT NULL DEFAULT 'medium',
      category     TEXT NOT NULL DEFAULT 'general',
      tags         TEXT NOT NULL DEFAULT '[]',
      due_date     TEXT,
      reminder_at  TEXT,
      created_at   TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES ${AppConstants.tableUsers}(id)
        ON DELETE CASCADE
    )
  ''';

  static const String _createRemindersTable = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableReminders} (
      id              TEXT PRIMARY KEY,
      task_id         TEXT NOT NULL,
      scheduled_at    TEXT NOT NULL,
      is_fired        INTEGER NOT NULL DEFAULT 0,
      notification_id INTEGER NOT NULL,
      FOREIGN KEY (task_id) REFERENCES ${AppConstants.tableTasks}(id)
        ON DELETE CASCADE
    )
  ''';

  static const String _createTasksIndex = '''
    CREATE INDEX IF NOT EXISTS idx_tasks_user_id
    ON ${AppConstants.tableTasks}(user_id)
  ''';

  // ── Genel CRUD Yardımcıları ───────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> row) async {
    try {
      final db = await database;
      return await db.insert(
        table,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw AppDatabaseException('INSERT hatası: $table', e);
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    try {
      final db = await database;
      return await db.query(
        table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
      );
    } catch (e) {
      throw AppDatabaseException('QUERY hatası: $table', e);
    }
  }

  Future<int> update(
    String table,
    Map<String, dynamic> row, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.update(table, row, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw AppDatabaseException('UPDATE hatası: $table', e);
    }
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.delete(table, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw AppDatabaseException('DELETE hatası: $table', e);
    }
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? args,
  ]) async {
    try {
      final db = await database;
      return await db.rawQuery(sql, args);
    } catch (e) {
      throw AppDatabaseException('RAW QUERY hatası', e);
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  // ── Demo Seed Verisi ──────────────────────────────────────────────────────

  Future<void> _seedDemoData(Database db) async {
    const uuid = Uuid();
    const userId = 'demo-user-001';

    // Demo kullanıcı ekle
    await db.insert(
      AppConstants.tableUsers,
      {
        'id': userId,
        'name': 'Berkay',
        'avatar_path': '',
        'pin': '1234',
        'role': 'admin',
        'language': 'tr_TR',
        'voice_enabled': 1,
        'notifications_enabled': 1,
        'tts_speed': 1.0,
        'tts_pitch': 1.0,
        'created_at': DateTime.now().toIso8601String(),
        'last_login_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // Aktif kullanıcı olarak işaretle
    // (shared_preferences yerine doğrudan DB'de tutulmuyor,
    //  user_repository setActiveUser çağırıyor — seed sadece task ekler)

    final tasks = [
      // 10 Mart
      _task(uuid, userId, 'Berberi ara', '2026-03-10T19:30:00', 'high', 'personal'),
      _task(uuid, userId, 'Market alışverişi', '2026-03-10T18:00:00', 'medium', 'personal'),
      // 11 Mart
      _task(uuid, userId, 'Doktor randevusu', '2026-03-11T14:00:00', 'high', 'health'),
      _task(uuid, userId, 'Spor salonu', '2026-03-11T08:00:00', 'medium', 'health'),
      // 12 Mart
      _task(uuid, userId, 'Proje sunumu hazırlık', '2026-03-12T10:00:00', 'high', 'work'),
      _task(uuid, userId, 'Fatura öde', '2026-03-12T15:00:00', 'medium', 'finance'),
      // 13 Mart
      _task(uuid, userId, 'Toplantı - Ekip standup', '2026-03-13T09:30:00', 'high', 'work'),
      _task(uuid, userId, 'Kitap okuma', '2026-03-13T21:00:00', 'low', 'personal'),
      // 14 Mart
      _task(uuid, userId, 'Aile yemeği', '2026-03-14T19:00:00', 'high', 'personal'),
      _task(uuid, userId, 'Araba bakım servisi', '2026-03-14T11:00:00', 'medium', 'personal'),
      // 15 Mart
      _task(uuid, userId, 'TÜBİTAK rapor teslimi', '2026-03-15T17:00:00', 'high', 'work'),
      _task(uuid, userId, 'Spor salonu', '2026-03-15T08:00:00', 'medium', 'health'),
      // 16 Mart
      _task(uuid, userId, 'Haftalık planlama', '2026-03-16T10:00:00', 'medium', 'work'),
      _task(uuid, userId, 'Alışveriş listesi hazırla', '2026-03-16T16:00:00', 'low', 'personal'),
      // 17 Mart
      _task(uuid, userId, 'Proje kodu review', '2026-03-17T14:00:00', 'high', 'work'),
      _task(uuid, userId, 'Akşam yürüyüşü', '2026-03-17T19:00:00', 'low', 'health'),
    ];

    for (final task in tasks) {
      await db.insert(
        AppConstants.tableTasks,
        task,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Map<String, dynamic> _task(
    Uuid uuid,
    String userId,
    String title,
    String dueDate,
    String priority,
    String category,
  ) {
    return {
      'id': uuid.v4(),
      'user_id': userId,
      'title': title,
      'description': '',
      'is_completed': 0,
      'completed_at': null,
      'priority': priority,
      'category': category,
      'tags': '[]',
      'due_date': dueDate,
      'reminder_at': null,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}
