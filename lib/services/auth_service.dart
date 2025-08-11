import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _dbName = "users.db";
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  Database? _db;

  // Secure storage (для ключей)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _apiKeyStorageKey = "API_KEY";

  Future<void> init() async {
    _db = await openDatabase(
      join(await getDatabasesPath(), _dbName),
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            PIN TEXT UNIQUE,
            API_KEY TEXT
          )
        ''');
      },
      version: 1,
    );
  }

  Future<Map<String, dynamic>> register(String username, String key) async {
    final existing = await _db!.query(
      "users",
      where: "username = ?",
      whereArgs: [username],
    );
    if (existing.isNotEmpty) {
      return {'message': "Пользователь с таким username уже существует!", 'code': 400};
    }

    final pin = _generatePin();
    await _db!.insert("users", {
      "username": username,
      "PIN": pin,
      "API_KEY": key,
    });

    // Сохраняем ключ в secure storage
    await _secureStorage.write(key: _apiKeyStorageKey, value: key);

    return {
      'content': {'message': "Регистрация выполнена успешно.", 'pin': pin},
      'code': 200
    };
  }

  String _generatePin() {
    final rnd = Random();
    return (rnd.nextInt(10000)).toString().padLeft(4, '0');
  }

  Future<bool> login(String pin) async {
    final result = await _db!.query(
      "users",
      where: "PIN = ?",
      whereArgs: [pin],
    );

    if (result.isNotEmpty) {
      final key = result.first["API_KEY"] as String;
      await _secureStorage.write(key: _apiKeyStorageKey, value: key);
      return true;
    }
    return false;
  }

  Future<void> delUser(String username) async {
    await _db!.delete(
      "users",
      where: "username = ?",
      whereArgs: [username],
    );
  }

  /// Чтение ключа
  Future<String?> getStoredApiKey() async {
    return await _secureStorage.read(key: _apiKeyStorageKey);
  }

  /// Удаление ключа
  Future<void> clearApiKey() async {
    await _secureStorage.delete(key: _apiKeyStorageKey);
  }
}