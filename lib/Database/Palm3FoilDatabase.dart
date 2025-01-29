import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:smartgetrack/Common/Constants.dart';
import 'package:smartgetrack/HomeScreen.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

import 'DatabaseHelper.dart';

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

class Palm3FoilDatabase {
  static const String DATABASE_NAME = 'smartgeotrack.sqlite';
  static final Lock _lock = Lock();
  static Palm3FoilDatabase? _instance;
  static Database? _database;
  static String? _dbPath;

  Palm3FoilDatabase._privateConstructor();

  /// Singleton Instance
  static Future<Palm3FoilDatabase?> getInstance() async {
    if (_instance == null) {
      _instance = Palm3FoilDatabase._privateConstructor();
      await _instance!._initializeDatabasePath();
    }
    return _instance;
  }

  /// Initialize the database path
  Future<void> _initializeDatabasePath() async {
    try {
      final dbDirectory = await getApplicationDocumentsDirectory();
      if (!await dbDirectory.exists()) {
        await dbDirectory.create(recursive: true);
      }
      print('database path: $dbDirectory');
      _dbPath = join(dbDirectory.path, DATABASE_NAME);
    } catch (e) {
      print('Error initializing database path: $e');
      rethrow;
    }
  }

  /// Create Database (if it doesn't exist)
  Future<void> createDatabase() async {
    bool dbExists = await _checkDatabase();
    if (!dbExists) {
      try {
        await _copyDatabase();
        print('Database copied successfully.');
      } catch (e) {
        print('Error copying database: $e');
        throw Exception('Error copying database');
      }
    }

    // Open the database after creation or if it already exists
    await _getDatabaseInstance();
    await printTables();
  }

  /// Check if the database file exists
  Future<bool> _checkDatabase() async {
    try {
      if (_dbPath == null) throw Exception("Database path is not initialized.");
      final dbFile = File(_dbPath!);
      return await dbFile.exists();
    } catch (e) {
      print('Error checking database: $e');
      return false;
    }
  }

  /// Copy the database from assets to the local directory
  Future<void> _copyDatabase() async {
    try {
      if (_dbPath == null) throw Exception("Database path is not initialized.");
      final data = await rootBundle.load('assets/$DATABASE_NAME');
      final bytes = data.buffer.asUint8List();
      final dbFile = File(_dbPath!);

      if (await dbFile.exists()) {
        await dbFile.delete(); // Delete any existing database file
      }
      await dbFile.writeAsBytes(bytes, flush: true);
    } catch (e) {
      print('Error copying database from assets: $e');
      throw Exception('Error copying database');
    }
  }

  /// Open or return the database instance
  Future<Database> _getDatabaseInstance() async {
    if (_database != null) {
      return _database!;
    }

    if (_dbPath == null) {
      throw Exception("Database path is not initialized.");
    }

    _database = await openDatabase(_dbPath!);
    return _database!;
  }

  /// Insert location values
  Future<void> insertLocationValues({
    required double latitude,
    required double longitude,
    required int? createdByUserId,
    required bool serverUpdatedStatus,
    required String? from,
  }) async {
    await _lock.synchronized(() async {
      try {
        final db = await _getDatabaseInstance();
        final geoBoundaryValues = {
          'Latitude': latitude,
          'Longitude': longitude,
          'Address': from,
          'CreatedByUserId': createdByUserId,
          'CreatedDate': DateTime.now().toIso8601String(),
          'ServerUpdatedStatus': serverUpdatedStatus ? 1 : 0,
        };

        await db.insert('GeoBoundaries', geoBoundaryValues);
        print('Location values inserted successfully.');
        appendLog('Location values inserted successfully.');
      } catch (e) {
        print('Failed to insert location values: $e');
        appendLog('Failed to insert location values: $e');
        throw Exception('Failed to insert location values');
      }
   });
  }

  /// Print all tables in the database
  Future<void> printTables() async {
    try {
      final db = await _getDatabaseInstance();
      var result = await db.rawQuery(
          'SELECT name FROM sqlite_master WHERE type="table" ORDER BY name');
      print('Tables in the database: $result');
      print('Number of tables: ${result.length}');
    } catch (e) {
      print('Error retrieving tables: $e');
    }
  }

  /// Get location by latitude and longitude
  Future<List<Map<String, dynamic>>> getLocationByLatLong(
      double latitude, double longitude) async {
    final db = await _getDatabaseInstance();
    final result = await db.query(
      'GeoBoundaries',
      where: 'Latitude = ? AND Longitude = ?',
      whereArgs: [latitude, longitude],
    );
    return result;
  }
}

