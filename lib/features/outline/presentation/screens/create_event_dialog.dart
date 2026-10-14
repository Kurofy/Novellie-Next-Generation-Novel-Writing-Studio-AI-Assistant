import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/planning_providers.dart';
import '../../domain/models/planning_models.dart';

class CreateEventDialog extends ConsumerStatefulWidget {
  final String novelId;
  final TimelineEventModel? eventToEdit;

  const CreateEventDialog({
    super.key,
    required this.novelId,
    this.eventToEdit,
  });

  static Future<TimelineEventModel?> show(
    BuildContext context,
    String novelId, {
    TimelineEventModel? eventToEdit,
  }) {
    final c = context.colors;
    return showModalBottomSheet<TimelineEventModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => CreateEventDialog(
        novelId: novelId,
        eventToEdit: eventToEdit,
      ),
    );
  }

  @override
  ConsumerState<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends ConsumerState<CreateEventDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _dateController;
  late final TextEditingController _descriptionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.eventToEdit?.title ?? '');
    _dateController =
        TextEditingController(text: widget.eventToEdit?.dateText ?? '');
    _descriptionController =
        TextEditingController(text: widget.eventToEdit?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final TimelineEventModel event;
      if (widget.eventToEdit != null) {
        event = await ref.read(planningActionsControllerProvider).updateEvent(
              eventId: widget.eventToEdit!.id,
              title: title,
              dateText: _dateController.text.trim().isNotEmpty
                  ? _dateController.text.trim()
                  : null,
              description: _descriptionController.text.trim().isNotEmpty
                  ? _descriptionController.text.trim()
                  : null,
            );
      } else {
        event = await ref.read(planningActionsControllerProvider).createEvent(
              novelId: widget.novelId,
              title: title,
              dateText: _dateController.text.trim().isNotEmpty
                  ? _dateController.text.trim()
                  : null,
              description: _descriptionController.text.trim().isNotEmpty
                  ? _descriptionController.text.trim()
                  : null,
            );
      }

      if (mounted) {
        Navigator.of(context).pop(event);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.eventToEdit != null
                  ? 'Failed to update event: $e'
                  : 'Failed to create event: $e',
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
    final isEditing = widget.eventToEdit != null;
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
                          ? (isIndo ? 'Edit Peristiwa Garis Waktu' : 'Edit Timeline Event')
                          : (isIndo ? 'Peristiwa Garis Waktu Baru' : 'New Timeline Event'),
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

              Text(isIndo ? 'Judul Peristiwa *' : 'Event Title *', style: AppTypography.labelMd),
              const SizedBox(height: AppSpacing.sm),
              NvTextField(
                controller: _titleController,
                hintText: isIndo ? 'mis. Raja Gugur, Dewan Dipanggil' : 'e.g. The King Dies, Council Summoned',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                isIndo ? 'Tanggal Kronologis / Penanda' : 'Chronological Date / Marker',
                style: AppTypography.labelMd,
              ),
              const SizedBox(height: AppSpacing.sm),
              NvTextField(
                controller: _dateController,
                hintText: isIndo ? 'mis. Tahun 412, Musim Gugur, Hari 14' : 'e.g. Year 412, Autumn, Day 14',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(isIndo ? 'Deskripsi Peristiwa' : 'Event Description', style: AppTypography.labelMd),
              const SizedBox(height: AppSpacing.sm),
              NvTextField(
                controller: _descriptionController,
                hintText: isIndo ? 'Apa yang terjadi selama peristiwa ini?' : 'What occurs during this event?',
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.x2),

              NvButton(
                label: isEditing
                    ? (l10n?.saveChanges ?? 'Save Changes')
                    : (isIndo ? 'Buat Peristiwa' : 'Create Event'),
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
