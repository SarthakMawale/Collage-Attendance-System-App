import 'package:flutter/material.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final days = List.generate(31, (i) => i + 1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Attendance History",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.arrow_back_ios, size: 14),
                const Spacer(),
                const Text("May 2026", style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: days.length,
              itemBuilder: (ctx, i) {
                final day = days[i];
                final isPresent = day % 3 == 0;
                final isAbsent = day % 7 == 0;
                Color bg = Colors.transparent;
                Color textColor = Colors.black;
                if (day == 8) {
                  bg = const Color(0xFF0A1E3C);
                  textColor = Colors.white;
                } else if (isPresent) {
                  bg = Colors.green.shade100;
                  textColor = Colors.green.shade700;
                } else if (isAbsent) {
                  bg = Colors.red.shade100;
                  textColor = Colors.red.shade700;
                }
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("08 May 2026", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                  _buildHistoryItem("DSA", "9:00 AM - 10:00 AM", "Present", true),
                  const Divider(height: 8),
                  _buildHistoryItem("Maths", "11:00 AM - 12:00 PM", "Present", true),
                  const Divider(height: 8),
                  _buildHistoryItem("English", "1:00 PM - 2:00 PM", "Absent", false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String subject, String time, String status, bool isPresent) {
    return Row(
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
    );
  }
}