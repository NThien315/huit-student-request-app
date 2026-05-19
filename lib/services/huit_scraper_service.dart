import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class HuitScraperService {
  static Future<List<Map<String, String>>> fetchAnnouncements() async {
    List<Map<String, String>> results = []; // Khai báo rõ ràng để tránh lỗi undefined

    try {
      final url = Uri.parse('https://sinhvien.huit.edu.vn/sinh-vien/dm-tin-tuc/thong-tin-chung-095310.html');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      });

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var items = document.querySelectorAll('.notification .item .desc-txt a.title'); 

        for (var item in items) {
          String fullText = item.text.trim();
          String title = fullText;
          String date = "Vừa xong";

          // Tách ngày nếu tiêu đề có dạng: "Tiêu đề tin tức - 15/05/2026"
          if (fullText.contains(' - ')) {
            List<String> parts = fullText.split(' - ');
            date = parts.last.trim();
            title = parts.sublist(0, parts.length - 1).join(' - ').trim();
          }

          results.add({
            'title': title,
            'date': date,
            'link': item.attributes['href']?.startsWith('http') == true 
                ? item.attributes['href']! 
                : 'https://sinhvien.huit.edu.vn${item.attributes['href']}',
          });
        }
      }
      debugPrint("Đã tìm thấy ${results.length} tin tức."); 
    } catch (e) {
      debugPrint("Lỗi cào dữ liệu HUIT: $e");
    }
    
    return results;
  }
}