import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/world_providers.dart';
import '../../domain/models/world_models.dart';

class CreateWorldEntryDialog extends ConsumerStatefulWidget {
  final String novelId;
  final String? initialCategoryId;
  final WorldEntryModel? entryToEdit;

  const CreateWorldEntryDialog({
    super.key,
    required this.novelId,
    this.initialCategoryId,
    this.entryToEdit,
  });

  static Future<WorldEntryModel?> show(
    BuildContext context,
    String novelId, {
    String? categoryId,
    WorldEntryModel? entryToEdit,
  }) {
    final c = context.colors;
    return showModalBottomSheet<WorldEntryModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => CreateWorldEntryDialog(
        novelId: novelId,
        initialCategoryId: categoryId ?? entryToEdit?.categoryId,
        entryToEdit: entryToEdit,
      ),
    );
  }

  @override
  ConsumerState<CreateWorldEntryDialog> createState() =>
      _CreateWorldEntryDialogState();
}

class _CreateWorldEntryDialogState
    extends ConsumerState<CreateWorldEntryDialog> {
  final _nameController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _summaryController = TextEditingController();
  String? _selectedCategoryId;
  bool _verifiedCanon = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.entryToEdit;
    if (edit != null) {
      _nameController.text = edit.name;
      _subtitleController.text = edit.subtitle ?? '';
      _summaryController.text = edit.summary ?? '';
      _selectedCategoryId = edit.categoryId;
      _verifiedCanon = edit.verifiedCanon;
    } else {
      _selectedCategoryId = widget.initialCategoryId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedCategoryId == null) return;

    setState(() => _isCreating = true);
    try {
      if (widget.entryToEdit != null) {
        final updated = widget.entryToEdit!.copyWith(
          categoryId: _selectedCategoryId!,
          name: name,
          subtitle: _subtitleController.text.trim().isNotEmpty
              ? _subtitleController.text.trim()
              : null,
          summary: _summaryController.text.trim().isNotEmpty
              ? _summaryController.text.trim()
              : null,
          verifiedCanon: _verifiedCanon,
          updatedAt: DateTime.now().toUtc(),
        );

        await ref.read(worldActionsControllerProvider).updateEntry(updated);

        if (mounted) {
          Navigator.of(context).pop(updated);
        }
        return;
      }

      final entry = await ref
          .read(worldActionsControllerProvider)
          .createEntry(
            novelId: widget.novelId,
            categoryId: _selectedCategoryId!,
            name: name,
            subtitle: _subtitleController.text.trim().isNotEmpty
                ? _subtitleController.text.trim()
                : null,
            summary: _summaryController.text.trim().isNotEmpty
                ? _summaryController.text.trim()
                : null,
            verifiedCanon: _verifiedCanon,
          );

      if (mounted) {
        Navigator.of(context).pop(entry);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.entryToEdit != null
                  ? 'Failed to update world entry: $e'
                  : 'Failed to create world entry: $e',
            ),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final categoriesAsync =
        ref.watch(worldCategoriesStreamProvider(widget.novelId));

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.sm,
          bottom: bottomInset + AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: c.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.entryToEdit != null
                          ? (isIndo ? 'Edit Entri Dunia' : 'Edit World Entry')
                          : (isIndo ? 'Entri Dunia Baru' : 'New World Entry'),
                      style: AppTypography.screenTitle.copyWith(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  IconButton(
                    icon: const Icon(Symbols.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: isIndo ? 'Tutup' : 'Close',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(isIndo ? 'Nama Entri *' : 'Entry Name *', style: AppTypography.labelMd),
              const SizedBox(height: AppSpacing.sm),
              NvTextField(
                controller: _nameController,
                hintText: isIndo ? 'mis. Benteng Besi, Skisma Akbar' : 'e.g. Iron Citadel, The Great Schism',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(isIndo ? 'Subjudul / Tipe' : 'Subtitle / Type', style: AppTypography.labelMd),
              const SizedBox(height: AppSpacing.sm),
              NvTextField(
                controller: _subtitleController,
                hintText: isIndo ? 'mis. Benteng Pegunungan, Era Historis' : 'e.g. Mountain Fortress, Historical Era',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Category Selector
              Text(isIndo ? 'Kategori *' : 'Category *', style: AppTypography.labelMd),
              const SizedBox(height: AppSpacing.sm),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text(isIndo ? 'Tidak dapat memuat kategori' : 'Could not load categories'),
                data: (categories) {
                  if (categories.isNotEmpty && _selectedCategoryId == null) {
                    _selectedCategoryId = categories.first.id;
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    items: categories
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategoryId = val),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: c.surfaceSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        borderSide: BorderSide(
                          color: c.outlineVariant,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(isIndo ? 'Ringkasan / Gambaran Lore' : 'Summary / Lore Overview', style: AppTypography.labelMd),
              const SizedBox(height: AppSpacing.sm),
              NvTextField(
                controller: _summaryController,
                hintText: isIndo
                    ? 'Deskripsikan lokasi, faksi, sihir, atau konsep ini'
                    : 'Describe this location, faction, magic, or concept',
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),

              SwitchListTile(
                title: Text(isIndo ? 'Tandai sebagai Kanon' : 'Mark as Canon'),
                subtitle: Text(isIndo ? 'Kebenaran cerita terverifikasi di semesta ini' : 'Verified story truth in this universe'),
                value: _verifiedCanon,
                onChanged: (val) => setState(() => _verifiedCanon = val),
                activeThumbColor: c.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.x2),

              NvButton(
                label: widget.entryToEdit != null
                    ? (l10n?.saveChanges ?? 'Save Changes')
                    : (isIndo ? 'Buat Entri Dunia' : 'Create World Entry'),
                variant: NvButtonVariant.primary,
                icon: Symbols.check,
                isLoading: _isCreating,
                onPressed: _isCreating ? null : _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
