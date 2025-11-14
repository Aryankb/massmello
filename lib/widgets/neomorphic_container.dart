import 'package:flutter/material.dart';

class NeomorphicContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isPressed;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const NeomorphicContainer({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.padding,
    this.margin,
    this.isPressed = false,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
    final shadowDark = isDark ? Colors.black.withValues(alpha: 0.5) : const Color(0xFFA3B1C6);
    final shadowLight = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: isPressed
            ? []
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
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
