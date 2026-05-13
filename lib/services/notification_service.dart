// lib/services/notification_service.dart
// TV2 — Thiết lập Firebase Cloud Messaging (Task 3.2)
// UC007 — Sinh viên nhận Push Notification khi trạng thái yêu cầu thay đổi

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'auth_service.dart';

// ── Top-level handler: bắt buộc phải nằm ngoài class để Flutter có thể gọi ──
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // App đang ở background hoặc terminated — chỉ log, không cần xử lý UI
  print('[FCM Background] messageId: ${message.messageId}');
  print('[FCM Background] title: ${message.notification?.title}');
}

// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final AuthService _authService;

  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  // Channel ID cho Android
  static const String _channelId = 'hdpe_requests';
  static const String _channelName = 'Thông báo yêu cầu';
  static const String _channelDesc =
      'Nhận thông báo khi trạng thái yêu cầu thay đổi';

  NotificationService(this._authService);

  // ──────────────────────────────────────────────────────────────────────────
  // Khởi tạo toàn bộ notification pipeline — gọi trong main() sau Firebase.initializeApp()
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    // 1. Đăng ký background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Xin quyền hiển thị thông báo
    await _requestPermission();

    // 3. Cấu hình local notifications (hiển thị khi app foreground)
    await _setupLocalNotifications();

    // 4. Tạo Android Notification Channel
    await _createAndroidChannel();

    // 5. Lấy FCM token và lưu vào Firestore
    await _saveTokenToFirestore();

    // 6. Lắng nghe token refresh (token có thể thay đổi)
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

    // 7. Xử lý thông báo khi app đang mở (foreground)
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 8. Xử lý khi user tap thông báo (app background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // 9. Kiểm tra nếu app được mở từ terminated state qua notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _onNotificationTap(initialMessage);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Xin quyền thông báo (iOS bắt buộc, Android 13+ cũng cần)
  // ──────────────────────────────────────────────────────────────────────────
  Future<NotificationSettings> _requestPermission() async {
    return _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Cấu hình flutter_local_notifications
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // Đã xin qua FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Xử lý khi user tap local notification
        _handleLocalNotificationTap(details.payload);
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Tạo Android Notification Channel (Android 8.0+)
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Lấy FCM token và lưu vào Firestore → dùng để server gửi notification đúng thiết bị
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _saveTokenToFirestore([String? token]) async {
    //token ??= await _fcm.getToken();
    token = "fake_token_for_ui_testing"; // TV2 chưa có backend API, tạm hardcode token để test UI
    final user = _authService.currentUser;
    if (token != null && user != null) {
      await _authService.updateFcmToken(user.uid, token);
      print('[FCM] Token saved for uid: ${user.uid}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Hiển thị thông báo khi app đang mở (foreground)
  // ──────────────────────────────────────────────────────────────────────────
  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotif.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // Payload chứa requestId để điều hướng khi tap
      payload: message.data['requestId'],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Xử lý khi user tap thông báo (từ FCM hoặc local notification)
  // ──────────────────────────────────────────────────────────────────────────
  void _onNotificationTap(RemoteMessage message) {
    final requestId = message.data['requestId'];
    _navigateToRequestDetail(requestId);
  }

  void _handleLocalNotificationTap(String? payload) {
    _navigateToRequestDetail(payload);
  }

  // Navigation sẽ được implement sau khi có NavigationService/Router
  void _navigateToRequestDetail(String? requestId) {
    if (requestId == null || requestId.isEmpty) return;
    print('[Notification] Navigate to request detail: $requestId');
    // TODO: Kết nối với app router
    // NavigatorKey.currentState?.pushNamed('/request-detail', arguments: requestId);
  }
}
