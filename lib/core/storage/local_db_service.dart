import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _database;
  final Map<String, String> _webMemCache = {};
  final List<Map<String, dynamic>> _webSyncQueue = [];

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'stockalert_local.db');

    return await openDatabase(
      path,
      version: 7,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'CREATE TABLE IF NOT EXISTS inventory (id TEXT PRIMARY KEY, name TEXT, expiry TEXT, level TEXT)');
          await db.execute(
              'CREATE TABLE IF NOT EXISTS bookings (id TEXT PRIMARY KEY, doctorName TEXT, specialty TEXT, date TEXT, time TEXT)');
        }
        if (oldVersion < 3) {
          await _addColumnIfMissing(db, 'bookings', 'avatarUrl', 'TEXT');
          await _addColumnIfMissing(db, 'bookings', 'videoLink', 'TEXT');
          await _addColumnIfMissing(db, 'bookings', 'notes', 'TEXT');
        }
        if (oldVersion < 4) {
          await db.execute(
            'CREATE TABLE IF NOT EXISTS sync_queue ('
            'mutationId TEXT PRIMARY KEY, entityType TEXT NOT NULL, '
            'operation TEXT NOT NULL, entityId TEXT, payload TEXT NOT NULL, '
            'attemptCount INTEGER NOT NULL DEFAULT 0, status TEXT NOT NULL, '
            'lastError TEXT, createdAt TEXT NOT NULL)',
          );
        }
        if (oldVersion < 5) {
          await _addColumnIfMissing(
            db,
            'bookings',
            'version',
            'INTEGER NOT NULL DEFAULT 1',
          );
          await _addColumnIfMissing(
            db,
            'bookings',
            'status',
            "TEXT NOT NULL DEFAULT 'pending'",
          );
        }
        if (oldVersion < 6) {
          await _addColumnIfMissing(db, 'bookings', 'providerId', 'TEXT');
        }
        if (oldVersion < 7) {
          for (final column in const {
            'quantity': 'INTEGER NOT NULL DEFAULT 0',
            'version': 'INTEGER NOT NULL DEFAULT 1',
            'barcode': "TEXT NOT NULL DEFAULT ''",
            'batchNumber': "TEXT NOT NULL DEFAULT ''",
            'genericName': "TEXT NOT NULL DEFAULT ''",
            'brandName': "TEXT NOT NULL DEFAULT ''",
            'strength': "TEXT NOT NULL DEFAULT ''",
            'dosageForm': "TEXT NOT NULL DEFAULT ''",
            'manufacturer': "TEXT NOT NULL DEFAULT ''",
            'reorderLevel': 'INTEGER NOT NULL DEFAULT 0',
            'unitPrice': 'REAL',
            'currency': "TEXT NOT NULL DEFAULT 'GHS'",
          }.entries) {
            await _addColumnIfMissing(
                db, 'inventory', column.key, column.value);
          }
        }
      },
    );
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info("$table")');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute(
        'ALTER TABLE "$table" ADD COLUMN "$column" $definition',
      );
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute(
        'CREATE TABLE IF NOT EXISTS kv_store (key TEXT PRIMARY KEY, value TEXT)');
    await db.execute('''CREATE TABLE IF NOT EXISTS inventory (
          id TEXT PRIMARY KEY, name TEXT, expiry TEXT, level TEXT,
          quantity INTEGER NOT NULL DEFAULT 0, version INTEGER NOT NULL DEFAULT 1,
          barcode TEXT NOT NULL DEFAULT '', batchNumber TEXT NOT NULL DEFAULT '',
          genericName TEXT NOT NULL DEFAULT '', brandName TEXT NOT NULL DEFAULT '',
          strength TEXT NOT NULL DEFAULT '', dosageForm TEXT NOT NULL DEFAULT '',
          manufacturer TEXT NOT NULL DEFAULT '', reorderLevel INTEGER NOT NULL DEFAULT 0,
          unitPrice REAL, currency TEXT NOT NULL DEFAULT 'GHS')''');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS bookings (id TEXT PRIMARY KEY, doctorName TEXT, specialty TEXT, date TEXT, time TEXT, avatarUrl TEXT, videoLink TEXT, notes TEXT, version INTEGER NOT NULL DEFAULT 1, status TEXT NOT NULL DEFAULT "pending", providerId TEXT)');
    await db.execute(
      'CREATE TABLE IF NOT EXISTS sync_queue ('
      'mutationId TEXT PRIMARY KEY, entityType TEXT NOT NULL, '
      'operation TEXT NOT NULL, entityId TEXT, payload TEXT NOT NULL, '
      'attemptCount INTEGER NOT NULL DEFAULT 0, status TEXT NOT NULL, '
      'lastError TEXT, createdAt TEXT NOT NULL)',
    );
  }

  // Key-Value helpers
  Future<void> write(String key, String value) async {
    if (kIsWeb) {
      _webMemCache[key] = value;
      return;
    }
    final db = await database;
    await db.insert(
      'kv_store',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> read(String key) async {
    if (kIsWeb) {
      return _webMemCache[key];
    }
    final db = await database;
    final maps = await db.query(
      'kv_store',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> delete(String key) async {
    if (kIsWeb) {
      _webMemCache.remove(key);
      return;
    }
    final db = await database;
    await db.delete(
      'kv_store',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<void> clearAll() async {
    if (kIsWeb) {
      _webMemCache.clear();
      _webSyncQueue.clear();
      return;
    }
    final db = await database;
    await db.delete('kv_store');
    await db.delete('inventory');
    await db.delete('bookings');
    await db.delete('sync_queue');
  }

  // Inventory helpers
  Future<void> insertMedicine(Map<String, dynamic> medicine) async {
    if (kIsWeb) return; // Simple mock for web if needed, but focus is mobile
    final db = await database;
    await db.insert(
      'inventory',
      medicine,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getMedicines() async {
    if (kIsWeb) return [];
    final db = await database;
    return await db.query('inventory');
  }

  // Bookings helpers
  Future<void> insertBooking(Map<String, dynamic> booking) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(
      'bookings',
      booking,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getBookings() async {
    if (kIsWeb) return [];
    final db = await database;
    return await db.query('bookings');
  }

  Future<void> deleteBooking(String id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete(
      'bookings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // NOTE: saveProfile / getProfile removed.
  // User profiles are now managed by Supabase (public.profiles table).
  // Only in-progress registration state is saved locally.

  // High-level registration step helpers
  Future<void> saveRegistrationProgress(
      int step, Map<String, dynamic> stateJson) async {
    await write('reg_step', step.toString());
    await write('reg_state', jsonEncode(stateJson));
  }

  Future<int?> getRegistrationStep() async {
    final stepStr = await read('reg_step');
    return stepStr != null ? int.tryParse(stepStr) : null;
  }

  Future<Map<String, dynamic>?> getRegistrationState() async {
    final data = await read('reg_state');
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> clearRegistrationProgress() async {
    await delete('reg_step');
    await delete('reg_state');
  }

  Future<void> enqueueSyncMutation(Map<String, dynamic> mutation) async {
    final record = {
      ...mutation,
      'payload': jsonEncode(mutation['payload'] ?? const {}),
      'attemptCount': 0,
      'status': 'pending',
      'lastError': null,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    if (kIsWeb) {
      _webSyncQueue.removeWhere(
        (item) => item['mutationId'] == record['mutationId'],
      );
      _webSyncQueue.add(record);
      return;
    }
    final db = await database;
    await db.insert(
      'sync_queue',
      record,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSyncMutations({
    int limit = 50,
  }) async {
    final records = kIsWeb
        ? _webSyncQueue.take(limit).toList()
        : await (await database).query(
            'sync_queue',
            where: 'status IN (?, ?)',
            whereArgs: ['pending', 'failed'],
            orderBy: 'createdAt ASC',
            limit: limit,
          );
    return records
        .map((record) => {
              ...record,
              'payload': jsonDecode(record['payload'] as String),
            })
        .toList();
  }

  Future<void> removeSyncMutation(String mutationId) async {
    if (kIsWeb) {
      _webSyncQueue.removeWhere((item) => item['mutationId'] == mutationId);
      return;
    }
    await (await database).delete(
      'sync_queue',
      where: 'mutationId = ?',
      whereArgs: [mutationId],
    );
  }

  Future<void> markSyncMutationFailed(
    String mutationId,
    String error,
  ) async {
    if (kIsWeb) {
      final index =
          _webSyncQueue.indexWhere((item) => item['mutationId'] == mutationId);
      if (index >= 0) {
        _webSyncQueue[index]['status'] = 'failed';
        _webSyncQueue[index]['lastError'] = error;
        _webSyncQueue[index]['attemptCount'] =
            (_webSyncQueue[index]['attemptCount'] as int) + 1;
      }
      return;
    }
    await (await database).rawUpdate(
      'UPDATE sync_queue SET status = ?, lastError = ?, '
      'attemptCount = attemptCount + 1 WHERE mutationId = ?',
      ['failed', error, mutationId],
    );
  }
}
