import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../utils/mock_data.dart';
import '../widgets/toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String email = "";
  String password = "";
  Role selectedRole = Role.Student;

  void handleLogin() {
    AppUser? user;

    if (selectedRole == Role.Admin) {
      if (email == mockAdmin.email && password == mockAdmin.password) {
        user = mockAdmin;
      }
    } else if (selectedRole == Role.Teacher) {
      user = mockTeachers.firstWhere(
        (t) => t.email.toLowerCase() == email.toLowerCase() && t.password == password,
        orElse: () => mockTeachers[0],
      );
      if (user.email.toLowerCase() != email.toLowerCase()) user = null;
    } else {
      user = mockStudents.firstWhere(
        (s) => (s.email.toLowerCase() == email.toLowerCase() || s.rollNo == email) && s.password == password,
        orElse: () => mockStudents[0],
      );
      if (user.email.toLowerCase() != email.toLowerCase() && user.rollNo != email) {
        user = null;
      }
    }

    if (user != null) {
      showToast(context, "Welcome ${user.name}!");
      Navigator.pushReplacementNamed(
        context,
        selectedRole == Role.Admin ? '/admin' :
        selectedRole == Role.Teacher ? '/teacher' : '/student',
      );
    } else {
      showToast(context, "❌ Invalid credentials!");
    }
  }

  void quickLogin(Role role) {
    if (role == Role.Admin) {
      setState(() {
        email = "admin@college.edu";
        password = "admin123";
        selectedRole = Role.Admin;
      });
    } else if (role == Role.Teacher) {
      setState(() {
        email = "john@college.edu";
        password = "123456";
        selectedRole = Role.Teacher;
      });
    } else {
      setState(() {
        email = "rohan@college.edu";
        password = "123456";
        selectedRole = Role.Student;
      });
    }
    showToast(context, "Filled ${role.name} demo credentials");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Text(
                "Welcome Back 👋",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0A1E3C),
                ),
              ),
              const Text(
                "Login to Continue",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Role>(
                    value: selectedRole,
                    isExpanded: true,
                    items: Role.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedRole = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => email = v),
                  decoration: const InputDecoration(
                    hintText: "Email / Roll Number",
                    border: InputBorder.none,
                    // prefixIcon: Text("📧"),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => password = v),
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "Password",
                    border: InputBorder.none,
                    // prefixIcon: Text("🔒"),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1E3C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Don't have an account?",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickButton("Admin", Role.Admin),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickButton("Teacher", Role.Teacher),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickButton("Student", Role.Student),
                  ),
                ],
              ),
              // const SizedBox(height: 16),
              //  Container(
              //   padding: const EdgeInsets.all(12),
              //   decoration: BoxDecoration(
              //     color: Colors.blue.shade50,
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: const Text(
              //     "Demo: teacher@college.edu / 123456\nStudent: rohan@college.edu / 123456",
              //     textAlign: TextAlign.center,
              //     style: TextStyle(
              //       fontSize: 11,
              //       color: Colors.grey,
              //     ),
              //   ),
              // ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickButton(String label, Role role) {
    return ElevatedButton(
      onPressed: () => quickLogin(role),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0A1E3C),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}