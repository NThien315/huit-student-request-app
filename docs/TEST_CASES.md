# Kịch bản Test — TV2 Backend/API (Task 4.2)
> **TV2 phụ trách** — Viết kịch bản Test Case cho toàn bộ API/Service do TV2 xây dựng.

---

## 1. Test Case — Xác thực (AuthService)

| Mã TC | Chức năng | Mô tả kịch bản | Dữ liệu đầu vào | Kết quả mong đợi | Trạng thái |
|-------|-----------|-----------------|------------------|-------------------|------------|
| TC-AUTH-001 | UC001 Đăng nhập | Đăng nhập với tài khoản Admin hợp lệ | Email: `admin@hdpe.edu.vn`, Pass: `Admin@123` | Trả về UserModel với role = admin | ✅ Pass |
| TC-AUTH-002 | UC001 Đăng nhập | Đăng nhập với email không tồn tại | Email: `khongtontai@hdpe.edu.vn`, Pass: `123456` | Throw Exception "Tài khoản không tồn tại" | ✅ Pass |
| TC-AUTH-003 | UC001 Đăng nhập | Đăng nhập với mật khẩu sai | Email: `admin@hdpe.edu.vn`, Pass: `saimatkhau` | Throw Exception "Mật khẩu không chính xác" | ✅ Pass |
| TC-AUTH-004 | UC001 Đăng nhập | Đăng nhập với email rỗng | Email: `""`, Pass: `123456` | Throw Exception "Địa chỉ email không hợp lệ" | ✅ Pass |
| TC-AUTH-005 | UC001 Đăng nhập | Đăng nhập với mật khẩu rỗng | Email: `admin@hdpe.edu.vn`, Pass: `""` | Throw Exception lỗi xác thực | ✅ Pass |
| TC-AUTH-006 | UC008 Đăng xuất | Đăng xuất khi đang đăng nhập | User đã đăng nhập thành công | `currentUser` trở thành `null`, quay về màn hình Login | ✅ Pass |
| TC-AUTH-007 | UC002 Đổi mật khẩu | Đổi mật khẩu với mật khẩu mới < 6 ký tự | Current: `Admin@123`, New: `123` | Throw Exception "Mật khẩu mới phải có ít nhất 6 ký tự" | ✅ Pass |
| TC-AUTH-008 | UC002 Đổi mật khẩu | Đổi mật khẩu khi chưa đăng nhập | Current: `Admin@123`, New: `NewPass@123` | Throw Exception "Chưa đăng nhập" | ✅ Pass |
| TC-AUTH-009 | UC002 Đổi mật khẩu | Đổi mật khẩu với mật khẩu hiện tại sai | Current: `SaiPass`, New: `NewPass@123` | Throw Exception "Phiên đăng nhập hết hạn" | ✅ Pass |
| TC-AUTH-010 | UC002 Đổi mật khẩu | Đổi mật khẩu thành công | Current: `Admin@123`, New: `Admin@456` | Không throw, mật khẩu được cập nhật | ✅ Pass |
| TC-AUTH-011 | Tạo tài khoản | Admin tạo tài khoản Sinh viên | Email: `sv1@huit.edu.vn`, Role: student | Trả về UserModel, lưu vào Firestore /users | ✅ Pass |
| TC-AUTH-012 | Tạo tài khoản | Tạo tài khoản trùng email | Email: `admin@hdpe.edu.vn` (đã có) | Throw Exception "Email này đã được đăng ký" | ✅ Pass |
| TC-AUTH-013 | Auto-login | Kiểm tra session khi mở app | User đã đăng nhập trước đó | `fetchCurrentUser()` trả về UserModel | ✅ Pass |
| TC-AUTH-014 | Auto-login | Kiểm tra session khi chưa đăng nhập | Không có session | `fetchCurrentUser()` trả về `null` | ✅ Pass |

---

## 2. Test Case — Quản lý yêu cầu (FirestoreService — Requests)

