import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// A text button that can only be used again after a cooldown.
class ResendButton extends StatefulWidget {
  const ResendButton({
    super.key,
    required this.onResend,
    this.label = 'Resend email',
    this.cooldownSeconds = 30,
  });

  final VoidCallback onResend;
  final String label;
  final int cooldownSeconds;

  @override
  State<ResendButton> createState() => _ResendButtonState();
}

class _ResendButtonState extends State<ResendButton> {
  Timer? _timer;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _remaining = widget.cooldownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waiting = _remaining > 0;
    return TextButton(
      onPressed: waiting
          ? null
          : () {
              widget.onResend();
              setState(_start);
            },
      child: Text(
        waiting ? 'Resend in ${_remaining}s' : widget.label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: waiting ? AppColors.textHint : AppColors.navy,
        ),
      ),
    );
  }
}