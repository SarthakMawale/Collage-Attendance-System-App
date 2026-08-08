import 'package:flutter/material.dart';
import '../models/app_models.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  Role? selected;

  @override
  Widget build(BuildContext context) {
    final roles = [
      {"icon": "👨‍💼", "label": "Admin", "desc": "Manage everything", "color": Colors.blue.shade50},
      {"icon": "👩‍🏫", "label": "Teacher", "desc": "Take attendance", "color": Colors.orange.shade50},
      {"icon": "🧑‍🎓", "label": "Student", "desc": "View your attendance", "color": Colors.green.shade50},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Select Your Role",
          style: TextStyle(color: Color(0xFF0A1E3C), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Choose your role to continue",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ...roles.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  final role = r["label"] == "Admin" ? Role.Admin :
                      r["label"] == "Teacher" ? Role.Teacher : Role.Student;
                  Navigator.pop(context, role);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: r["color"] as Color? ?? Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected == (r["label"] == "Admin" ? Role.Admin :
                          r["label"] == "Teacher" ? Role.Teacher : Role.Student)
                          ? const Color(0xFF0A1E3C)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(r["icon"] as String, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r["label"] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A1E3C),
                              ),
                            ),
                            Text(
                              r["desc"] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}