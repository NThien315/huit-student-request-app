import 'package:flutter/material.dart';

class AdminStat {
  final String title;
  final int value;
  final String percent;
  final IconData icon;
  final Color color;

  const AdminStat({
    required this.title,
    required this.value,
    required this.percent,
    required this.icon,
    required this.color,
  });
}

class StudentRequest {
  final String id;
  final String studentName;
  final String studentClass;
  final String requestType;
  final String date;
  String status;
  String note;

  StudentRequest({
    required this.id,
    required this.studentName,
    required this.studentClass,
    required this.requestType,
    required this.date,
    required this.status,
    this.note = '',
  });
}

class RequestCategory {
  final String id;
  String name;
  String description;
  String department;
  String processingTime;
  bool active;

  RequestCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.department,
    required this.processingTime,
    required this.active,
  });
}

class StaffAccount {
  final String id;
  String name;
  String code;
  String email;
  String role;
  bool locked;

  StaffAccount({
    required this.id,
    required this.name,
    required this.code,
    required this.email,
    required this.role,
    this.locked = false,
  });
}
