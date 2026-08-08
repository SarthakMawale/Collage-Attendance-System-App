import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../utils/mock_data.dart';
import '../widgets/bottom_nav.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String activeTab = "Dashboard";
  final student = mockStudents[1];

  void navigateTo(String tab) {
    if (tab == "Dashboard") return;
    if (tab == "History") {
      Navigator.pushNamed(context, '/attendanceHistory');
    } else if (tab == "Notices") {
      Navigator.pushNamed(context, '/notices');
    } else if (tab == "Profile") {
      Navigator.pushNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0A1E3C),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      "Hello, ${student.name.split(" ").first} 👋",
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Spacer(),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: Text("🔔", style: TextStyle(fontSize: 16))),
                    ),
                  ],
                ),
                Text(
                  student.className ?? "BCA FY - Sem 1",
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text("Attendance Percentage", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const Spacer(),
                          const Text(
                            "85%",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0A1E3C)),
                          ),
                          const SizedBox(width: 4),
                          Text("Great!", style: TextStyle(fontSize: 11, color: Colors.green.shade600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.85,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          color: Colors.green.shade500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: const [
                                Text("40", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text("Total Classes", style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: const [
                                Text("34", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                Text("Present", style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: const [
                                Text("6", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                Text("Absent", style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Classes",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1E3C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildClassItem("DSA", "9:00 AM - 10:00 AM", "Present"),
                  const SizedBox(height: 8),
                  _buildClassItem("Maths", "11:00 AM - 12:00 PM", "Present"),
                  const SizedBox(height: 8),
                  _buildClassItem("English", "1:00 PM - 2:00 PM", "Absent"),
                ],
              ),
            ),
          ),
          BottomNav(
            active: activeTab,
            onNav: navigateTo,
            role: Role.Student,
          ),
        ],
      ),
    );
  }

  Widget _buildClassItem(String subject, String time, String status) {
    final isPresent = status == "Present";
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text("📚", style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}