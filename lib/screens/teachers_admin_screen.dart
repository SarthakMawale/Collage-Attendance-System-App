import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/toast.dart';

class TeachersAdminScreen extends StatefulWidget {
  const TeachersAdminScreen({super.key});

  @override
  State<TeachersAdminScreen> createState() => _TeachersAdminScreenState();
}

class _TeachersAdminScreenState extends State<TeachersAdminScreen> {
  String query = "";

  Future<void> _confirmDelete(BuildContext context, int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Teacher"),
        content: Text("Remove $name? Their attendance-marking history stays saved."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<AppProvider>().deleteTeacher(id);
      if (context.mounted) showToast(context, "🗑️ $name removed");
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachers = context.watch<AppProvider>().teachers;
    final filtered = teachers
        .where((t) => t.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Teachers",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
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
                          onChanged: (v) => setState(() => query = v),
                          decoration: const InputDecoration(
                            hintText: "Search Teacher",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          teachers.isEmpty
                              ? "No teachers yet. Tap + to add one."
                              : "No teachers match your search.",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final t = filtered[i];
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
                                    t.photo ?? "https://i.pravatar.cc/150?img=1",
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
                                      Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      Text(t.email, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      if (t.subject != null)
                                        Text(t.subject!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      _confirmDelete(context, t.id!, t.name);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text("Remove", style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/addTeacher'),
              backgroundColor: const Color(0xFF0A1E3C),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}