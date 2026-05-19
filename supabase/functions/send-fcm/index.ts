import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { GoogleAuth } from "https://esm.sh/google-auth-library"

// Nhúng thẳng nội dung file JSON hỏa lực của Firebase vào đây để né việc cài Secrets trên Web
const serviceAccount = {
  "type": "service_account",
  "project_id": "huit-student-request-app",
  "private_key_id": "fe549ebd2ef1a0f48a4caa99b10c2679a54aeca3",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDBWq0dllz4jIIy\nJKYsuO9Enb/fIR+ZhmZyKOz9/qfRxLVhM0t9toPOhOZgsvEHqDbxPXbSJyJV92U+\n2AGHcBeQDM18SZotrsTkxYUQ22GEed3GCBQ9MYGnFOALa2LJ54GjNCtaFU8SPtzd\nKdFfnq53QzeBgL14isiobIbtvDRy2WEnS/XU5GDiEqDEKrwIp1oMmBkHFA960TN1\npDoWgW5tvhWDJ6cAP0KjBahzhfb8szOEoIjA2/synTAK9nJ7lYZJxhTWRLujopU8\nBaa/njQBs9X1Sn3EckMySIhZZKeVv1SQgc9qQ+auMKcRimBrkKiQ2dJgcodWezkq\nh0STzUetAgMBAAECggEADJBaUGJdXy8uJJj6DUzlC0Xe2l5aIc04afGb2LNL71cD\nXDILlTsfXHOJTr5B6Df3ffx69JPjaMefFhLOIqFXfp4+WfWkZZSGKcFl8J74urV6\ngiwzOHi3joZOOp+7NxhqdZLlwEBDN5HLIznc54Q1nP1KpYkahrMp77vBlsAUfmPh\nsbj7H+OdT0+2DP52ZhnKZhGv6sUbuTpUt8B2PVWja7luzy59CX/k64HOE6LSP4di\npX9nzMM8LwhJ/nL1mOSqk3Sw3D3OZ68a9UewBekqmZaR33+qJ8GA7ic62/lD9p8R\nCM1zJkLSbZTTg/r7KfuI0Hc8KxuLQovALuzWruT6cQKBgQDtKe5y5Eov3nSVxmlc\nJfdMHgzS43EejwR6jEVOpgDgtBfFL8HAdd+1RG36Frb9b3sWCYOvTw68CETeBy2v\ncNj/qfkBfNVAcuBgL9hJkQnM1jTzWUnMOpX29/9VUkEX+SGj/zsRI3GzrXezqTpo\npMeOZYm/SEj8oukL/6cLhLTDeQKBgQDQtf+H4ImHEsPdFL+jPZmxD/4vTE2EmoVW\nxM9djNLdqAt0kXqgiYkoHJKYqh9iu2EpyA6N3qsDsg5v98OW1g9OYRXECBb7qC00\nF7XlqtN+PSET9bEunNjrjaA3EssyFF0Gz3dhFetQ4sUWlh7I+qcmQJcuwbvuEPWI\naV05xC7E1QKBgQCxinNj9PyIi0rRmL/k6NMRW2mUMgnLq5rZtspnjyQXExq8Vf0A\ne/1lcH23+2svnFYTcDnxcgiAwNv1LoCH1r3L3s12zKHD5nuL5iVPJVGl0zG+frgd\nODptsMencrUiIjGJ2Ja6RMNok9KJX4VHMxvkwKR22sEwxzAY+GBv4f+EWQKBgHZv\nsRAkRSbXaTpd+dnirQKjdrTUcfDb1urESIBn14ldQRLnM1VCdwjCHhZwA9t9Rcf1\n9Pxg7V7tfe/gA6fm1Uy/HyDdDl3Es9Ip2lj4NYgfnFO9SsyOyTHyboaSLai/kYK5\n3J7FV4HRDdKhYdrfEldMs/4ehky0ZwD/+Z08TOX5AoGAVkR/qvIgXAunNmdYhebl\n1Ec3X/qSjCWYMAd4ITxwF2p1Dx8ySa0CE+24i5YRU3cq99XJJlAWc365X/muN/Nh\nvPl37E3bnUm18LmohkIukIcQk7xBcqdOJoLuZf3jGHse6+/djxKYGY/Dru55JrOb\nKijMueBOIvwc49beA3+47h4=\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@huit-student-request-app.iam.gserviceaccount.com",
  "client_id": "108748758167032146653",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40huit-student-request-app.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
};

serve(async (req) => {
  try {
    const payload = await req.json()
    const record = payload.record // Dòng thông báo mới từ bảng 'notifications'

    if (!record || !record.studentUid) {
      return new Response("Invalid payload", { status: 400 })
    }

    // 1. Khởi tạo Supabase Client nội bộ bằng quyền hệ thống
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Lấy FCM Token thiết bị của sinh viên
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('fcm_token')
      .eq('uid', record.studentUid)
      .single()

    if (userError || !user || !user.fcm_token) {
      return new Response("No FCM Token found for this student", { status: 200 })
    }

    // 2. Gọi quyền OAuth2 trực tiếp từ biến cục bộ đã khai báo phía trên
    const auth = new GoogleAuth({
      credentials: serviceAccount,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    const client = await auth.getClient()
    const token = await client.getAccessToken()

    // 3. Tiến hành gọi API Firebase gửi thông báo đẩy
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`
    
    await fetch(fcmUrl, {
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

    return new Response("Notification triggered via Firebase successfully", { status: 200 })
  } catch (error) {
    // Ép kiểu hoặc kiểm tra nếu error đúng là thực thể Error thì mới lấy .message
    const errorMessage = error instanceof Error ? error.message : String(error);
    
    return new Response(
      JSON.stringify({ error: errorMessage }), 
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})