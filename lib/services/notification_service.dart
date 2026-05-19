// lib/services/notification_service.dart
import 'package:firebase_core/firebase_core.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); 
  debugPrint("Nhận thông báo ngầm Firebase: ${message.notification?.title}");
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initNotification() async {
    await Firebase.initializeApp(); 
    // ──────────────────────────────────────────────────────────────────

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');
    await _notificationsPlugin.initialize(const InitializationSettings(android: initializationSettingsAndroid));

    // Xin quyền thông báo hiển thị lơ lửng cho Android 13+
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    // Xử lý nổ banner lơ lửng khi sinh viên ĐANG MỞ APP xem giao diện
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showLocalNotification(
          id: message.hashCode,
          title: message.notification!.title ?? 'Cập nhật từ Khoa CNTT',
          body: message.notification!.body ?? '',
        );
      }
    });
  }

  // Hàm lấy mã Token định danh thiết bị của điện thoại
  static Future<String?> getFCMToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      return null;
    }
  }

  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'huit_fcm_channel',
      'Thông báo Đơn HUIT',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    await _notificationsPlugin.show(id, title, body, const NotificationDetails(android: androidDetails));
  }
}