// supabase/functions/send-fcm/index.ts
// TV2 — Edge Function gửi Push Notification qua Firebase Cloud Messaging
// Được trigger bởi Database Webhook khi INSERT vào bảng 'notifications'
//
// Luồng hoạt động:
// 1. Giáo vụ cập nhật trạng thái yêu cầu → Flutter app ghi record vào bảng 'notifications'
// 2. Supabase Database Webhook trigger → gọi Edge Function này
// 3. Edge Function lấy FCM token của sinh viên từ bảng 'users'
// 4. Edge Function dùng Service Account Key → gọi Firebase FCM API v1
// 5. Firebase gửi push notification tới điện thoại sinh viên

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { GoogleAuth } from "https://esm.sh/google-auth-library"

// Đọc Service Account Key từ Environment Variable (bảo mật)
// Setup: supabase secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account",...}'
const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
if (!serviceAccountJson) {
  console.error("❌ FIREBASE_SERVICE_ACCOUNT chưa được cấu hình trong Supabase Secrets!");
}
const serviceAccount = serviceAccountJson ? JSON.parse(serviceAccountJson) : null;

serve(async (req) => {
  console.log("🚀 BẮT ĐẦU CHẠY EDGE FUNCTION SEND-FCM");
  
  // Kiểm tra Service Account Key đã cấu hình chưa
  if (!serviceAccount) {
    console.error("❌ Không có FIREBASE_SERVICE_ACCOUNT — không thể gửi notification");
    return new Response(
      JSON.stringify({ error: "FIREBASE_SERVICE_ACCOUNT not configured" }), 
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  try {
    const payload = await req.json()
    console.log("📦 Dữ liệu từ Webhook nhận được:", JSON.stringify(payload));

    const record = payload.record // Dòng thông báo mới từ bảng 'notifications'

    if (!record || !record.student_uid) {
      console.error("❌ Lỗi: Payload không có record hoặc thiếu student_uid");
      return new Response("Invalid payload", { status: 400 })
    }

    // 1. Khởi tạo Supabase Client nội bộ
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    console.log(`🔍 Đang truy vấn FCM Token cho student_uid: ${record.student_uid}`);
    
    // 2. Lấy FCM Token thiết bị của sinh viên từ bảng 'users'
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('fcm_token')
      .eq('uid', record.student_uid)
      .single()

    if (userError || !user || !user.fcm_token) {
      console.error("⚠️ Sinh viên chưa có fcm_token hoặc lỗi DB:", userError);
      return new Response(
        JSON.stringify({ warning: "No FCM Token found — student chưa mở app" }), 
        { status: 200, headers: { "Content-Type": "application/json" } }
      )
    }

    console.log(`✅ Lấy Token thành công! Mã: ${user.fcm_token.substring(0, 15)}...`);

    // 3. Xin OAuth2 Access Token từ Google
    console.log("🔐 Đang xin Access Token từ Google...");
    const auth = new GoogleAuth({
      credentials: serviceAccount,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    const client = await auth.getClient()
    const token = await client.getAccessToken()

    // 4. Gọi Firebase Cloud Messaging API v1 gửi thông báo đẩy
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`
    
    console.log("📡 Đang gửi thông báo qua Firebase FCM...");
    const fcmResponse = await fetch(fcmUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token.token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: user.fcm_token,
          notification: {
            title: record.title || "Cập nhật từ Khoa CNTT",
            body: record.body || "Trạng thái đơn yêu cầu của bạn đã thay đổi.",
          },
          data: {
            // Data payload để app Flutter xử lý khi tap notification
            requestId: record.request_id || "",
            type: "request_status_update",
          },
        },
      }),
    })

    const fcmResult = await fcmResponse.json();
    
    if (!fcmResponse.ok) {
      console.error("❌ Firebase từ chối gửi:", JSON.stringify(fcmResult));
      return new Response(
        JSON.stringify(fcmResult), 
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // 5. Cập nhật trạng thái đã gửi trong bảng notifications
    await supabase
      .from('notifications')
      .update({ is_sent: true, sent_at: new Date().toISOString() })
      .eq('id', record.id)

    console.log("🎉 THÀNH CÔNG! Firebase đã chấp nhận gửi thông báo!");
    return new Response(
      JSON.stringify({ success: true, fcmResult }), 
      { status: 200, headers: { "Content-Type": "application/json" } }
    )

  } catch (error) {
    console.error("💥 LỖI HỆ THỐNG:", error);
    const errorMessage = error instanceof Error ? error.message : String(error);
    return new Response(
      JSON.stringify({ error: errorMessage }), 
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
