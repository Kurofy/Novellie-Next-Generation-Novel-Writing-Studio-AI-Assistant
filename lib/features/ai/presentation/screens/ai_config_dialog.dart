import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/ai_providers.dart';
import '../../domain/models/ai_models.dart';

class AiConfigDialog extends ConsumerStatefulWidget {
  const AiConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AiConfigDialog(),
    );
  }

  @override
  ConsumerState<AiConfigDialog> createState() => _AiConfigDialogState();
}

class _AiConfigDialogState extends ConsumerState<AiConfigDialog> {
  late AiProviderType _provider;
  late Map<AiProviderType, String> _keysByProvider;
  late Map<AiProviderType, String> _modelsByProvider;
  late TextEditingController _apiKeyController;
  late TextEditingController _customModelController;
  late TextEditingController _baseUrlController;
  late String _selectedModel;
  bool _isCustomModel = false;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final currentConfig =
        ref.read(aiConfigProvider).valueOrNull ?? const AiConfigModel();
    _provider = currentConfig.provider;
    _keysByProvider = Map<AiProviderType, String>.from(currentConfig.apiKeys);
    _modelsByProvider = Map<AiProviderType, String>.from(currentConfig.models);

    final currentKey = _keysByProvider[_provider] ?? '';
    _apiKeyController = TextEditingController(text: currentKey);

    var activeModel = _modelsByProvider[_provider] ?? _provider.defaultModel;
    if (_provider == AiProviderType.gemini &&
        (activeModel.contains('latest') ||
            activeModel.contains('1.5-flash') ||
            activeModel == 'gemini-2.5-flash')) {
      activeModel = _provider.defaultModel;
      _modelsByProvider[_provider] = activeModel;
    }
    if (_provider.availableModels.contains(activeModel)) {
      _selectedModel = activeModel;
      _isCustomModel = false;
      _customModelController = TextEditingController();
    } else {
      _selectedModel = '__custom__';
      _isCustomModel = true;
      _customModelController = TextEditingController(text: activeModel);
    }

    _baseUrlController =
        TextEditingController(text: currentConfig.customBaseUrl ?? '');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _customModelController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  void _onProviderChanged(AiProviderType? newProvider) {
    if (newProvider == null || newProvider == _provider) return;

    // Save current provider's inputs into scoped state before switching
    _keysByProvider[_provider] = _apiKeyController.text.trim();
    final currentModelToSave = _isCustomModel
        ? _customModelController.text.trim()
        : _selectedModel;
    _modelsByProvider[_provider] = currentModelToSave.isNotEmpty
        ? currentModelToSave
        : _provider.defaultModel;

    setState(() {
      _provider = newProvider;

      // Scoped key management:
      // If new provider has a saved key, populate it.
      // If no saved key for this provider, reset API key input to empty.
      final savedKey = _keysByProvider[newProvider];
      if (savedKey != null && savedKey.isNotEmpty) {
        _apiKeyController.text = savedKey;
      } else {
        _apiKeyController.text = '';
      }

      // Populate models dynamically based on the selected provider
      var savedModel =
          _modelsByProvider[newProvider] ?? newProvider.defaultModel;
      if (newProvider == AiProviderType.gemini &&
          (savedModel.contains('latest') ||
              savedModel.contains('1.5-flash') ||
              savedModel == 'gemini-2.5-flash')) {
        savedModel = newProvider.defaultModel;
        _modelsByProvider[newProvider] = savedModel;
      }
      if (newProvider.availableModels.contains(savedModel)) {
        _selectedModel = savedModel;
        _isCustomModel = false;
      } else {
        _selectedModel = '__custom__';
        _isCustomModel = true;
        _customModelController.text = savedModel;
      }
    });
  }

