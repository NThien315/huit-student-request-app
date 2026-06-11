// lib/services/web_exporter_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';

class WebExporter {
  // Hàm xử lý tải file thật sự bằng thư viện dart:html trên Web
  static void downloadCSVWeb(String csvContent, String fileName, BuildContext context) {
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "${fileName}_${DateTime.now().millisecondsSinceEpoch}.csv")
      ..style.display = 'none';
    
    html.document.body?.children.add(anchor);
    anchor.click();
    
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}