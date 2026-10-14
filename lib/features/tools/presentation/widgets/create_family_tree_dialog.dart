import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../characters/application/character_providers.dart';
import '../../../characters/domain/models/character_model.dart';
import '../../domain/models/family_tree_models.dart';

class CreateFamilyTreeDialog extends ConsumerStatefulWidget {
  final String novelId;

  const CreateFamilyTreeDialog({
    super.key,
    required this.novelId,
  });

  static Future<FamilyTree?> show(BuildContext context, String novelId) {
    return showDialog<FamilyTree>(
      context: context,
      builder: (_) => CreateFamilyTreeDialog(novelId: novelId),
    );
  }

  @override
  ConsumerState<CreateFamilyTreeDialog> createState() =>
      _CreateFamilyTreeDialogState();
}

class _CreateFamilyTreeDialogState
    extends ConsumerState<CreateFamilyTreeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  // Root character option: 'existing' or 'custom' or 'none'
  String _rootSelectionMode = 'existing';
  CharacterModel? _selectedCharacter;

  final _customRootNameController = TextEditingController();
  final _customRootRoleController =
      TextEditingController(text: 'Founder / Progenitor');
  String _customGender = 'female';

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _customRootNameController.dispose();
    _customRootRoleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final charactersAsync =
        ref.watch(charactersStreamProvider(widget.novelId));

    return Dialog(
      backgroundColor: c.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Symbols.family_restroom,
                        color: Color(0xFFD97706),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isIndo ? 'Buat Pohon Silsilah' : 'Create Family Tree',
                            style: AppTypography.screenTitle.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isIndo
                                ? 'Buat pohon garis keturunan tersendiri untuk karakter atau dinasti.'
                                : 'Establish a distinct lineage tree for a character or dynasty.',
                            style: AppTypography.bodySm
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

                const SizedBox(height: 20),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tree Name field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: isIndo
                                ? 'Nama Pohon Silsilah / Dinasti *'
                                : 'Family Tree / Dynasty Name *',
                            hintText: isIndo
                                ? 'misalnya Wangsa Blackwood, Silsilah Elena'
                                : 'e.g. House Blackwood, Elena\'s Lineage',
                            prefixIcon: const Icon(Symbols.shield),
                            filled: true,
                            fillColor: c.surfaceSecondary,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isIndo
                                  ? 'Silakan masukkan nama pohon silsilah'
                                  : 'Please enter a name for the family tree';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Description
                        TextFormField(
                          controller: _descController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: isIndo
                                ? 'Lore / Deskripsi Garis Keturunan (Opsional)'
                                : 'Lineage Lore / Description (Optional)',
                            hintText: isIndo
                                ? 'Catatan singkat tentang dinasti keluarga, takhta leluhur, atau sejarah...'
                                : 'Brief notes on this family dynasty, ancestral seat, or history...',
                            prefixIcon: const Icon(Symbols.history_edu),
                            filled: true,
                            fillColor: c.surfaceSecondary,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          isIndo
                              ? 'Leluhur / Karakter Awal'
                              : 'Root Progenitor / Starting Character',
                          style: AppTypography.labelMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Segmented selection mode
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'existing',
                              label: Text(isIndo ? 'Karakter Novel' : 'Novel Character'),
                              icon: const Icon(Symbols.person, size: 16),
                            ),
                            ButtonSegment(
                              value: 'custom',
                              label: Text(isIndo ? 'Leluhur Baru' : 'New Ancestor'),
                              icon: const Icon(Symbols.person_add, size: 16),
                            ),
                            ButtonSegment(
                              value: 'none',
                              label: Text(isIndo ? 'Pohon Kosong' : 'Empty Tree'),
                              icon: const Icon(Symbols.crop_square, size: 16),
                            ),
                          ],
                          selected: {_rootSelectionMode},
                          onSelectionChanged: (val) {
                            setState(() {
                              _rootSelectionMode = val.first;
                            });
                          },
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),

                        const SizedBox(height: 14),

                        if (_rootSelectionMode == 'existing') ...[
                          charactersAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(
                                  child: CircularProgressIndicator.adaptive(),),
                            ),
                            error: (e, _) => Text(
                              '${isIndo ? "Gagal memuat karakter:" : "Failed to load characters:"} $e',
                              style: TextStyle(color: c.error),
                            ),
                            data: (characters) {
                              if (characters.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: c.surfaceSecondary,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.card),
                                  ),
                                  child: Text(
                                    isIndo
                                        ? 'Belum ada karakter yang dibuat di novel ini. Anda dapat menambahkan leluhur kustom baru.'
                                        : 'No characters created yet in this novel. You can add a new custom ancestor instead.',
                                    style: AppTypography.bodySm
                                        .copyWith(color: c.textSecondary),
                                  ),
                                );
                              }

                              return DropdownButtonFormField<CharacterModel>(
                                initialValue: _selectedCharacter,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: isIndo ? 'Pilih Karakter Awal' : 'Select Root Character',
                                  filled: true,
                                  fillColor: c.surfaceSecondary,
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.card),
                                  ),
                                ),
                                hint: Text(isIndo ? 'Pilih karakter awal...' : 'Choose starting character...'),
                                items: characters.map((ch) {
                                  return DropdownMenuItem<CharacterModel>(
                                    value: ch,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: const Color(0xFFD97706)
                                              .withValues(alpha: 0.2),
                                          child: Text(
                                            ch.name.isNotEmpty
                                                ? ch.name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFD97706),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            ch.name,
                                            style: TextStyle(
                                                color: c.textPrimary,),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          ' (${ch.role.getLabel(l10n)})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (ch) {
                                  setState(() {
                                    _selectedCharacter = ch;
                                    if (_nameController.text.isEmpty &&
                                        ch != null) {
                                      _nameController.text = isIndo
                                          ? 'Silsilah ${ch.name}'
                                          : '${ch.name}\'s Lineage';
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ] else if (_rootSelectionMode == 'custom') ...[
                          TextFormField(
                            controller: _customRootNameController,
                            decoration: InputDecoration(
                              labelText: isIndo
                                  ? 'Nama Leluhur / Pendiri *'
                                  : 'Ancestor / Progenitor Name *',
                              hintText: isIndo
                                  ? 'misalnya Tuan Aldous Blackwood'
                                  : 'e.g. Lord Aldous Blackwood',
                              filled: true,
                              fillColor: c.surfaceSecondary,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.card),
                              ),
                            ),
                            validator: (val) {
                              if (_rootSelectionMode == 'custom' &&
                                  (val == null || val.trim().isEmpty)) {
                                return isIndo
                                    ? 'Silakan masukkan nama leluhur'
                                    : 'Please enter the ancestor\'s name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _customRootRoleController,
                            decoration: InputDecoration(
                              labelText: isIndo
                                  ? 'Gelar Dinasti atau Peran'
                                  : 'Dynastic Title or Role',
                              hintText: isIndo
                                  ? 'misalnya Patriark, Pendiri, Raja Agung'
                                  : 'e.g. Patriarch, Founder, High King',
                              filled: true,
                              fillColor: c.surfaceSecondary,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.card),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _customGender,
                            decoration: InputDecoration(
                              labelText: isIndo ? 'Jenis Kelamin' : 'Gender',
                              filled: true,
                              fillColor: c.surfaceSecondary,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.card),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'female',
                                child: Text(isIndo ? 'Perempuan' : 'Female'),
                              ),
                              DropdownMenuItem(
                                value: 'male',
                                child: Text(isIndo ? 'Laki-laki' : 'Male'),
                              ),
                              DropdownMenuItem(
                                value: 'other',
                                child: Text(isIndo ? 'Lainnya' : 'Other'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _customGender = val);
                              }
                            },
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: c.surfaceSecondary,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                            ),
                            child: Text(
                              isIndo
                                  ? 'Pohon silsilah kosong akan dibuat. Anda dapat menambahkan karakter dan kerabat nanti di kanvas.'
                                  : 'An empty lineage tree will be created. You can add characters and relatives later on the canvas.',
                              style: AppTypography.bodySm
                                  .copyWith(color: c.textSecondary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(isIndo ? 'Batal' : 'Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Symbols.add, size: 18),
                      label: Text(isIndo ? 'Buat Pohon Silsilah' : 'Create Family Tree'),
                      onPressed: _handleSubmit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    String? rootCharId;
    String? rootCharName;
    String? rootRole;
    String? rootGender;
    String? rootAvatar;

    if (_rootSelectionMode == 'existing' && _selectedCharacter != null) {
      rootCharId = _selectedCharacter!.id;
      rootCharName = _selectedCharacter!.name;
      rootRole = _selectedCharacter!.role.label;
      rootGender = _selectedCharacter!.gender;
      rootAvatar = _selectedCharacter!.portraitPath;
    } else if (_rootSelectionMode == 'custom') {
      rootCharName = _customRootNameController.text.trim();
      rootRole = _customRootRoleController.text.trim();
      rootGender = _customGender;
    }

    final tree = FamilyTree(
      id: '', // Will be assigned by notifier/repo
      novelId: widget.novelId,
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      rootCharacterId: rootCharId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Pass back values via Navigator
    Navigator.of(context).pop(tree.copyWith(
      description: rootCharName != null ? 'ROOT:$rootCharName|ROLE:${rootRole ?? ''}|GENDER:${rootGender ?? ''}|AVATAR:${rootAvatar ?? ''}|CHARID:${rootCharId ?? ''}' : null,
    ),);
  }
}
