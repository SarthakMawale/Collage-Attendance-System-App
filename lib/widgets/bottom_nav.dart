import 'package:flutter/material.dart';
import '../models/app_models.dart';

class BottomNav extends StatelessWidget {
  final String active;
  final Function(String) onNav;
  final Role role;

  const BottomNav({
    super.key,
    required this.active,
    required this.onNav,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> items;
    switch (role) {
      case Role.Admin:
        items = [
          {"label": "Dashboard", "icon": "🏠"},
          {"label": "Students", "icon": "👥"},
          {"label": "Teachers", "icon": "👩‍🏫"},
          {"label": "More", "icon": "☰"},
        ];
        break;
      case Role.Teacher:
        items = [
          {"label": "Dashboard", "icon": "🏠"},
          {"label": "Classes", "icon": "🏫"},
          {"label": "Reports", "icon": "📊"},
          {"label": "More", "icon": "☰"},
        ];
        break;
      case Role.Student:
        items = [
          {"label": "Dashboard", "icon": "🏠"},
          {"label": "History", "icon": "🕒"},
          {"label": "Notices", "icon": "🔔"},
          {"label": "Profile", "icon": "👤"},
        ];
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isActive = active == item["label"];
          return GestureDetector(
            onTap: () => onNav(item["label"]!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (index == 2 && role != Role.Student)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A1E3C),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "🔳",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  )
                else
                  Text(
                    item["icon"]!,
                    style: TextStyle(
                      fontSize: 20,
                      color: isActive ? Colors.black : Colors.grey.shade500,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  item["label"]!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? Colors.black : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}