  Future<void> _handleSave() async {
    // Record active inputs into scoped state
    _keysByProvider[_provider] = _apiKeyController.text.trim();
    final modelToSave = _isCustomModel
        ? _customModelController.text.trim()
        : _selectedModel;
    _modelsByProvider[_provider] = modelToSave.isNotEmpty
        ? modelToSave
        : _provider.defaultModel;

    final baseUrl = _baseUrlController.text.trim();

    final config = AiConfigModel(
      provider: _provider,
      apiKeys: _keysByProvider,
      models: _modelsByProvider,
      customBaseUrl: baseUrl.isNotEmpty ? baseUrl : null,
    );

    await ref.read(aiConfigProvider.notifier).updateConfig(config);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _handleClearActiveProvider() async {
    setState(() {
      _keysByProvider[_provider] = '';
      _apiKeyController.text = '';
    });

    final config = AiConfigModel(
      provider: _provider,
      apiKeys: _keysByProvider,
      models: _modelsByProvider,
      customBaseUrl: _baseUrlController.text.trim().isNotEmpty
          ? _baseUrlController.text.trim()
          : null,
    );

    await ref.read(aiConfigProvider.notifier).updateConfig(config);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final c = context.colors;
    final hasActiveKey = (_keysByProvider[_provider]?.isNotEmpty ?? false) ||
        _apiKeyController.text.trim().isNotEmpty;

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
                  child: Row(
                    children: [
                      Icon(Symbols.auto_awesome, color: c.primary, size: 24),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          isIndo ? 'Pengaturan Penyedia AI (BYOK)' : 'AI Provider Settings (BYOK)',
                          style: AppTypography.screenTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Symbols.close),
                  tooltip: isIndo ? 'Tutup' : 'Close',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isIndo
                  ? 'Kunci API disimpan secara aman per-penyedia di perangkat Anda dan tidak pernah dibagikan antar penyedia.'
                  : 'API keys are stored securely per-provider on your device and are never shared or leaked across providers.',
              style: AppTypography.bodySm.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Provider Dropdown
            Text(isIndo ? 'Penyedia AI' : 'AI Provider', style: AppTypography.labelMd),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<AiProviderType>(
              key: ValueKey(_provider),
              initialValue: _provider,
              items: AiProviderType.values
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.localizedLabel(isIndo)),
                    ),
                  )
                  .toList(),
              onChanged: _onProviderChanged,
              decoration: InputDecoration(
                filled: true,
                fillColor: c.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide(color: c.outlineVariant),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Model Selector Dropdown
            Text(isIndo ? 'Pilihan Model' : 'Model Selection', style: AppTypography.labelMd),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<String>(
              key: ValueKey('$_provider-$_selectedModel-$_isCustomModel'),
              initialValue: _isCustomModel ? '__custom__' : _selectedModel,
              items: [
                ..._provider.availableModels.map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(m),
                  ),
                ),
                DropdownMenuItem(
                  value: '__custom__',
                  child: Text(isIndo ? 'Pengidentifikasi Model Kustom...' : 'Custom Model Identifier...'),
                ),
              ],
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  if (val == '__custom__') {
                    _isCustomModel = true;
                    if (_customModelController.text.isEmpty) {
                      _customModelController.text = _provider.defaultModel;
                    }
                  } else {
                    _isCustomModel = false;
                    _selectedModel = val;
                    _modelsByProvider[_provider] = val;
                  }
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: c.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide(color: c.outlineVariant),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Custom Model input if custom option selected
            if (_isCustomModel) ...[
              const SizedBox(height: AppSpacing.xs),
              NvTextField(
                controller: _customModelController,
                hintText: isIndo
                    ? 'Masukkan nama model (cth. ${_provider.defaultModel})'
                    : 'Enter model name (e.g. ${_provider.defaultModel})',
                onChanged: (val) {
                  _modelsByProvider[_provider] = val.trim();
                },
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            // Scoped API Key Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_provider.localizedLabel(isIndo)} ${isIndo ? 'Kunci API' : 'API Key'}',
                  style: AppTypography.labelMd,
                ),
                if (_keysByProvider[_provider]?.isNotEmpty ?? false)
                  Text(
                    isIndo ? 'Terkonfigurasi untuk ${_provider.localizedLabel(isIndo)}' : 'Configured for ${_provider.label}',
                    style: AppTypography.bodySm.copyWith(
                      color: c.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            NvTextField(
              controller: _apiKeyController,
              hintText: isIndo
                  ? 'Tempel kunci API ${_provider.localizedLabel(isIndo)} di sini'
                  : 'Paste ${_provider.label} API key here',
              obscureText: _obscureKey,
              trailingIcon:
                  _obscureKey ? Symbols.visibility : Symbols.visibility_off,
              onTrailingTap: () => setState(() => _obscureKey = !_obscureKey),
              onChanged: (val) {
                _keysByProvider[_provider] = val.trim();
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Custom Base URL (if custom or Anthropic/OpenAI custom endpoint)
            if (_provider == AiProviderType.custom) ...[
              Text(
                isIndo ? 'URL Dasar (Kompatibel OpenAI / Ollama)' : 'Base URL (OpenAI / Ollama Compatible)',
                style: AppTypography.labelMd,
              ),
              const SizedBox(height: AppSpacing.xs),
              NvTextField(
                controller: _baseUrlController,
                hintText: 'http://localhost:11434/v1',
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                if (hasActiveKey) ...[
                  Expanded(
                    child: NvButton.secondary(
                      label: isIndo ? 'Putuskan (${_provider.name})' : 'Disconnect (${_provider.name})',
                      onPressed: _handleClearActiveProvider,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: NvButton.primary(
                    label: isIndo ? 'Simpan & Hubungkan' : 'Save & Connect',
                    onPressed: _handleSave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
