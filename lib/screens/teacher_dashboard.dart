import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../widgets/bottom_nav.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String activeTab = "Dashboard";

  final List<Map<String, String>> todayClasses = [
    {"class": "BCA FY - Sem 1", "time": "9:00 AM - 10:00 AM", "subject": "DSA"},
    {"class": "BCA SY - Sem 3", "time": "11:00 AM - 12:00 PM", "subject": "Maths"},
    {"class": "BSc FY - Sem 1", "time": "1:00 PM - 2:00 PM", "subject": "English"},
  ];

  void navigateTo(String tab) {
    if (tab == "Dashboard") return;
    if (tab == "Classes") {
      Navigator.pushNamed(context, '/teacherClasses');
    } else if (tab == "Reports") {
      Navigator.pushNamed(context, '/reports');
    } else if (tab == "More") {
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
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      "Teacher Dashboard",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Image.network(
                        "https://i.pravatar.cc/150?img=8",
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Good Morning", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text("Prof. John Doe", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard("Today's Classes", "3"),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard("Pending", "2"),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard("Completed", "1"),
                    ),
                  ],
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
                  const Row(
                    children: [
                      Text(
                        "Today's Classes",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A1E3C),
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...todayClasses.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/teacherClasses'),
                      child: Container(
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
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(child: Text("📘", style: TextStyle(fontSize: 14))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c["class"]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(c["time"]!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text("Present", style: TextStyle(fontSize: 10, color: Colors.green)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
          BottomNav(
            active: activeTab,
            onNav: navigateTo,
            role: Role.Teacher,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}