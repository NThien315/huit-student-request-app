import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassToast {
  static void show(BuildContext context, String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _GlassToastWidget(
        message: message,
        isError: isError,
        onDismiss: () {
          entry.remove(); // Chỉ xóa hẳn khi hiệu ứng Fade Out kết thúc
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _GlassToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _GlassToastWidget({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_GlassToastWidget> createState() => _GlassToastWidgetState();
}

class _GlassToastWidgetState extends State<_GlassToastWidget> {
  double _opacity = 0.0;
  late Timer _fadeInTimer;
  late Timer _fadeOutTimer;
  late Timer _dismissTimer;

  @override
  void initState() {
    super.initState();
    // 1. Kích hoạt hiệu ứng Fade In ngay khi lên màn hình
    _fadeInTimer = Timer(const Duration(milliseconds: 50), () {
      if (mounted) setState(() => _opacity = 1.0);
    });

    // 2. Kích hoạt hiệu ứng Fade Out sau 2.7 giây
    _fadeOutTimer = Timer(const Duration(milliseconds: 2700), () {
      if (mounted) setState(() => _opacity = 0.0);
    });

    // 3. Gọi hàm remove hoàn toàn sau đúng 3 giây
    _dismissTimer = Timer(const Duration(milliseconds: 3000), () {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _fadeInTimer.cancel();
    _fadeOutTimer.cancel();
    _dismissTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 110,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 300), // Thời gian chuyển đổi độ mờ
          curve: Curves.easeInOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: (widget.isError ? const Color(0xFFE53935) : const Color(0xFF0066CC)).withValues(alpha: 0.93),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}