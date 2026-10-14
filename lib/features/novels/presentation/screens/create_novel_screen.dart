import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/novel_providers.dart';
import '../../domain/models/novel_model.dart';

const _suggestedGenres = [
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

class CreateNovelScreen extends ConsumerStatefulWidget {
  const CreateNovelScreen({super.key});

  @override
  ConsumerState<CreateNovelScreen> createState() => _CreateNovelScreenState();
}

class _CreateNovelScreenState extends ConsumerState<CreateNovelScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Step 1 Controllers & State
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _authorController = TextEditingController();
  final Set<String> _selectedGenres = {'Fantasy'};
  final List<String> _genres = List.from(_suggestedGenres);
  String? _coverPath;
  final ImagePicker _imagePicker = ImagePicker();

  // Step 2 Controllers
  final _descriptionController = TextEditingController();
  NovelStatus _selectedStatus = NovelStatus.idea;
  final _wordTargetController = TextEditingController(text: '50000');
  final _chapterTargetController = TextEditingController(text: '2500');

  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _wordTargetController.dispose();
    _chapterTargetController.dispose();
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

  Future<void> _handleCreate() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _isCreating = true);

    try {
      final novel = await ref.read(novelActionsControllerProvider).createNovel(
            title: _titleController.text.trim(),
            subtitle: _subtitleController.text.trim().isNotEmpty
                ? _subtitleController.text.trim()
                : null,
            author: _authorController.text.trim().isNotEmpty
                ? _authorController.text.trim()
                : null,
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            genre: _selectedGenres.isEmpty
                ? 'General'
                : _selectedGenres.join(', '),
            status: _selectedStatus,
            novelWordTarget: int.tryParse(_wordTargetController.text.trim()),
            chapterWordTarget:
                int.tryParse(_chapterTargetController.text.trim()),
            coverPath: _coverPath,
          );

      if (mounted) {
        context.go(Routes.novelWorkspace(novel.id));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create novel: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: NvAppBar(
        title: _currentStep == 0 ? l10n.createNovel : l10n.premiseAndGoals,
        leading: IconButton(
          icon: const Icon(Symbols.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Indicator Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _currentStep >= 1
                            ? c.primary
                            : c.outlineVariant,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: _currentStep == 0
                      ? _buildStep1Identity(c, l10n)
                      : _buildStep2Premise(c, l10n),
                ),
              ),
            ),

            // Bottom Navigation Actions
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
                  if (_currentStep == 1) ...[
                    Expanded(
                      child: NvButton(
                        label: l10n.back,
                        variant: NvButtonVariant.tonal,
                        onPressed: _isCreating
                            ? null
                            : () => setState(() => _currentStep = 0),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    flex: _currentStep == 1 ? 2 : 1,
                    child: NvButton(
                      label: _currentStep == 0
                          ? l10n.nextPremiseAndGoals
                          : l10n.createNovel,
                      variant: NvButtonVariant.primary,
                      icon: _currentStep == 0
                          ? Symbols.arrow_forward
                          : Symbols.check,
                      isLoading: _isCreating,
                      onPressed: _isCreating
                          ? null
                          : () {
                              if (_currentStep == 0) {
                                if (_titleController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text(l10n.pleaseEnterNovelTitle),
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _currentStep = 1);
                              } else {
                                _handleCreate();
                              }
                            },
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

  Widget _buildStep1Identity(AppColors c, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.identityAndDetails,
          style: AppTypography.screenTitle,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.identityAndDetailsDesc,
          style: AppTypography.bodySm,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Cover Image Uploader & Preview
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickCoverImage,
                child: Container(
                  width: 108,
                  height: 148,
                  decoration: BoxDecoration(
                    color: c.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.cover),
                    border: Border.all(
                      color: _coverPath != null ? c.primary : c.outlineVariant,
                      width: _coverPath != null ? 2 : 1,
                    ),
                  ),
                  child: _coverPath != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.cover - 1),
                              child: Image.file(
                                File(_coverPath!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(
                                    Symbols.broken_image,
                                    size: 32,
                                    color: c.error,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => setState(() => _coverPath = null),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Symbols.add_photo_alternate,
                              size: 32,
                              color: c.primary,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.addCover,
                              style: AppTypography.labelSm
                                  .copyWith(color: c.primary),
                            ),
                            Text(
                              l10n.tapToUpload,
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
                  _coverPath != null ? Symbols.cached : Symbols.upload,
                  size: 16,
                ),
                label: Text(
                  _coverPath != null ? l10n.changeCover : l10n.chooseCoverImage,
                  style: AppTypography.labelSm,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Title Input
        Text('${l10n.novelTitle} *', style: AppTypography.labelMd),
        const SizedBox(height: AppSpacing.sm),
        NvTextField(
          controller: _titleController,
          hintText: l10n.enterNovelTitle,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Subtitle Input
        Text(
          l10n.subtitleOptional,
          style: AppTypography.labelMd,
        ),
        const SizedBox(height: AppSpacing.sm),
        NvTextField(
          controller: _subtitleController,
          hintText: 'e.g. Book 1 of The Chronicles',
        ),
        const SizedBox(height: AppSpacing.lg),

        // Author Input
        Text(l10n.authorOptional, style: AppTypography.labelMd),
        const SizedBox(height: AppSpacing.sm),
        NvTextField(
          controller: _authorController,
          hintText: 'Your pen name',
        ),
        const SizedBox(height: AppSpacing.x2),

        // Genre Picker
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.genre, style: AppTypography.labelMd),
            TextButton.icon(
              onPressed: _showAddCustomGenreDialog,
              icon: const Icon(Symbols.add, size: 16),
              label: Text(l10n.addGenre),
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
                    ? AppTypography.labelSm.copyWith(color: c.primary)
                    : AppTypography.bodySm,
              );
            }),
            ActionChip(
              avatar: Icon(Symbols.add, size: 16, color: c.primary),
              label: Text(l10n.customGenre),
              onPressed: _showAddCustomGenreDialog,
              backgroundColor: c.surfaceSecondary,
              side: BorderSide(color: c.outlineVariant),
              labelStyle: AppTypography.labelSm.copyWith(color: c.primary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2Premise(AppColors c, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.premiseAndGoals,
          style: AppTypography.screenTitle,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.premiseAndGoalsDesc,
          style: AppTypography.bodySm,
        ),
        const SizedBox(height: AppSpacing.x2),

        // Description / Premise
        Text(l10n.synopsisPremise, style: AppTypography.labelMd),
        const SizedBox(height: AppSpacing.sm),
        NvTextField(
          controller: _descriptionController,
          hintText: l10n.synopsisHint,
          maxLines: 4,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Status Selection
        Text(l10n.initialStatus, style: AppTypography.labelMd),
        const SizedBox(height: AppSpacing.sm),
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
                  ? AppTypography.labelSm.copyWith(color: c.primary)
                  : AppTypography.bodySm,
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Target Word Count
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.novelTargetWords,
                    style: AppTypography.labelMd,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  NvTextField(
                    controller: _wordTargetController,
                    hintText: 'e.g. 50000',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chapterTargetWords,
                    style: AppTypography.labelMd,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  NvTextField(
                    controller: _chapterTargetController,
                    hintText: 'e.g. 2500',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
