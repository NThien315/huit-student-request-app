
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  // ════════════════════════════════════════════════════════════════════════════
  // UPLOAD FILE
  // Dùng khi: Sinh viên đính kèm ảnh/file vào yêu cầu (UC003)
  // ════════════════════════════════════════════════════════════════════════════

  /// Upload một file lên Supabase Storage
  /// Trả về URL công khai của file đã upload
  ///
  /// [file] — File từ image_picker hoặc file_picker
  /// [studentUid] — UID sinh viên (để tổ chức thư mục)
  Future<String> uploadAttachment({
    required File file,
    required String studentUid,
  }) async {
    try {
      // Tạo tên file duy nhất: studentUid/uuid_filename.ext
      final ext = file.path.split('.').last.toLowerCase();
      final fileName = '${_uuid.v4()}.$ext';
      final filePath = '$studentUid/$fileName';

      // Upload lên bucket 'attachments'
      await _client.storage
          .from(SupabaseConfig.attachmentBucket)
          .upload(filePath, file);

      // Lấy URL công khai
      final publicUrl = _client.storage
          .from(SupabaseConfig.attachmentBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Không thể upload file: $e');
    }
  }

  /// Upload nhiều file cùng lúc
  /// Trả về danh sách URL của các file đã upload
  Future<List<String>> uploadMultipleAttachments({
    required List<File> files,
    required String studentUid,
  }) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadAttachment(
        file: file,
        studentUid: studentUid,
      );
      urls.add(url);
    }
    return urls;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // XÓA FILE
  // Dùng khi: Admin/Giáo vụ xóa yêu cầu hoặc sinh viên hủy đính kèm
  // ════════════════════════════════════════════════════════════════════════════

  /// Xóa file theo URL công khai
  Future<void> deleteAttachment(String publicUrl) async {
    try {
      // Trích xuất đường dẫn file từ URL
      // URL dạng: https://xxx.supabase.co/storage/v1/object/public/attachments/uid/file.ext
      final uri = Uri.parse(publicUrl);
      final pathSegments = uri.pathSegments;

      // Tìm vị trí 'attachments' trong path rồi lấy phần còn lại
      final bucketIndex = pathSegments.indexOf(SupabaseConfig.attachmentBucket);
      if (bucketIndex == -1) return;

      final filePath = pathSegments
          .sublist(bucketIndex + 1)
          .join('/');

      await _client.storage
          .from(SupabaseConfig.attachmentBucket)
          .remove([filePath]);
    } catch (e) {
      throw Exception('Không thể xóa file: $e');
    }
  }

  /// Xóa nhiều file theo danh sách URL
  Future<void> deleteMultipleAttachments(List<String> urls) async {
    for (final url in urls) {
      await deleteAttachment(url);
    }
  }
}
