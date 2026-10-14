import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../tools/application/family_tree_providers.dart';
import '../../../tools/domain/models/family_tree_models.dart';
import '../../../tools/presentation/screens/family_tree_screen.dart';
import '../../application/character_providers.dart';
import '../../domain/models/character_model.dart';
import '../widgets/character_avatar.dart';

class PsychologicalTrait {
  final String id;
  final String name;
  final String description;

  const PsychologicalTrait({
    required this.id,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };

  factory PsychologicalTrait.fromJson(Map<String, dynamic> json) =>
      PsychologicalTrait(
        id: json['id'] as String? ?? UniqueKey().toString(),
        name: json['name'] as String? ?? 'Trait',
        description: json['description'] as String? ?? '',
      );
}

class PsychologicalData {
  final String? summary;
  final List<PsychologicalTrait> traits;

  const PsychologicalData({this.summary, this.traits = const []});

  factory PsychologicalData.fromRawNotes(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const PsychologicalData();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final summary = decoded['summary'] as String?;
        final traitsList = (decoded['traits'] as List<dynamic>?)
                ?.map(
                  (t) =>
                      PsychologicalTrait.fromJson(t as Map<String, dynamic>),
                )
                .toList() ??
            [];
        return PsychologicalData(summary: summary, traits: traitsList);
      }
    } catch (_) {
      // Legacy plain text notes: gracefully treat as psychological summary
      return PsychologicalData(summary: raw.trim());
    }
    return const PsychologicalData();
  }

  String toJsonString() {
    return jsonEncode({
      if (summary != null && summary!.isNotEmpty) 'summary': summary,
      'traits': traits.map((t) => t.toJson()).toList(),
    });
  }

  PsychologicalData copyWith({
    String? summary,
    bool clearSummary = false,
    List<PsychologicalTrait>? traits,
  }) {
    return PsychologicalData(
      summary: clearSummary ? null : (summary ?? this.summary),
      traits: traits ?? this.traits,
    );
  }
}

class CharacterDetailScreen extends ConsumerStatefulWidget {
  final String characterId;

  const CharacterDetailScreen({
    super.key,
    required this.characterId,
  });

  @override
  ConsumerState<CharacterDetailScreen> createState() =>
      _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends ConsumerState<CharacterDetailScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _goalController;
  late TextEditingController _flawController;
  late TextEditingController _fearController;
  late TextEditingController _secretController;
  late TextEditingController _backstoryController;
  late TextEditingController _appearanceController;
  CharacterRole _role = CharacterRole.supporting;
  CharacterGender _gender = CharacterGender.custom;
  late TextEditingController _customGenderController;
  String _race = 'Human';
  late TextEditingController _customRaceController;
  Timer? _debounceTimer;
  late FocusNode _nameFocusNode;
  late FocusNode _nicknameFocusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nicknameController = TextEditingController();
    _goalController = TextEditingController();
    _flawController = TextEditingController();
    _fearController = TextEditingController();
    _secretController = TextEditingController();
    _backstoryController = TextEditingController();
    _appearanceController = TextEditingController();
    _customGenderController = TextEditingController();
    _customRaceController = TextEditingController();

