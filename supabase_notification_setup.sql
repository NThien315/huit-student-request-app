-- ============================================================================
-- SUPABASE SQL — Tạo bảng NOTIFICATIONS + Sync bảng USERS
-- TV2 — Hệ thống Push Notification kết nối Firebase FCM
-- ============================================================================
-- Chạy script này trên Supabase Dashboard → SQL Editor → New Query → Run
-- ============================================================================

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ BẢNG 1: notifications                                                  ║
-- ║ Mỗi khi Giáo vụ cập nhật trạng thái yêu cầu, Flutter app sẽ INSERT   ║
-- ║ 1 record vào đây → Webhook trigger → Edge Function gửi FCM            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS notifications (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  student_uid   TEXT NOT NULL,           -- UID sinh viên cần nhận thông báo
  title         TEXT NOT NULL,           -- Tiêu đề: "Yêu cầu đã được duyệt"
  body          TEXT NOT NULL,           -- Nội dung chi tiết
  request_id    TEXT,                    -- ID yêu cầu trên Firestore
  is_sent       BOOLEAN DEFAULT FALSE,   -- Edge Function đã gửi chưa
  is_read       BOOLEAN DEFAULT FALSE,   -- Sinh viên đã đọc chưa
  sent_at       TIMESTAMPTZ,             -- Thời điểm gửi thành công
  created_at    TIMESTAMPTZ DEFAULT NOW() -- Thời điểm tạo record
);

-- Index cho truy vấn nhanh theo student_uid
CREATE INDEX IF NOT EXISTS idx_notifications_student_uid 
  ON notifications(student_uid);

-- Index cho truy vấn thông báo chưa gửi
CREATE INDEX IF NOT EXISTS idx_notifications_unsent 
  ON notifications(is_sent) WHERE is_sent = FALSE;


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ BẢNG 2: users (sync FCM Token từ Firebase)                             ║
-- ║ Edge Function cần đọc fcm_token từ đây để gửi notification             ║
-- ║ Nếu bảng 'users' đã có từ TV1, chỉ cần đảm bảo có cột fcm_token      ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Tạo bảng users nếu chưa có (nếu đã có thì bỏ qua)
CREATE TABLE IF NOT EXISTS users (
  uid           TEXT PRIMARY KEY,        -- UID từ Firebase Auth
  email         TEXT,
  display_name  TEXT,
  role          TEXT,                    -- 'student' | 'staff' | 'admin'
  student_id    TEXT,
  fcm_token     TEXT,                    -- Token để gửi Push Notification
  created_at    TIMESTAMPTZ DEFAULT NOW()
);


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ RLS POLICIES cho bảng notifications                                     ║
-- ║ Cho phép app Flutter INSERT (ghi thông báo mới)                         ║
-- ║ và SELECT (đọc lịch sử thông báo)                                       ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Cho phép INSERT (Flutter app ghi thông báo mới)
CREATE POLICY "allow_insert_notifications"
  ON notifications FOR INSERT
  WITH CHECK (true);

-- Cho phép SELECT (đọc thông báo)
CREATE POLICY "allow_select_notifications"
  ON notifications FOR SELECT
  USING (true);

-- Cho phép UPDATE (đánh dấu đã đọc, đã gửi)
CREATE POLICY "allow_update_notifications"
  ON notifications FOR UPDATE
  USING (true);


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ RLS POLICIES cho bảng users                                             ║
-- ║ Edge Function cần đọc fcm_token, Flutter app cần sync FCM token         ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Cho phép đọc (Edge Function cần đọc fcm_token)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'allow_select_users'
  ) THEN
    CREATE POLICY "allow_select_users"
      ON users FOR SELECT
      USING (true);
  END IF;
END $$;

-- Cho phép insert/update (Flutter app sync FCM token)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'allow_upsert_users'
  ) THEN
    CREATE POLICY "allow_upsert_users"
      ON users FOR INSERT
      WITH CHECK (true);
  END IF;
END $$;

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'allow_update_users'
  ) THEN
    CREATE POLICY "allow_update_users"
      ON users FOR UPDATE
      USING (true);
  END IF;
END $$;


-- ============================================================================
-- ✅ XONG! Sau khi chạy script này, cần thêm 1 bước trên Supabase Dashboard:
-- 
-- Tạo Database Webhook:
-- 1. Vào Supabase Dashboard → Database → Webhooks
-- 2. Nhấn "Create a new hook"
-- 3. Cấu hình:
--    - Name: send-fcm-on-new-notification
--    - Table: notifications
--    - Events: INSERT
--    - Type: Supabase Edge Functions
--    - Edge Function: send-fcm
-- 4. Nhấn "Create webhook"
--
-- Setup Service Account Key trong Supabase Secrets:
-- Chạy trên terminal (cần Supabase CLI):
--   supabase secrets set FIREBASE_SERVICE_ACCOUNT='<nội dung file JSON key>'
-- ============================================================================
