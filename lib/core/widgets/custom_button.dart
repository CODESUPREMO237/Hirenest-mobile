
// ============================================================================
// custom_button.dart
// lib/core/widgets/custom_button.dart
// ============================================================================

import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType type;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = isLoading
        ? const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(Colors.white),
      ),
    )
        : icon != null
        ? Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(text),
      ],
    )
        : Text(text);

    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case ButtonType.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case ButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
    }
  }
}

enum ButtonType { primary, secondary, text }