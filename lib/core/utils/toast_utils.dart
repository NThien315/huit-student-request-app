import 'dart:ui';
import 'package:flutter/material.dart';

void showGlassToast(BuildContext context, String message, {bool isError = false}) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 20, // Hiện ở phía trên
      left: 20, right: 20,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: (isError ? Colors.red : Colors.white).withValues(alpha: 0.8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(isError ? Icons.error_outline : Icons.info_outline, 
                    color: isError ? Colors.white : Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(child: Text(message, style: TextStyle(
                    color: isError ? Colors.white : Colors.black87, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 3), () => entry.remove());
}