import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Animated shimmer skeleton card placeholder.
class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key, this.height = 80, this.width = double.infinity});
  final double height;
  final double width;

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        height: widget.height,
        width: widget.width,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.darkSurface.withAlpha((_animation.value * 255).toInt()),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Animated shimmer list-tile placeholder.
class SkeletonListTile extends StatefulWidget {
  const SkeletonListTile({super.key});

  @override
  State<SkeletonListTile> createState() => _SkeletonListTileState();
}

class _SkeletonListTileState extends State<SkeletonListTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color =>
      AppColors.darkSurface.withAlpha((_animation.value * 255).toInt());

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Leading circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(7))),
                  const SizedBox(height: AppSpacing.xs),
                  Container(height: 11, width: 140, decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(6))),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(height: 14, width: 60, decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(7))),
          ],
        ),
      ),
    );
  }
}
