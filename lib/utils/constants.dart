import 'package:flutter/material.dart';
import '../models/app_models.dart';

const primaryColor = Color(0xFF0A1E3C);
const secondaryColor = Color(0xFF1E3A8A);
const backgroundColor = Color(0xFFF6F8FC);

// Use a function instead of const list
List<ClassItem> getDefaultClasses() {
  return [
    ClassItem(id: 1, name: "BCA FY - Sem 1", students: 40, semester: "Sem 1"),
    ClassItem(id: 2, name: "BCA SY - Sem 3", students: 38, semester: "Sem 3"),
    ClassItem(id: 3, name: "BSc FY - Sem 1", students: 36, semester: "Sem 1"),
    ClassItem(id: 4, name: "BCOM FY - Sem 1", students: 42, semester: "Sem 1"),
  ];
}

const String qrBaseUrl = "https://api.qrserver.com/v1/create-qr-code/";