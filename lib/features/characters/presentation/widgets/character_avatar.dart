import 'dart:io';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/character_model.dart';

class CharacterAvatarTheme {
  final Color background;
  final Color border;
  final Color textOrIcon;
  final IconData defaultIcon;

  const CharacterAvatarTheme({
    required this.background,
    required this.border,
    required this.textOrIcon,
    required this.defaultIcon,
  });

  static CharacterAvatarTheme of(BuildContext context, String? gender) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = CharacterGender.fromString(gender);

    switch (category) {
      case CharacterGender.male:
        return CharacterAvatarTheme(
          background: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE),
          border: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
          textOrIcon: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
          defaultIcon: Symbols.male,
        );
      case CharacterGender.female:
        return CharacterAvatarTheme(
          background: isDark ? const Color(0xFF501B34) : const Color(0xFFFCE7F3),
          border: isDark ? const Color(0xFFF472B6) : const Color(0xFFEC4899),
          textOrIcon: isDark ? const Color(0xFFFBCFE8) : const Color(0xFFBE185D),
          defaultIcon: Symbols.female,
        );
      case CharacterGender.custom:
        return CharacterAvatarTheme(
          background: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          border: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          textOrIcon: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          defaultIcon: Symbols.person,
        );
    }
  }
}

class CharacterAvatar extends StatelessWidget {
  final String? name;
  final String? portraitPath;
  final String? gender;
  final double size;
  final double borderWidth;
  final VoidCallback? onTap;
  final bool showCameraBadge;
  final VoidCallback? onCameraTap;

  const CharacterAvatar({
    super.key,
    this.name,
    this.portraitPath,
    this.gender,
    this.size = 72,
    this.borderWidth = 2,
    this.onTap,
    this.showCameraBadge = false,
    this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CharacterAvatarTheme.of(context, gender);
    final rawPortrait = portraitPath?.trim();
    final hasPortrait = rawPortrait != null && rawPortrait.isNotEmpty;
    final isNetwork = hasPortrait &&
        (rawPortrait.startsWith('http://') || rawPortrait.startsWith('https://'));

    Widget avatarContent;
    if (hasPortrait) {
      avatarContent = isNetwork
          ? Image.network(
              rawPortrait,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
            )
          : Image.file(
              File(rawPortrait),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
            );
    } else {
      avatarContent = _buildPlaceholder(theme);
    }

    final avatarCircle = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.background,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.border,
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(child: avatarContent),
      ),
    );

    if (!showCameraBadge) {
      return avatarCircle;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarCircle,
        Positioned(
          bottom: -2,
          right: -2,
          child: InkWell(
            onTap: onCameraTap ?? onTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: theme.border,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: const Icon(
                Symbols.photo_camera,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(CharacterAvatarTheme theme) {
    final initial = (name != null && name!.trim().isNotEmpty)
        ? name!.trim().substring(0, 1).toUpperCase()
        : null;

    if (initial != null) {
      return Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.44,
            fontWeight: FontWeight.bold,
            color: theme.textOrIcon,
            fontFamily: 'Signika',
          ),
        ),
      );
    }

    return Center(
      child: Icon(
        theme.defaultIcon,
        size: size * 0.5,
        color: theme.textOrIcon,
      ),
    );
  }
}