    _nameFocusNode = FocusNode();
    _nicknameFocusNode = FocusNode();
  }

  void _syncControllers(CharacterModel character) {
    if (!_isEditing) {
      _nameController.text = character.name;
      _nicknameController.text = character.nickname ?? '';
      _goalController.text = character.goal ?? '';
      _flawController.text = character.flaw ?? '';
      _fearController.text = character.fear ?? '';
      _secretController.text = character.secret ?? '';
      _backstoryController.text = character.backstory ?? '';
      _appearanceController.text = character.appearance ?? '';
      _role = character.role;
      _gender = character.genderCategory;
      _customGenderController.text =
          (character.genderCategory == CharacterGender.custom)
              ? (character.gender ?? '')
              : '';
      final r = character.race ?? 'Human';
      if (CharacterRacePreset.presets.contains(r)) {
        _race = r;
        _customRaceController.text = '';
      } else {
        _race = 'Custom';
        _customRaceController.text = r;
      }
    }
  }

  String get _resolvedGenderString {
    switch (_gender) {
      case CharacterGender.male:
        return 'male';
      case CharacterGender.female:
        return 'female';
      case CharacterGender.custom:
        final custom = _customGenderController.text.trim();
        return custom.isNotEmpty ? custom : 'custom';
    }
  }

  String get _resolvedRaceString {
    if (_race == 'Custom') {
      final custom = _customRaceController.text.trim();
      return custom.isNotEmpty ? custom : 'Custom';
    }
    return _race;
  }

  void _onFieldChanged(CharacterModel character) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _autoCommit(character);
    });
  }

  Future<void> _autoCommit(CharacterModel character) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final updated = character.copyWith(
      name: name,
      nickname: _nicknameController.text.trim().isNotEmpty
          ? _nicknameController.text.trim()
          : null,
      role: _role,
      gender: _resolvedGenderString,
      race: _resolvedRaceString,
      goal: _goalController.text.trim().isNotEmpty
          ? _goalController.text.trim()
          : null,
      flaw: _flawController.text.trim().isNotEmpty
          ? _flawController.text.trim()
          : null,
      fear: _fearController.text.trim().isNotEmpty
          ? _fearController.text.trim()
          : null,
      secret: _secretController.text.trim().isNotEmpty
          ? _secretController.text.trim()
          : null,
      backstory: _backstoryController.text.trim().isNotEmpty
          ? _backstoryController.text.trim()
          : null,
      appearance: _appearanceController.text.trim().isNotEmpty
          ? _appearanceController.text.trim()
          : null,
      updatedAt: DateTime.now().toUtc(),
    );

    await ref
        .read(characterActionsControllerProvider)
        .updateCharacter(updated);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameFocusNode.dispose();
    _nicknameFocusNode.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    _goalController.dispose();
    _flawController.dispose();
    _fearController.dispose();
    _secretController.dispose();
    _backstoryController.dispose();
    _appearanceController.dispose();
    _customGenderController.dispose();
    _customRaceController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(CharacterModel character) async {
    final updated = character.copyWith(
      name: _nameController.text.trim(),
      nickname: _nicknameController.text.trim().isNotEmpty
          ? _nicknameController.text.trim()
          : null,
      role: _role,
      gender: _resolvedGenderString,
      race: _resolvedRaceString,
      goal: _goalController.text.trim().isNotEmpty
          ? _goalController.text.trim()
          : null,
      flaw: _flawController.text.trim().isNotEmpty
          ? _flawController.text.trim()
          : null,
      fear: _fearController.text.trim().isNotEmpty
          ? _fearController.text.trim()
          : null,
      secret: _secretController.text.trim().isNotEmpty
          ? _secretController.text.trim()
          : null,
      backstory: _backstoryController.text.trim().isNotEmpty
          ? _backstoryController.text.trim()
          : null,
      appearance: _appearanceController.text.trim().isNotEmpty
          ? _appearanceController.text.trim()
          : null,
      updatedAt: DateTime.now().toUtc(),
    );

    await ref
        .read(characterActionsControllerProvider)
        .updateCharacter(updated);
    setState(() => _isEditing = false);
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIndo ? 'Hapus Karakter?' : 'Delete Character?'),
        content: Text(
          isIndo
              ? 'Yakin ingin menghapus karakter ini? Anda dapat memulihkannya dari tempat sampah dalam 30 hari.'
              : 'Are you sure you want to remove this character? You can restore from trash within 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(characterActionsControllerProvider)
                  .deleteCharacter(widget.characterId);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(
              l10n?.delete ?? 'Delete',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
  }

  // --- Avatar & Interactive Preview Helpers ---

  Future<void> _pickImageFromGallery(CharacterModel character) async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked != null) {
        final updated = character.copyWith(
          portraitPath: picked.path,
          updatedAt: DateTime.now().toUtc(),
        );
        await ref
            .read(characterActionsControllerProvider)
            .updateCharacter(updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isIndo
                  ? 'Gagal memilih gambar: $e'
                  : 'Failed to pick image: $e',
            ),
          ),
        );
      }
    }
  }

  void _showImageUrlDialog(CharacterModel character) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final controller =
        TextEditingController(text: character.portraitPath ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIndo ? 'Masukkan URL Gambar Potret' : 'Enter Portrait Image URL'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: isIndo ? 'URL Gambar' : 'Image URL',
            hintText: 'https://example.com/portrait.jpg',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              Navigator.of(ctx).pop();
              final updated = character.copyWith(
                portraitPath: url.isNotEmpty ? url : '',
                updatedAt: DateTime.now().toUtc(),
              );
              ref
                  .read(characterActionsControllerProvider)
                  .updateCharacter(updated);
            },
            child: Text(isIndo ? 'Simpan URL' : 'Save URL'),
          ),
        ],
      ),
    );
  }

  void _showPortraitOptions(CharacterModel character) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Symbols.upload_file),
              title: Text(
                isIndo
                    ? 'Unggah Gambar dari Perangkat'
                    : 'Upload Image from Device',
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImageFromGallery(character);
              },
            ),
            ListTile(
              leading: const Icon(Symbols.link),
              title: Text(
                isIndo ? 'Masukkan URL Gambar' : 'Enter Image URL',
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _showImageUrlDialog(character);
              },
            ),
            if (character.portraitPath != null &&
                character.portraitPath!.trim().isNotEmpty) ...[
              ListTile(
                leading: const Icon(Symbols.fullscreen),
                title: Text(
                  isIndo
                      ? 'Lihat Gambar Resolusi Penuh'
                      : 'View Full Resolution Image',
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showFullResolutionModal(
                    context,
                    character.portraitPath!.trim(),
                    character.name,
                  );
                },
              ),
              ListTile(
                leading: Icon(Symbols.delete, color: context.colors.error),
                title: Text(
                  isIndo ? 'Hapus Potret' : 'Remove Portrait',
                  style: TextStyle(color: context.colors.error),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  final updated = character.copyWith(
                    portraitPath: '',
                    updatedAt: DateTime.now().toUtc(),
                  );
                  ref
                      .read(characterActionsControllerProvider)
                      .updateCharacter(updated);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFullResolutionModal(
    BuildContext context,
    String imagePath,
    String characterName,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        final isIndo = l10n?.localeName == 'id';
        final isNetwork =
            imagePath.startsWith('http://') || imagePath.startsWith('https://');

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lightbox Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      characterName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.close, color: Colors.white),
                    tooltip: isIndo ? 'Tutup Pratinjau' : 'Close Preview',
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Full-Resolution Lightbox Viewer with pinch-to-zoom / pan
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: isNetwork
                        ? Image.network(
                            imagePath,
                            fit: BoxFit.contain,
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Text(
                                  isIndo
                                      ? 'Gagal memuat gambar penuh'
                                      : 'Failed to load full image',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            ),
                          )
                        : Image.file(
                            File(imagePath),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Text(
                                  isIndo
                                      ? 'Berkas gambar tidak ditemukan di perangkat'
                                      : 'Image file not found on device',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Psychological Core Customization Helpers ---

  void _showAddSummaryDialog(
    CharacterModel character,
    PsychologicalData data,
  ) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final controller = TextEditingController(text: data.summary ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIndo ? 'Ringkasan Psikologis' : 'Psychological Summary'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            labelText: isIndo ? 'Narasi Ringkasan' : 'Summary Narrative',
            hintText: isIndo
                ? 'Gambarkan psikis batin, moral, atau pandangan filosofis karakter ini...'
                : 'Describe the internal psyche, moral architecture, or philosophical perspective of this character...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newSummary = controller.text.trim();
              Navigator.of(ctx).pop();
              final updatedData = data.copyWith(
                summary: newSummary.isNotEmpty ? newSummary : null,
                clearSummary: newSummary.isEmpty,
              );
              final updatedChar = character.copyWith(
                notes: updatedData.toJsonString(),
                updatedAt: DateTime.now().toUtc(),
              );
              ref
                  .read(characterActionsControllerProvider)
                  .updateCharacter(updatedChar);
            },
            child: Text(isIndo ? 'Simpan Ringkasan' : 'Save Summary'),
          ),
        ],
      ),
    );
  }

  void _showTraitDialog({
    required CharacterModel character,
    required PsychologicalData data,
    PsychologicalTrait? existingTrait,
  }) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final nameController =
        TextEditingController(text: existingTrait?.name ?? '');
    final descController =
        TextEditingController(text: existingTrait?.description ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existingTrait != null
              ? (isIndo ? 'Edit Sifat / Catatan' : 'Edit Trait / Note')
              : (isIndo ? 'Tambah Sifat / Catatan Kustom' : 'Add Custom Trait / Note'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: isIndo ? 'Nama Sifat / Catatan' : 'Trait / Note Name',
                hintText: isIndo
                    ? 'mis. Trauma Utama, Kebiasaan Khas, Konflik Moral'
                    : 'e.g. Core Trauma, Defining Habit, Moral Conflict',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: isIndo
                    ? 'Deskripsi / Detail Narasi'
                    : 'Description / Narrative Detail',
                hintText: isIndo
                    ? 'Jelaskan bagaimana aspek psikologis ini bermanifestasi...'
                    : 'Explain how this psychological aspect manifests...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              final traitName = nameController.text.trim();
              final traitDesc = descController.text.trim();
              if (traitName.isEmpty) return;

              Navigator.of(ctx).pop();

              final updatedTraits = List<PsychologicalTrait>.from(data.traits);
              if (existingTrait != null) {
                final idx = updatedTraits
                    .indexWhere((t) => t.id == existingTrait.id);
                if (idx >= 0) {
                  updatedTraits[idx] = PsychologicalTrait(
                    id: existingTrait.id,
                    name: traitName,
                    description: traitDesc,
                  );
                }
              } else {
                updatedTraits.add(
                  PsychologicalTrait(
                    id: UniqueKey().toString(),
                    name: traitName,
                    description: traitDesc,
                  ),
                );
              }

              final updatedData = data.copyWith(traits: updatedTraits);
              final updatedChar = character.copyWith(
                notes: updatedData.toJsonString(),
                updatedAt: DateTime.now().toUtc(),
              );
              ref
                  .read(characterActionsControllerProvider)
                  .updateCharacter(updatedChar);
            },
            child: Text(l10n?.save ?? 'Save'),
          ),
        ],
      ),
    );
  }

  void _removeTrait({
    required CharacterModel character,
    required PsychologicalData data,
    required String traitId,
  }) {
    final updatedTraits =
        data.traits.where((t) => t.id != traitId).toList();
    final updatedData = data.copyWith(traits: updatedTraits);
    final updatedChar = character.copyWith(
      notes: updatedData.toJsonString(),
      updatedAt: DateTime.now().toUtc(),
    );
    ref.read(characterActionsControllerProvider).updateCharacter(updatedChar);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final characterAsync =
        ref.watch(characterDetailStreamProvider(widget.characterId));

    return characterAsync.when(
      loading: () => Scaffold(
        appBar: NvAppBar(
          showBack: true,
          title: isIndo ? 'Detail Karakter' : 'Character Details',
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: NvAppBar(
          showBack: true,
          title: isIndo ? 'Karakter' : 'Character',
        ),
        body: Center(
          child: NvErrorState(
            title: isIndo
                ? 'Gagal memuat detail karakter'
                : 'Failed to load character details',
            message: isIndo
                ? 'Terjadi kesalahan saat mengambil detail karakter.'
                : 'An error occurred while fetching character details.',
            onRetry: () => ref.invalidate(
              characterDetailStreamProvider(widget.characterId),
            ),
          ),
        ),
      ),
      data: (character) {
        if (character == null) {
          return Scaffold(
            appBar: NvAppBar(
              showBack: true,
              title: isIndo
                  ? 'Karakter Tidak Ditemukan'
                  : 'Character Not Found',
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.person_off, size: 48, color: c.textMuted),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isIndo
                        ? 'Karakter ini tidak lagi ada di indeks.'
                        : 'This character no longer exists in index.',
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NvButton(
                    label: isIndo ? 'Kembali' : 'Go Back',
                    variant: NvButtonVariant.secondary,
                    icon: Symbols.arrow_back,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          );
        }

        _syncControllers(character);
        final psychData = PsychologicalData.fromRawNotes(character.notes);

        final rawPortraitPath = character.portraitPath?.trim();
        final hasPortrait =
            rawPortraitPath != null && rawPortraitPath.isNotEmpty;
        final portraitPath = rawPortraitPath ?? '';

        return Scaffold(
          appBar: NvAppBar(
            showBack: true,
            title: character.displayName,
            actions: [
              IconButton(
                icon: Icon(
                  _isEditing ? Symbols.save : Symbols.edit,
                  color: c.textPrimary,
                ),
                onPressed: () {
                  if (_isEditing) {
                    _handleSave(character);
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
                tooltip: _isEditing
                    ? (l10n?.save ?? 'Save')
                    : (isIndo ? 'Edit Karakter' : 'Edit Character'),
              ),
              IconButton(
                icon: Icon(Symbols.delete, color: c.error),
                onPressed: () => _confirmDelete(context),
                tooltip: l10n?.delete ?? 'Delete',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Profile Card (Full-width)
                SizedBox(
                  width: double.infinity,
                  child: NvCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Gender-Adaptive Character Avatar with Lightbox Modal
                            CharacterAvatar(
                              name: character.name,
                              portraitPath: character.portraitPath,
                              gender: _isEditing
                                  ? _resolvedGenderString
                                  : character.gender,
                              size: 76,
                              showCameraBadge: true,
                              onTap: () {
                                if (hasPortrait) {
                                  _showFullResolutionModal(
                                    context,
                                    portraitPath,
                                    character.name,
                                  );
                                } else {
                                  _showPortraitOptions(character);
                                }
                              },
                              onCameraTap: () =>
                                  _showPortraitOptions(character),
                            ),
                            const SizedBox(width: AppSpacing.lg),

                            // Character Name, Nickname & Badges Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isEditing) ...[
                                    NvTextField(
                                      controller: _nameController,
                                      focusNode: _nameFocusNode,
                                      hintText: isIndo ? 'Nama' : 'Name',
                                      onChanged: (_) =>
                                          _onFieldChanged(character),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    NvTextField(
                                      controller: _nicknameController,
                                      focusNode: _nicknameFocusNode,
                                      hintText: isIndo
                                          ? 'Nama Panggilan / Alias'
                                          : 'Nickname / Alias',
                                      onChanged: (_) =>
                                          _onFieldChanged(character),
                                    ),
                                  ] else ...[
                                    Text(
                                      character.name,
                                      style: AppTypography.screenTitle,
                                    ),
                                    if (character.nickname != null &&
                                        character.nickname!.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        '"${character.nickname!}"',
                                        style: AppTypography.bodySm.copyWith(
                                          color: c.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: AppSpacing.xs,
                                    runSpacing: AppSpacing.xs,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      NvChip.status(
                                        label: character.role.getLabel(l10n),
                                        statusKind: NvStatusTagKind.neutral,
                                      ),
                                      _buildGenderBadge(
                                        context,
                                        character.gender,
                                        isIndo,
                                      ),
                                      _buildRaceBadge(
                                        context,
                                        character.race,
                                        isIndo,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_isEditing) ...[
                          const SizedBox(height: AppSpacing.lg),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.md),
                          _buildRoleSelector(character),
                          const SizedBox(height: AppSpacing.md),
                          _buildGenderSelector(character),
                          const SizedBox(height: AppSpacing.md),
                          _buildRaceSelector(character),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Family Tree Lineage Preview Section
                _buildFamilyTreeSection(context, character, c),
                const SizedBox(height: AppSpacing.xl),

                // Inter-Character Relationships Section
                _buildRelationshipsSection(context, character, c),
                const SizedBox(height: AppSpacing.xl),

                // Psychological Core Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isIndo ? 'Inti Psikologis' : 'Psychological Core',
                      style: AppTypography.screenTitle,
                    ),
                    if (psychData.summary == null ||
                        psychData.summary!.isEmpty)
                      TextButton.icon(
                        icon: const Icon(Symbols.add_circle, size: 16),
                        label: Text(
                          isIndo ? 'Tambah Ringkasan' : 'Add Summary',
                        ),
                        onPressed: () =>
                            _showAddSummaryDialog(character, psychData),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Full-width Justified Psychological Core Card
                SizedBox(
                  width: double.infinity,
                  child: NvCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildField(
                          label: isIndo
                              ? 'Tujuan / Keinginan Utama'
                              : 'Primary Goal / Desire',
                          content: character.goal,
                          controller: _goalController,
                          placeholder: isIndo
                              ? 'Apa yang diinginkan karakter ini?'
                              : 'What does this character desire?',
                          isEditing: _isEditing,
                          onChanged: (_) => _onFieldChanged(character),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildField(
                          label: isIndo ? 'Kelemahan Fatal' : 'Fatal Flaw',
                          content: character.flaw,
                          controller: _flawController,
                          placeholder: isIndo
                              ? 'Keyakinan atau kelemahan batin apa yang menghambat mereka?'
                              : 'What internal belief or weakness holds them back?',
                          isEditing: _isEditing,
                          onChanged: (_) => _onFieldChanged(character),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildField(
                          label: isIndo ? 'Ketakutan Terdalam' : 'Deepest Fear',
                          content: character.fear,
                          controller: _fearController,
                          placeholder: isIndo
                              ? 'Apa yang sangat mereka takuti untuk dihadapi?'
                              : 'What are they terrified to face?',
                          isEditing: _isEditing,
                          onChanged: (_) => _onFieldChanged(character),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildField(
                          label: isIndo ? 'Rahasia Tersembunyi' : 'Hidden Secret',
                          content: character.secret,
                          controller: _secretController,
                          placeholder: isIndo
                              ? 'Apa yang mereka sembunyikan dari dunia?'
                              : 'What do they hide from the world?',
                          isEditing: _isEditing,
                          onChanged: (_) => _onFieldChanged(character),
                        ),

                        // Customizable Psychological Summary
                        if (psychData.summary != null &&
                            psychData.summary!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isIndo
                                    ? 'Ringkasan Psikologis'
                                    : 'Psychological Summary',
                                style: AppTypography.labelMd,
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Symbols.edit, size: 16),
                                    tooltip: isIndo
                                        ? 'Edit Ringkasan'
                                        : 'Edit Summary',
                                    onPressed: () => _showAddSummaryDialog(
                                      character,
                                      psychData,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Symbols.delete,
                                      size: 16,
                                      color: c.error,
                                    ),
                                    tooltip: isIndo
                                        ? 'Hapus Ringkasan'
                                        : 'Delete Summary',
                                    onPressed: () {
                                      final updatedData = psychData.copyWith(
                                        clearSummary: true,
                                      );
                                      final updatedChar = character.copyWith(
                                        notes: updatedData.toJsonString(),
                                        updatedAt: DateTime.now().toUtc(),
                                      );
                                      ref
                                          .read(
                                            characterActionsControllerProvider,
                                          )
                                          .updateCharacter(updatedChar);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              psychData.summary!,
                              textAlign: TextAlign.justify,
                              style: AppTypography.body,
                            ),
                          ),
                        ],

                        // Dynamic Custom Traits & Notes Header & Action
                        const SizedBox(height: AppSpacing.lg),
                        const Divider(height: 1),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isIndo
                                  ? 'Sifat & Catatan Kustom'
                                  : 'Custom Traits & Notes',
                              style: AppTypography.labelMd,
                            ),
                            TextButton.icon(
                              icon: const Icon(Symbols.add, size: 16),
                              label: Text(
                                isIndo
                                    ? 'Tambah Sifat / Catatan'
                                    : 'Add Trait / Note',
                              ),
                              onPressed: () => _showTraitDialog(
                                character: character,
                                data: psychData,
                              ),
                            ),
                          ],
                        ),

                        // List of Dynamic Custom Traits
                        if (psychData.traits.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              isIndo
                                  ? 'Belum ada sifat kustom. Klik "Tambah Sifat / Catatan" untuk menyematkan dimensi psikologis.'
                                  : 'No custom traits added yet. Click "Add Trait / Note" to attach custom psychological dimensions.',
                              style: AppTypography.bodySm.copyWith(
                                color: c.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          ...psychData.traits.map((trait) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(top: AppSpacing.md),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: c.surfaceSecondary,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.input),
                                  border: Border.all(
                                    color: c.outlineVariant,
                                    width: 0.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            trait.name,
                                            style: AppTypography.labelSm.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: c.primary,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Symbols.edit,
                                                size: 16,
                                              ),
                                              tooltip: isIndo
                                                  ? 'Edit Sifat'
                                                  : 'Edit Trait',
                                              onPressed: () => _showTraitDialog(
                                                character: character,
                                                data: psychData,
                                                existingTrait: trait,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Symbols.delete,
                                                size: 16,
                                                color: c.error,
                                              ),
                                              tooltip: isIndo
                                                  ? 'Hapus Sifat'
                                                  : 'Delete Trait',
                                              onPressed: () => _removeTrait(
                                                character: character,
                                                data: psychData,
                                                traitId: trait.id,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Text(
                                        trait.description.isNotEmpty
                                            ? trait.description
                                            : '—',
                                        textAlign: TextAlign.justify,
                                        style: AppTypography.body,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Narrative Context Section Header
                Text(
                  isIndo ? 'Konteks Naratif' : 'Narrative Context',
                  style: AppTypography.screenTitle,
                ),
                const SizedBox(height: AppSpacing.md),

                // Full-width Justified Narrative Context Card
                SizedBox(
                  width: double.infinity,
                  child: NvCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildField(
                          label: isIndo ? 'Penampilan' : 'Appearance',
                          content: character.appearance,
                          controller: _appearanceController,
                          placeholder: isIndo
                              ? 'Deskripsi fisik dan gerak-gerik'
                              : 'Physical description and mannerisms',
                          isEditing: _isEditing,
                          onChanged: (_) => _onFieldChanged(character),
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildField(
                          label: isIndo ? 'Kisah Latar Belakang' : 'Backstory',
                          content: character.backstory,
                          controller: _backstoryController,
                          placeholder: isIndo
                              ? 'Peristiwa penting yang membentuk karakter ini'
                              : 'Key events that shaped this character',
                          isEditing: _isEditing,
                          onChanged: (_) => _onFieldChanged(character),
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenderBadge(
    BuildContext context,
    String? gender, [
    bool isIndo = false,
  ]) {
    final category = CharacterGender.fromString(gender);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color border;
    Color text;
    IconData icon;
    String label;

    switch (category) {
      case CharacterGender.male:
        bg = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE);
        border = isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
        text = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
        icon = Symbols.male;
        label = isIndo ? 'Pria' : 'Male';
        break;
      case CharacterGender.female:
        bg = isDark ? const Color(0xFF501B34) : const Color(0xFFFCE7F3);
        border = isDark ? const Color(0xFFF472B6) : const Color(0xFFEC4899);
        text = isDark ? const Color(0xFFFBCFE8) : const Color(0xFFBE185D);
        icon = Symbols.female;
        label = isIndo ? 'Wanita' : 'Female';
        break;
      case CharacterGender.custom:
        bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
        border = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
        text = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
        icon = Symbols.person;
        label = (gender != null &&
                gender.trim().isNotEmpty &&
                gender.toLowerCase() != 'custom')
            ? gender.trim()
            : (isIndo ? 'Kustom' : 'Custom');
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: border.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceBadge(
    BuildContext context,
    String? race, [
    bool isIndo = false,
  ]) {
    final c = context.colors;
    final r = race != null ? race.trim() : '';
    final displayRace = r.isEmpty || r.toLowerCase() == 'human'
        ? (isIndo ? 'Manusia' : 'Human')
        : r;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.outlineVariant, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.fingerprint, size: 14, color: c.textSecondary),
          const SizedBox(width: 4),
          Text(
            displayRace,
            style: AppTypography.labelSm.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector(CharacterModel character) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isIndo ? 'Peran' : 'Role', style: AppTypography.labelSm),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          children: CharacterRole.values.map((role) {
            final isSelected = _role == role;
            return ChoiceChip(
              label: Text(role.getLabel(l10n)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _role = role);
                  _onFieldChanged(character);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(CharacterModel character) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: AppTypography.labelSm),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            ChoiceChip(
              avatar: const Icon(Symbols.male, size: 16),
              label: Text(isIndo ? 'Pria' : 'Male'),
              selected: _gender == CharacterGender.male,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _gender = CharacterGender.male);
                  _onFieldChanged(character);
                }
              },
            ),
            ChoiceChip(
              avatar: const Icon(Symbols.female, size: 16),
              label: Text(isIndo ? 'Wanita' : 'Female'),
              selected: _gender == CharacterGender.female,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _gender = CharacterGender.female);
                  _onFieldChanged(character);
                }
              },
            ),
            ChoiceChip(
              avatar: const Icon(Symbols.person, size: 16),
              label: Text(isIndo ? 'Kustom' : 'Custom'),
              selected: _gender == CharacterGender.custom,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _gender = CharacterGender.custom);
                  _onFieldChanged(character);
                }
              },
            ),
          ],
        ),
        if (_gender == CharacterGender.custom) ...[
          const SizedBox(height: AppSpacing.xs),
          NvTextField(
            controller: _customGenderController,
            hintText: isIndo
                ? 'Nama gender kustom (mis. Non-biner, Agender)'
                : 'Custom gender name (e.g. Non-binary, Agender)',
            onChanged: (_) => _onFieldChanged(character),
          ),
        ],
      ],
    );
  }

  Widget _buildRaceSelector(CharacterModel character) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isIndo ? 'Ras' : 'Race / Ras', style: AppTypography.labelSm),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: CharacterRacePreset.presets.map((preset) {
            final isSelected = _race == preset;
            final labelText = preset == 'Human' && isIndo ? 'Manusia' : preset;
            return ChoiceChip(
              label: Text(labelText),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _race = preset);
                  _onFieldChanged(character);
                }
              },
            );
          }).toList(),
        ),
        if (_race == 'Custom') ...[
          const SizedBox(height: AppSpacing.xs),
          NvTextField(
            controller: _customRaceController,
            hintText: isIndo
                ? 'Nama ras kustom (mis. Kitsune, Vampir, Golem)'
                : 'Custom race name (e.g. Kitsune, Vampire, Golem)',
            onChanged: (_) => _onFieldChanged(character),
          ),
        ],
      ],
    );
  }

  Widget _buildFamilyTreeSection(
    BuildContext context,
    CharacterModel character,
    AppColors c,
  ) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final treesAsync = ref.watch(familyTreesProvider(character.novelId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Symbols.account_tree, size: 22, color: c.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  isIndo ? 'Silsilah & Pohon Keluarga' : 'Family Tree & Lineage',
                  style: AppTypography.screenTitle,
                ),
              ],
            ),
            TextButton.icon(
              icon: const Icon(Symbols.open_in_new, size: 16),
              label: Text(isIndo ? 'Buka Alat' : 'Open Tool'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FamilyTreeScreen(
                      initialNovelId: character.novelId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        treesAsync.when(
          loading: () => const SizedBox(height: 24),
          error: (err, _) => NvCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                isIndo
                    ? 'Tidak dapat memuat pohon keluarga: $err'
                    : 'Could not load family trees: $err',
                style: TextStyle(color: c.error),
              ),
            ),
          ),
          data: (trees) {
            final linkedTrees = trees.where((tree) {
              final hasMatchingNode = tree.nodes.any(
                (n) =>
                    n.characterId == character.id ||
                    (n.name.trim().toLowerCase() ==
                        character.name.trim().toLowerCase()),
              );
              final isRoot = tree.rootCharacterId == character.id;
              return hasMatchingNode || isRoot;
            }).toList();

            if (linkedTrees.isEmpty) {
              return NvCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Symbols.family_restroom,
                        size: 40,
                        color: c.textMuted,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        isIndo
                            ? 'Tidak Ada Silsilah Keluarga Ditemukan'
                            : 'No Family Tree Lineage Found',
                        style: AppTypography.labelMd.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        isIndo
                            ? 'Karakter ini belum terhubung ke pohon keluarga. Buka alat Pohon Keluarga untuk melacak leluhur, keturunan, dan pasangan mereka.'
                            : 'This character is not yet connected to a family tree. Open the Family Tree tool to trace their ancestry, descendants, and spouses.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySm.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      NvButton(
                        label: isIndo
                            ? 'Buka Pohon Keluarga'
                            : 'Open Family Tree',
                        variant: NvButtonVariant.secondary,
                        icon: Symbols.account_tree,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => FamilyTreeScreen(
                                initialNovelId: character.novelId,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: linkedTrees.map((tree) {
                final matchingNode = tree.nodes.firstWhere(
                  (n) =>
                      n.characterId == character.id ||
                      (n.name.trim().toLowerCase() ==
                          character.name.trim().toLowerCase()),
                  orElse: () => tree.nodes.isNotEmpty
                      ? tree.nodes.first
                      : FamilyTreeNode(
                          id: '',
                          treeId: tree.id,
                          name: character.name,
                        ),
                );

                final relatives =
                    _extractImmediateRelatives(tree, matchingNode, isIndo);

                return NvCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Symbols.family_history,
                                      size: 18,
                                      color: c.primary,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        tree.name,
                                        style: AppTypography.cardTitle.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (tree.description != null &&
                                    tree.description!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    tree.description!.trim(),
                                    style: AppTypography.labelSm.copyWith(
                                      color: c.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          NvChip.status(
                            label: isIndo
                                ? '${tree.nodes.length} anggota'
                                : '${tree.nodes.length} members',
                            statusKind: NvStatusTagKind.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.md),
                      if (relatives.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            isIndo
                                ? 'Karakter ini terdaftar di "${tree.name}", tetapi belum ada keluarga terdekat (orang tua, pasangan, anak) yang terhubung.'
                                : 'This character is listed in "${tree.name}", but no immediate relatives (parents, spouse, children) are linked yet.',
                            style: AppTypography.bodySm.copyWith(
                              color: c.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else ...[
                        Text(
                          isIndo
                              ? 'Pratinjau Keluarga Terdekat'
                              : 'Immediate Family Preview',
                          style: AppTypography.labelSm.copyWith(
                            color: c.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: relatives.map((rel) {
                            return _buildFamilyMemberChip(context, rel, c);
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      NvButton(
                        label: isIndo
                            ? 'Lihat Silsilah Lengkap di Pohon Keluarga'
                            : 'View Full Lineage in Family Tree',
                        variant: NvButtonVariant.primary,
                        icon: Symbols.account_tree,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => FamilyTreeScreen(
                                initialNovelId: character.novelId,
                                initialTreeId: tree.id,
                                initialNodeId: matchingNode.id.isNotEmpty
                                    ? matchingNode.id
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  List<_FamilyRelativePreview> _extractImmediateRelatives(
    FamilyTree tree,
    FamilyTreeNode current, [
    bool isIndo = false,
  ]) {
    if (current.id.isEmpty) return const [];
    final results = <_FamilyRelativePreview>[];
    final seenNodeIds = <String>{};

    for (final edge in tree.edges) {
      if (edge.fromNodeId == current.id) {
        final targetNode =
            tree.nodes.where((n) => n.id == edge.toNodeId).firstOrNull;
        if (targetNode != null && !seenNodeIds.contains(targetNode.id)) {
          seenNodeIds.add(targetNode.id);
          String label;
          IconData icon;
          switch (edge.relationshipType) {
            case FamilyRelationshipType.parent:
              label = isIndo ? 'Orang Tua' : 'Parent';
              icon = Symbols.elderly;
              break;
            case FamilyRelationshipType.child:
              label = isIndo ? 'Anak' : 'Child';
              icon = Symbols.child_care;
              break;
            case FamilyRelationshipType.spouse:
              label = isIndo ? 'Pasangan' : 'Spouse';
              icon = Symbols.favorite;
              break;
            case FamilyRelationshipType.sibling:
              label = isIndo ? 'Saudara' : 'Sibling';
              icon = Symbols.group;
              break;
            case FamilyRelationshipType.ancestor:
              label = isIndo ? 'Leluhur' : 'Ancestor';
              icon = Symbols.history_edu;
              break;
            case FamilyRelationshipType.adoptive:
              label = isIndo ? 'Anak Angkat' : 'Adopted';
              icon = Symbols.diversity_1;
              break;
          }
          results.add(
            _FamilyRelativePreview(
              node: targetNode,
              relationshipLabel: label,
              icon: icon,
            ),
          );
        }
      } else if (edge.toNodeId == current.id) {
        final sourceNode =
            tree.nodes.where((n) => n.id == edge.fromNodeId).firstOrNull;
        if (sourceNode != null && !seenNodeIds.contains(sourceNode.id)) {
          seenNodeIds.add(sourceNode.id);
          String label;
          IconData icon;
          switch (edge.relationshipType) {
            case FamilyRelationshipType.parent:
              label = isIndo ? 'Anak' : 'Child';
              icon = Symbols.child_care;
              break;
            case FamilyRelationshipType.child:
              label = isIndo ? 'Orang Tua' : 'Parent';
              icon = Symbols.elderly;
              break;
            case FamilyRelationshipType.spouse:
              label = isIndo ? 'Pasangan' : 'Spouse';
              icon = Symbols.favorite;
              break;
            case FamilyRelationshipType.sibling:
              label = isIndo ? 'Saudara' : 'Sibling';
              icon = Symbols.group;
              break;
            case FamilyRelationshipType.ancestor:
              label = isIndo ? 'Keturunan' : 'Descendant';
              icon = Symbols.child_care;
              break;
            case FamilyRelationshipType.adoptive:
              label = isIndo ? 'Wali' : 'Guardian';
              icon = Symbols.diversity_1;
              break;
          }
          results.add(
            _FamilyRelativePreview(
              node: sourceNode,
              relationshipLabel: label,
              icon: icon,
            ),
          );
        }
      }
    }

    return results;
  }

  Widget _buildFamilyMemberChip(
    BuildContext context,
    _FamilyRelativePreview rel,
    AppColors c,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.outlineVariant, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CharacterAvatar(
            name: rel.node.name,
            portraitPath: rel.node.avatarPath,
            gender: rel.node.gender,
            size: 28,
            borderWidth: 1.5,
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rel.node.name,
                style: AppTypography.bodySm.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(rel.icon, size: 12, color: c.primary),
                  const SizedBox(width: 3),
                  Text(
                    rel.relationshipLabel,
                    style: AppTypography.labelSm.copyWith(
                      color: c.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipsSection(
    BuildContext context,
    CharacterModel character,
    AppColors c,
  ) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final relsAsync =
        ref.watch(characterRelationshipsStreamProvider(character.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Symbols.diversity_3, size: 22, color: c.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  isIndo ? 'Hubungan Antar-Karakter' : 'Relationships',
                  style: AppTypography.screenTitle,
                ),
              ],
            ),
            TextButton.icon(
              icon: const Icon(Symbols.add_circle, size: 16),
              label: Text(isIndo ? 'Tambah Hubungan' : 'Add Relationship'),
              onPressed: () => _showAddRelationshipDialog(context, character),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        relsAsync.when(
          loading: () => const SizedBox(height: 24),
          error: (err, _) => NvCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                isIndo
                    ? 'Tidak dapat memuat hubungan: $err'
                    : 'Could not load relationships: $err',
                style: TextStyle(color: c.error),
              ),
            ),
          ),
          data: (rels) {
            if (rels.isEmpty) {
              return NvCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Symbols.group_off, size: 32, color: c.textMuted),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          isIndo
                              ? 'Belum ada hubungan karakter yang dicatat. Lacak sekutu, rival, mentor, dan musuh dengan mengklik "Tambah Hubungan".'
                              : 'No character relationships recorded yet. Track allies, rivals, mentors, and foes by clicking "Add Relationship".',
                          style: AppTypography.bodySm.copyWith(
                            color: c.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: rels.map((rel) {
                final displayType = isIndo
                    ? _translateRelationshipType(rel.displayType)
                    : rel.displayType;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: NvCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CharacterAvatar(
                          name: rel.targetCharacterName,
                          portraitPath: rel.targetCharacterPortrait,
                          gender: rel.targetCharacterGender,
                          size: 46,
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
                                      rel.targetCharacterName ??
                                          (isIndo ? 'Karakter' : 'Character'),
                                      style: AppTypography.labelMd.copyWith(
                                        fontWeight: FontWeight.bold,
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
                                      color: c.primarySoft,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.pill),
                                    ),
                                    child: Text(
                                      displayType,
                                      style: AppTypography.labelSm.copyWith(
                                        color: c.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (rel.description != null &&
                                  rel.description!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  rel.description!.trim(),
                                  style: AppTypography.bodySm.copyWith(
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Symbols.delete, size: 18, color: c.error),
                          tooltip: isIndo
                              ? 'Hapus Hubungan'
                              : 'Delete Relationship',
                          onPressed: () => _confirmDeleteRelationship(
                            context,
                            rel.id,
                            rel.targetCharacterName ??
                                (isIndo ? 'karakter ini' : 'this character'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _translateRelationshipType(String type) {
    switch (type.toLowerCase()) {
      case 'ally':
        return 'Sekutu';
      case 'rival':
        return 'Rival';
      case 'mentor':
        return 'Mentor';
      case 'student':
        return 'Murid';
      case 'friend':
        return 'Teman';
      case 'lover':
        return 'Kekasih';
      case 'enemy':
        return 'Musuh';
      case 'companion':
        return 'Sahabat';
      case 'family':
        return 'Keluarga';
      case 'custom':
        return 'Kustom';
      default:
        return type;
    }
  }

  Future<void> _showAddRelationshipDialog(
    BuildContext context,
    CharacterModel character,
  ) async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    final characters = await ref
        .read(characterRepositoryProvider)
        .watchCharacters(character.novelId)
        .first;

    final otherCharacters =
        characters.where((c) => c.id != character.id).toList();

    if (!context.mounted) return;

    if (otherCharacters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isIndo
                ? 'Buat karakter lain di novel ini terlebih dahulu untuk menghubungkan relasi.'
                : 'Create other characters in this novel first to link relationships.',
          ),
        ),
      );
      return;
    }

    String selectedTargetId = otherCharacters.first.id;
    String selectedType = 'Ally';
    final customLabelController = TextEditingController();
    final descriptionController = TextEditingController();

    const relationshipTypes = [
      'Ally',
      'Rival',
      'Mentor',
      'Student',
      'Friend',
      'Lover',
      'Enemy',
      'Companion',
      'Family',
      'Custom',
    ];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(
              isIndo
                  ? 'Tambah Hubungan Karakter'
                  : 'Add Character Relationship',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isIndo ? 'Karakter Target' : 'Target Character',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTargetId,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: otherCharacters.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Text('${c.name} (${c.role.getLabel(l10n)})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedTargetId = val);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    isIndo ? 'Tipe Hubungan' : 'Relationship Type',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: relationshipTypes.map((type) {
                      final isSelected = selectedType == type;
                      final typeLabel = isIndo
                          ? _translateRelationshipType(type)
                          : type;
                      return ChoiceChip(
                        label: Text(typeLabel),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setDialogState(() => selectedType = type);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  if (selectedType == 'Custom') ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: customLabelController,
                      decoration: InputDecoration(
                        labelText: isIndo ? 'Label Kustom' : 'Custom Label',
                        hintText: isIndo
                            ? 'mis. Saudara Seperguruan, Musuh Bebuyutan'
                            : 'e.g. Sworn Brother, Nemesis, Co-conspirator',
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: isIndo
                          ? 'Catatan / Deskripsi Dinamis (Opsional)'
                          : 'Notes / Dynamic Description (Optional)',
                      hintText: isIndo
                          ? 'Jelaskan secara singkat bagaimana mereka berinteraksi atau riwayatnya...'
                          : 'Briefly describe how they interact or history...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n?.cancel ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final customLabel = selectedType == 'Custom'
                      ? customLabelController.text.trim()
                      : null;
                  final description = descriptionController.text.trim();

                  Navigator.of(ctx).pop();

                  await ref
                      .read(characterActionsControllerProvider)
                      .addRelationship(
                        novelId: character.novelId,
                        characterAId: character.id,
                        characterBId: selectedTargetId,
                        type: selectedType,
                        customLabel: customLabel?.isNotEmpty == true
                            ? customLabel
                            : null,
                        description:
                            description.isNotEmpty ? description : null,
                      );
                },
                child: Text(isIndo ? 'Tambah' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteRelationship(
    BuildContext context,
    String relationshipId,
    String targetName,
  ) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIndo ? 'Hapus Hubungan?' : 'Remove Relationship?'),
        content: Text(
          isIndo
              ? 'Yakin ingin menghapus hubungan dengan $targetName?'
              : 'Are you sure you want to delete the relationship with $targetName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(characterActionsControllerProvider)
                  .deleteRelationship(relationshipId);
            },
            child: Text(
              l10n?.delete ?? 'Delete',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String? content,
    required TextEditingController controller,
    required String placeholder,
    required bool isEditing,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTypography.labelMd),
        const SizedBox(height: AppSpacing.xs),
        if (isEditing)
          NvTextField(
            controller: controller,
            hintText: placeholder,
            maxLines: maxLines,
            onChanged: onChanged,
          )
        else
          SizedBox(
            width: double.infinity,
            child: Text(
              (content != null && content.isNotEmpty) ? content : '—',
              textAlign: TextAlign.justify,
              style: AppTypography.body,
            ),
          ),
      ],
    );
  }
}

class _FamilyRelativePreview {
  final FamilyTreeNode node;
  final String relationshipLabel;
  final IconData icon;

  const _FamilyRelativePreview({
    required this.node,
    required this.relationshipLabel,
    required this.icon,
  });
}
