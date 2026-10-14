import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/character_providers.dart';
import '../../domain/models/character_model.dart';
import '../widgets/character_avatar.dart';

class CreateCharacterDialog extends ConsumerStatefulWidget {
  final String novelId;
  final CharacterModel? characterToEdit;

  const CreateCharacterDialog({
    super.key,
    required this.novelId,
    this.characterToEdit,
  });

  static Future<CharacterModel?> show(
    BuildContext context,
    String novelId, {
    CharacterModel? characterToEdit,
  }) {
    final c = context.colors;
    return showModalBottomSheet<CharacterModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => CreateCharacterDialog(
        novelId: novelId,
        characterToEdit: characterToEdit,
      ),
    );
  }

  @override
  ConsumerState<CreateCharacterDialog> createState() =>
      _CreateCharacterDialogState();
}

class _CreateCharacterDialogState extends ConsumerState<CreateCharacterDialog> {
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _goalController = TextEditingController();
  final _flawController = TextEditingController();
  final _fearController = TextEditingController();
  final _secretController = TextEditingController();
  final _summaryController = TextEditingController();
  final _customGenderController = TextEditingController();
  final _customRaceController = TextEditingController();
  CharacterRole _selectedRole = CharacterRole.protagonist;
  CharacterGender _selectedGender = CharacterGender.male;
  String _selectedRace = 'Human';
  String? _portraitPath;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.characterToEdit;
    if (edit != null) {
      _nameController.text = edit.name;
      _nicknameController.text = edit.nickname ?? '';
      _goalController.text = edit.goal ?? '';
      _flawController.text = edit.flaw ?? '';
      _fearController.text = edit.fear ?? '';
      _secretController.text = edit.secret ?? '';
      _selectedRole = edit.role;
      _portraitPath = edit.portraitPath;
      if (edit.gender != null && edit.gender!.isNotEmpty) {
        _selectedGender = CharacterGender.fromString(edit.gender);
        if (_selectedGender == CharacterGender.custom) {
          _customGenderController.text = edit.gender!;
        }
      }
      if (edit.race != null && edit.race!.isNotEmpty) {
        if (CharacterRacePreset.presets.contains(edit.race)) {
          _selectedRace = edit.race!;
        } else {
          _selectedRace = 'Custom';
          _customRaceController.text = edit.race!;
        }
      }
      if (edit.notes != null && edit.notes!.isNotEmpty) {
        try {
          final decoded = jsonDecode(edit.notes!);
          if (decoded is Map<String, dynamic> && decoded['summary'] != null) {
            _summaryController.text = decoded['summary'] as String;
          }
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _goalController.dispose();
    _flawController.dispose();
    _fearController.dispose();
    _secretController.dispose();
    _summaryController.dispose();
    _customGenderController.dispose();
    _customRaceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked != null) {
        setState(() => _portraitPath = picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showUrlDialog() {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final controller = TextEditingController(text: _portraitPath ?? '');
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
              final val = controller.text.trim();
              Navigator.of(ctx).pop();
              setState(() => _portraitPath = val.isNotEmpty ? val : null);
            },
            child: Text(isIndo ? 'Simpan URL' : 'Save URL'),
          ),
        ],
      ),
    );
  }

  void _showPortraitOptions() {
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
              title: Text(isIndo ? 'Unggah Gambar dari Perangkat' : 'Upload Image from Device'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Symbols.link),
              title: Text(isIndo ? 'Masukkan URL Gambar' : 'Enter Image URL'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showUrlDialog();
              },
            ),
            if (_portraitPath != null)
              ListTile(
                leading: Icon(Symbols.delete, color: context.colors.error),
                title: Text(
                  isIndo ? 'Hapus Potret' : 'Remove Portrait',
                  style: TextStyle(color: context.colors.error),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _portraitPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final resolvedGender = _selectedGender == CharacterGender.custom
        ? (_customGenderController.text.trim().isNotEmpty
            ? _customGenderController.text.trim()
            : 'Custom')
        : _selectedGender.name;

    final resolvedRace = _selectedRace == 'Custom'
        ? (_customRaceController.text.trim().isNotEmpty
            ? _customRaceController.text.trim()
            : 'Custom')
        : _selectedRace;

    setState(() => _isCreating = true);
    try {
      final summary = _summaryController.text.trim();
      final notesJson = summary.isNotEmpty
          ? jsonEncode({'summary': summary, 'traits': <Map<String, dynamic>>[], 'race': resolvedRace})
          : jsonEncode({'race': resolvedRace});

      if (widget.characterToEdit != null) {
        final updated = widget.characterToEdit!.copyWith(
          name: name,
          nickname: _nicknameController.text.trim().isNotEmpty
              ? _nicknameController.text.trim()
              : null,
          role: _selectedRole,
          gender: resolvedGender,
          race: resolvedRace,
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
          portraitPath: _portraitPath,
          notes: notesJson,
          updatedAt: DateTime.now().toUtc(),
        );

        await ref
            .read(characterActionsControllerProvider)
            .updateCharacter(updated);

        if (mounted) {
          Navigator.of(context).pop(updated);
        }
        return;
      }

      final character = await ref
          .read(characterActionsControllerProvider)
          .createCharacter(
            novelId: widget.novelId,
            name: name,
            nickname: _nicknameController.text.trim().isNotEmpty
                ? _nicknameController.text.trim()
                : null,
            role: _selectedRole,
            gender: resolvedGender,
            race: resolvedRace,
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
            portraitPath: _portraitPath,
            notes: notesJson,
          );

      if (mounted) {
        Navigator.of(context).pop(character);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.characterToEdit != null
                  ? 'Failed to update character: $e'
                  : 'Failed to create character: $e',
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
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.88;

    return SafeArea(
      child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight: maxHeight,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: AppSpacing.md,
              bottom: mediaQuery.viewInsets.bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Header: Title and Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.characterToEdit != null
                          ? (isIndo ? 'Edit Karakter' : 'Edit Character')
                          : (l10n?.createCharacter ?? 'New Character'),
                      style: AppTypography.screenTitle,
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
              const SizedBox(height: AppSpacing.md),

              // Scrollable Form Fields
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Portrait & Core Name Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CharacterAvatar(
                            name: _nameController.text,
                            portraitPath: _portraitPath,
                            gender: _selectedGender == CharacterGender.custom
                                ? _customGenderController.text
                                : _selectedGender.name,
                            size: 64,
                            showCameraBadge: true,
                            onTap: _showPortraitOptions,
                            onCameraTap: _showPortraitOptions,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isIndo ? 'Nama *' : 'Name *',
                                  style: AppTypography.labelMd.copyWith(color: c.textPrimary),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                NvTextField(
                                  controller: _nameController,
                                  hintText: isIndo ? 'Nama karakter' : 'Character name',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        isIndo ? 'Nama Panggilan / Alias' : 'Nickname / Alias',
                        style: AppTypography.labelMd.copyWith(color: c.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      NvTextField(
                        controller: _nicknameController,
                        hintText: isIndo ? 'mis. Sang Rubah Perak' : 'e.g. The Silver Fox',
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        isIndo ? 'Peran Cerita' : 'Story Role',
                        style: AppTypography.labelMd.copyWith(color: c.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: CharacterRole.values.map((role) {
                          final isSelected = _selectedRole == role;
                          return ChoiceChip(
                            label: Text(role.getLabel(l10n)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedRole = role);
                            },
                            selectedColor: c.primarySoft,
                            backgroundColor: c.surfaceSecondary,
                            checkmarkColor: c.textPrimary,
                            labelStyle: isSelected
                                ? AppTypography.labelSm.copyWith(
                                    color: c.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  )
                                : AppTypography.bodySm.copyWith(
                                    color: c.textSecondary,
                                  ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Gender Section (Male: Blue, Female: Pink, Custom: Gray)
                      Row(
                        children: [
                          Text(
                            isIndo ? 'Jenis Kelamin' : 'Gender',
                            style: AppTypography.labelMd.copyWith(color: c.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Builder(builder: (ctx) {
                        final isDark = Theme.of(ctx).brightness == Brightness.dark;
                        final isMale = _selectedGender == CharacterGender.male;
                        final isFemale = _selectedGender == CharacterGender.female;
                        final isCustom = _selectedGender == CharacterGender.custom;
                        return Row(
                          children: [
                            ChoiceChip(
                              avatar: Icon(
                                Symbols.male,
                                size: 16,
                                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                              ),
                              label: Text(
                                isIndo ? 'Pria' : 'Male',
                                style: TextStyle(
                                  color: isMale
                                      ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))
                                      : c.textSecondary,
                                  fontWeight: isMale ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                              selected: isMale,
                              selectedColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE),
                              backgroundColor: c.surfaceSecondary,
                              checkmarkColor: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedGender = CharacterGender.male);
                              },
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            ChoiceChip(
                              avatar: Icon(
                                Symbols.female,
                                size: 16,
                                color: isDark ? const Color(0xFFFBCFE8) : const Color(0xFFBE185D),
                              ),
                              label: Text(
                                isIndo ? 'Wanita' : 'Female',
                                style: TextStyle(
                                  color: isFemale
                                      ? (isDark ? const Color(0xFFFBCFE8) : const Color(0xFFBE185D))
                                      : c.textSecondary,
                                  fontWeight: isFemale ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                              selected: isFemale,
                              selectedColor: isDark ? const Color(0xFF501B34) : const Color(0xFFFCE7F3),
                              backgroundColor: c.surfaceSecondary,
                              checkmarkColor: isDark ? const Color(0xFFFBCFE8) : const Color(0xFFBE185D),
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedGender = CharacterGender.female);
                              },
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            ChoiceChip(
                              avatar: Icon(Symbols.person, size: 16, color: c.textSecondary),
                              label: Text(
                                isIndo ? 'Kustom' : 'Custom',
                                style: TextStyle(
                                  color: isCustom ? c.textPrimary : c.textSecondary,
                                  fontWeight: isCustom ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                              selected: isCustom,
                              selectedColor: c.primarySoft,
                              backgroundColor: c.surfaceSecondary,
                              checkmarkColor: c.textPrimary,
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedGender = CharacterGender.custom);
                              },
                            ),
                          ],
                        );
                      },),
                      if (_selectedGender == CharacterGender.custom) ...[
                        const SizedBox(height: AppSpacing.sm),
                        NvTextField(
                          controller: _customGenderController,
                          hintText: isIndo
                              ? 'Masukkan jenis kelamin kustom (mis. Non-Biner, Android, Agender)'
                              : 'Enter custom gender (e.g. Non-Binary, Android, Agender)',
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),

                      // Race / Species Section
                      Text(
                        isIndo ? 'Ras / Spesies' : 'Race / Species',
                        style: AppTypography.labelMd.copyWith(color: c.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: CharacterRacePreset.presets.map((race) {
                            final isSelected = _selectedRace == race;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(race),
                                selected: isSelected,
                                selectedColor: c.primarySoft,
                                backgroundColor: c.surfaceSecondary,
                                checkmarkColor: c.textPrimary,
                                labelStyle: isSelected
                                    ? AppTypography.labelSm.copyWith(
                                        color: c.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      )
                                    : AppTypography.bodySm.copyWith(
                                        color: c.textSecondary,
                                      ),
                                onSelected: (selected) {
                                  if (selected) setState(() => _selectedRace = race);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (_selectedRace == 'Custom') ...[
                        const SizedBox(height: AppSpacing.sm),
                        NvTextField(
                          controller: _customRaceController,
                          hintText: isIndo
                              ? 'Masukkan ras kustom (mis. Raja Vampir, Celestial, Cyborg)'
                              : 'Enter custom race (e.g. Vampire Lord, Celestial, Cyborg)',
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),

                      // Psychological Core Section
                      Text(
                        isIndo ? 'Inti Psikologis' : 'Psychological Core',
                        style: AppTypography.sectionTitle.copyWith(color: c.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Text(
                        isIndo ? 'Keinginan Utama / Tujuan' : 'Primary Desire / Goal',
                        style: AppTypography.labelMd.copyWith(color: c.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      NvTextField(
                        controller: _goalController,
                        hintText: isIndo
                            ? 'Apa yang paling mereka inginkan di atas segalanya?'
                            : 'What do they want more than anything?',
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Text(
                        isIndo ? 'Kelemahan Fatal' : 'Fatal Flaw',
                        style: AppTypography.labelMd.copyWith(color: c.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      NvTextField(
                        controller: _flawController,
                        hintText: isIndo
                            ? 'Keyakinan atau kelemahan internal apa yang menghambat mereka?'
                            : 'What internal belief or weakness holds them back?',
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Text(
                        isIndo ? 'Ketakutan Terdalam' : 'Deepest Fear',
                        style: AppTypography.labelMd.copyWith(color: c.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      NvTextField(
                        controller: _fearController,
                        hintText: isIndo
                            ? 'Apa yang paling mereka takuti untuk dihadapi?'
                            : 'What are they terrified of confronting?',
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Text(
                        isIndo ? 'Rahasia Tersembunyi' : 'Hidden Secret',
                        style: AppTypography.labelMd.copyWith(color: c.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      NvTextField(
                        controller: _secretController,
                        hintText: isIndo
                            ? 'Apa yang mereka sembunyikan dari dunia?'
                            : 'What do they hide from the world?',
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Text(
                        isIndo ? 'Ringkasan Psikologis (Opsional)' : 'Psychological Summary (Optional)',
                        style: AppTypography.labelMd.copyWith(color: c.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      NvTextField(
                        controller: _summaryController,
                        hintText: isIndo
                            ? 'Jiwa internal, arsitektur moral, atau perspektif filosofis...'
                            : 'Internal psyche, moral architecture, or philosophical perspective...',
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Fixed Create / Save Button at Bottom
              NvButton(
                label: widget.characterToEdit != null
                    ? (l10n?.saveChanges ?? 'Save Changes')
                    : (l10n?.createCharacter ?? 'Create Character'),
                variant: NvButtonVariant.primary,
                icon: Symbols.check,
                isLoading: _isCreating,
                onPressed: _isCreating ? null : _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
