import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

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
          "Reports",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Daily Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const Text("Date: 08 May 2026", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: CustomPaint(
                        painter: _PieChartPainter([0.78, 0.15, 0.05, 0.02]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLegend("Present", 31, "78%", Colors.green),
                  _buildLegend("Absent", 6, "15%", Colors.red),
                  _buildLegend("Late", 2, "5%", Colors.orange),
                  _buildLegend("Leave", 1, "2%", Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("📊 Viewing student details")),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1E3C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "View Students",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, int count, String percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Text("$count ($percent)", style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<double> data;

  _PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final startAngle = -0.5 * 3.14159;
    final colors = [Colors.green, Colors.red, Colors.orange, Colors.blue];
    double currentAngle = startAngle;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = data[i] * 2 * 3.14159;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, currentAngle, sweepAngle, true, paint);
      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}