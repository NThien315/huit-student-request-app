import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../state/auth_provider.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Rút thẳng dữ liệu từ "bộ não" AuthProvider
    final authState = context.watch<AuthProvider>();
    final user = authState.currentUser;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Thông tin cá nhân', style: TextStyle(color: AppColors.gray900, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: const BackButton(color: AppColors.primarySV),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // 1. Header: Tên và MSSV
            Text(
              user?.displayName ?? 'Chưa cập nhật',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.gray900),
            ),
            const SizedBox(height: 4),
            Text(
              'MSSV: ${user?.studentId ?? 'N/A'}',
              style: const TextStyle(fontSize: 14, color: AppColors.gray500),
            ),
            const SizedBox(height: 32),

            // 2. Danh sách thông tin dạng Text
            // Tạm thời nếu DB chưa có, hiển thị giá trị mặc định để giữ form UI
            _buildInfoRow('Lớp', user?.className ?? '14DHTH01'),
            const SizedBox(height: 16),
            _buildInfoRow('Khoa', user?.faculty ?? 'Công nghệ Thông tin'),
            const SizedBox(height: 16),
            _buildInfoRow('Ngành', user?.major ?? 'Công nghệ phần mềm'),
            const SizedBox(height: 16),
            _buildInfoRow('Khoá', user?.cohort ?? '2022-2026'),
            const SizedBox(height: 16),
            _buildInfoRow('Hệ đào tạo', user?.trainingType ?? 'Chính quy'),
            
            const SizedBox(height: 32),

            // 3. Danh sách thông tin dạng TextField (Đã lấy data thật)
            _buildEditableField('Email', user?.email ?? ''),
            const SizedBox(height: 20),
            _buildEditableField('Số điện thoại', user?.phoneNumber ?? 'Chưa cập nhật'),
            const SizedBox(height: 20),
            _buildEditableField('Số CCCD', user?.idCard ?? 'Chưa cập nhật'),
            const SizedBox(height: 20),
            _buildEditableField('Địa chỉ', user?.address ?? 'Chưa cập nhật'),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Hàm vẽ dòng thông tin cơ bản
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100, // Chiều rộng cố định cho nhãn để các cột thẳng hàng
          child: Text(label, style: const TextStyle(color: AppColors.gray500, fontSize: 14)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray900, fontSize: 14)),
        ),
      ],
    );
  }

  // Hàm vẽ ô TextField bo góc giống UI của bạn
  Widget _buildEditableField(String label, String initialValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.gray500, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          readOnly: true, // Tạm thời khóa nhập liệu, sau này làm tính năng Edit thì mở ra
          style: const TextStyle(color: AppColors.gray900, fontSize: 15),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primarySV),
            ),
          ),
        ),
      ],
    );
  }
}