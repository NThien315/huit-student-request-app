# Sơ đồ luồng Admin — HDPE (Task 1.2)
> **TV2 phụ trách** — Thiết kế luồng hoạt động của Admin trong hệ thống xử lý yêu cầu sinh viên.

---

## 1. Tổng quan vai trò Admin

Admin là người quản trị toàn bộ hệ thống, có quyền:
- Quản lý tài khoản người dùng (Sinh viên, Giáo vụ)
- Quản lý danh mục yêu cầu
- Giám sát toàn bộ yêu cầu trong hệ thống
- Xem thống kê, báo cáo

---

## 2. Luồng đăng nhập Admin

```mermaid
flowchart TD
    A[Mở ứng dụng] --> B{Còn session?}
    B -- Có --> C[Auto-login]
    B -- Không --> D[Màn hình Đăng nhập]
    D --> E[Nhập Email + Mật khẩu]
    E --> F{Xác thực Firebase Auth}
    F -- Thành công --> G[Lấy UserModel từ Firestore]
    G --> H{Kiểm tra role}
    H -- role = admin --> I[Điều hướng → Dashboard Admin]
    H -- role ≠ admin --> J[Điều hướng → Màn hình SV/GV tương ứng]
    F -- Thất bại --> K[Hiển thị lỗi tiếng Việt]
    K --> D
    C --> G
```

---

## 3. Luồng quản lý tài khoản (Admin)

```mermaid
flowchart TD
    A[Dashboard Admin] --> B[Chọn: Quản lý Tài khoản]
    B --> C[Xem danh sách Users từ Firestore]
    C --> D{Chọn thao tác}
    
    D -- Thêm mới --> E[Nhập: Email, Tên, Mật khẩu, Role]
    E --> F{Validate dữ liệu}
    F -- Hợp lệ --> G[Gọi AuthService.createAccount]
    G --> H[Firebase Auth tạo UID]
    H --> I[Lưu UserModel vào Firestore /users/uid]
    I --> J[Thông báo thành công]
    F -- Không hợp lệ --> K[Hiển thị lỗi validate]
    K --> E

    D -- Xem chi tiết --> L[Hiển thị thông tin User]
    D -- Xóa --> M[Xác nhận xóa]
    M --> N[Xóa document trong Firestore]
    
    J --> C
    N --> C
```

---

## 4. Luồng quản lý danh mục yêu cầu (Admin)

```mermaid
flowchart TD
    A[Dashboard Admin] --> B[Chọn: Quản lý Danh mục]
    B --> C[Stream danh sách Categories từ Firestore]
    C --> D{Chọn thao tác}
    
    D -- Thêm mới --> E[Nhập: Tên danh mục + Mô tả]
    E --> F{Kiểm tra trùng tên?}
    F -- Không trùng --> G[Gọi FirestoreService.addCategory]
    G --> H[Lưu vào /requestCategories]
    H --> C
    F -- Trùng tên --> I[Báo lỗi: Tên đã tồn tại]
    I --> E

    D -- Sửa --> J[Sửa tên/mô tả]
    J --> K[Gọi FirestoreService.updateCategory]
    K --> C

    D -- Ẩn/Hiện --> L[Gọi toggleCategoryActive]
    L --> C
```

---

## 5. Luồng giám sát yêu cầu (Admin)

```mermaid
flowchart TD
    A[Dashboard Admin] --> B[Chọn: Xem Yêu cầu]
    B --> C[Stream getAllRequests từ Firestore]
    C --> D[Hiển thị danh sách toàn bộ yêu cầu]
    D --> E{Lọc theo trạng thái?}
    E -- Có --> F[Chọn: Pending / Processing / Completed / Rejected]
    F --> G[Stream getAllRequests với filterStatus]
    G --> D
    E -- Không --> H[Xem chi tiết yêu cầu]
    H --> I[Hiển thị: SV, Loại, Lý do, Trạng thái, Phản hồi GV]
    I --> J{Admin muốn cập nhật?}
    J -- Có --> K[Cập nhật trạng thái + ghi chú]
    K --> L[Gọi FirestoreService.updateRequestStatus]
    L --> D
    J -- Không --> D
```

---

## 6. Luồng đăng xuất

```mermaid
flowchart TD
    A[Bất kỳ màn hình nào] --> B[Nhấn Đăng xuất]
    B --> C[Gọi AuthService.signOut]
    C --> D[Xóa session Firebase Auth]
    D --> E[AuthProvider set currentUser = null]
    E --> F[Điều hướng → Màn hình Đăng nhập]
```

---

## 7. Tổng quan luồng Admin đầy đủ

```mermaid
flowchart LR
    Login[Đăng nhập] --> Dashboard[Dashboard Admin]
    Dashboard --> Users[Quản lý Tài khoản]
    Dashboard --> Categories[Quản lý Danh mục]
    Dashboard --> Requests[Giám sát Yêu cầu]
    Dashboard --> Stats[Xem Thống kê]
    Dashboard --> Logout[Đăng xuất]
    
    Users --> U1[Thêm tài khoản]
    Users --> U2[Xem danh sách]
    Users --> U3[Xóa tài khoản]
    
    Categories --> C1[Thêm danh mục]
    Categories --> C2[Sửa danh mục]
    Categories --> C3[Ẩn/Hiện danh mục]
    
    Requests --> R1[Xem tất cả]
    Requests --> R2[Lọc theo trạng thái]
    Requests --> R3[Cập nhật trạng thái]
```
