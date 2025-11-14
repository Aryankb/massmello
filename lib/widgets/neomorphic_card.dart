import 'package:flutter/material.dart';

class NeomorphicCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  const NeomorphicCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
    final shadowDark = isDark ? Colors.black.withValues(alpha: 0.5) : const Color(0xFFA3B1C6);
    final shadowLight = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    final cardWidget = Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
