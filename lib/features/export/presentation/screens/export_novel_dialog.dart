import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../manuscript/application/manuscript_providers.dart';
import '../../../manuscript/domain/models/manuscript_models.dart';
import '../../../novels/domain/models/novel_model.dart';
import '../../application/export_providers.dart';
import '../../domain/models/export_format.dart';

class ExportNovelDialog extends ConsumerStatefulWidget {
  final NovelModel novel;

  const ExportNovelDialog({
    super.key,
    required this.novel,
  });

  static Future<void> show(BuildContext context, NovelModel novel) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExportNovelDialog(novel: novel),
    );
  }

  @override
  ConsumerState<ExportNovelDialog> createState() => _ExportNovelDialogState();
}

class _ExportNovelDialogState extends ConsumerState<ExportNovelDialog> {
  ExportFormat _selectedFormat = ExportFormat.markdown;
  bool _isLoading = true;
  String _generatedContent = '';
  List<ChapterModel> _chapters = [];
  String? _savedPath;

  @override
  void initState() {
    super.initState();
    _loadAndGenerate();
  }

  Future<void> _loadAndGenerate() async {
    setState(() => _isLoading = true);
    final repo = ref.read(manuscriptRepositoryProvider);
    final chapters = await repo.watchChapters(widget.novel.id).first;

    final contents = <String, ChapterContentModel>{};
    for (final ch in chapters) {
      contents[ch.id] = await repo.getChapterContent(ch.id);
    }

    final exporter = ref.read(novelExportServiceProvider);
    final result = exporter.generateExport(
      novel: widget.novel,
      chapters: chapters,
      chapterContents: contents,
      format: _selectedFormat,
    );

    if (mounted) {
      setState(() {
        _chapters = chapters;
        _generatedContent = result;
        _isLoading = false;
      });
    }
  }

  void _onFormatChanged(ExportFormat format) {
    setState(() => _selectedFormat = format);
    _loadAndGenerate();
  }

  Future<void> _handleCopyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _generatedContent));
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.localeName == 'id'
                ? 'Ekspor naskah berhasil disalin ke papan klip!'
                : 'Copied novel export to clipboard!',
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSaveToFile() async {
    setState(() => _isLoading = true);
    final exporter = ref.read(novelExportServiceProvider);
    final file = await exporter.saveExportFile(
      novel: widget.novel,
      content: _generatedContent,
      format: _selectedFormat,
    );

    if (mounted) {
      setState(() {
        _savedPath = file.path;
        _isLoading = false;
      });
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.localeName == 'id'
                ? 'Ekspor tersimpan di: ${file.path}'
                : 'Export saved to: ${file.path}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndonesian = l10n?.localeName == 'id';

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screenMargin(context),
        right: AppSpacing.screenMargin(context),
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    l10n?.exportManuscript ?? 'Export Manuscript',
                    style: AppTypography.screenTitle,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Symbols.close),
                  tooltip: l10n?.close ?? 'Close',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isIndonesian
                  ? 'Ekspor "${widget.novel.title}" untuk penerbitan, cadangan, atau berbagi offline.'
                  : 'Export "${widget.novel.title}" for publishing, backups, or offline sharing.',
              style: AppTypography.bodySm,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Format Selector Chips
            Text(l10n?.format ?? 'Format', style: AppTypography.labelMd),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: ExportFormat.values.map((fmt) {
                final isSelected = fmt == _selectedFormat;
                return ChoiceChip(
                  label: Text(fmt.label),
                  selected: isSelected,
                  onSelected: (_) => _onFormatChanged(fmt),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Statistics Info
            NvCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${_chapters.length}',
                        style: AppTypography.screenTitle.copyWith(
                          color: c.primary,
                        ),
                      ),
                      Text(l10n?.chapters ?? 'Chapters', style: AppTypography.bodySm),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${widget.novel.totalWordCount}',
                        style: AppTypography.screenTitle.copyWith(
                          color: c.primary,
                        ),
                      ),
                      Text(l10n?.totalWords ?? 'Total Words', style: AppTypography.bodySm),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '.${_selectedFormat.extension}',
                        style: AppTypography.screenTitle.copyWith(
                          color: c.primary,
                        ),
                      ),
                      Text(l10n?.extension ?? 'Extension', style: AppTypography.bodySm),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (_savedPath != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: c.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: c.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Symbols.check_circle, color: c.success, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${isIndonesian ? 'Tersimpan' : 'Saved'}: $_savedPath',
                        style: AppTypography.bodySm.copyWith(color: c.success),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Action Buttons
            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: NvButton.secondary(
                      label: l10n?.copyToClipboard ?? 'Copy to Clipboard',
                      onPressed: _handleCopyToClipboard,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: NvButton.primary(
                      label: l10n?.saveFile ?? 'Save File',
                      onPressed: _handleSaveToFile,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
