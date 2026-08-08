import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../utils/mock_data.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  bool isScanning = false;
  late AppUser selectedStudent;

  @override
  void initState() {
    super.initState();
    selectedStudent = mockStudents[1];
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is AppUser) {
      selectedStudent = args;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1E3C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "QR Scan",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1E3C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text("QR Scan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/manualAttendance',
                        arguments: selectedStudent,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Center(
                        child: Text("Manual", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Image.network(
                            "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${selectedStudent.rollNo}-${selectedStudent.name}",
                            width: 160,
                            height: 160,
                            colorBlendMode: BlendMode.dstIn,
                            opacity: const AlwaysStoppedAnimation(0.6),
                          ),
                        ),
                      ),
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.green.shade500, width: 3),
                        ),
                        child: Stack(
                          children: [
                            Positioned(top: 8, left: 8, child: _cornerPiece()),
                            Positioned(top: 8, right: 8, child: _cornerPiece()),
                            Positioned(bottom: 8, left: 8, child: _cornerPiece()),
                            Positioned(bottom: 8, right: 8, child: _cornerPiece()),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 1200),
                        height: 2,
                        color: Colors.red.shade500,
                        width: 240,
                        margin: EdgeInsets.only(
                          bottom: isScanning ? 100 : -100,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Scan Student QR Code",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Text(
                    "Ensure the QR code is\nwithin the frame",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => isScanning = !isScanning);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("📸 Scanning started...")),
                        );
                        Future.delayed(const Duration(seconds: 2), () {
                          setState(() => isScanning = false);
                          Navigator.pushNamed(context, '/attendanceMarked');
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1E3C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        isScanning ? "Scanning..." : "Start Scanning",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cornerPiece() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.green.shade500, width: 3),
          left: BorderSide(color: Colors.green.shade500, width: 3),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}