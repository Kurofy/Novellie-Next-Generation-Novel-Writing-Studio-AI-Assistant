import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/novel_providers.dart';
import '../../domain/models/novel_model.dart';

const _defaultGenres = [
  'Fantasy',
  'Sci-Fi',
  'Mystery',
  'Thriller',
  'Romance',
  'Historical',
  'Literary',
  'Horror',
  'Adventure',
];

class EditNovelDialog extends ConsumerStatefulWidget {
  final NovelModel novel;

  const EditNovelDialog({
    super.key,
    required this.novel,
  });

  static Future<bool?> show(BuildContext context, NovelModel novel) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => EditNovelDialog(novel: novel),
    );
  }

  @override
  ConsumerState<EditNovelDialog> createState() => _EditNovelDialogState();
}

class _EditNovelDialogState extends ConsumerState<EditNovelDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _synopsisController;
  late final TextEditingController _wordTargetController;

  late Set<String> _selectedGenres;
  late List<String> _genres;
  late NovelStatus _selectedStatus;
  String? _coverPath;
  bool _isSaving = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.novel.title);
    _subtitleController = TextEditingController(text: widget.novel.subtitle ?? '');
    _synopsisController =
        TextEditingController(text: widget.novel.description ?? '');
    _wordTargetController = TextEditingController(
      text: widget.novel.novelWordTarget?.toString() ?? '',
    );

    _genres = List.from(_defaultGenres);
    final rawGenre = widget.novel.genre;
    if (rawGenre != null && rawGenre.trim().isNotEmpty) {
      final parsedGenres = rawGenre
          .split(RegExp(r',\s*'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      _selectedGenres = parsedGenres.isNotEmpty ? parsedGenres : {'Fantasy'};
      for (final g in _selectedGenres) {
        if (!_genres.contains(g)) {
          _genres.add(g);
        }
      }
    } else {
      _selectedGenres = {'Fantasy'};
    }

    _selectedStatus = widget.novel.status;
    _coverPath = widget.novel.coverPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _synopsisController.dispose();
    _wordTargetController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _coverPath = file.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select cover image: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  void _showAddCustomGenreDialog() {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.addCustomGenre ?? 'Add Custom Genre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Cyberpunk, LitRPG, Xianxia',
          ),
          onSubmitted: (_) {
            _addCustomGenre(controller.text);
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              _addCustomGenre(controller.text);
              Navigator.of(ctx).pop();
            },
            child: Text(l10n?.localeName == 'id' ? 'Tambah' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _addCustomGenre(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      if (!_genres.contains(trimmed)) {
        _genres.add(trimmed);
      }
      _selectedGenres.add(trimmed);
    });
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedNovel = NovelModel(
        id: widget.novel.id,
        title: title,
        subtitle: _subtitleController.text.trim().isNotEmpty
            ? _subtitleController.text.trim()
            : null,
        author: widget.novel.author,
        coverPath: _coverPath,
        description: _synopsisController.text.trim().isNotEmpty
            ? _synopsisController.text.trim()
            : null,
        genre: _selectedGenres.isEmpty
            ? 'General'
            : _selectedGenres.join(', '),
        status: _selectedStatus,
        language: widget.novel.language,
        pov: widget.novel.pov,
        tense: widget.novel.tense,
        dialogueStyle: widget.novel.dialogueStyle,
        quotationStyle: widget.novel.quotationStyle,
        chapterWordTarget: widget.novel.chapterWordTarget,
        novelWordTarget: int.tryParse(_wordTargetController.text.trim()),
        aiContextAllowed: widget.novel.aiContextAllowed,
        totalWordCount: widget.novel.totalWordCount,
        chapterCount: widget.novel.chapterCount,
        lastOpenedAt: widget.novel.lastOpenedAt,
        createdAt: widget.novel.createdAt,
        updatedAt: DateTime.now().toUtc(),
        archivedAt: widget.novel.archivedAt,
        deletedAt: widget.novel.deletedAt,
      );

      await ref
          .read(novelActionsControllerProvider)
          .updateNovel(updatedNovel);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update novel: $e'),
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      l10n?.editNovelDetails ?? 'Edit Novel Details',
                      style: AppTypography.screenTitle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  IconButton(
                    icon: const Icon(Symbols.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: l10n?.close ?? 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Image Section
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickCoverImage,
                            child: Container(
                              width: 100,
                              height: 136,
                              decoration: BoxDecoration(
                                color: c.surfaceSecondary,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.cover),
                                border: Border.all(
                                  color: _coverPath != null
                                      ? c.primary
                                      : c.outlineVariant,
                                  width: _coverPath != null ? 2 : 1,
                                ),
                              ),
                              child: _coverPath != null
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.cover - 1,
                                          ),
                                          child: Image.file(
                                            File(_coverPath!),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Center(
                                              child: Icon(
                                                Symbols.broken_image,
                                                size: 28,
                                                color: c.error,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => setState(
                                              () => _coverPath = null,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Color(0x99000000),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Symbols.close,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Symbols.add_photo_alternate,
                                          size: 32,
                                          color: c.primary,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          l10n?.addCover ?? 'Cover Image',
                                          style: AppTypography.labelSm
                                              .copyWith(color: c.primary),
                                        ),
                                        Text(
                                          l10n?.tapToUpload ?? 'Tap to upload',
                                          style: AppTypography.bodySm.copyWith(
                                            fontSize: 10,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextButton.icon(
                            onPressed: _pickCoverImage,
                            icon: Icon(
                              _coverPath != null
                                  ? Symbols.cached
                                  : Symbols.upload,
                              size: 16,
                            ),
                            label: Text(
                              _coverPath != null
                                  ? (l10n?.changeCover ?? 'Change Cover')
                                  : (l10n?.chooseCoverImage ?? 'Upload Cover Image'),
                              style: AppTypography.labelSm,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Title Field
                    Text('${l10n?.novelTitle ?? "Title"} *', style: AppTypography.labelMd),
                    const SizedBox(height: AppSpacing.xs),
                    NvTextField(
                      controller: _titleController,
                      hintText: l10n?.enterNovelTitle ?? 'Novel title',
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Subtitle Field
                    Text(l10n?.subtitleOptional ?? 'Subtitle (Optional)', style: AppTypography.labelMd),
                    const SizedBox(height: AppSpacing.xs),
                    NvTextField(
                      controller: _subtitleController,
                      hintText: 'e.g. Volume 1',
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Synopsis / Description Field
                    Text(l10n?.synopsisPremise ?? 'Synopsis / Description', style: AppTypography.labelMd),
                    const SizedBox(height: AppSpacing.xs),
                    NvTextField(
                      controller: _synopsisController,
                      hintText: l10n?.synopsisHint ?? 'Brief summary or premise of the novel',
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Genre Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n?.genre ?? 'Genre', style: AppTypography.labelMd),
                        TextButton.icon(
                          onPressed: _showAddCustomGenreDialog,
                          icon: const Icon(Symbols.add, size: 16),
                          label: Text(l10n?.addGenre ?? 'Add Genre'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        ..._genres.map((genre) {
                          final isSelected = _selectedGenres.contains(genre);
                          return FilterChip(
                            label: Text(genre),
                            selected: isSelected,
                            showCheckmark: false,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedGenres.add(genre);
                                } else {
                                  _selectedGenres.remove(genre);
                                }
                              });
                            },
                            selectedColor: c.primarySoft,
                            backgroundColor: c.surfaceSecondary,
                            labelStyle: isSelected
                                ? AppTypography.labelSm
                                    .copyWith(color: c.primary)
                                : AppTypography.bodySm,
                          );
                        }),
                        ActionChip(
                          avatar: Icon(Symbols.add, size: 16, color: c.primary),
                          label: Text(l10n?.customGenre ?? 'Custom'),
                          onPressed: _showAddCustomGenreDialog,
                          backgroundColor: c.surfaceSecondary,
                          side: BorderSide(color: c.outlineVariant),
                          labelStyle:
                              AppTypography.labelSm.copyWith(color: c.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Status Section
                    Text(l10n?.initialStatus ?? 'Status', style: AppTypography.labelMd),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: NovelStatus.values.map((status) {
                        final isSelected = _selectedStatus == status;
                        return ChoiceChip(
                          label: Text(status.getLabel(l10n)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedStatus = status);
                            }
                          },
                          selectedColor: c.primarySoft,
                          backgroundColor: c.surfaceSecondary,
                          labelStyle: isSelected
                              ? AppTypography.labelSm
                                  .copyWith(color: c.primary)
                              : AppTypography.bodySm,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: c.outlineVariant,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: NvButton(
                      label: l10n?.cancel ?? 'Cancel',
                      variant: NvButtonVariant.tonal,
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: NvButton(
                      label: l10n?.saveChanges ?? 'Save Changes',
                      variant: NvButtonVariant.primary,
                      icon: Symbols.check,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _handleSave,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
