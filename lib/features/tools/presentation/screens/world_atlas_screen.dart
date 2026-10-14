import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../novels/application/novel_providers.dart';
import '../../../novels/domain/models/novel_model.dart';
import '../../application/world_map_providers.dart';
import '../../domain/models/world_map_models.dart';
import '../widgets/map_pin_detail_sheet.dart';
import '../widgets/map_pin_dialog.dart';
import '../widgets/map_pin_widget.dart';

class WorldAtlasScreen extends ConsumerStatefulWidget {
  final String? initialNovelId;

  const WorldAtlasScreen({super.key, this.initialNovelId});

  @override
  ConsumerState<WorldAtlasScreen> createState() => _WorldAtlasScreenState();
}

class _WorldAtlasScreenState extends ConsumerState<WorldAtlasScreen> {
  final TransformationController _transformController =
      TransformationController();
  final TextEditingController _searchController = TextEditingController();

  MapPinCategory? _selectedCategory;
  String _searchQuery = '';
  String? _highlightedPinId;
  bool _showPinLabels = true;
  bool _isDropMarkerMode = false;

  @override
  void dispose() {
    _transformController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final matrix = _transformController.value.clone();
    matrix.scaleByDouble(1.25, 1.25, 1.0, 1.0);
    _transformController.value = matrix;
  }

  void _zoomOut() {
    final matrix = _transformController.value.clone();
    matrix.scaleByDouble(0.8, 0.8, 1.0, 1.0);
    _transformController.value = matrix;
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  Future<void> _handleUploadSvg(String novelId) async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final messenger = ScaffoldMessenger.of(context);
    final primaryColor = context.colors.primary;
    final errorColor = context.colors.error;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['svg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String? content;

        if (file.bytes != null) {
          content = utf8.decode(file.bytes!);
        } else if (file.path != null) {
          content = await File(file.path!).readAsString();
        }

        if (content != null && content.trim().isNotEmpty && mounted) {
          // Remove BOM if present
          if (content.startsWith('\uFEFF')) {
            content = content.substring(1);
          }

          await ref.read(worldMapProvider(novelId).notifier).importSvg(
                content,
                title: file.name
                    .replaceAll(RegExp(r'\.svg$', caseSensitive: false), ''),
              );

          messenger.showSnackBar(
            SnackBar(
              content: Text(isIndo
                  ? 'Peta SVG kustom berhasil diimpor: "${file.name}"'
                  : 'Imported custom SVG map: "${file.name}"'),
              backgroundColor: primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(isIndo ? 'Gagal memuat SVG: $e' : 'Failed to load SVG: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showPasteSvgDialog(String novelId) async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final controller = TextEditingController();

    final pasted = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIndo ? 'Tempel Kode Vektor SVG' : 'Paste SVG Vector Code'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isIndo
                    ? 'Tempel kode SVG mentah yang diekspor dari Azgaar’s Fantasy Map Generator atau Inkarnate:'
                    : 'Paste raw SVG code exported from Azgaar’s Fantasy Map Generator or Inkarnate:',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '<svg viewBox="0 0 1600 1000" ...> ... </svg>',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isIndo ? 'Batal' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(isIndo ? 'Terapkan Peta' : 'Apply Map'),
          ),
        ],
      ),
    );

    if (pasted != null && pasted.isNotEmpty && mounted) {
      var content = pasted;
      if (content.startsWith('\uFEFF')) {
        content = content.substring(1);
      }
      await ref.read(worldMapProvider(novelId).notifier).importSvg(content);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isIndo
                ? 'Peta vektor SVG kustom berhasil diterapkan!'
                : 'Applied custom vector SVG map!'),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteMap(String novelId) async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIndo ? 'Hapus Peta dari Atlas?' : 'Remove Map from Atlas?'),
        content: Text(
          isIndo
              ? 'Ini akan menghapus peta SVG saat ini dan kembali ke panduan awal. Anda dapat mengunggah peta baru kapan saja.'
              : 'This will remove the current SVG map and return to the onboarding setup. You can upload a new map at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isIndo ? 'Batal' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              isIndo ? 'Hapus Peta' : 'Remove Map',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(worldMapProvider(novelId).notifier).deleteMap();
      messenger.showSnackBar(
        SnackBar(
          content: Text(isIndo
              ? 'Peta dihapus dari Atlas Dunia.'
              : 'Removed map from World Atlas.'),
        ),
      );
    }
  }

