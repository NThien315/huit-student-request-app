# HDPE — Hướng dẫn Setup Firebase cho TV2

## Cấu trúc Firestore Database (Task 2.2)

```
Firestore Root
├── users/                        ← Tài khoản người dùng
│   └── {uid}/
│       ├── uid: string
│       ├── email: string
│       ├── displayName: string
│       ├── role: "student" | "staff" | "admin"
│       ├── studentId: string?    ← Mã SV (chỉ role=student)
│       ├── fcmToken: string?     ← Token gửi Push Notification
│       └── createdAt: timestamp
│
├── requestCategories/            ← Danh mục yêu cầu (Admin quản lý)
│   └── {categoryId}/
│       ├── name: string          ← VD: "Xin bảng điểm"
│       ├── description: string
│       ├── isActive: boolean     ← false = ẩn khỏi SV
│       └── createdAt: timestamp
│
└── requests/                     ← Yêu cầu của sinh viên
    └── {requestId}/
        ├── studentUid: string    ← UID của SV tạo yêu cầu
        ├── studentName: string
        ├── studentId: string     ← Mã số SV
        ├── categoryId: string
        ├── categoryName: string
        ├── reason: string        ← Lý do/nội dung yêu cầu
        ├── attachmentUrls: []    ← Mảng URL ảnh đính kèm
        ├── status: "pending" | "processing" | "completed" | "rejected"
        ├── note: string?         ← Phản hồi của Giáo vụ
        ├── staffUid: string?     ← UID cán bộ xử lý
        ├── createdAt: timestamp
        └── updatedAt: timestamp
```

---

## Bước 1 — Tạo Firebase Project

1. Vào https://console.firebase.google.com
2. Nhấn **"Add project"** → Đặt tên: `hdpe-sinhvien`
3. Tắt Google Analytics (không cần cho project này) → **Create project**

---

## Bước 2 — Bật Authentication

1. Sidebar → **Authentication** → **Get started**
2. Tab **Sign-in method** → Bật **Email/Password** → Save

---

## Bước 3 — Tạo Firestore Database

1. Sidebar → **Firestore Database** → **Create database**
2. Chọn **Production mode** (sẽ dùng rules của mình)
3. Chọn region: **asia-southeast1** (Singapore — gần VN nhất)

---

## Bước 4 — Deploy Security Rules

```bash
# Cài Firebase CLI (chỉ cần 1 lần)
npm install -g firebase-tools

# Đăng nhập
firebase login

# Trong thư mục project
firebase init firestore
# → Chọn project hdpe-sinhvien
# → File rules: firestore/firestore.rules

# Deploy rules
firebase deploy --only firestore:rules
```

---

## Bước 5 — Kết nối Flutter với Firebase

```bash
# Cài FlutterFire CLI (chỉ cần 1 lần)
dart pub global activate flutterfire_cli

# Trong thư mục Flutter project
flutterfire configure --project=hdpe-sinhvien
```

Lệnh này tự tạo `lib/firebase_options.dart` — **không cần tạo tay**.

---

## Bước 6 — Cài dependencies

```bash
flutter pub get
```

---

## Bước 7 — Tạo tài khoản test ban đầu

Vào Firebase Console → Authentication → Add user:
- `admin@hdpe.edu.vn` / `Admin@123` 

Sau đó vào Firestore → Collection `users` → Add document với id = UID vừa tạo:
```json
{
  "uid": "<uid từ Authentication>",
  "email": "admin@hdpe.edu.vn",
  "displayName": "Quản trị viên",
  "role": "admin",
  "createdAt": <timestamp>
}
```

---

## Bước 8 — Cấu hình FCM (Push Notification) cho Android

1. Firebase Console → Project Settings → Cloud Messaging
2. Lấy **Server Key**
3. Trong `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```
4. File `google-services.json` đã được tự download bởi `flutterfire configure`

---

## Cấu trúc file TV2 cung cấp

```
lib/
├── models/
│   ├── user_model.dart       ← Model + enum UserRole
│   ├── category_model.dart   ← Model danh mục yêu cầu
│   └── request_model.dart    ← Model yêu cầu + enum RequestStatus
├── services/
│   ├── auth_service.dart     ← Firebase Auth (đăng nhập, đăng xuất, đổi pass)
│   ├── firestore_service.dart← Toàn bộ CRUD Firestore
│   └── notification_service.dart ← FCM Push Notification
├── providers/
│   └── auth_provider.dart    ← State management xác thực
└── main.dart                 ← Entry point, setup Firebase

firestore/
└── firestore.rules           ← Security rules phân quyền
```

---

## Cách TV1 và TV3 dùng code của TV2

### TV1 (UI screens) — dùng AuthProvider và FirestoreService:
```dart
// Đăng nhập
final success = await context.read<AuthProvider>().signIn(email, password);

// Lấy yêu cầu của sinh viên (real-time)
final firestoreService = FirestoreService();
firestoreService.getStudentRequests(auth.currentUser!.uid);

// Tạo yêu cầu mới
await firestoreService.createRequest(
  student: auth.currentUser!,
  category: selectedCategory,
  reason: reasonController.text,
  attachmentUrls: uploadedUrls,
);
```

### TV3 (State Management) — wrap thêm Provider cho request:
```dart
// TV3 tạo RequestProvider sử dụng FirestoreService của TV2
class RequestProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  // ...
}
```
