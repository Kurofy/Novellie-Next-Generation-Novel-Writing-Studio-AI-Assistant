import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class NvProgressBar extends StatelessWidget {
  const NvProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.onInset = false,
  });

  const NvProgressBar.compact({
    super.key,
    required this.value,
    this.onInset = false,
  }) : height = 6;

  final double? value;
  final double height;
  final bool onInset;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final trackColor = onInset ? c.timelineTrack : c.progressTrack;
    final clampedValue = value != null ? value!.clamp(0.0, 1.0) : 0.0;

    return Semantics(
      value:
          value != null ? '${(clampedValue * 100).toInt()}%' : 'Indeterminate',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          height: height,
          width: double.infinity,
          color: trackColor,
          alignment: Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                height: height,
                width: constraints.maxWidth * clampedValue,
                decoration: BoxDecoration(
                  color: c.primaryFill,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
