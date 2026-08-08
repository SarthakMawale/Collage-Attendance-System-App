import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../utils/mock_data.dart';
import 'qr_generation_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  final AppUser student;

  const PersonalInfoScreen({super.key, required this.student});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedBranch;
  bool _isInfoFilled = false;

  final List<String> _branches = [
    'FYBSC',
    'SYBSC',
    'TYBSC',
    'FYBCA',
    'SYBCA',
    'TYBCA',
    'FYBCOM',
    'SYBCOM',
    'TYBCOM',
  ];

@override
void initState() {
  super.initState();
  _isInfoFilled = widget.student.rollNo != null;
  if (_isInfoFilled) {
    _nameController.text = widget.student.name;
    _rollNoController.text = widget.student.rollNo ?? '';
    _emailController.text = widget.student.email;
    _phoneController.text = widget.student.mobile ?? '';
    
    // Map className to branch format
    final className = widget.student.className ?? '';
    if (className.contains('BCA')) {
      if (className.contains('FY') || className.contains('Sem 1')) {
        _selectedBranch = 'FYBCA';
      } else if (className.contains('SY') || className.contains('Sem 3')) {
        _selectedBranch = 'SYBCA';
      } else if (className.contains('TY') || className.contains('Sem 5')) {
        _selectedBranch = 'TYBCA';
      }
    } else if (className.contains('BSc') || className.contains('BSC')) {
      if (className.contains('FY') || className.contains('Sem 1')) {
        _selectedBranch = 'FYBSC';
      } else if (className.contains('SY') || className.contains('Sem 3')) {
        _selectedBranch = 'SYBSC';
      } else if (className.contains('TY') || className.contains('Sem 5')) {
        _selectedBranch = 'TYBSC';
      }
    } else if (className.contains('BCOM') || className.contains('BCom')) {
      if (className.contains('FY') || className.contains('Sem 1')) {
        _selectedBranch = 'FYBCOM';
      } else if (className.contains('SY') || className.contains('Sem 3')) {
        _selectedBranch = 'SYBCOM';
      } else if (className.contains('TY') || className.contains('Sem 5')) {
        _selectedBranch = 'TYBCOM';
      }
    }
  }
}

  @override
  void dispose() {
    _nameController.dispose();
    _rollNoController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  String _generateRollNumber(String branch, String fullName) {
    final branchStudents = mockStudents
        .where((s) => s.className?.startsWith(branch) ?? false)
        .toList();

    branchStudents.sort((a, b) => a.name.compareTo(b.name));

    int position = branchStudents.indexWhere((s) => s.name == fullName);
    if (position == -1) {
      position = branchStudents.length;
    }

    final rollNumber = position + 1;
    return '$branch-${rollNumber.toString().padLeft(3, '0')}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _saveInfo() {
    if (_formKey.currentState!.validate()) {
      if (_selectedBranch == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a branch')),
        );
        return;
      }

      final rollNumber =
          _generateRollNumber(_selectedBranch!, _nameController.text);
      _rollNoController.text = rollNumber;

      setState(() {
        _isInfoFilled = true;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QrGenerationScreen(
            studentName: _nameController.text,
            rollNumber: rollNumber,
            branch: _selectedBranch!,
          ),
        ),
      );
    }
  }

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
          "Personal Information",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isInfoFilled) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Information already filled. Only admin can edit.',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              TextFormField(
                controller: _nameController,
                enabled: !_isInfoFilled,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedBranch,
                decoration: InputDecoration(
                  labelText: 'Branch *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.school),
                  filled: _isInfoFilled,
                  fillColor: _isInfoFilled ? Colors.grey.shade200 : null,
                ),
                items: _branches.map((branch) {
                  return DropdownMenuItem(
                    value: branch,
                    child: Text(branch),
                  );
                }).toList(),
                onChanged: _isInfoFilled
                    ? null
                    : (value) {
                        setState(() {
                          _selectedBranch = value;
                        });
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a branch';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rollNoController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Roll Number *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                  helperText: 'Auto-generated based on branch and name',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                enabled: !_isInfoFilled,
                decoration: const InputDecoration(
                  labelText: 'Gmail (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                enabled: !_isInfoFilled,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dobController,
                enabled: !_isInfoFilled,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _isInfoFilled ? null : _selectDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your date of birth';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              if (!_isInfoFilled) ...[
                ElevatedButton(
                  onPressed: _saveInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1E3C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save & Generate QR',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
