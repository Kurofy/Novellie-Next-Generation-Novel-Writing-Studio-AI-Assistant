import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../characters/application/character_providers.dart';
import '../../../characters/domain/models/character_model.dart';
import '../../../novels/application/novel_providers.dart';
import '../../application/tools_providers.dart';
import '../../domain/models/name_models.dart';

class NameResultCard extends ConsumerWidget {
  const NameResultCard({
    super.key,
    required this.name,
    this.onRegenerate,
  });

  final GeneratedName name;
  final VoidCallback? onRegenerate;

  void _copyToClipboard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    var text = name.fullName;
    if (name.title != null && name.title!.isNotEmpty) {
      text = '$text (${name.title})';
    }
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isIndo ? 'Menyalin "$text" ke papan klip' : 'Copied "$text" to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyFullLore(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final buffer = StringBuffer();
    buffer.writeln(name.fullName);
    if (name.title != null) buffer.writeln(isIndo ? 'Gelar: ${name.title}' : 'Title: ${name.title}');
    buffer.writeln(isIndo ? 'Kategori: ${name.category} (${name.gender})' : 'Category: ${name.category} (${name.gender})');
    if (name.meaning != null) buffer.writeln(isIndo ? 'Arti: ${name.meaning}' : 'Meaning: ${name.meaning}');
    if (name.backstory != null) buffer.writeln(isIndo ? 'Latar Belakang: ${name.backstory}' : 'Backstory: ${name.backstory}');

    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isIndo ? 'Lore karakter lengkap disalin ke papan klip' : 'Full character lore copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveAsNovelCharacter(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final activeNovelAsync = ref.read(activeNovelProvider);
    final novel = activeNovelAsync.valueOrNull;

    if (novel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isIndo ? 'Silakan pilih atau buat novel aktif terlebih dahulu.' : 'Please select or create an active novel first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showNvBottomSheet<void>(
      context: context,
      title: isIndo ? 'Simpan ke Karakter' : 'Save to Characters',
      subtitle: isIndo ? 'Tambahkan ${name.fullName} ke "${novel.title}"' : 'Add ${name.fullName} to "${novel.title}"',
      child: _SaveCharacterSheet(
        novelId: novel.id,
        initialName: name,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final c = context.colors;
    final isFav = ref.watch(favoriteNamesProvider).any((e) => e.fullName == name.fullName);

    return NvCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.fullName,
                      style: AppTypography.sectionTitle.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (name.title != null && name.title!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        name.title!,
                        style: AppTypography.labelMd.copyWith(
                          color: c.primary,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isFav ? Symbols.star : Symbols.star,
                  fill: isFav ? 1.0 : 0.0,
                  color: isFav ? Colors.amber : c.textMuted,
                  size: 20,
                ),
                tooltip: isFav
                    ? (isIndo ? 'Hapus Favorit' : 'Remove Favorite')
                    : (isIndo ? 'Simpan Favorit' : 'Save Favorite'),
                onPressed: () {
                  ref.read(favoriteNamesProvider.notifier).toggleFavorite(name);
                },
              ),
              IconButton(
                icon: Icon(Symbols.content_copy, color: c.textSecondary, size: 20),
                tooltip: isIndo ? 'Salin nama' : 'Copy name',
                onPressed: () => _copyToClipboard(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: c.outlineVariant),
                ),
                child: Text(
                  name.category,
                  style: AppTypography.labelSm.copyWith(
                    color: c.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: c.outlineVariant),
                ),
                child: Text(
                  name.gender.toUpperCase(),
                  style: AppTypography.labelSm.copyWith(
                    color: c.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (name.isAiGenerated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Symbols.auto_awesome, size: 12, color: c.primary),
                      const SizedBox(width: 4),
                      Text(
                        'AI Lore',
                        style: AppTypography.labelSm.copyWith(
                          color: c.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (name.meaning != null && name.meaning!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Symbols.menu_book, size: 14, color: c.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    name.meaning!,
                    style: AppTypography.bodySm.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (name.backstory != null && name.backstory!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.xs),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: c.surfaceSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.inset),
                border: Border.all(color: c.outlineVariant.withValues(alpha: 0.6)),
              ),
              child: Text(
                name.backstory!,
                style: AppTypography.bodySm.copyWith(
                  color: c.textPrimary,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (name.isAiGenerated) ...[
                TextButton.icon(
                  onPressed: () => _copyFullLore(context),
                  icon: const Icon(Symbols.format_quote, size: 16),
                  label: Text(isIndo ? 'Salin Lore' : 'Copy Lore'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: c.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              TextButton.icon(
                onPressed: () => _saveAsNovelCharacter(context, ref),
                icon: const Icon(Symbols.person_add, size: 16),
                label: Text(isIndo ? 'Simpan sbg Karakter' : 'Save as Character'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: c.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaveCharacterSheet extends ConsumerStatefulWidget {
  const _SaveCharacterSheet({
    required this.novelId,
    required this.initialName,
  });

  final String novelId;
  final GeneratedName initialName;

  @override
  ConsumerState<_SaveCharacterSheet> createState() => _SaveCharacterSheetState();
}

class _SaveCharacterSheetState extends ConsumerState<_SaveCharacterSheet> {
  late CharacterRole _role;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _role = CharacterRole.supporting;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(characterRepositoryProvider);
      await repo.createCharacter(
        novelId: widget.novelId,
        name: widget.initialName.fullName,
        nickname: widget.initialName.title,
        gender: widget.initialName.gender,
        role: _role,
        notes: widget.initialName.meaning,
        backstory: widget.initialName.backstory,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isIndo
                ? '${widget.initialName.fullName} ditambahkan ke karakter novel!'
                : '${widget.initialName.fullName} added to novel characters!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isIndo ? 'Gagal menyimpan: $e' : 'Error saving: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isIndo ? 'Tetapkan Peran:' : 'Assign Role:',
            style: AppTypography.labelMd.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<CharacterRole>(
            initialValue: _role,

            decoration: InputDecoration(
              filled: true,
              fillColor: c.surfaceSecondary,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
                borderSide: BorderSide(color: c.outlineVariant),
              ),
            ),
            items: CharacterRole.values
                .map((r) => DropdownMenuItem(value: r, child: Text(r.getLabel(l10n))))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _role = val);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          NvButton(
            label: _isSaving
                ? (isIndo ? 'Menyimpan…' : 'Saving…')
                : (isIndo ? 'Tambahkan ke Novel' : 'Add to Novel'),
            onPressed: _isSaving ? null : _save,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