  void _showPinsListSheet(BuildContext context, WorldMap map) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NvBottomSheet(
        title: isIndo ? 'Penanda Peta (${map.pins.length})' : 'Map Markers (${map.pins.length})',
        subtitle: isIndo ? 'Ketuk penanda untuk memeriksa detail' : 'Tap any marker to inspect details',
        child: map.pins.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Text(isIndo ? 'Belum ada penanda di peta ini.' : 'No markers on this map yet.'),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: map.pins.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final pin = map.pins[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          pin.category.color.withValues(alpha: 0.15),
                      child: Icon(
                        pin.category.icon,
                        size: 18,
                        color: pin.category.color,
                      ),
                    ),
                    title: Text(pin.title, style: AppTypography.cardTitle),
                    subtitle: Text(
                      '${pin.category.localizedLabel(isIndo)} · ${(pin.x * 100).toStringAsFixed(1)}% X, ${(pin.y * 100).toStringAsFixed(1)}% Y',
                      style: AppTypography.labelSm,
                    ),
                    trailing: const Icon(Symbols.chevron_right, size: 16),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() => _highlightedPinId = pin.id);
                      MapPinDetailSheet.show(
                        context,
                        novelId: map.novelId,
                        mapId: map.id,
                        pin: pin,
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Future<void> _openAddPinDialog({
    required String novelId,
    required String mapId,
    required double x,
    required double y,
  }) async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final createdPin = await MapPinDialog.show(
      context,
      novelId: novelId,
      mapId: mapId,
      x: x,
      y: y,
    );

    if (!mounted || createdPin == null) return;

    // Ensure the placed marker is immediately visible: clear any filter that would hide it
    setState(() {
      if (_selectedCategory != null &&
          _selectedCategory != createdPin.category) {
        _selectedCategory = null;
      }
      if (_searchQuery.isNotEmpty) {
        _searchController.clear();
        _searchQuery = '';
      }
      _highlightedPinId = createdPin.id;
      _isDropMarkerMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isIndo
              ? 'Penanda "${createdPin.title}" ditempatkan pada ${(createdPin.x * 100).toStringAsFixed(1)}% X, ${(createdPin.y * 100).toStringAsFixed(1)}% Y'
              : 'Placed marker "${createdPin.title}" at ${(createdPin.x * 100).toStringAsFixed(1)}% X, ${(createdPin.y * 100).toStringAsFixed(1)}% Y',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final novelsAsync = ref.watch(novelListStreamProvider);
    final activeNovelAsync = ref.watch(activeNovelProvider);

    return novelsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text(isIndo ? 'Gagal memuat novel: $e' : 'Error loading novel: $e')),
      ),
      data: (novels) {
        if (novels.isEmpty) {
          return Scaffold(
            appBar: NvAppBar(title: isIndo ? 'Atlas Dunia' : 'World Atlas'),
            body: Center(
              child: NvEmptyState.nothingYet(
                icon: Symbols.map,
                title: isIndo ? 'Belum ada novel yang dibuat' : 'No novels created',
                body: isIndo
                    ? 'Buat novel terlebih dahulu untuk memetakan geografi dan lokasinya.'
                    : 'Create a novel first to map its geography and places.',
                actionLabel: isIndo ? 'Buat Novel' : 'Create Novel',
                onAction: () => context.push(Routes.createNovel),
              ),
            ),
          );
        }

        final currentNovel = activeNovelAsync.valueOrNull ?? novels.first;
        final mapAsync = ref.watch(worldMapProvider(currentNovel.id));

        return mapAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            body: Center(child: Text(isIndo ? 'Gagal memuat peta: $e' : 'Error loading map: $e')),
          ),
          data: (worldMap) {
            // If no SVG map has been uploaded yet, require SVG upload first and show Onboarding Guide
            if (worldMap == null || worldMap.svgContent.trim().isEmpty) {
              return _buildOnboardingGuide(context, currentNovel, novels);
            }

            return _buildActiveAtlasView(
              context,
              currentNovel,
              novels,
              worldMap,
            );
          },
        );
      },
    );
  }

  /// Initial onboarding guide when no SVG map has been uploaded for this novel yet.
  Widget _buildOnboardingGuide(
    BuildContext context,
    NovelModel currentNovel,
    List<NovelModel> novels,
  ) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isIndo ? 'Atlas Dunia' : 'World Atlas',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              currentNovel.title,
              style: AppTypography.bodySm
                  .copyWith(color: c.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          // Switch Novel dropdown
          PopupMenuButton<NovelModel>(
            icon: const Icon(Symbols.swap_horiz),
            tooltip: isIndo ? 'Ganti Novel' : 'Switch Novel',
            onSelected: (n) {
              ref.read(activeNovelIdProvider.notifier).state = n.id;
            },
            itemBuilder: (ctx) => novels.map((n) {
              return PopupMenuItem(
                value: n,
                child: Text(n.title),
              );
            }).toList(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin(context),
          vertical: AppSpacing.lg,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Hero Banner
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0284C7).withValues(alpha: 0.15),
                        const Color(0xFF38BDF8).withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Symbols.map,
                          size: 42,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isIndo ? 'Panduan Pengenalan Atlas Dunia' : 'World Atlas Onboarding Guide',
                        textAlign: TextAlign.center,
                        style: AppTypography.screenTitle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isIndo
                            ? 'Untuk memetakan geografi novel Anda, buat dan unggah berkas peta vektor SVG terlebih dahulu. Penanda dan lokasi dapat ditempatkan setelah latar belakang peta dimuat.'
                            : 'To map your novel’s geography, please generate and upload an SVG vector map file first. Markers and locations can be placed once your map background is loaded.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySm.copyWith(
                          color: c.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          FilledButton.icon(
                            icon: const Icon(Symbols.upload_file),
                            label: Text(isIndo ? 'Unggah Berkas Peta .SVG' : 'Upload .SVG Map File'),
                            onPressed: () => _handleUploadSvg(currentNovel.id),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Symbols.code),
                            label: Text(isIndo ? 'Tempel Kode SVG' : 'Paste SVG Code'),
                            onPressed: () =>
                                _showPasteSvgDialog(currentNovel.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.x2),

                // Step-by-Step Instructions
                Text(
                  isIndo ? 'Cara Membuat & Mengekspor Peta Anda' : 'How to Create & Export Your Map',
                  style: AppTypography.cardTitle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Step 1
                _GuideStepCard(
                  stepNumber: '1',
                  title: isIndo ? 'Hasilkan Peta di Generator Eksternal' : 'Generate Map in External Generator',
                  description: isIndo
                      ? 'Gunakan alat kartografi gratis seperti Azgaar’s Fantasy Map Generator (azgaar.github.io) atau Inkarnate untuk membuat benua, bioma, sungai, dan wilayah politik realm Anda.'
                      : 'Use free external worldbuilding cartography tools such as Azgaar’s Fantasy Map Generator (azgaar.github.io) or Inkarnate to create your realm with continents, biomes, rivers, and political provinces.',
                  actionWidget: OutlinedButton.icon(
                    icon: const Icon(Symbols.content_copy, size: 16),
                    label: Text(isIndo ? 'Salin URL Generator Peta Azgaar' : 'Copy Azgaar Map Generator URL'),
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(
                          text:
                              'https://azgaar.github.io/Fantasy-Map-Generator/',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isIndo
                                ? 'URL Generator Peta Azgaar disalin ke papan klip!'
                                : 'Copied "https://azgaar.github.io/Fantasy-Map-Generator/" to clipboard!',
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Step 2
                _GuideStepCard(
                  stepNumber: '2',
                  title: isIndo ? 'Ekspor Peta sebagai Vektor (.SVG)' : 'Export Map as Vector (.SVG)',
                  description: isIndo
                      ? 'Di Azgaar, buka Menu bilah samping, pilih "Export", dan pilih "SVG". Simpan berkas vektor ke perangkat Anda. Format SVG menjamin perbesaran tajam tanpa pecah.'
                      : 'In Azgaar, open the Menu sidebar, choose "Export", and select "SVG". Save the vector file to your device. SVG format guarantees crisp, infinite zoom without pixelation.',
                ),

                const SizedBox(height: AppSpacing.md),

                // Step 3
                _GuideStepCard(
                  stepNumber: '3',
                  title: isIndo ? 'Unggah ke Novellie & Pasang Penanda' : 'Upload to Novellie & Plot Markers',
                  description: isIndo
                      ? 'Klik "Unggah Berkas Peta .SVG" di atas. Novellie langsung merender karya seni vektor sebagai latar atlas interaktif. Lalu pasang penanda untuk ibu kota, dungeon, pelabuhan, dan tautkan ke entri Kodeks serta karakter!'
                      : 'Click "Upload .SVG Map File" above. Novellie directly renders the vector artwork as your interactive atlas background. Then drop custom markers for capitals, dungeons, ports, and link them to Codex entries and novel characters!',
                ),

                const SizedBox(height: AppSpacing.x2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Active Interactive Canvas View once an SVG map has been uploaded.
  Widget _buildActiveAtlasView(
    BuildContext context,
    NovelModel currentNovel,
    List<NovelModel> novels,
    WorldMap worldMap,
  ) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final c = context.colors;

    final filteredPins = worldMap.pins.where((p) {
      if (_selectedCategory != null && p.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final titleMatch = p.title.toLowerCase().contains(query);
        final descMatch = p.description?.toLowerCase().contains(query) ?? false;
        if (!titleMatch && !descMatch) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isIndo ? 'Atlas Dunia' : 'World Atlas',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isIndo ? 'Vektor' : 'Vector',
                    style: TextStyle(
                      fontSize: 10,
                      color: c.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${currentNovel.title} · ${worldMap.pins.length} ${isIndo ? 'penanda' : 'markers'}',
              style: AppTypography.bodySm
                  .copyWith(color: c.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          // Drop Marker Mode Toggle
          IconButton(
            icon: Icon(
              _isDropMarkerMode
                  ? Symbols.location_on
                  : Symbols.add_location_alt,
              color: _isDropMarkerMode ? Colors.amber : null,
            ),
            tooltip: _isDropMarkerMode
                ? (isIndo ? 'Mode Penempatan Aktif: Ketuk peta untuk memasang' : 'Drop Mode Active: Tap map to place')
                : (isIndo ? 'Masuk Mode Pasang Penanda' : 'Enter Drop Marker Mode'),
            onPressed: () {
              setState(() => _isDropMarkerMode = !_isDropMarkerMode);
              if (_isDropMarkerMode) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isIndo
                          ? 'Mode Pasang Penanda: Ketuk di mana saja pada peta untuk memasang penanda lokasi.'
                          : 'Drop Marker Mode: Tap anywhere on the map to place a location pin.',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),

          // Novel Selector dropdown
          PopupMenuButton<NovelModel>(
            icon: const Icon(Symbols.swap_horiz),
            tooltip: isIndo ? 'Ganti Novel' : 'Switch Novel',
            onSelected: (n) {
              ref.read(activeNovelIdProvider.notifier).state = n.id;
            },
            itemBuilder: (ctx) => novels.map((n) {
              return PopupMenuItem(
                value: n,
                child: Text(n.title),
              );
            }).toList(),
          ),

          // Map Options Menu
          PopupMenuButton<String>(
            icon: const Icon(Symbols.more_vert),
            tooltip: isIndo ? 'Pengaturan Peta' : 'Map Settings',
            onSelected: (val) {
              if (val == 'upload_file') {
                _handleUploadSvg(currentNovel.id);
              } else if (val == 'paste_svg') {
                _showPasteSvgDialog(currentNovel.id);
              } else if (val == 'toggle_labels') {
                setState(() => _showPinLabels = !_showPinLabels);
              } else if (val == 'delete_map') {
                _handleDeleteMap(currentNovel.id);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'upload_file',
                child: Row(
                  children: [
                    const Icon(Symbols.upload_file, size: 18),
                    const SizedBox(width: 8),
                    Text(isIndo ? 'Ganti Berkas .SVG' : 'Replace .SVG File'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'paste_svg',
                child: Row(
                  children: [
                    const Icon(Symbols.code, size: 18),
                    const SizedBox(width: 8),
                    Text(isIndo ? 'Tempel Kode SVG' : 'Paste SVG Code'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_labels',
                child: Row(
                  children: [
                    Icon(
                      _showPinLabels
                          ? Symbols.visibility_off
                          : Symbols.visibility,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showPinLabels
                          ? (isIndo ? 'Sembunyikan Label Penanda' : 'Hide Marker Labels')
                          : (isIndo ? 'Tampilkan Label Penanda' : 'Show Marker Labels'),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete_map',
                child: Row(
                  children: [
                    Icon(Symbols.delete, size: 18, color: c.error),
                    const SizedBox(width: 8),
                    Text(
                      isIndo ? 'Hapus Peta' : 'Remove Map',
                      style: TextStyle(color: c.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Interactive Vector Map Canvas
          LayoutBuilder(
            builder: (context, constraints) {
              final mapW = worldMap.width > 0 ? worldMap.width : 1600.0;
              final mapH = worldMap.height > 0 ? worldMap.height : 1000.0;

              return InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.15,
                maxScale: 8.0,
                boundaryMargin: EdgeInsets.all(constraints.maxWidth * 1.2),
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      if (_isDropMarkerMode) {
                        final localPos = details.localPosition;
                        final nx = (localPos.dx / mapW).clamp(0.0, 1.0);
                        final ny = (localPos.dy / mapH).clamp(0.0, 1.0);

                        _openAddPinDialog(
                          novelId: currentNovel.id,
                          mapId: worldMap.id,
                          x: nx,
                          y: ny,
                        );
                      }
                    },
                    onLongPressStart: (details) {
                      final localPos = details.localPosition;
                      final nx = (localPos.dx / mapW).clamp(0.0, 1.0);
                      final ny = (localPos.dy / mapH).clamp(0.0, 1.0);

                      _openAddPinDialog(
                        novelId: currentNovel.id,
                        mapId: worldMap.id,
                        x: nx,
                        y: ny,
                      );
                    },
                    child: SizedBox(
                      width: mapW,
                      height: mapH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Background Vector Map Layer (Directly rendered SVG)
                          RepaintBoundary(
                            child: SvgPicture.string(
                              worldMap.sanitizedSvgContent,
                              width: mapW,
                              height: mapH,
                              fit: BoxFit.fill,
                              placeholderBuilder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorBuilder: (ctx, err, _) => Container(
                                width: mapW,
                                height: mapH,
                                color: const Color(0xFF0F172A),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Symbols.broken_image,
                                      size: 54,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      isIndo
                                          ? 'Tidak dapat merender markup SVG sebagai gambar vektor'
                                          : 'Unable to render SVG markup as vector image',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$err',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        FilledButton.icon(
                                          onPressed: () =>
                                              _handleUploadSvg(currentNovel.id),
                                          icon: const Icon(Symbols.upload_file,
                                              size: 18),
                                          label: Text(isIndo
                                              ? 'Ganti Berkas .SVG'
                                              : 'Replace .SVG File'),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () => _showPasteSvgDialog(
                                              currentNovel.id),
                                          icon: const Icon(
                                              Symbols.content_paste,
                                              size: 18),
                                          label: Text(isIndo
                                              ? 'Tempel Kode SVG'
                                              : 'Paste SVG Code'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Foreground Markers Overlay
                          for (final pin in filteredPins)
                            Positioned(
                              key: ValueKey(pin.id),
                              left: pin.x * mapW,
                              top: pin.y * mapH,
                              child: FractionalTranslation(
                                translation: const Offset(-0.5, -1.0),
                                child: MapPinWidget(
                                  pin: pin,
                                  isSelected: _highlightedPinId == pin.id,
                                  showLabel: _showPinLabels,
                                  onTap: () {
                                    setState(() => _highlightedPinId = pin.id);
                                    MapPinDetailSheet.show(
                                      context,
                                      novelId: currentNovel.id,
                                      mapId: worldMap.id,
                                      pin: pin,
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. Top Filter and Search Bar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search & List Bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: c.surface.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: isIndo ? 'Cari penanda peta...' : 'Search map markers...',
                            hintStyle:
                                TextStyle(fontSize: 13, color: c.textMuted),
                            prefixIcon: const Icon(Symbols.search, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Symbols.close, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Marker List View Button
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.surface.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Symbols.list, size: 20),
                        tooltip: isIndo ? 'Daftar Semua Penanda' : 'All Markers List',
                        onPressed: () => _showPinsListSheet(context, worldMap),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Horizontal Category Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text(isIndo ? 'Semua' : 'All'),
                        selected: _selectedCategory == null,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = null),
                      ),
                      const SizedBox(width: 6),
                      for (final cat in MapPinCategory.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            avatar: Icon(cat.icon, size: 14, color: cat.color),
                            label: Text(cat.localizedLabel(isIndo)),
                            selected: _selectedCategory == cat,
                            onSelected: (val) {
                              setState(() {
                                _selectedCategory = val ? cat : null;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Zoom & Control Pad (Bottom-Right)
          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Add Pin Button (center drop)
                FloatingActionButton.small(
                  heroTag: 'add_pin_center',
                  backgroundColor: _isDropMarkerMode ? Colors.amber : c.primary,
                  foregroundColor:
                      _isDropMarkerMode ? Colors.black : c.onPrimary,
                  tooltip: _isDropMarkerMode
                      ? (isIndo ? 'Pasang Penanda (Ketuk Peta)' : 'Drop Marker (Tap Map)')
                      : (isIndo ? 'Tambah Penanda (atau Tekan Lama)' : 'Add Marker (or Long-press)'),
                  onPressed: () {
                    _openAddPinDialog(
                      novelId: currentNovel.id,
                      mapId: worldMap.id,
                      x: 0.5,
                      y: 0.5,
                    );
                  },
                  child: Icon(
                    _isDropMarkerMode
                        ? Symbols.location_on
                        : Symbols.add_location_alt,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: c.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Symbols.add),
                        tooltip: isIndo ? 'Perbesar' : 'Zoom In',
                        onPressed: _zoomIn,
                      ),
                      const Divider(height: 1),
                      IconButton(
                        icon: const Icon(Symbols.remove),
                        tooltip: isIndo ? 'Perkecil' : 'Zoom Out',
                        onPressed: _zoomOut,
                      ),
                      const Divider(height: 1),
                      IconButton(
                        icon: const Icon(Symbols.fit_screen),
                        tooltip: isIndo ? 'Atur Ulang Tampilan' : 'Reset View',
                        onPressed: _resetZoom,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Instructions Hint Overlay (Bottom-Left)
          Positioned(
            left: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isDropMarkerMode ? Symbols.touch_app : Symbols.touch_app,
                    size: 14,
                    color: _isDropMarkerMode ? Colors.amber : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isDropMarkerMode
                        ? (isIndo ? 'Ketuk peta untuk memasang penanda' : 'Tap map to drop marker')
                        : (isIndo ? 'Tekan lama kanvas atau ketuk "+" untuk memasang penanda' : 'Long-press canvas or tap "+" to place marker'),
                    style: TextStyle(
                      color: _isDropMarkerMode ? Colors.amber : Colors.white70,
                      fontSize: 11,
                      fontWeight: _isDropMarkerMode
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStepCard extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String description;
  final Widget? actionWidget;

  const _GuideStepCard({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.actionWidget,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: c.primarySoft,
            child: Text(
              stepNumber,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: c.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.cardTitle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySm.copyWith(
                    color: c.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (actionWidget != null) ...[
                  const SizedBox(height: 10),
                  actionWidget!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
