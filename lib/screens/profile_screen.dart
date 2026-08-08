import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../utils/mock_data.dart';
import '../widgets/bottom_nav.dart';
import 'personal_info_screen.dart';
import 'attendance_history_screen.dart';
import 'leave_requests_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final student = mockStudents[1];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                ClipOval(
                  child: Image.network(
                    student.photo ?? "https://i.pravatar.cc/150?img=1",
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  student.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF0A1E3C),
                  ),
                ),
                Text(
                  student.rollNo ?? student.email,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                children: [
                  _buildMenuItem(
                    "Personal Information", 
                    "👤",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PersonalInfoScreen(student: student),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    "Attendance Summary", 
                    "📊",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendanceHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    "Leave Requests", 
                    "📝",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LeaveRequestsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    "Change Password", 
                    "🔒",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    "Logout", 
                    "🚪", 
                    isLogout: true,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                              },
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          BottomNav(
            active: "Profile",
            onNav: (tab) {
              if (tab == "Dashboard") {
                Navigator.pop(context);
              }
            },
            role: Role.Student,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String label, String icon, {bool isLogout = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLogout ? Colors.red.shade100 : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isLogout ? Colors.red.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(icon)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isLogout ? Colors.red : const Color(0xFF0A1E3C),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}