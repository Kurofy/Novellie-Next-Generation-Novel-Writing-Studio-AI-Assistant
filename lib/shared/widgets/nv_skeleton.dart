import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class NvSkeleton extends StatefulWidget {
  const NvSkeleton({
    super.key,
    this.width,
    this.height,
    this.radius = AppRadius.card,
  });

  const NvSkeleton.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = AppRadius.inset,
  });

  const NvSkeleton.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        radius = AppRadius.pill;

  const NvSkeleton.line({
    super.key,
    this.width = double.infinity,
    this.height = 16,
  }) : radius = AppRadius.pill;

  final double? width;
  final double? height;
  final double radius;

  @override
  State<NvSkeleton> createState() => _NvSkeletonState();
}

class _NvSkeletonState extends State<NvSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: c.surfaceSecondary,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    );

    if (disableAnimations) {
      return box;
    }

    return FadeTransition(
      opacity: _animation,
      child: box,
    );
  }
}
