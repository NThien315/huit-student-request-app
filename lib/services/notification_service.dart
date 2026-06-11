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
    try {
      await Firebase.initializeApp(); 

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'hdpe_fcm_channel', // 🌟 Phải trùng khớp với hàm hiển thị bên dưới
        'Thông báo Đơn HDPE',
        description: 'Kênh hiển thị thông báo xử lý đơn yêu cầu sinh viên HDPE.',
        importance: Importance.max, 
        playSound: true,
      );

      // Khởi tạo icon mặc định cho toàn hệ thống thông báo (Bỏ đuôi .png)
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_notification');
          
      await _notificationsPlugin.initialize(
        const InitializationSettings(android: initializationSettingsAndroid),
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          NotificationService.showLocalNotification(
            id: message.hashCode,
            title: message.notification!.title ?? 'Cập nhật từ Khoa CNTT',
            body: message.notification!.body ?? '',
          );
        }
      });
      
      debugPrint("Hệ thống thông báo đã khởi tạo thành công!");
    } catch (e) {
      debugPrint("Cảnh báo lỗi cấu hình thông báo: $e");
    }
  }

  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hdpe_fcm_channel',
      'Thông báo Đơn HDPE',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: 'ic_notification', 
    );
    await _notificationsPlugin.show(id, title, body, const NotificationDetails(android: androidDetails));
  }

  // Hàm lấy mã Token định danh thiết bị của điện thoại
  static Future<String?> getFCMToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      return null;
    }
  }
}