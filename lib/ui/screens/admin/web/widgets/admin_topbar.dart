import 'package:flutter/material.dart';
import 'admin_common.dart';

class AdminTopbar extends StatelessWidget {
  const AdminTopbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          const Spacer(),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
                color: const Color(0xff334155),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  height: 18,
                  width: 18,
                  decoration: const BoxDecoration(
                    color: AdminColors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '3',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 22),
          Container(height: 40, width: 1, color: AdminColors.border),
          const SizedBox(width: 22),
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xffeff6ff),
            child: Icon(Icons.person_rounded, color: AdminColors.blue),
          ),
          const SizedBox(width: 12),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cán bộ Giáo vụ',
                style: TextStyle(fontWeight: FontWeight.w900, color: AdminColors.text),
              ),
              SizedBox(height: 3),
              Text(
                'Khoa Công nghệ Thông tin',
                style: TextStyle(fontSize: 13, color: AdminColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
