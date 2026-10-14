import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/constants/external_links.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';

class SupportUsSheet extends StatelessWidget {
  const SupportUsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SupportUsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    final platforms = [
      _PlatformData(
        name: 'Saweria',
        description: isIndo
            ? 'Dukungan via QRIS, GoPay, OVO, Dana, LinkAja, ShopeePay'
            : 'Support via QRIS, GoPay, OVO, Dana, LinkAja, ShopeePay',
        badge: 'Indonesia',
        url: AppExternalLinks.saweria,
        brandColor: const Color(0xFFFAAE2B),
        brandSvg: AppBrandSvgs.saweria,
        brandIcon: Symbols.payments,
      ),
      _PlatformData(
        name: 'SociaBuzz',
        description: isIndo
            ? 'Dukungan via QRIS, e-Wallet, PayPal, dan Kartu Kredit'
            : 'Support via QRIS, e-Wallets, PayPal, and Credit Cards',
        badge: isIndo ? 'ID & Global' : 'ID & Global',
        url: AppExternalLinks.sociaBuzz,
        brandColor: const Color(0xFF00B14F),
        brandSvg: AppBrandSvgs.sociaBuzz,
        brandIcon: Symbols.card_giftcard,
      ),
      _PlatformData(
        name: 'Buy Me a Coffee',
        description: isIndo
            ? 'Donasi sekali dan membership via Kartu, Apple/Google Pay'
            : 'One-time donations and memberships via Cards, Apple/Google Pay',
        badge: 'Global',
        url: AppExternalLinks.buyMeACoffee,
        brandColor: const Color(0xFFE5A823),
        brandSvg: AppBrandSvgs.buyMeACoffee,
        brandIcon: Symbols.local_cafe,
      ),
      _PlatformData(
        name: 'GitHub',
        description: isIndo
            ? 'Beri bintang pada repositori, fork kode, atau laporkan kendala'
            : 'Star our repository, fork the code, or report issues',
        badge: 'Open Source',
        url: AppExternalLinks.github,
        brandColor: c.textPrimary,
        brandSvg: AppBrandSvgs.github,
        brandIcon: Symbols.code,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5E5B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.tile),
                    ),
                    child: const Icon(
                      Symbols.favorite,
                      color: Color(0xFFFF5E5B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.supportUs ?? 'Support Us',
                          style: AppTypography.screenTitle.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isIndo
                              ? 'Bantu Novellie terus berkembang dan gratis bagi semua penulis'
                              : 'Keep Novellie growing and free for all writers',
                          style: AppTypography.bodySm.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Symbols.close, color: c.textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isIndo
                    ? 'Novellie adalah studio penulisan novel offline-first independen. Jika aplikasi ini membantu Anda berkarya, dukung pengembangan kami melalui platform berikut:'
                    : 'Novellie is an independent, offline-first novel writing studio. If it helps you craft stories, consider supporting our development through any of the platforms below:',
                style: AppTypography.body.copyWith(
                  color: c.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final platform in platforms) ...[
                _PlatformCard(platform: platform),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformData {
  final String name;
  final String description;
  final String badge;
  final String url;
  final Color brandColor;
  final String brandSvg;
  final IconData brandIcon;

  const _PlatformData({
    required this.name,
    required this.description,
    required this.badge,
    required this.url,
    required this.brandColor,
    required this.brandSvg,
    required this.brandIcon,
  });
}

class _PlatformCard extends StatelessWidget {
  final _PlatformData platform;

  const _PlatformCard({required this.platform});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: c.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: c.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => AppExternalLinks.openUrl(context, platform.url),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: platform.brandColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.inset),
                    border: Border.all(
                      color: platform.brandColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: SvgPicture.string(
                      platform.brandSvg,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        platform.brandColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              platform.name,
                              style: AppTypography.cardTitle.copyWith(
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: c.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              platform.badge,
                              style: AppTypography.labelSm.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        platform.description,
                        style: AppTypography.bodySm.copyWith(
                          color: c.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  tooltip: 'Copy link',
                  icon: Icon(
                    Symbols.content_copy,
                    size: 18,
                    color: c.textSecondary,
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: platform.url));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied ${platform.name} link: ${platform.url}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                Icon(
                  Symbols.open_in_new,
                  size: 18,
                  color: c.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
