import 'package:flutter/material.dart';
import 'admin_web_models.dart';

class AdminMockData {
  static final List<StudentRequest> requests = [
    StudentRequest(
      id: 'REQ-1001',
      studentName: 'Lê Nhật Thiện',
      studentClass: 'SE101',
      requestType: 'Xin bảng điểm',
      date: '03/06/2026',
      status: 'Chờ xử lý',
    ),
    StudentRequest(
      id: 'REQ-1002',
      studentName: 'Võ Xuân Trường',
      studentClass: 'SE102',
      requestType: 'Hoãn thi y tế',
      date: '02/06/2026',
      status: 'Đã duyệt',
      note: 'Hồ sơ hợp lệ',
    ),
    StudentRequest(
      id: 'REQ-1003',
      studentName: 'Trần Tiến Hoài Nam',
      studentClass: 'IA101',
      requestType: 'Hủy học phần',
      date: '01/06/2026',
      status: 'Từ chối',
      note: 'Thiếu minh chứng',
    ),
    StudentRequest(
      id: 'REQ-1004',
      studentName: 'Nguyễn Văn A',
      studentClass: 'SE101',
      requestType: 'Bảo lưu kết quả',
      date: '01/06/2026',
      status: 'Chờ xử lý',
    ),
    StudentRequest(
      id: 'REQ-1005',
      studentName: 'Trần Thị B',
      studentClass: 'SE103',
      requestType: 'Cấp lại thẻ SV',
      date: '31/05/2026',
      status: 'Đã duyệt',
    ),
  ];

  static final List<RequestCategory> categories = [
    RequestCategory(
      id: 'CAT01',
      name: 'Giấy xác nhận sinh viên',
      description: 'Giấy xác nhận sinh viên',
      department: 'Phòng CTSV',
      processingTime: '1-3 ngày',
      active: false,
    ),
    RequestCategory(
      id: 'CAT02',
      name: 'Đơn gia hạn học phí',
      description: 'Đang cập nhật mô tả',
      department: 'Phòng CTSV',
      processingTime: '1-3 ngày',
      active: true,
    ),
    RequestCategory(
      id: 'CAT03',
      name: 'Xét học bổng vượt khó',
      description: 'Đang cập nhật mô tả',
      department: 'Phòng CTSV',
      processingTime: '1-3 ngày',
      active: true,
    ),
    RequestCategory(
      id: 'CAT04',
      name: 'Miễn giảm học phí',
      description: 'Đang cập nhật mô tả',
      department: 'Phòng CTSV',
      processingTime: '1-3 ngày',
      active: true,
    ),
    RequestCategory(
      id: 'CAT05',
      name: 'Cấp/Làm lại thẻ sinh viên',
      description: 'Đang cập nhật mô tả',
      department: 'Phòng CTSV',
      processingTime: '1-3 ngày',
      active: true,
    ),
    RequestCategory(
      id: 'CAT06',
      name: 'Xác nhận điểm rèn luyện',
      description: 'Đang cập nhật mô tả',
      department: 'Phòng CTSV',
      processingTime: '1-3 ngày',
      active: true,
    ),
  ];

  static final List<StaffAccount> staffs = [
    StaffAccount(
      id: 'ST01',
      name: 'Nguyễn Thị Hoa',
      code: 'GV0012',
      email: 'hoa.nt@huit.edu.vn',
      role: 'Giáo vụ',
    ),
    StaffAccount(
      id: 'ST02',
      name: 'Võ Tuấn Minh',
      code: 'GV0015',
      email: 'minh.vt@huit.edu.vn',
      role: 'Giáo vụ',
    ),
    StaffAccount(
      id: 'ST03',
      name: 'Lê Tiến Văn Anh',
      code: 'GV0016',
      email: 'anh.ltv@huit.edu.vn',
      role: 'Giáo vụ',
      locked: true,
    ),
  ];

  static List<AdminStat> getStats() {
    return [
      AdminStat(
        title: 'Tổng đơn tiếp nhận',
        value: requests.length,
        percent: '-100.0%',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xff2563eb),
      ),
      AdminStat(
        title: 'Đang chờ xử lý',
        value: requests.where((e) => e.status == 'Chờ xử lý').length,
        percent: '-100.0%',
        icon: Icons.timer_rounded,
        color: const Color(0xfff59e0b),
      ),
      AdminStat(
        title: 'Đã hoàn thành',
        value: requests.where((e) => e.status == 'Đã duyệt').length,
        percent: '0%',
        icon: Icons.check_circle_rounded,
        color: const Color(0xff10b981),
      ),
      AdminStat(
        title: 'Đã từ chối/Hủy',
        value: requests.where((e) => e.status == 'Từ chối').length,
        percent: '-100.0%',
        icon: Icons.cancel_rounded,
        color: const Color(0xffef4444),
      ),
    ];
  }
}
