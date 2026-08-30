import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/services/cellar_location_service.dart';
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
    try {
      final ssid = await CellarLocationService.getCurrentWifiSsid();
      if (ssid != null && ssid.isNotEmpty) {
        setState(() => _wifiController.text = ssid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📡 Wi-Fi détecté et associé : "$ssid"'),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de détecter le Wi-Fi (activez la localisation ou saisissez le nom manuellement)'),
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
              content: Text('📍 Coordonnées GPS capturées (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})'),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Position GPS inaccessible. Vérifiez les autorisations de localisation.'),
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
            content: Text('✅ Paramètres de la cave "$name" mis à jour'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              'Gérer la cave',
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
                  decoration: const InputDecoration(
                    labelText: 'Nom de la cave *',
                    hintText: 'ex: Cave Principale, Cave de Bordeaux',
                    prefixIcon: Icon(Icons.wine_bar),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Veuillez saisir un nom' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Surnom / Alias (optionnel)',
                    hintText: 'ex: Maison, Campagne, Cellier',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Ville ou Emplacement',
                    hintText: 'ex: Paris 15e, Beaune, Sous-sol',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description / Remarques',
                    hintText: 'ex: Température constante 12°C, hygrométrie 70%',
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
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
                      'Détection & Transition Automatique',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B1E3F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Associez votre réseau Wi-Fi ou vos coordonnées GPS pour que l\'application bascule automatiquement sur cette cave dès que vous y êtes.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),

                // Wi-Fi SSID
                TextFormField(
                  controller: _wifiController,
                  decoration: InputDecoration(
                    labelText: 'Réseau Wi-Fi (SSID)',
                    hintText: 'ex: Livebox-Cave, Freebox_Maison',
                    prefixIcon: const Icon(Icons.wifi),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: _isDetectingWifi
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location, color: Color(0xFF8B1E3F)),
                      tooltip: 'Capturer le Wi-Fi actuel',
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
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          hintText: '48.8566',
                          prefixIcon: Icon(Icons.pin_drop_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lonController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          hintText: '2.3522',
                          prefixIcon: Icon(Icons.pin_drop_outlined, size: 20),
                          border: OutlineInputBorder(),
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
                    label: const Text('Définir avec ma position GPS actuelle'),
                  ),
                ),
                const SizedBox(height: 8),

                // Detection Radius
                DropdownButtonFormField<int>(
                  initialValue: _radiusMeters,
                  decoration: const InputDecoration(
                    labelText: 'Rayon de détection GPS',
                    prefixIcon: Icon(Icons.radar),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 100, child: Text('100 mètres (très précis)')),
                    DropdownMenuItem(value: 300, child: Text('300 mètres (recommandé)')),
                    DropdownMenuItem(value: 500, child: Text('500 mètres')),
                    DropdownMenuItem(value: 1000, child: Text('1 kilomètre')),
                    DropdownMenuItem(value: 3000, child: Text('3 kilomètres')),
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
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF8B1E3F),
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
