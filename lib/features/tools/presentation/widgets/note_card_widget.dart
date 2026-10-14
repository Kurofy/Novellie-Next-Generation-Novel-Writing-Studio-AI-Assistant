import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/writer_notes_providers.dart';
import '../../domain/models/writer_note_model.dart';

class NoteCardWidget extends ConsumerWidget {
  final WriterNote note;
  final VoidCallback onTap;
  final void Function(NoteColorPreset preset)? onColorChanged;

  const NoteCardWidget({
    super.key,
    required this.note,
    required this.onTap,
    this.onColorChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preset = note.colorPreset;

    final bgColor = preset == NoteColorPreset.defaultColor
        ? c.surface
        : preset.resolveBackground(isDark);

    final borderColor = preset == NoteColorPreset.defaultColor
        ? c.outlineVariant.withValues(alpha: 0.6)
        : preset.resolveBorder(isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: note.isPinned ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              if (note.isPinned)
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Title & Pin Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: note.title.isNotEmpty
                        ? Text(
                            note.title,
                            style: AppTypography.cardTitle.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: c.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text(
                            isIndo ? 'Catatan Tanpa Judul' : 'Untitled Note',
                            style: TextStyle(
                              fontSize: 13,
                              color: c.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                  ),
                  const SizedBox(width: 4),

                  // Pin/Unpin Button
                  InkWell(
                    onTap: () {
                      ref.read(writerNotesProvider.notifier).togglePin(note.id);
                    },
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        Symbols.push_pin,
                        fill: note.isPinned ? 1.0 : 0.0,
                        size: 18,
                        color: note.isPinned
                            ? const Color(0xFFD97706)
                            : c.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Content: Checklist preview or Text snippet
              if (note.isChecklist) ...[
                _buildChecklistPreview(context, ref, c, isIndo),
              ] else if (note.content.isNotEmpty) ...[
                Text(
                  note.content,
                  style: AppTypography.bodySm.copyWith(
                    color: c.textSecondary,
                    height: 1.35,
                    fontSize: 12.5,
                  ),
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Label Chips & Novel Tag
              if (note.labels.isNotEmpty || note.novelTitle != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (note.novelTitle != null && note.novelTitle!.isNotEmpty)
                      _buildPillTag(
                        icon: Symbols.menu_book,
                        label: note.novelTitle!,
                        color: const Color(0xFFD97706),
                        c: c,
                      ),
                    ...note.labels.map(
                      (label) => _buildPillTag(
                        icon: Symbols.label,
                        label: label,
                        color: const Color(0xFF2563EB),
                        c: c,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),

              // Footer: Timestamp & Quick Action Buttons
              Row(
                children: [
                  Text(
                    _formatTime(note.updatedAt, isIndo),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: c.textMuted,
                    ),
                  ),
                  const Spacer(),

                  // Quick Color Palette Icon Button
                  PopupMenuButton<NoteColorPreset>(
                    tooltip: isIndo ? 'Warna Catatan' : 'Note Color',
                    icon: Icon(
                      Symbols.palette,
                      size: 16,
                      color: c.textSecondary.withValues(alpha: 0.8),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (colorPreset) {
                      ref
                          .read(writerNotesProvider.notifier)
                          .updateNoteColor(note.id, colorPreset.id);
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem<NoteColorPreset>(
                        enabled: false,
                        child: Text(
                          isIndo ? 'Pilih Warna' : 'Choose Color',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      ...NoteColorPreset.values.map(
                        (preset) => PopupMenuItem<NoteColorPreset>(
                          value: preset,
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: preset.resolveBackground(isDark),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: preset.resolveBorder(isDark),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(preset.localizedName(isIndo), style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 4),

                  // Archive/Unarchive Icon Button
                  IconButton(
                    icon: Icon(
                      note.isArchived ? Symbols.unarchive : Symbols.archive,
                      size: 16,
                      color: c.textSecondary.withValues(alpha: 0.8),
                    ),
                    tooltip: note.isArchived
                        ? (isIndo ? 'Batalkan Arsip' : 'Unarchive')
                        : (isIndo ? 'Arsipkan' : 'Archive'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      ref
                          .read(writerNotesProvider.notifier)
                          .toggleArchive(note.id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistPreview(
    BuildContext context,
    WidgetRef ref,
    AppColors c,
    bool isIndo,
  ) {
    final displayItems = note.checklist.take(5).toList();
    final remainingCount = note.checklist.length - 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayItems.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: InkWell(
              onTap: () {
                ref
                    .read(writerNotesProvider.notifier)
                    .toggleChecklistItem(note.id, item.id);
              },
              child: Row(
                children: [
                  Icon(
                    item.isDone
                        ? Symbols.check_box
                        : Symbols.check_box_outline_blank,
                    size: 16,
                    color: item.isDone
                        ? const Color(0xFF10B981)
                        : c.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.text,
                      style: TextStyle(
                        fontSize: 12,
                        color: item.isDone ? c.textMuted : c.textPrimary,
                        decoration: item.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (remainingCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 22),
            child: Text(
              isIndo ? '+ $remainingCount item lagi' : '+ $remainingCount more items',
              style: TextStyle(
                fontSize: 11,
                color: c.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPillTag({
    required IconData icon,
    required String label,
    required Color color,
    required AppColors c,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date, bool isIndo) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return isIndo ? 'Baru saja' : 'Just now';
    if (diff.inMinutes < 60) return isIndo ? '${diff.inMinutes} mnt lalu' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isIndo ? '${diff.inHours} jam lalu' : '${diff.inHours}h ago';
    if (diff.inDays < 7) return isIndo ? '${diff.inDays} hr lalu' : '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}
