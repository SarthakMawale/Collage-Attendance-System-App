import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  DatabaseHelper
///  Single SQLite database for the whole app.
///
///  WHERE IS IT SAVED?
///  sqflite automatically stores the .db file inside the app's PRIVATE
///  internal storage:
///     Android: /data/data/<package_name>/databases/attendance_app.db
///     iOS:     Application Support directory (sandboxed to this app)
///
///  This location is NEVER touched by Android/iOS automatically. Data only
///  goes away if the user manually:
///     1) Uninstalls the app, OR
///     2) Goes to Settings → Apps → (this app) → Storage → "Clear Data"
///  Normal app updates, phone restarts, low storage cleanups etc. do NOT
///  delete it. This is the standard, safe way to store data that must
///  survive app restarts on a single device.
/// ─────────────────────────────────────────────────────────────────────────
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath(); // internal app storage path
    final path = join(dbPath, 'attendance_app.db');

    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        // enforce foreign keys + wait properly on writes
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Soft-delete flag: 1 = active/visible, 0 = deleted (hidden but
          // the row + all its attendance history stays in the DB forever)
          await db.execute(
            'ALTER TABLE users ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1',
          );
          await db.execute(
            'ALTER TABLE classes ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1',
          );
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            password TEXT NOT NULL,
            role TEXT NOT NULL,
            rollNo TEXT,
            mobile TEXT,
            photo TEXT,
            className TEXT,
            subject TEXT,
            isActive INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE classes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            students INTEGER NOT NULL DEFAULT 0,
            semester TEXT,
            teacherId TEXT,
            isActive INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            studentId INTEGER NOT NULL,
            teacherId INTEGER NOT NULL,
            classId INTEGER NOT NULL,
            subject TEXT,
            status TEXT NOT NULL,
            date TEXT NOT NULL,
            time TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE notices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            date TEXT NOT NULL,
            postedBy TEXT
          )
        ''');

        // Unique index so the same email can't be inserted twice
        await db.execute(
          'CREATE UNIQUE INDEX idx_users_email ON users(email)',
        );
      },
    );
  }

  /// Wipes and recreates the DB file. Only ever call this from a
  /// deliberate "Reset App Data" admin action — never automatically.
  Future<void> resetDatabase() async {
    final db = await database;
    await db.close();
    _db = null;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'attendance_app.db');
    await deleteDatabase(path);
    _db = await _initDb();
  }
}