import 'package:flutter/material.dart';
import '../utils/mock_data.dart';
import '../utils/constants.dart';

class StudentQRScreen extends StatelessWidget {
  const StudentQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = mockStudents[1];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1E3C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My QR Code",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Image.network(
                "$qrBaseUrl?size=200x200&data=${student.rollNo}-${student.name}",
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              student.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF0A1E3C),
              ),
            ),
            Text(
              student.className ?? "BCA FY - Sem 1",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            Text(
              "Roll No: ${student.rollNo}",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              "Show this QR code to\nyour teacher during attendance",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("QR Code downloaded")),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1E3C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Download QR",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}