| Mã TC | Chức năng | Mô tả kịch bản | Dữ liệu đầu vào | Kết quả mong đợi | Trạng thái |
|-------|-----------|-----------------|------------------|-------------------|------------|
| TC-FS-001 | UC003 Tạo yêu cầu | SV tạo yêu cầu hợp lệ | Student, Category "Xin bảng điểm", Reason: "Xin cấp bảng điểm HK1" | Tạo thành công, trạng thái = pending, trả về requestId | ✅ Pass |
| TC-FS-002 | UC003 Tạo yêu cầu | Tạo yêu cầu với lý do rỗng | Reason: `""` | Throw Exception "Vui lòng nhập lý do yêu cầu" | ✅ Pass |
| TC-FS-003 | UC003 Tạo yêu cầu | Tạo yêu cầu với lý do chỉ chứa khoảng trắng | Reason: `"   "` | Throw Exception "Vui lòng nhập lý do yêu cầu" | ✅ Pass |
| TC-FS-004 | UC003 Tạo yêu cầu | Tạo yêu cầu với file đính kèm | Reason hợp lệ + attachmentUrls: ["url1.jpg"] | Tạo thành công, attachmentUrls chứa 1 phần tử | ✅ Pass |
| TC-FS-005 | UC004 Xem yêu cầu SV | SV xem danh sách yêu cầu của mình | studentUid = uid đã đăng nhập | Stream trả về List<RequestModel> chỉ chứa yêu cầu của SV đó | ✅ Pass |
| TC-FS-006 | UC005 GV xem yêu cầu | GV/Admin xem tất cả yêu cầu | Không lọc | Stream trả về toàn bộ yêu cầu, sắp xếp mới nhất trước | ✅ Pass |
| TC-FS-007 | UC005 Lọc yêu cầu | Lọc yêu cầu theo trạng thái Pending | filterStatus = pending | Stream chỉ trả về yêu cầu có status = pending | ✅ Pass |
| TC-FS-008 | UC005 Cập nhật TT | GV chuyển yêu cầu sang "Đang xử lý" | requestId, newStatus: processing, staffUid | Cập nhật thành công, updatedAt thay đổi | ✅ Pass |
| TC-FS-009 | UC005 Cập nhật TT | GV hoàn thành yêu cầu | newStatus: completed, note: "Đã xử lý" | Cập nhật thành công | ✅ Pass |
| TC-FS-010 | UC005 Từ chối | GV từ chối yêu cầu có lý do | newStatus: rejected, note: "Thiếu hồ sơ" | Cập nhật thành công, note được lưu | ✅ Pass |
| TC-FS-011 | UC005 Từ chối | GV từ chối yêu cầu KHÔNG có lý do | newStatus: rejected, note: null | Throw Exception "Vui lòng nhập lý do từ chối" | ✅ Pass |
| TC-FS-012 | UC005 Từ chối | GV từ chối yêu cầu với lý do rỗng | newStatus: rejected, note: "" | Throw Exception "Vui lòng nhập lý do từ chối" | ✅ Pass |
| TC-FS-013 | Xem chi tiết | Lấy yêu cầu theo ID hợp lệ | requestId tồn tại | Trả về RequestModel đầy đủ thông tin | ✅ Pass |
| TC-FS-014 | Xem chi tiết | Lấy yêu cầu theo ID không tồn tại | requestId: "khongtontai" | Trả về `null` | ✅ Pass |

---

## 3. Test Case — Quản lý danh mục (FirestoreService — Categories)

| Mã TC | Chức năng | Mô tả kịch bản | Dữ liệu đầu vào | Kết quả mong đợi | Trạng thái |
|-------|-----------|-----------------|------------------|-------------------|------------|
| TC-CAT-001 | UC006 Thêm DM | Thêm danh mục hợp lệ | Name: "Xin bảng điểm", Desc: "Mô tả" | Tạo thành công, isActive = true | ✅ Pass |
| TC-CAT-002 | UC006 Thêm DM | Thêm danh mục trùng tên | Name: "Xin bảng điểm" (đã tồn tại) | Throw Exception "Tên danh mục đã tồn tại" | ✅ Pass |
| TC-CAT-003 | UC006 Sửa DM | Sửa tên danh mục | id, name: "Tên mới" | Cập nhật thành công trên Firestore | ✅ Pass |
| TC-CAT-004 | UC006 Ẩn DM | Ẩn danh mục | id, isActive: false | Danh mục không hiển thị cho SV | ✅ Pass |
| TC-CAT-005 | UC006 Hiện DM | Bật lại danh mục đã ẩn | id, isActive: true | Danh mục hiển thị trở lại cho SV | ✅ Pass |
| TC-CAT-006 | Lấy DM active | SV lấy danh mục đang hoạt động | Không tham số | Stream chỉ trả về danh mục có isActive = true | ✅ Pass |
| TC-CAT-007 | Lấy tất cả DM | Admin lấy tất cả danh mục | Không tham số | Stream trả về toàn bộ, kể cả isActive = false | ✅ Pass |
| TC-CAT-008 | Seed data | Seed danh mục mẫu lần đầu | Firestore trống | Tạo 6 danh mục mẫu thành công | ✅ Pass |
| TC-CAT-009 | Seed data | Seed khi đã có data | Firestore đã có danh mục | Không tạo thêm, giữ nguyên data cũ | ✅ Pass |

---

## 4. Test Case — Model Serialization

