import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.primarySV), // Nút quay lại màu xanh
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: TextField(
            controller: _searchController,
            autofocus: true, // QUAN TRỌNG: Tự động bật bàn phím ngay khi vào trang
            decoration: InputDecoration(
              hintText: 'Tìm kiếm yêu cầu...',
              hintStyle: const TextStyle(color: AppColors.gray500, fontSize: 15),
              prefixIcon: const Icon(Icons.search, color: AppColors.gray900),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close, color: AppColors.gray500, size: 20),
                onPressed: () => _searchController.clear(), // Bấm X để xóa text
              ),
              filled: true,
              fillColor: AppColors.gray100, // Nền xám nhạt như thiết kế
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TÌM KIẾM GẦN ĐÂY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 16),
            // Danh sách lịch sử
            _buildHistoryItem('xin vay vốn'),
            _buildHistoryItem('đơn phúc khảo'),
          ],
        ),
      ),
    );
  }

  // Hàm vẽ từng dòng lịch sử
  Widget _buildHistoryItem(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, color: AppColors.gray900),
          ),
          const Icon(Icons.cancel, color: AppColors.gray500, size: 18),
        ],
      ),
    );
  }
}