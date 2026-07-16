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
      version: 3, // Incremented version to add detailed bookings columns
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('CREATE TABLE IF NOT EXISTS inventory (id TEXT PRIMARY KEY, name TEXT, expiry TEXT, level TEXT)');
          await db.execute('CREATE TABLE IF NOT EXISTS bookings (id TEXT PRIMARY KEY, doctorName TEXT, specialty TEXT, date TEXT, time TEXT)');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE bookings ADD COLUMN avatarUrl TEXT');
          await db.execute('ALTER TABLE bookings ADD COLUMN videoLink TEXT');
          await db.execute('ALTER TABLE bookings ADD COLUMN notes TEXT');
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS kv_store (key TEXT PRIMARY KEY, value TEXT)');
    await db.execute('CREATE TABLE IF NOT EXISTS inventory (id TEXT PRIMARY KEY, name TEXT, expiry TEXT, level TEXT)');
    await db.execute('CREATE TABLE IF NOT EXISTS bookings (id TEXT PRIMARY KEY, doctorName TEXT, specialty TEXT, date TEXT, time TEXT, avatarUrl TEXT, videoLink TEXT, notes TEXT)');
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
      return;
    }
    final db = await database;
    await db.delete('kv_store');
    await db.delete('inventory');
    await db.delete('bookings');
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
  Future<void> saveRegistrationProgress(int step, Map<String, dynamic> stateJson) async {
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
}
