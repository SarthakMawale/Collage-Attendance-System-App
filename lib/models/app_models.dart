enum Role { Admin, Teacher, Student }

enum AttendanceStatus { Present, Absent, Late, Leave }

// ── helpers to convert enums <-> plain strings for SQLite storage ─────────
String roleToStr(Role r) => r.name;
Role roleFromStr(String s) =>
    Role.values.firstWhere((r) => r.name == s, orElse: () => Role.Student);

String statusToStr(AttendanceStatus s) => s.name;
AttendanceStatus statusFromStr(String s) => AttendanceStatus.values
    .firstWhere((v) => v.name == s, orElse: () => AttendanceStatus.Absent);

class AppUser {
  // id is nullable: null means "not saved yet" (SQLite assigns it on insert)
  final int? id;
  final String name;
  final String email;
  final String password;
  final Role role;
  final String? rollNo;
  final String? mobile;
  final String? photo;
  final String? className;
  final String? subject;
  final bool isActive;

  AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.rollNo,
    this.mobile,
    this.photo,
    this.className,
    this.subject,
    this.isActive = true,
  });

  AppUser copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    Role? role,
    String? rollNo,
    String? mobile,
    String? photo,
    String? className,
    String? subject,
    bool? isActive,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      rollNo: rollNo ?? this.rollNo,
      mobile: mobile ?? this.mobile,
      photo: photo ?? this.photo,
      className: className ?? this.className,
      subject: subject ?? this.subject,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'role': roleToStr(role),
      'rollNo': rollNo,
      'mobile': mobile,
      'photo': photo,
      'className': className,
      'subject': subject,
      'isActive': isActive ? 1 : 0,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      role: roleFromStr(map['role'] as String),
      rollNo: map['rollNo'] as String?,
      mobile: map['mobile'] as String?,
      photo: map['photo'] as String?,
      className: map['className'] as String?,
      subject: map['subject'] as String?,
      isActive: (map['isActive'] as int? ?? 1) == 1,
    );
  }
}

class ClassItem {
  final int? id;
  final String name;
  final int students;
  final String semester;
  final String? teacherId;
  final bool isActive;

  ClassItem({
    this.id,
    required this.name,
    required this.students,
    required this.semester,
    this.teacherId,
    this.isActive = true,
  });

  ClassItem copyWith({
    int? id,
    String? name,
    int? students,
    String? semester,
    String? teacherId,
    bool? isActive,
  }) {
    return ClassItem(
      id: id ?? this.id,
      name: name ?? this.name,
      students: students ?? this.students,
      semester: semester ?? this.semester,
      teacherId: teacherId ?? this.teacherId,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'students': students,
      'semester': semester,
      'teacherId': teacherId,
      'isActive': isActive ? 1 : 0,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory ClassItem.fromMap(Map<String, dynamic> map) {
    return ClassItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      students: map['students'] as int,
      semester: map['semester'] as String? ?? '',
      teacherId: map['teacherId'] as String?,
      isActive: (map['isActive'] as int? ?? 1) == 1,
    );
  }
}

class AttendanceRecord {
  final int? id;
  final int studentId;
  final int teacherId;
  final int classId;
  final String subject;
  final AttendanceStatus status;
  final String date;
  final String? time;

  AttendanceRecord({
    this.id,
    required this.studentId,
    required this.teacherId,
    required this.classId,
    required this.subject,
    required this.status,
    required this.date,
    this.time,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'studentId': studentId,
      'teacherId': teacherId,
      'classId': classId,
      'subject': subject,
      'status': statusToStr(status),
      'date': date,
      'time': time,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as int?,
      studentId: map['studentId'] as int,
      teacherId: map['teacherId'] as int,
      classId: map['classId'] as int,
      subject: map['subject'] as String? ?? '',
      status: statusFromStr(map['status'] as String),
      date: map['date'] as String,
      time: map['time'] as String?,
    );
  }
}

class Notice {
  final int? id;
  final String title;
  final String description;
  final String date;
  final String postedBy;

  Notice({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.postedBy,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'date': date,
      'postedBy': postedBy,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Notice.fromMap(Map<String, dynamic> map) {
    return Notice(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      date: map['date'] as String,
      postedBy: map['postedBy'] as String? ?? '',
    );
  }
}