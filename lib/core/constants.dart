// lib/core/constants.dart
// Cấu hình Supabase Storage

class SupabaseConfig {
  // URL của Supabase project
  static const String url = 'https://eqiwsekizowaklmxghkw.supabase.co';

  // Anon key
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVxaXdzZWtpem93YWtsbXhnaGt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NzY2NzEsImV4cCI6MjA5NDI1MjY3MX0.ZrzgIpOa474j7kn_gOHIdPBykig4XiU2Wt3Gd3hpCnk';

  // Tên bucket lưu file đính kèm
  static const String attachmentBucket = 'attachments';
}
