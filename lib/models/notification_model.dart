import 'package:flutter/material.dart';
import '../../../core/theme.dart';

enum NotificationType { success, warning, danger, info }

class NotificationModel {
  final String id;
  final String studentUid;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.studentUid,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      studentUid: map['studentUid'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      // Map string từ DB sang Enum trong Flutter
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.info,
      ),
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']).toLocal() 
          : DateTime.now(),
    );
  }

  // Tiện ích lấy màu sắc dựa trên phân loại thông báo
  Color get color {
    switch (type) {
      case NotificationType.success: return AppColors.success;
      case NotificationType.warning: return AppColors.warning;
      case NotificationType.danger: return AppColors.danger;
      default: return AppColors.primarySV;
    }
  }

  // Tiện ích lấy icon dựa trên phân loại thông báo
  IconData get icon {
    switch (type) {
      case NotificationType.success: return Icons.check_circle_rounded;
      case NotificationType.warning: return Icons.error_outline_rounded;
      case NotificationType.danger: return Icons.cancel_outlined;
      default: return Icons.notifications_active_rounded;
    }
  }
}