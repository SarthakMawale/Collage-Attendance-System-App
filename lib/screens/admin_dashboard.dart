import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../utils/mock_data.dart';
import '../widgets/bottom_nav.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String activeTab = "Dashboard";

  void navigateTo(String tab) {
    if (tab == "Dashboard") return;
    if (tab == "Students") {
      Navigator.pushNamed(context, '/studentsAdmin');
    } else if (tab == "Teachers") {
      Navigator.pushNamed(context, '/teachersAdmin');
    } else if (tab == "Classes") {
      Navigator.pushNamed(context, '/classesAdmin');
    } else if (tab == "More") {
      Navigator.pushNamed(context, '/reports');
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
                    const Text(
                      "≡ Admin Dashboard",
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Total Students",
                        "${mockStudents.length + 1242}",
                        "👥",
                        Colors.white,
                        const Color(0xFF0A1E3C),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        "Total Teachers",
                        "${mockTeachers.length + 82}",
                        "👩‍🏫",
                        Colors.white,
                        const Color(0xFF0A1E3C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Total Classes",
                        "${4 + 58}",
                        "🏫",
                        Colors.white,
                        const Color(0xFF0A1E3C),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        "Today's Attendance",
                        "78%",
                        "✅",
                        Colors.green.shade500,
                        Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Absent Students",
                              style: TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                            Text(
                              "120 ⚠️",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "QR Generated Today",
                              style: TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                            Text(
                              "32 🔳",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1E3C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton("Add Student", "🧑‍🎓", () {
                          Navigator.pushNamed(context, '/addStudent');
                        }),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton("Add Teacher", "👩‍🏫", () {
                          Navigator.pushNamed(context, '/addTeacher');
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton("Add Class", "🏫", () {
                          Navigator.pushNamed(context, '/addClass');
                        }),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton("Reports", "📊", () {
                          Navigator.pushNamed(context, '/reports');
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/notices'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Row(
                        children: [
                          Text("📢", style: TextStyle(fontSize: 18)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Notices",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A1E3C),
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          BottomNav(
            active: activeTab,
            onNav: navigateTo,
            role: Role.Admin,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String icon, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.7))),
          Row(
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
              const Spacer(),
              Text(icon, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, String icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
              child: Center(child: Text(icon)),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A1E3C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}