import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../db/database_helper.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  AppProvider
///  Single source of truth for the whole app's data. Everything here is
///  backed by SQLite (via DatabaseHelper) so it survives app restarts,
///  phone reboots, etc. Nothing is ever silently reset.
///
///  Usage in screens:
///    final provider = context.read<AppProvider>();   // to call methods
///    final provider = context.watch<AppProvider>();  // to rebuild on change
/// ─────────────────────────────────────────────────────────────────────────
class AppProvider extends ChangeNotifier {
  final _dbHelper = DatabaseHelper.instance;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AppUser? _currentUser;
  List<AppUser> _students = [];
  List<AppUser> _teachers = [];
  List<ClassItem> _classes = [];
  List<AttendanceRecord> _attendance = [];
  List<Notice> _notices = [];

  AppUser? get currentUser => _currentUser;
  List<AppUser> get students => _students;
  List<AppUser> get teachers => _teachers;
  List<ClassItem> get classes => _classes;
  List<AttendanceRecord> get attendance => _attendance;
  List<Notice> get notices => _notices;

  /// Call this once at app startup (e.g. from the splash screen) before
  /// showing any real UI. Loads everything from SQLite into memory and
  /// restores the last logged-in session if there was one.
  Future<void> init() async {
    await _seedDefaultDataIfFirstRun();
    await _reloadAll();
    await _restoreSession();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _reloadAll() async {
    final db = await _dbHelper.database;

    final userRows = await db.query('users', where: 'isActive = 1');
    final allUsers = userRows.map((m) => AppUser.fromMap(m)).toList();
    _students = allUsers.where((u) => u.role == Role.Student).toList();
    _teachers = allUsers.where((u) => u.role == Role.Teacher).toList();

    final classRows = await db.query('classes', where: 'isActive = 1');
    _classes = classRows.map((m) => ClassItem.fromMap(m)).toList();

    final attendanceRows = await db.query('attendance', orderBy: 'date DESC, id DESC');
    _attendance = attendanceRows.map((m) => AttendanceRecord.fromMap(m)).toList();

    final noticeRows = await db.query('notices', orderBy: 'date DESC, id DESC');
    _notices = noticeRows.map((m) => Notice.fromMap(m)).toList();
  }

  // ── First-run seeding ────────────────────────────────────────────────
  // Runs ONLY if the users table is completely empty (i.e. truly first
  // launch ever, or right after a deliberate factory reset). Never wipes
  // or overwrites existing data on subsequent launches.
  Future<void> _seedDefaultDataIfFirstRun() async {
    final db = await _dbHelper.database;
    final existing = await db.query('users', limit: 1);
    if (existing.isNotEmpty) return; // already has real data, don't touch it

    // Default admin account — change this password after first login via
    // the Change Password screen for production use.
    await db.insert('users', {
      'name': 'Admin',
      'email': 'admin@college.edu',
      'password': 'admin123',
      'role': roleToStr(Role.Admin),
      'rollNo': null,
      'mobile': null,
      'photo': 'https://i.pravatar.cc/150?img=68',
      'className': null,
      'subject': null,
    });

    // A couple of demo teacher/student accounts so the app isn't empty
    // on first run. Admin can delete these from the admin screens later.
    await db.insert('users', {
      'name': 'Prof. John Doe',
      'email': 'john@college.edu',
      'password': '123456',
      'role': roleToStr(Role.Teacher),
      'subject': 'DSA',
      'photo': 'https://i.pravatar.cc/150?img=8',
    });

    await db.insert('users', {
      'name': 'Rohan Kumar',
      'email': 'rohan@college.edu',
      'password': '123456',
      'role': roleToStr(Role.Student),
      'rollNo': '23BCA1002',
      'mobile': '9876543211',
      'className': 'BCA FY - Sem 1',
      'photo': 'https://i.pravatar.cc/150?img=12',
    });

    await db.insert('classes', {
      'name': 'BCA FY - Sem 1',
      'students': 1,
      'semester': 'Sem 1',
      'teacherId': null,
    });
  }

  // ── Session persistence (so the user stays logged in after closing app) ─
  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('session_user_id');
    if (userId == null) return;

    final db = await _dbHelper.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (rows.isNotEmpty) {
      _currentUser = AppUser.fromMap(rows.first);
    } else {
      // stale session (user was deleted) — clear it
      await prefs.remove('session_user_id');
    }
  }

