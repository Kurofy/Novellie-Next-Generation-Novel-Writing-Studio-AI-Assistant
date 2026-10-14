import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/family_tree_models.dart';

class FamilyTreeSummaryDialog extends StatelessWidget {
  final FamilyTree tree;
  final String novelTitle;

  const FamilyTreeSummaryDialog({
    super.key,
    required this.tree,
    required this.novelTitle,
  });

  static void show(
    BuildContext context, {
    required FamilyTree tree,
    required String novelTitle,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => FamilyTreeSummaryDialog(
        tree: tree,
        novelTitle: novelTitle,
      ),
    );
  }

  String _generateTextSummary([bool isIndo = false]) {
    final buffer = StringBuffer();
    buffer.writeln('=== $novelTitle: ${tree.name} ===');
    if (tree.description != null && tree.description!.isNotEmpty) {
      buffer.writeln('${tree.description}\n');
    }

    final nodeMap = {for (final n in tree.nodes) n.id: n};

    // Group by generation
    final genMap = <int, List<FamilyTreeNode>>{};
    for (final node in tree.nodes) {
      genMap.putIfAbsent(node.generation, () => []).add(node);
    }

    final sortedGens = genMap.keys.toList()..sort();
    for (final gen in sortedGens) {
      final genLabel = gen == 0
          ? (isIndo
              ? 'Generasi 0 (Pendiri / Leluhur Utama)'
              : 'Generation 0 (Founder / Progenitor)')
          : (gen < 0
              ? (isIndo
                  ? 'Generasi $gen (Leluhur)'
                  : 'Generation $gen (Ancestors)')
              : (isIndo
                  ? 'Generasi +$gen (Keturunan)'
                  : 'Generation +$gen (Descendants)'));
      buffer.writeln('[$genLabel]');
      for (final node in genMap[gen]!) {
        buffer.writeln(
            '• ${node.name}${node.titleOrRole != null ? " (${node.titleOrRole})" : ""}${node.years != null ? " [${node.years}]" : ""}',);

        // Outgoing/Incoming connections
        final edges = tree.edges
            .where((e) => e.fromNodeId == node.id || e.toNodeId == node.id)
            .toList();

        for (final edge in edges) {
          final isFrom = edge.fromNodeId == node.id;
          final otherId = isFrom ? edge.toNodeId : edge.fromNodeId;
          final otherNode = nodeMap[otherId];
          if (otherNode != null) {
            final relText = edge.localizedDisplayLabel(isIndo);
            buffer.writeln('   ↳ $relText: ${otherNode.name}');
          }
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final summaryText = _generateTextSummary(isIndo);

    // Stats
    final genSet = tree.nodes.map((n) => n.generation).toSet();
    final aliveCount =
        tree.nodes.where((n) => n.status?.toLowerCase() == 'alive').length;

    return Dialog(
      backgroundColor: c.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Symbols.summarize,
                      color: Color(0xFFD97706),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isIndo
                              ? 'Ringkasan ${tree.name}'
                              : '${tree.name} Summary',
                          style: AppTypography.screenTitle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          novelTitle,
                          style: AppTypography.labelSm
                              .copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Quick metric pills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _metricPill(
                    isIndo
                        ? '${tree.nodes.length} Anggota'
                        : '${tree.nodes.length} Members',
                    Symbols.group,
                    c,
                  ),
                  _metricPill(
                    isIndo
                        ? '${genSet.length} Generasi'
                        : '${genSet.length} Generations',
                    Symbols.family_restroom,
                    c,
                  ),
                  _metricPill(
                    isIndo
                        ? '${tree.edges.length} Tautan Silsilah'
                        : '${tree.edges.length} Lineage Links',
                    Symbols.account_tree,
                    c,
                  ),
                  _metricPill(
                    isIndo ? '$aliveCount Masih Hidup' : '$aliveCount Living',
                    Symbols.favorite,
                    c,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Text scroll view
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: c.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      summaryText,
                      style: AppTypography.bodySm.copyWith(
                        fontFamily: 'monospace',
                        color: c.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Copy to clipboard
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Symbols.content_copy, size: 18),
                    label: Text(
                      isIndo ? 'Salin Teks Silsilah' : 'Copy Lineage Text',
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: summaryText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isIndo
                                ? 'Ringkasan silsilah berhasil disalin ke papan klip'
                                : 'Copied lineage summary to clipboard',
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(isIndo ? 'Selesai' : 'Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricPill(String label, IconData icon, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD97706).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
            color: const Color(0xFFD97706).withValues(alpha: 0.3),),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFD97706)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }
}
