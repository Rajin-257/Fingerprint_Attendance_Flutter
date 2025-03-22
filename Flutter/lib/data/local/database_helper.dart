import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../config/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, DBConstants.databaseName);
    return await openDatabase(
      path,
      version: DBConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE ${DBConstants.usersTable} (
        id INTEGER PRIMARY KEY,
        serverUserId INTEGER,
        userType TEXT NOT NULL,
        email TEXT NOT NULL,
        name TEXT NOT NULL,
        code TEXT,
        instituteId INTEGER,
        instituteName TEXT,
        lastSync TEXT
      )
    ''');

    // Departments table
    await db.execute('''
      CREATE TABLE ${DBConstants.departmentsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serverDepartmentId INTEGER,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        description TEXT,
        active INTEGER DEFAULT 1,
        instituteId INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Sections table
    await db.execute('''
      CREATE TABLE ${DBConstants.sectionsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serverSectionId INTEGER,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        capacity INTEGER DEFAULT 50,
        description TEXT,
        active INTEGER DEFAULT 1,
        departmentId INTEGER NOT NULL,
        instituteId INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Courses table
    await db.execute('''
      CREATE TABLE ${DBConstants.coursesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serverCourseId INTEGER,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        description TEXT,
        creditHours REAL DEFAULT 3.0,
        schedule TEXT,
        active INTEGER DEFAULT 1,
        departmentId INTEGER NOT NULL,
        sectionId INTEGER NOT NULL,
        teacherId INTEGER,
        instituteId INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Teachers table
    await db.execute('''
      CREATE TABLE ${DBConstants.teachersTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serverTeacherId INTEGER,
        employeeId TEXT NOT NULL,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT,
        qualification TEXT,
        joiningDate TEXT,
        fingerprint TEXT,
        deviceId TEXT,
        active INTEGER DEFAULT 1,
        instituteId INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Students table
    await db.execute('''
      CREATE TABLE ${DBConstants.studentsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serverStudentId INTEGER,
        registrationNumber TEXT NOT NULL,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        email TEXT,
        dateOfBirth TEXT,
        gender TEXT,
        contactNumber TEXT,
        address TEXT,
        fingerprint TEXT,
        active INTEGER DEFAULT 1,
        instituteId INTEGER NOT NULL,
        departmentId INTEGER NOT NULL,
        sectionId INTEGER NOT NULL,
        addedBy INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Student Course (enrollment) table
    await db.execute('''
      CREATE TABLE student_course (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serverEnrollmentId INTEGER,
        studentId INTEGER NOT NULL,
        courseId INTEGER NOT NULL,
        enrollmentDate TEXT NOT NULL,
        status TEXT DEFAULT 'Active',
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        synced INTEGER DEFAULT 0,
        UNIQUE(studentId, courseId)
      )
    ''');

    // Attendance table
    await db.execute('''
      CREATE TABLE ${DBConstants.attendanceTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serverAttendanceId INTEGER,
        offlineId TEXT NOT NULL,
        studentId INTEGER NOT NULL,
        courseId INTEGER NOT NULL,
        teacherId INTEGER NOT NULL,
        instituteId INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        timeIn TEXT,
        remarks TEXT,
        fingerprintVerified INTEGER DEFAULT 0,
        verified INTEGER DEFAULT 0,
        syncedFromOffline INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Sync Queue table for tracking pending sync operations
    await db.execute('''
      CREATE TABLE ${DBConstants.syncQueueTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tableType TEXT NOT NULL,
        recordId INTEGER NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        priority INTEGER DEFAULT 0,
        attempts INTEGER DEFAULT 0,
        lastAttempt TEXT,
        createdAt TEXT NOT NULL,
        UNIQUE(tableType, recordId, operation)
      )
    ''');

    // Fingerprint templates table
    await db.execute('''
      CREATE TABLE ${DBConstants.fingerprintsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        templateData TEXT NOT NULL,
        fingerPosition TEXT,
        quality INTEGER,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        synced INTEGER DEFAULT 0,
        UNIQUE(studentId, fingerPosition)
      )
    ''');
  }

  // Upgrade database if needed
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
      // Example: await db.execute('ALTER TABLE ${DBConstants.studentsTable} ADD COLUMN newColumn TEXT');
    }
  }

  // Insert record
  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(table, row);
  }

  // Query records
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    Database db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  // Update record
  Future<int> update(
    String table,
    Map<String, dynamic> row, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    Database db = await database;
    return await db.update(
      table,
      row,
      where: where,
      whereArgs: whereArgs,
    );
  }

  // Delete record
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    Database db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  // Execute raw SQL query
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    Database db = await database;
    return await db.rawQuery(sql, arguments);
  }

  // Get record by ID
  Future<Map<String, dynamic>?> getById(String table, int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Count records
  Future<int> count(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    Database db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table ${where != null ? 'WHERE $where' : ''}',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Begin transaction
  Future<void> transaction(Future<dynamic> Function(Transaction txn) action) async {
    Database db = await database;
    await db.transaction(action);
  }

  // Check if record exists
  Future<bool> exists(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    Database db = await database;
    final result = await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Get all unsynchronized records for a table
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    Database db = await database;
    return await db.query(
      table,
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  // Mark record as synchronized
  Future<int> markAsSynced(String table, int id, int serverId) async {
    Database db = await database;
    return await db.update(
      table,
      {
        'synced': 1,
        'server${table.substring(0, table.length - 1).capitalize()}Id': serverId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clear database (for testing or reset)
  Future<void> clearDatabase() async {
    Database db = await database;
    var tables = [
      DBConstants.usersTable,
      DBConstants.departmentsTable,
      DBConstants.sectionsTable,
      DBConstants.coursesTable,
      DBConstants.teachersTable,
      DBConstants.studentsTable,
      'student_course',
      DBConstants.attendanceTable,
      DBConstants.syncQueueTable,
      DBConstants.fingerprintsTable,
    ];

    for (var table in tables) {
      await db.delete(table);
    }
  }
}

// Helper extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
