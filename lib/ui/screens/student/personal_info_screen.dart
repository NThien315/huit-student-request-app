import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../../../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final user = AuthService().currentUser;
  Future<Map<String, dynamic>?>? _userDataFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _userDataFuture = Supabase.instance.client.from('users').select().eq('uid', user?.id ?? '').maybeSingle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Ép Status bar màu đen
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: AppColors.primarySV),
        title: const Text('Thông tin cá nhân', style: TextStyle(color: AppColors.gray900, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primarySV));
          }
          final data = snapshot.data ?? {};

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('THÔNG TIN CƠ BẢN'),
              _buildCard([
                _buildInfoRow(Icons.badge_outlined, 'Họ và tên', data['name'] ?? 'Chưa cập nhật', isLocked: true),
                const Divider(height: 24, color: AppColors.gray100),
                _buildInfoRow(Icons.credit_card_outlined, 'Mã số sinh viên', data['studentId'] ?? 'Chưa cập nhật', isLocked: true),
                const Divider(height: 24, color: AppColors.gray100),
                _buildInfoRow(Icons.transgender_outlined, 'Giới tính', data['gender'] ?? 'Chưa cập nhật', isLocked: true),
                const Divider(height: 24, color: AppColors.gray100),
                _buildInfoRow(Icons.calendar_month_outlined, 'Ngày sinh', data['dob'] ?? 'Chưa cập nhật', isLocked: true),
                const Divider(height: 24, color: AppColors.gray100),
                _buildInfoRow(Icons.perm_identity, 'CCCD / CMND', data['idCard'] ?? 'Chưa cập nhật', isLocked: false),
              ]),
              const SizedBox(height: 24),

              _buildSectionTitle('THÔNG TIN HỌC VẤN (Khóa)'),
              _buildCard([
                _buildInfoRow(Icons.school_outlined, 'Khoa', data['faculty'] ?? 'Công nghệ Thông tin', isLocked: true),
                const Divider(height: 24, color: AppColors.gray100),
                _buildInfoRow(Icons.menu_book_outlined, 'Ngành học', data['major'] ?? 'Chưa cập nhật', isLocked: true),
                const Divider(height: 24, color: AppColors.gray100),
                _buildInfoRow(Icons.class_outlined, 'Lớp sinh hoạt', data['className'] ?? 'Chưa cập nhật', isLocked: true),
              ]),
              const SizedBox(height: 24),

              _buildSectionTitle('THÔNG TIN LIÊN HỆ'),
              _buildCard([
                _buildInfoRow(Icons.email_outlined, 'Email trường', user?.email ?? 'Chưa cập nhật', isLocked: true),
                const Divider(height: 24, color: AppColors.gray100),
                _buildInfoRow(Icons.phone_outlined, 'Số điện thoại', data['phone'] ?? 'Chưa cập nhật', isLocked: false),
                const Divider(height: 24, color: AppColors.gray100),
                _buildInfoRow(Icons.home_outlined, 'Địa chỉ liên lạc', data['address'] ?? 'Chưa cập nhật', isLocked: false),
              ]),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showEditProfileModal(context, data),
                  icon: const Icon(Icons.edit, color: AppColors.white, size: 20),
                  label: const Text('Cập nhật thông tin', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySV, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.gray500)));
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isLocked = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppColors.gray100, shape: BoxShape.circle), child: Icon(icon, color: AppColors.primarySV, size: 20)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w500)),
                  if (isLocked) ...[const SizedBox(width: 4), const Icon(Icons.lock_outline, size: 12, color: AppColors.gray500)],
                ],
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 15, color: AppColors.gray900, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditProfileModal(BuildContext context, Map<String, dynamic> currentData) {
    final phoneCtrl = TextEditingController(text: currentData['phone']);
    final idCardCtrl = TextEditingController(text: currentData['idCard']);
    final addressCtrl = TextEditingController(text: currentData['address']);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                const Text('Cập nhật thông tin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Chỉ những thông tin dưới đây mới được phép chỉnh sửa.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 24),

                _buildTextField('Số điện thoại', controller: phoneCtrl, keyboardType: TextInputType.phone),
                _buildTextField('Số CCCD / CMND', controller: idCardCtrl, keyboardType: TextInputType.number),
                _buildTextField('Địa chỉ liên lạc', controller: addressCtrl),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      setModalState(() => isSaving = true);
                      try {
                        await Supabase.instance.client.from('users').update({
                          'phone': phoneCtrl.text.trim(),
                          'idCard': idCardCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                        }).eq('uid', user!.id);
                        
                        if (context.mounted) {
                          Navigator.pop(modalContext);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: Colors.green));
                          setState(() => _fetchData());
                        }
                      } catch (e) {
                        setModalState(() => isSaving = false);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySV, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Lưu thay đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildTextField(String label, {required TextEditingController controller, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySV)),
        ),
      ),
    );
  }
}