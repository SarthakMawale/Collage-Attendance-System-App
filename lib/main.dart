import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/student_dashboard.dart';
import 'screens/student_qr_screen.dart';
import 'screens/teacher_classes_screen.dart';
import 'screens/student_list_screen.dart';
import 'screens/qr_scan_screen.dart';
import 'screens/scanning_screen.dart';
import 'screens/attendance_marked_screen.dart';
import 'screens/manual_attendance_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/attendance_history_screen.dart';
import 'screens/students_admin_screen.dart';
import 'screens/add_student_screen.dart';
import 'screens/teachers_admin_screen.dart';
import 'screens/add_teacher_screen.dart';
import 'screens/classes_admin_screen.dart';
import 'screens/add_class_screen.dart';
import 'screens/notices_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';

void main() => runApp(const CollegeApp());

class CollegeApp extends StatelessWidget {
  const CollegeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'College Attendance',
        theme: ThemeData(
          primaryColor: const Color(0xFF0A1E3C),
          scaffoldBackgroundColor: const Color(0xFFF6F8FC),
          useMaterial3: true,
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/login': (_) => const LoginScreen(),
          '/role': (_) => const RoleSelectionScreen(),
          '/admin': (_) => const AdminDashboard(),
          '/teacher': (_) => const TeacherDashboard(),
          '/student': (_) => const StudentDashboard(),
          '/myQR': (_) => const StudentQRScreen(),
          '/teacherClasses': (_) => const TeacherClassesScreen(),
          '/studentList': (_) => const StudentListScreen(),
          '/qrScan': (_) => const QRScanScreen(),
          '/scanning': (_) => const ScanningScreen(),
          '/attendanceMarked': (_) => const AttendanceMarkedScreen(),
          '/manualAttendance': (_) => const ManualAttendanceScreen(),
          '/reports': (_) => const ReportsScreen(),
          '/attendanceHistory': (_) => const AttendanceHistoryScreen(),
          '/studentsAdmin': (_) => const StudentsAdminScreen(),
          '/addStudent': (_) => const AddStudentScreen(),
          '/teachersAdmin': (_) => const TeachersAdminScreen(),
          '/addTeacher': (_) => const AddTeacherScreen(),
          '/classesAdmin': (_) => const ClassesAdminScreen(),
          '/addClass': (_) => const AddClassScreen(),
          '/notices': (_) => const NoticesScreen(),
          '/profile': (_) => const ProfileScreen(),
        },
      ),
    );
  }
}