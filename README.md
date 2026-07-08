# 🎓 HDPE Student Request - Hệ thống Quản lý Yêu cầu Sinh viên

Một ứng dụng đa nền tảng được xây dựng bằng **Flutter**, đóng vai trò là cổng thông tin tập trung để quản lý và xử lý các yêu cầu học vụ của sinh viên tại **Trường Đại học Công Thương TP.HCM (HUIT)**. Hệ thống cung cấp giao diện riêng biệt và luồng nghiệp vụ tối ưu cho ba đối tượng người dùng: Sinh viên, Cán bộ Giáo vụ và Quản trị viên.

![Giao diện tổng quan](https://github.com/user-attachments/assets/b7f7dffe-4e39-433f-a95a-af2bac9b1e67)

---

## ✨ Tính năng nổi bật

Hệ thống được thiết kế chặt chẽ và phân chia thành ba luồng chức năng chính tương ứng với vai trò của từng người dùng:

### 👨‍🎓 Luồng Sinh viên (Chạy trên Mobile)
* **Tạo yêu cầu trực tuyến:** Gửi các loại đơn từ học vụ (Xin bảng điểm, phúc khảo, hủy học phần,...) với giao diện trực quan, nhanh chóng.
* **Theo dõi tiến độ thời gian thực:** Cập nhật trạng thái xử lý đơn từ cụ thể từng bước (`Chờ xử lý`, `Đang xử lý`, `Đã duyệt`, `Từ chối`).
* **Đính kèm minh chứng:** Hỗ trợ tải lên các tệp tin, hình ảnh cần thiết để hoàn thiện hồ sơ minh chứng.
* **Thông báo tức thời:** Nhận thông báo đẩy (Push Notification) ngay trên thiết bị khi trạng thái đơn có cập nhật mới.
* **Quản lý hồ sơ cá nhân:** Xem và sửa thông tin cá nhân.

### 💼 Luồng Cán bộ Giáo vụ (Chạy trên Web)
* **Dashboard thông minh:** Bảng điều khiển trực quan thống kê số lượng đơn theo trạng thái, biểu đồ lưu lượng và danh sách các yêu cầu cần xử lý gấp.
* **Xử lý yêu cầu:** Xem chi tiết, phê duyệt hoặc từ chối các đơn từ thuộc thẩm quyền xử lý của phòng ban.
* **Phản hồi & Trả kết quả:** Gửi ghi chú hướng dẫn hoặc đính kèm các tài liệu, quyết định kết quả xử lý cho sinh viên.
* **Quản lý danh mục phụ trách:** Theo dõi và phân loại các loại đơn từ được phân công.
* **Xuất dữ liệu:** Hỗ trợ trích xuất danh sách các yêu cầu ra file CSV để phục vụ báo cáo.

### 👑 Luồng Quản trị viên (Admin)
* **Giám sát toàn diện:** Dashboard tổng quan về tình trạng hệ thống, lượng truy cập, số lượng người dùng và phân bổ trạng thái đơn toàn trường.
* **Quản lý người dùng:** Thêm, sửa, xóa và reset mật khẩu cho tài khoản Sinh viên/Cán bộ. Hỗ trợ import dữ liệu hàng loạt từ file CSV.
* **Quản lý danh mục cấu hình:** Toàn quyền cấu hình (Thêm, sửa, xóa, bật/tắt) các loại yêu cầu và thiết lập thời gian xử lý tiêu chuẩn (SLA).
* **Quản lý tác vụ hàng loạt:** Giám sát toàn bộ đơn từ trong hệ thống và thực hiện các thao tác xóa/cập nhật hàng loạt (Bulk actions).
* **Nhật ký hệ thống (Audit Logs):** Theo dõi chi tiết mọi hoạt động nhạy cảm hoặc thay đổi quan trọng trên nền tảng để bảo mật.
* **Thông báo toàn trường:** Gửi thông báo đẩy đồng loạt đến tất cả các tài khoản sinh viên.

---

## 🚀 Công nghệ sử dụng

* **Frontend Framework:** Flutter 3 (Dart)
* **Backend & Database:** Supabase (PostgreSQL, Authentication, Storage, Edge Functions)
* **State Management:** Provider
* **Thư viện giao diện & Biểu đồ:** `fl_chart`
* **Xử lý Tệp tin & Hệ thống:** `file_picker`, `image_picker`, `url_launcher`

---

## ⚙️ Hướng dẫn Cài đặt & Triển khai

Để khởi chạy dự án này trên môi trường local của bạn, hãy thực hiện theo các bước hướng dẫn chi tiết dưới đây:

### 1. Clone Repository
```bash
git clone https://github.com/NThien315/huit-student-request-app
cd huit-student-request-app
```

### 2. Cấu hình Supabase

#### Bước 2.1: Khởi tạo dự án
1. Truy cập [Supabase Console](https://supabase.com/) và tạo một dự án (Project) mới.
2. Đợi dự án khởi tạo xong trong vài phút.

#### Bước 2.2: Thiết lập Database Schema & Row Level Security (RLS)
> ⚠️ **Lưu ý:** Hãy đảm bảo bạn đã tạo trước các custom functions kiểm tra role như `public.is_admin()` và `public.is_staff_or_admin()` (nếu có dùng trong logic phân quyền của bạn) trước khi thực thi đoạn script dưới đây.

Vào mục **SQL Editor** trên thanh menu trái của Supabase, chọn **New query**, dán đoạn mã SQL sau và nhấn **Run**:

```sql
-- 1. Bảng lưu thông tin người dùng (Mở rộng từ auth.users)
CREATE TABLE public.users (
  uid uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name character varying,
  "studentId" character varying,
  email character varying,
  phone character varying,
  role user_role DEFAULT 'student'::user_role,
  avatar_url text,
  gender text,
  dob text,
  "className" text,
  "idCard" text,
  address text,
  faculty text,
  major text,
  fcm_token text,
  PRIMARY KEY (uid)
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public users are viewable by everyone." ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile." ON public.users FOR INSERT WITH CHECK (auth.uid() = uid);
CREATE POLICY "Users can update own profile." ON public.users FOR UPDATE USING (auth.uid() = uid);

-- 2. Bảng lưu các loại yêu cầu (Do Admin quản lý)
CREATE TABLE public.request_categories (
  id SERIAL PRIMARY KEY,
  name text NOT NULL,
  description text,
  "isActive" boolean DEFAULT true,
  department text,
  sla text
);

ALTER TABLE public.request_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Categories are viewable by everyone." ON public.request_categories FOR SELECT USING (true);
CREATE POLICY "Admin can manage categories." ON public.request_categories FOR ALL USING (public.is_admin());

-- 3. Bảng lưu các yêu cầu của sinh viên
CREATE TABLE public.requests (
  id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  "studentUid" uuid REFERENCES public.users(uid),
  "studentName" text,
  "studentId" text,
  "categoryId" integer REFERENCES public.request_categories(id),
  "categoryName" text,
  reason text,
  "attachmentUrls" jsonb,
  status text DEFAULT 'pending',
  note text,
  "staffUid" uuid REFERENCES public.users(uid),
  "createdAt" timestamp with time zone DEFAULT now(),
  "updatedAt" timestamp with time zone,
  "processedAt" timestamp with time zone,
  "completedAt" timestamp with time zone,
  "rejectedAt" timestamp with time zone,
  "attachedFiles" jsonb
);

ALTER TABLE public.requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own requests." ON public.requests FOR SELECT USING (auth.uid() = "studentUid");
CREATE POLICY "Staff/Admin can view all requests." ON public.requests FOR SELECT USING (public.is_staff_or_admin());
CREATE POLICY "Users can create requests." ON public.requests FOR INSERT WITH CHECK (auth.uid() = "studentUid");
CREATE POLICY "Staff/Admin can update requests." ON public.requests FOR UPDATE USING (public.is_staff_or_admin());
CREATE POLICY "Admin can delete requests." ON public.requests FOR DELETE USING (public.is_admin());

-- 4. Bảng lưu danh mục các môn học
CREATE TABLE public.subjects (
  "subjectCode" text PRIMARY KEY,
  "subjectName" text
);

ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Subjects are viewable by everyone." ON public.subjects FOR SELECT USING (true);

-- 5. Bảng lưu nhật ký hoạt động hệ thống
CREATE TABLE public.audit_logs (
  id bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  created_at timestamp with time zone DEFAULT now(),
  actor_name text,
  actor_email text,
  action_type text,
  target_name text,
  details text
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin can read audit logs." ON public.audit_logs FOR SELECT USING (public.is_admin());

-- 6. Bảng lưu thông báo người dùng
CREATE TABLE public.notifications (
  id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  student_uid uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text,
  body text,
  request_id uuid,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own notifications." ON public.notifications FOR SELECT USING (auth.uid() = student_uid);
CREATE POLICY "Admin can create notifications." ON public.notifications FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "Users can update their own notifications." ON public.notifications FOR UPDATE USING (auth.uid() = student_uid);
```

#### Bước 2.3: Cấu hình Storage
1. Tại thanh điều hướng bên trái của Supabase, chọn mục **Storage**.
2. Nhấn **New Bucket** và đặt tên chính xác là: `attachments`.
3. Đi tới phần thiết lập **Policies** của bucket này:
   * Cho phép mọi người đọc công khai (`SELECT`).
   * Chỉ cho phép người dùng đã qua xác thực (`authenticated`) thực hiện các quyền ghi và cập nhật (`INSERT`, `UPDATE`).

#### Bước 2.4: Lấy thông tin API Keys
Đi tới mục **Project Settings > API** (biểu tượng bánh răng), tìm và sao chép hai thông số quan trọng:
* **Project URL**
* **anon / public** API Key

---

### 3. Cấu hình Ứng dụng Flutter

Tạo một file mới tên là `env.dart` nằm bên trong thư mục `lib/` (`lib/env.dart`) và thêm vào đoạn code bên dưới:

```dart
// lib/env.dart
class Env {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
}
```
> ⚠️ **Quan trọng:** Thay thế các chuỗi mẫu bằng thông tin `Project URL` và `anon key` thực tế bạn vừa lấy từ bước 2.4.

Cài đặt các gói thư viện phụ thuộc của Flutter:
```bash
flutter pub get
```

---

### 4. Khởi chạy Ứng dụng

Dự án tích hợp cơ chế tự động nhận diện nền tảng (Platform Detection) tại điểm khởi chạy để điều hướng luồng giao diện phù hợp:

#### 💻 CHẠY TRÊN WEB (Giao diện Cán bộ Giáo vụ & Admin)
Khi khởi chạy ứng dụng trên môi trường trình duyệt web, hệ thống sẽ tự động kích hoạt luồng xử lý và Dashboard dành cho Giáo vụ và Quản trị viên.
```bash
flutter run -d chrome
```

#### 📱 CHẠY TRÊN THIẾT BỊ DI ĐỘNG (Giao diện Sinh viên)
Khi build ứng dụng hoặc chạy trên thiết bị di động thật / máy ảo (Android/iOS), hệ thống sẽ tự động mở giao diện cổng thông tin, tạo đơn và nhận thông báo dành cho Sinh viên.
```bash
# Kiểm tra danh sách thiết bị đang kết nối
flutter devices

# Chạy trên thiết bị mong muốn của bạn
flutter run -d <DEVICE_ID>
```
