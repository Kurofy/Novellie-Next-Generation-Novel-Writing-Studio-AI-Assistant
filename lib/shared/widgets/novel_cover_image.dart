import 'dart:io';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/theme/theme.dart';

class NovelCoverImage extends StatelessWidget {
  final String? coverPath;
  final double width;
  final double height;
  final double borderRadius;
  final IconData fallbackIcon;
  final double iconSize;

  const NovelCoverImage({
    super.key,
    required this.coverPath,
    this.width = 48,
    this.height = 64,
    this.borderRadius = AppRadius.cover,
    this.fallbackIcon = Symbols.book_5,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final hasValidFile = coverPath != null &&
        coverPath!.isNotEmpty &&
        File(coverPath!).existsSync();

    if (hasValidFile) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: c.surfaceSecondary,
            border: Border.all(color: c.outlineVariant),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Image.file(
            File(coverPath!),
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholder(c),
          ),
        ),
      );
    }

    return _buildPlaceholder(c);
  }

  Widget _buildPlaceholder(AppColors c) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: c.outlineVariant),
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          size: iconSize,
          color: c.primary,
        ),
      ),
    );
  }
}
