-- ============================================================================
-- SUPABASE SQL SETUP — Dự án HDPE (Hệ thống xử lý yêu cầu Sinh viên)
-- TV2 — Thiết lập RLS Policies cho Storage bucket "attachments"
-- ============================================================================
--
-- GHI CHÚ:
-- • Bucket "attachments" đã được tạo qua Supabase Dashboard UI
-- • RLS đã được Supabase bật sẵn cho storage.objects
-- • File này CHỈ tạo các policies phân quyền
--
-- ============================================================================


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ RLS POLICIES — Phân quyền truy cập Storage bucket "attachments"       ║
-- ║ Ai được upload? Ai được xem? Ai được xóa?                             ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- ── Policy 1: Cho phép XEM (SELECT) file ──────────────────────────────────
DROP POLICY IF EXISTS "allow_public_select" ON storage.objects;
CREATE POLICY "allow_public_select"
ON storage.objects FOR SELECT
USING (bucket_id = 'attachments');

-- ── Policy 2: Cho phép UPLOAD (INSERT) file ───────────────────────────────
DROP POLICY IF EXISTS "allow_public_insert" ON storage.objects;
CREATE POLICY "allow_public_insert"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'attachments');

-- ── Policy 3: Cho phép XÓA (DELETE) file ──────────────────────────────────
DROP POLICY IF EXISTS "allow_public_delete" ON storage.objects;
CREATE POLICY "allow_public_delete"
ON storage.objects FOR DELETE
USING (bucket_id = 'attachments');

-- ── Policy 4: Cho phép CẬP NHẬT (UPDATE) file ────────────────────────────
DROP POLICY IF EXISTS "allow_public_update" ON storage.objects;
CREATE POLICY "allow_public_update"
ON storage.objects FOR UPDATE
USING (bucket_id = 'attachments');


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ KIỂM TRA KẾT QUẢ                                                      ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Kiểm tra bucket đã tạo
SELECT id, name, public, file_size_limit
FROM storage.buckets
WHERE id = 'attachments';

-- Kiểm tra policies đã tạo
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'objects' AND schemaname = 'storage';
