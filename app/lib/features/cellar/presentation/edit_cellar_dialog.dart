import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/services/cellar_location_service.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/cellar.dart';

class EditCellarDialog extends ConsumerStatefulWidget {
  final Cellar cellar;

  const EditCellarDialog({super.key, required this.cellar});

  static Future<void> show(BuildContext context, Cellar cellar) {
    return showDialog(
      context: context,
      builder: (ctx) => EditCellarDialog(cellar: cellar),
    );
  }

  @override
  ConsumerState<EditCellarDialog> createState() => _EditCellarDialogState();
}

class _EditCellarDialogState extends ConsumerState<EditCellarDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _wifiController;
  late TextEditingController _latController;
  late TextEditingController _lonController;

  late int _radiusMeters;
  bool _isSaving = false;
  bool _isLocatingGps = false;
  bool _isDetectingWifi = false;

  @override
  void initState() {
    super.initState();
    final c = widget.cellar;
    _nameController = TextEditingController(text: c.name);
    _nicknameController = TextEditingController(text: c.nickname ?? '');
    _locationController = TextEditingController(text: c.locationName ?? '');
    _descriptionController = TextEditingController(text: c.description ?? '');
    _wifiController = TextEditingController(text: c.wifiSsid ?? '');
    _latController = TextEditingController(text: c.latitude != null ? c.latitude!.toStringAsFixed(6) : '');
    _lonController = TextEditingController(text: c.longitude != null ? c.longitude!.toStringAsFixed(6) : '');
    _radiusMeters = c.radiusMeters > 0 ? c.radiusMeters : 300;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _wifiController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _captureCurrentWifi() async {
    setState(() => _isDetectingWifi = true);
    final l10n = AppLocalizations.of(context);
    try {
      final ssid = await CellarLocationService.getCurrentWifiSsid();
      if (ssid != null && ssid.isNotEmpty) {
        setState(() => _wifiController.text = ssid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.cellarWifiDetectedSuccess(ssid) ?? '📡 Wi-Fi détecté et associé : "$ssid"'),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.cellarWifiDetectionFailed ?? 'Impossible de détecter le Wi-Fi (activez la localisation ou saisissez le nom manuellement)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isDetectingWifi = false);
    }
  }

  Future<void> _captureCurrentGps() async {
    setState(() => _isLocatingGps = true);
    final l10n = AppLocalizations.of(context);
    try {
      final pos = await CellarLocationService.getCurrentPosition();
      if (pos != null) {
        setState(() {
          _latController.text = pos.latitude.toStringAsFixed(6);
          _lonController.text = pos.longitude.toStringAsFixed(6);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.cellarGpsCoordsCaptured(pos.latitude.toStringAsFixed(4), pos.longitude.toStringAsFixed(4)) ??
                  '📍 Coordonnées GPS capturées (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})'),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.cellarGpsInaccessible ?? 'Position GPS inaccessible. Vérifiez les autorisations de localisation.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLocatingGps = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final nickname = _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim();
    final locName = _locationController.text.trim().isEmpty ? null : _locationController.text.trim();
    final desc = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();
    final wifi = _wifiController.text.trim().isEmpty ? null : _wifiController.text.trim();
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());

    try {
      final repo = ref.read(cellarRepositoryProvider);
      await repo.updateCellar(
        widget.cellar.id,
        name: name,
        nickname: nickname,
        locationName: locName,
        description: desc,
        latitude: lat,
        longitude: lon,
        wifiSsid: wifi,
        radiusMeters: _radiusMeters,
      );

      ref.invalidate(userCellarsProvider);
      ref.invalidate(currentCellarIdProvider);
      ref.invalidate(bottlesProvider(widget.cellar.id));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.cellarUpdatedSuccess(name) ?? '✅ Paramètres de la cave "$name" mis à jour'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.cellarUpdateError('$e') ?? 'Erreur lors de la mise à jour : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B1E3F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.settings, color: Color(0xFF8B1E3F), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n?.cellarManageTitle ?? 'Gérer la cave',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. General info
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n?.cellarNameLabel ?? 'Nom de la cave *',
                    hintText: l10n?.cellarNameHint ?? 'ex: Cave Principale, Cave de Bordeaux',
                    prefixIcon: const Icon(Icons.wine_bar),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? (l10n?.cellarNameRequired ?? 'Veuillez saisir un nom') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    labelText: l10n?.cellarNicknameLabel ?? 'Surnom / Alias (optionnel)',
                    hintText: l10n?.cellarNicknameHint ?? 'ex: Maison, Campagne, Cellier',
                    prefixIcon: const Icon(Icons.label_outline),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: l10n?.cellarLocationLabel ?? 'Ville ou Emplacement',
                    hintText: l10n?.cellarLocationHint ?? 'ex: Paris 15e, Beaune, Sous-sol',
                    prefixIcon: const Icon(Icons.location_city_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n?.cellarDescriptionLabel ?? 'Description / Remarques',
                    hintText: l10n?.cellarDescriptionHint ?? 'ex: Température constante 12°C, hygrométrie 70%',
                    prefixIcon: const Icon(Icons.notes_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // 2. Intelligent Auto-Detection Section
                Row(
                  children: [
                    const Icon(Icons.sensors, color: Color(0xFF8B1E3F), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n?.cellarAutoDetectionHeader ?? 'Détection & Transition Automatique',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B1E3F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n?.cellarAutoDetectionDesc ?? 'Associez votre réseau Wi-Fi ou vos coordonnées GPS pour que l\'application bascule automatiquement sur cette cave dès que vous y êtes.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),

                // Wi-Fi SSID
                TextFormField(
                  controller: _wifiController,
                  decoration: InputDecoration(
                    labelText: l10n?.cellarWifiLabel ?? 'Réseau Wi-Fi (SSID)',
                    hintText: l10n?.cellarWifiHint ?? 'ex: Livebox-Cave, Freebox_Maison',
                    prefixIcon: const Icon(Icons.wifi),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: _isDetectingWifi
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location, color: Color(0xFF8B1E3F)),
                      tooltip: l10n?.cellarCaptureCurrentWifiTooltip ?? 'Capturer le Wi-Fi actuel',
                      onPressed: _isDetectingWifi ? null : _captureCurrentWifi,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // GPS Coordinates
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(
                          labelText: l10n?.cellarLatitudeLabel ?? 'Latitude',
                          hintText: '48.8566',
                          prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lonController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(
                          labelText: l10n?.cellarLongitudeLabel ?? 'Longitude',
                          hintText: '2.3522',
                          prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isLocatingGps ? null : _captureCurrentGps,
                    icon: _isLocatingGps
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.gps_fixed, size: 16),
                    label: Text(l10n?.cellarUseCurrentGps ?? 'Définir avec ma position GPS actuelle'),
                  ),
                ),
                const SizedBox(height: 8),

                // Detection Radius
                DropdownButtonFormField<int>(
                  initialValue: _radiusMeters,
                  decoration: InputDecoration(
                    labelText: l10n?.cellarRadiusLabel ?? 'Rayon de détection GPS',
                    prefixIcon: const Icon(Icons.radar),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 100, child: Text(l10n?.cellarRadiusPrecise ?? '100 mètres (très précis)')),
                    DropdownMenuItem(value: 300, child: Text(l10n?.cellarRadiusRecommended ?? '300 mètres (recommandé)')),
                    DropdownMenuItem(value: 500, child: Text(l10n?.cellarRadius500m ?? '500 mètres')),
                    DropdownMenuItem(value: 1000, child: Text(l10n?.cellarRadius1km ?? '1 kilomètre')),
                    DropdownMenuItem(value: 3000, child: Text(l10n?.cellarRadius3km ?? '3 kilomètres')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _radiusMeters = val);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.cancel ?? 'Annuler'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF8B1E3F),
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(l10n?.save ?? 'Enregistrer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
