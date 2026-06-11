import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { GoogleAuth } from "https://esm.sh/google-auth-library"

// Nhúng thẳng nội dung file JSON của Firebase vào đây
const serviceAccount = JSON.parse(
  await Deno.readTextFile(new URL("./service-account.json", import.meta.url).pathname)
);


serve(async (req) => {
  console.log(" BẮT ĐẦU CHẠY EDGE FUNCTION SEND-FCM");
  try {
    const payload = await req.json()
    console.log(" Dữ liệu từ Webhook nhận được:", JSON.stringify(payload));

    const record = payload.record // Dòng thông báo mới từ bảng 'notifications'

    if (!record || !record.studentUid) {
      console.error(" Lỗi: Payload không có record hoặc thiếu studentUid");
      return new Response("Invalid payload", { status: 400 })
    }

    // 1. Khởi tạo Supabase Client nội bộ
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    console.log(` Đang truy vấn FCM Token cho studentUid: ${record.studentUid}`);
    // Lấy FCM Token thiết bị của sinh viên
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('fcm_token')
      .eq('uid', record.studentUid)
      .single()

    if (userError || !user || !user.fcm_token) {
      console.error(" Lỗi Database hoặc Sinh viên chưa có fcm_token:", userError);
      return new Response("No FCM Token found for this student", { status: 200 })
    }

    console.log(` Lấy Token sinh viên thành công! Mã: ${user.fcm_token.substring(0, 15)}...`);

    // 2. Gọi quyền OAuth2
    console.log(" Đang xin khóa Access Token từ Google...");
    const auth = new GoogleAuth({
      credentials: serviceAccount,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    const client = await auth.getClient()
    const token = await client.getAccessToken()

    // 3. Tiến hành gọi API Firebase gửi thông báo đẩy
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`
    
    console.log(" Đang bắn hỏa lực sang Firebase FCM...");
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
        },
      }),
    })

    // ÉP FIREBASE KHAI RA LỖI
    const fcmResult = await fcmResponse.json();
    
    if (!fcmResponse.ok) {
      console.error("LỖI TỪ FIREBASE TỪ CHỐI GỬI:", JSON.stringify(fcmResult));
      return new Response(JSON.stringify(fcmResult), { status: 500, headers: { "Content-Type": "application/json" } });
    }

    console.log("🎉 XONG! FIREBASE ĐÃ CHẤP NHẬN GỬI THÔNG BÁO VỀ ĐIỆN THOẠI!");
    return new Response("Notification triggered via Firebase successfully", { status: 200 })

  } catch (error) {
    console.error("LỖI SẬP HỆ THỐNG (CRASH CODE):", error);
    const errorMessage = error instanceof Error ? error.message : String(error);
    return new Response(
      JSON.stringify({ error: errorMessage }), 
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})