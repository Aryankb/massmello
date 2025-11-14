import 'package:flutter/material.dart';

class NeomorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const NeomorphicButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 56,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  State<NeomorphicButton> createState() => _NeomorphicButtonState();
}

class _NeomorphicButtonState extends State<NeomorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ?? Theme.of(context).colorScheme.surface;
    final shadowDark = isDark ? Colors.black.withValues(alpha: 0.5) : const Color(0xFFA3B1C6);
    final shadowLight = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: shadowDark.withValues(alpha: 0.3),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: shadowDark,
                    offset: const Offset(6, 6),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: shadowLight,
                    offset: const Offset(-6, -6),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Center(
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