| Mã TC | Chức năng | Mô tả kịch bản | Kết quả mong đợi | Trạng thái |
|-------|-----------|-----------------|-------------------|------------|
| TC-MDL-001 | UserModel.fromMap | Parse dữ liệu Firestore hợp lệ | Tạo UserModel đầy đủ thông tin | ✅ Pass |
| TC-MDL-002 | UserModel.toMap | Chuyển UserModel thành Map | Map chứa đủ các field (uid, email, displayName, role, createdAt) | ✅ Pass |
| TC-MDL-003 | UserRole enum | Parse role từ string | "student" → UserRole.student, "staff" → UserRole.staff | ✅ Pass |
| TC-MDL-004 | UserRole enum | Parse role không hợp lệ | Giá trị lạ → fallback UserRole.student | ✅ Pass |
| TC-MDL-005 | RequestModel.fromMap | Parse yêu cầu từ Firestore | Tạo RequestModel đầy đủ, status đúng | ✅ Pass |
| TC-MDL-006 | RequestModel.toMap | Chuyển RequestModel thành Map | Map chứa đủ field, Timestamp format đúng | ✅ Pass |
| TC-MDL-007 | RequestStatus enum | Kiểm tra label tiếng Việt | pending → "Chờ tiếp nhận", completed → "Đã hoàn thành" | ✅ Pass |
| TC-MDL-008 | RequestStatus enum | Kiểm tra colorHex | pending → "#FFA000", rejected → "#D32F2F" | ✅ Pass |
| TC-MDL-009 | CategoryModel.fromMap | Parse danh mục từ Firestore | Tạo CategoryModel đầy đủ | ✅ Pass |
| TC-MDL-010 | CategoryModel.copyWith | Tạo bản sao với field thay đổi | Bản sao có field mới, field cũ giữ nguyên | ✅ Pass |

---

## 5. Test Case — Push Notification (NotificationService)

| Mã TC | Chức năng | Mô tả kịch bản | Kết quả mong đợi | Trạng thái |
|-------|-----------|-----------------|-------------------|------------|
| TC-NTF-001 | UC007 Khởi tạo | Khởi tạo NotificationService | Không throw, đăng ký background handler thành công | ✅ Pass |
| TC-NTF-002 | UC007 Xin quyền | Xin quyền notification trên Android 13+ | Trả về NotificationSettings | ✅ Pass |
| TC-NTF-003 | UC007 FCM Token | Lấy và lưu FCM token vào Firestore | Token được lưu vào /users/{uid}/fcmToken | ✅ Pass |
| TC-NTF-004 | UC007 Foreground | Nhận thông báo khi app mở | Hiển thị local notification với title và body | ✅ Pass |
| TC-NTF-005 | UC007 Background | Nhận thông báo khi app ở background | Gọi firebaseMessagingBackgroundHandler, log message | ✅ Pass |
| TC-NTF-006 | UC007 Tap | User tap vào thông báo | Điều hướng đến màn hình chi tiết yêu cầu | ✅ Pass |

---

## 6. Test Case — Firestore Security Rules

| Mã TC | Chức năng | Mô tả kịch bản | Kết quả mong đợi | Trạng thái |
|-------|-----------|-----------------|-------------------|------------|
| TC-RULE-001 | /users read | SV đọc thông tin chính mình | Allow ✓ | ✅ Pass |
| TC-RULE-002 | /users read | SV đọc thông tin người khác | Deny ✗ | ✅ Pass |
| TC-RULE-003 | /users read | GV/Admin đọc thông tin bất kỳ user | Allow ✓ | ✅ Pass |
| TC-RULE-004 | /users create | Admin tạo tài khoản mới | Allow ✓ | ✅ Pass |
| TC-RULE-005 | /users create | SV/GV tạo tài khoản | Deny ✗ | ✅ Pass |
| TC-RULE-006 | /requests read | SV đọc yêu cầu của chính mình | Allow ✓ | ✅ Pass |
| TC-RULE-007 | /requests read | SV đọc yêu cầu của người khác | Deny ✗ | ✅ Pass |
| TC-RULE-008 | /requests create | SV tạo yêu cầu cho chính mình, status=pending | Allow ✓ | ✅ Pass |
| TC-RULE-009 | /requests create | SV tạo yêu cầu với status≠pending | Deny ✗ | ✅ Pass |
| TC-RULE-010 | /requests update | GV cập nhật trạng thái yêu cầu | Allow ✓ | ✅ Pass |
| TC-RULE-011 | /requests update | SV tự đổi trạng thái yêu cầu | Deny ✗ | ✅ Pass |
| TC-RULE-012 | /requests delete | Bất kỳ ai xóa yêu cầu | Deny ✗ (archive only) | ✅ Pass |
| TC-RULE-013 | /requestCategories | User đã đăng nhập đọc danh mục | Allow ✓ | ✅ Pass |
| TC-RULE-014 | /requestCategories | Chỉ Admin CRUD danh mục | SV/GV create → Deny ✗, Admin → Allow ✓ | ✅ Pass |

---

## Tổng kết

| Nhóm Test | Số lượng TC | Pass | Fail |
|-----------|-------------|------|------|
| Authentication (AuthService) | 14 | 14 | 0 |
| Requests (FirestoreService) | 14 | 14 | 0 |
| Categories (FirestoreService) | 9 | 9 | 0 |
| Model Serialization | 10 | 10 | 0 |
| Push Notification | 6 | 6 | 0 |
| Security Rules | 14 | 14 | 0 |
| **TỔNG** | **67** | **67** | **0** |
