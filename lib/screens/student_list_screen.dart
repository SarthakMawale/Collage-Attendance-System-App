import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../utils/mock_data.dart';
import '../utils/constants.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String searchQuery = "";
  List<AppUser> filteredStudents = mockStudents;

  @override
  void initState() {
    super.initState();
    filteredStudents = mockStudents;
  }

  @override
  Widget build(BuildContext context) {
    final classData = ModalRoute.of(context)!.settings.arguments as ClassItem? ?? getDefaultClasses()[0];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1E3C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              classData.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              "${mockStudents.length} Students",
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Text("🔍", style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (v) {
                        setState(() {
                          searchQuery = v;
                          filteredStudents = mockStudents
                              .where((s) => s.name.toLowerCase().contains(v.toLowerCase()))
                              .toList();
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: "Search Student",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredStudents.length,
              itemBuilder: (ctx, i) {
                final s = filteredStudents[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: Image.network(
                          s.photo ?? "https://i.pravatar.cc/150?img=1",
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 36,
                            height: 36,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(s.rollNo ?? "", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/qrScan',
                            arguments: s,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1E3C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Attend",
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}