  Future<void> _saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('session_user_id', userId);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_user_id');
  }

  // ── Auth ─────────────────────────────────────────────────────────────
  Future<bool> login(String emailOrRoll, String password, Role role) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'users',
      where:
          'role = ? AND password = ? AND isActive = 1 AND (LOWER(email) = ? OR rollNo = ?)',
      whereArgs: [
        roleToStr(role),
        password,
        emailOrRoll.toLowerCase(),
        emailOrRoll,
      ],
      limit: 1,
    );

    if (rows.isEmpty) return false;

    _currentUser = AppUser.fromMap(rows.first);
    await _saveSession(_currentUser!.id!);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _clearSession();
    notifyListeners();
  }

  // ── Students / Teachers (both stored in `users` table) ─────────────────
  Future<bool> addStudent(AppUser student) async {
    final db = await _dbHelper.database;
    try {
      final id = await db.insert('users', student.toMap());
      _students.add(student.copyWith(id: id));
      notifyListeners();
      return true;
    } catch (e) {
      // most likely a UNIQUE constraint failure (duplicate email)
      return false;
    }
  }

  Future<bool> addTeacher(AppUser teacher) async {
    final db = await _dbHelper.database;
    try {
      final id = await db.insert('users', teacher.toMap());
      _teachers.add(teacher.copyWith(id: id));
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateUser(AppUser user) async {
    final db = await _dbHelper.database;
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
    await _reloadAll();
    if (_currentUser?.id == user.id) _currentUser = user;
    notifyListeners();
  }

  /// Soft-delete: student disappears from lists/login, but the row and all
  /// their attendance history stay in the DB forever. Re-add the same
  /// email/rollNo later (via reactivateStudent) and their old records
  /// are still there, linked by the same id.
  Future<void> deleteStudent(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'isActive': 0},
      where: 'id = ? AND role = ?',
      whereArgs: [id, roleToStr(Role.Student)],
    );
    _students.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<void> deleteTeacher(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'isActive': 0},
      where: 'id = ? AND role = ?',
      whereArgs: [id, roleToStr(Role.Teacher)],
    );
    _teachers.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  /// Brings a soft-deleted user back — they can log in again and will see
  /// every attendance record they ever had, since the row (and its id)
  /// was never actually removed.
  Future<void> reactivateUser(int id) async {
    final db = await _dbHelper.database;
    await db.update('users', {'isActive': 1}, where: 'id = ?', whereArgs: [id]);
    await _reloadAll();
    notifyListeners();
  }

  /// Admin-only view of soft-deleted users (so they can be restored or
  /// permanently purged later if ever needed).
  Future<List<AppUser>> getDeletedUsers() async {
    final db = await _dbHelper.database;
    final rows = await db.query('users', where: 'isActive = 0');
    return rows.map((m) => AppUser.fromMap(m)).toList();
  }

  // ── Classes ──────────────────────────────────────────────────────────
  Future<void> addClass(ClassItem classItem) async {
    final db = await _dbHelper.database;
    final id = await db.insert('classes', classItem.toMap());
    _classes.add(classItem.copyWith(id: id));
    notifyListeners();
  }

  /// Soft-delete: hidden from lists, but every attendance record that
  /// references this classId (attendance.classId) still resolves fine.
  Future<void> deleteClass(int id) async {
    final db = await _dbHelper.database;
    await db.update('classes', {'isActive': 0}, where: 'id = ?', whereArgs: [id]);
    _classes.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  // ── Attendance ───────────────────────────────────────────────────────
  Future<void> markAttendance(AttendanceRecord record) async {
    final db = await _dbHelper.database;
    final id = await db.insert('attendance', record.toMap());
    _attendance.insert(
      0,
      AttendanceRecord(
        id: id,
        studentId: record.studentId,
        teacherId: record.teacherId,
        classId: record.classId,
        subject: record.subject,
        status: record.status,
        date: record.date,
        time: record.time,
      ),
    );
    notifyListeners();
  }

  // ── Notices ──────────────────────────────────────────────────────────
  Future<void> addNotice(Notice notice) async {
    final db = await _dbHelper.database;
    final id = await db.insert('notices', notice.toMap());
    _notices.insert(
      0,
      Notice(
        id: id,
        title: notice.title,
        description: notice.description,
        date: notice.date,
        postedBy: notice.postedBy,
      ),
    );
    notifyListeners();
  }

  Future<void> deleteNotice(int id) async {
    final db = await _dbHelper.database;
    await db.delete('notices', where: 'id = ?', whereArgs: [id]);
    _notices.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  // ── Derived / query helpers (unchanged logic, still in-memory) ─────────
  double getAttendancePercentage(int studentId) {
    final records = _attendance.where((a) => a.studentId == studentId).toList();
    if (records.isEmpty) return 0.0;
    final present = records.where((a) => a.status == AttendanceStatus.Present).length;
    return (present / records.length) * 100;
  }

  List<AttendanceRecord> getStudentAttendance(int studentId) {
    return _attendance.where((a) => a.studentId == studentId).toList();
  }

  List<AttendanceRecord> getClassAttendance(int classId) {
    return _attendance.where((a) => a.classId == classId).toList();
  }

  List<AppUser> getStudentsByClass(String className) {
    return _students.where((s) => s.className == className).toList();
  }
}