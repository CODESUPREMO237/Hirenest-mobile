// ============================================================================
// custom_button.dart
// lib/core/widgets/custom_button.dart
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum ButtonType { primary, secondary, text, iconOnly }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType type;
  final IconData? icon;
  final bool isFullWidth;
  final Color? color;
  final Color? textColor;

  const CustomButton({
    super.key,
    this.text = '',
    this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.icon,
    this.isFullWidth = false,
    this.color,
    this.textColor,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.isLoading || widget.onPressed == null;

    Widget child = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.type == ButtonType.primary
                    ? AppColors.white
                    : (widget.color ?? theme.colorScheme.primary),
              ),
            ),
          )
        : widget.type == ButtonType.iconOnly && widget.icon != null
            ? Icon(widget.icon, size: 24, color: widget.textColor)
            : widget.icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: 20, color: widget.textColor),
                      const SizedBox(width: AppSpacing.sm),
                      Text(widget.text,
                          style: widget.textColor != null
                              ? TextStyle(color: widget.textColor)
                              : null),
                    ],
                  )
                : Text(widget.text,
                    style: widget.textColor != null
                        ? TextStyle(color: widget.textColor)
                        : null);

    Widget button;
    switch (widget.type) {
      case ButtonType.primary:
        button = ElevatedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: widget.color != null
              ? ElevatedButton.styleFrom(backgroundColor: widget.color)
              : null,
          child: child,
        );
        break;
      case ButtonType.secondary:
        button = OutlinedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: widget.color != null
              ? OutlinedButton.styleFrom(
                  foregroundColor: widget.color,
                  side: BorderSide(color: widget.color!),
                )
              : null,
          child: child,
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: widget.color != null
              ? TextButton.styleFrom(foregroundColor: widget.color)
              : null,
          child: child,
        );
        break;
      case ButtonType.iconOnly:
        button = IconButton(
          onPressed: isDisabled ? null : widget.onPressed,
          icon: child,
          style: IconButton.styleFrom(
            backgroundColor: widget.color,
            padding: const EdgeInsets.all(AppSpacing.md),
          ),
        );
        break;
    }

    // Wrap with scale animation — no IgnorePointer so Material ripple works
    Widget result = GestureDetector(
      onTapDown: isDisabled ? null : (_) => _scaleController.forward(),
      onTapUp: isDisabled ? null : (_) => _scaleController.reverse(),
      onTapCancel: isDisabled ? null : () => _scaleController.reverse(),
      behavior: HitTestBehavior.translucent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: button,
      ),
    );

    if (widget.isFullWidth && widget.type != ButtonType.iconOnly) {
      return SizedBox(width: double.infinity, child: result);
    }
    return result;
  }
}