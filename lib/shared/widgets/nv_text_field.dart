import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/theme/theme.dart';

class NvTextField extends StatelessWidget {
  const NvTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.hintText,
    this.labelText,
    this.helperText,
    this.errorText,
    this.leadingIcon,
    this.trailingIcon,
    this.onTrailingTap,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.onCanvas = false,
  });

  const NvTextField.search({
    super.key,
    this.controller,
    this.hintText = 'Search…',
    this.onChanged,
    this.onSubmitted,
    this.onTrailingTap,
    this.onCanvas = false,
    this.textInputAction = TextInputAction.search,
  })  : labelText = null,
        helperText = null,
        errorText = null,
        leadingIcon = Symbols.search,
        trailingIcon = Symbols.tune,
        maxLines = 1,
        minLines = null,
        keyboardType = TextInputType.text,
        readOnly = false,
        autofocus = false,
        obscureText = false,
        initialValue = null,
        focusNode = null;

  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final String? errorText;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final bool readOnly;
  final bool autofocus;
  final bool obscureText;
  final bool onCanvas;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final fill = onCanvas ? c.surface : c.surfaceSecondary;
    final resolvedAction = textInputAction ??
        (maxLines == 1 ? TextInputAction.next : TextInputAction.newline);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: AppTypography.labelMd.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          focusNode: focusNode,
          onChanged: onChanged,
          textInputAction: resolvedAction,
          onFieldSubmitted: onSubmitted ??
              (resolvedAction == TextInputAction.next
                  ? (_) => FocusScope.of(context).nextFocus()
                  : null),
          maxLines: maxLines,
          minLines: minLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          autofocus: autofocus,
          obscureText: obscureText,
          style: AppTypography.body.copyWith(color: c.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: fill,
            hintText: hintText,
            hintStyle: AppTypography.body.copyWith(color: c.textSecondary),
            prefixIcon: leadingIcon != null
                ? Icon(leadingIcon, size: 20, color: c.textMuted)
                : null,
            suffixIcon: trailingIcon != null
                ? IconButton(
                    icon: Icon(trailingIcon, size: 20, color: c.textSecondary),
                    onPressed: onTrailingTap,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md + 2,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(
                color: c.primary.withAlpha(153),
                width: 2,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(Symbols.error, size: 14, color: c.error),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  errorText!,
                  style: AppTypography.bodySm.copyWith(color: c.error),
                ),
              ),
            ],
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            helperText!,
            style: AppTypography.bodySm.copyWith(color: c.textSecondary),
          ),
        ],
      ],
    );
  }
}
