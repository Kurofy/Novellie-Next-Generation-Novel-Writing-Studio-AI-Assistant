import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';

class FamilyTreeLegendWidget extends StatefulWidget {
  const FamilyTreeLegendWidget({super.key});

  @override
  State<FamilyTreeLegendWidget> createState() => _FamilyTreeLegendWidgetState();
}

class _FamilyTreeLegendWidgetState extends State<FamilyTreeLegendWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    if (!_isExpanded) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = true),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: c.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: c.outlineVariant.withValues(alpha: 0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Symbols.info, size: 15, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Text(
                  isIndo ? 'Legenda Silsilah' : 'Lineage Legend',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Symbols.expand_more, size: 14, color: c.textSecondary),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: const Color(0xFFD97706).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Row(
            children: [
              const Icon(
                Symbols.family_restroom,
                size: 16,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 6),
              Text(
                isIndo ? 'Jenis Hubungan Silsilah' : 'Lineage Relationship Types',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => setState(() => _isExpanded = false),
                child: const Icon(Symbols.close, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Legend Items
          _legendItem(
            color: const Color(0xFFE11D48),
            label: isIndo ? 'Pasangan / Suami/Istri' : 'Spouse / Partner',
            symbol: '══',
          ),
          _legendItem(
            color: const Color(0xFFD97706),
            label: isIndo ? 'Anak / Keturunan' : 'Child / Descendant',
            symbol: '──►',
          ),
          _legendItem(
            color: const Color(0xFF2563EB),
            label: isIndo ? 'Orang Tua / Leluhur' : 'Parent / Ancestor',
            symbol: '▲──',
          ),
          _legendItem(
            color: const Color(0xFF059669),
            label: isIndo ? 'Saudara Kandung' : 'Sibling',
            symbol: '══',
          ),
          _legendItem(
            color: const Color(0xFF9333EA),
            label: isIndo ? 'Anak Angkat / Asuh' : 'Adopted / Foster',
            symbol: '┄┄',
          ),

          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Symbols.lightbulb, size: 12, color: c.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isIndo
                      ? 'Tarik kartu untuk menata. Pilih kartu untuk menambah kerabat.'
                      : 'Drag cards to arrange. Select a card to add relatives.',
                  style: TextStyle(
                    fontSize: 10,
                    color: c.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    required String symbol,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 24,
            alignment: Alignment.center,
            child: Text(
              symbol,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
