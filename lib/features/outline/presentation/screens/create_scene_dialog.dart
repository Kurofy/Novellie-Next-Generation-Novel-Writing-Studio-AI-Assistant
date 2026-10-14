import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/planning_providers.dart';
import '../../domain/models/planning_models.dart';

class CreateSceneDialog extends ConsumerStatefulWidget {
  final String novelId;
  final String? chapterId;
  final SceneCardModel? sceneToEdit;

  const CreateSceneDialog({
    super.key,
    required this.novelId,
    this.chapterId,
    this.sceneToEdit,
  });

  static Future<SceneCardModel?> show(
    BuildContext context,
    String novelId, {
    String? chapterId,
    SceneCardModel? sceneToEdit,
  }) {
    final c = context.colors;
    return showModalBottomSheet<SceneCardModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => CreateSceneDialog(
        novelId: novelId,
        chapterId: chapterId,
        sceneToEdit: sceneToEdit,
      ),
    );
  }

  @override
  ConsumerState<CreateSceneDialog> createState() => _CreateSceneDialogState();
}

class _CreateSceneDialogState extends ConsumerState<CreateSceneDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _purposeController;
  late final TextEditingController _questionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.sceneToEdit?.title ?? '');
    _purposeController =
        TextEditingController(text: widget.sceneToEdit?.purpose ?? '');
    _questionController =
        TextEditingController(text: widget.sceneToEdit?.dramaticQuestion ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _purposeController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final SceneCardModel scene;
      if (widget.sceneToEdit != null) {
        scene = await ref.read(planningActionsControllerProvider).updateScene(
              sceneId: widget.sceneToEdit!.id,
              title: title,
              purpose: _purposeController.text.trim().isNotEmpty
                  ? _purposeController.text.trim()
                  : null,
              dramaticQuestion: _questionController.text.trim().isNotEmpty
                  ? _questionController.text.trim()
                  : null,
            );
      } else {
        scene = await ref.read(planningActionsControllerProvider).createScene(
              novelId: widget.novelId,
              chapterId: widget.chapterId,
              title: title,
              purpose: _purposeController.text.trim().isNotEmpty
                  ? _purposeController.text.trim()
                  : null,
              dramaticQuestion: _questionController.text.trim().isNotEmpty
                  ? _questionController.text.trim()
                  : null,
            );
      }

      if (mounted) {
        Navigator.of(context).pop(scene);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.sceneToEdit != null
                  ? 'Failed to update scene card: $e'
                  : 'Failed to create scene card: $e',
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
    final isEditing = widget.sceneToEdit != null;
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
                      isEditing
                          ? (isIndo ? 'Edit Kartu Adegan' : 'Edit Scene Card')
                          : (isIndo ? 'Kartu Adegan Baru' : 'New Scene Card'),
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

              Text(isIndo ? 'Judul Adegan *' : 'Scene Title *', style: AppTypography.labelMd),
              const SizedBox(height: AppSpacing.sm),
              NvTextField(
                controller: _titleController,
                hintText: isIndo ? 'mis. Konfrontasi di dermaga' : 'e.g. Confrontation at the docks',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(isIndo ? 'Tujuan Naratif' : 'Narrative Purpose', style: AppTypography.labelMd),
              const SizedBox(height: AppSpacing.sm),
              NvTextField(
                controller: _purposeController,
                hintText: isIndo
                    ? 'Beat cerita atau pengungkapan karakter apa yang terjadi?'
                    : 'What story beats or character reveals occur?',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(isIndo ? 'Pertanyaan Dramatis' : 'Dramatic Question', style: AppTypography.labelMd),
              const SizedBox(height: AppSpacing.sm),
              NvTextField(
                controller: _questionController,
                hintText: isIndo
                    ? 'Apakah protagonis akan lolos dari penyergapan?'
                    : 'Will the protagonist escape the ambush?',
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.x2),

              NvButton(
                label: isEditing
                    ? (l10n?.saveChanges ?? 'Save Changes')
                    : (isIndo ? 'Buat Kartu Adegan' : 'Create Scene Card'),
                variant: NvButtonVariant.primary,
                icon: Symbols.check,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
