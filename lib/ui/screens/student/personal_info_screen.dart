import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(backgroundColor: AppColors.white, elevation: 0, leading: const BackButton(color: AppColors.primarySV), centerTitle: true, title: const Text('Thông tin cá nhân', style: TextStyle(color: AppColors.gray900, fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, backgroundColor: AppColors.gray100, child: Icon(Icons.person, size: 40, color: AppColors.gray500)),
            const SizedBox(height: 12),
            const Text('Nguyễn Văn A', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('MSSV: 2201234567', style: TextStyle(color: AppColors.gray500)),
            const SizedBox(height: 32),
            
            _buildReadOnlyField('Lớp', '14DHTH01'),
            _buildReadOnlyField('Khoa', 'Công nghệ Thông tin'),
            _buildReadOnlyField('Ngành', 'Công nghệ phần mềm'),
            _buildReadOnlyField('Khoá', '2022-2026'),
            _buildReadOnlyField('Hệ đào tạo', 'Chính quy'),
            
            const SizedBox(height: 20),
            _buildEditableField('Email', '2201234567@huit.edu.vn'),
            _buildEditableField('Số điện thoại', '0123456789'),
            _buildEditableField('Số CCCD', '012345678912'),
            _buildEditableField('Địa chỉ', '140 Lê Trọng Tấn, Tây Thạnh, Tân Phú, HCM'),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppColors.gray500))), Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.gray900))]),
    );
  }

  Widget _buildEditableField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
          const SizedBox(height: 8),
          TextField(controller: TextEditingController(text: value), decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)))),
        ],
      ),
    );
  }
}