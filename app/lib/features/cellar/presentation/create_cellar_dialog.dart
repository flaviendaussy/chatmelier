import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/services/cellar_location_service.dart';

class CreateCellarDialog extends ConsumerStatefulWidget {
  const CreateCellarDialog({super.key});

  @override
  ConsumerState<CreateCellarDialog> createState() => _CreateCellarDialogState();
}

class _CreateCellarDialogState extends ConsumerState<CreateCellarDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _wifiController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  int _radiusMeters = 300;
  bool _isCreating = false;
  bool _isLocatingGps = false;
  bool _isDetectingWifi = false;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final repo = ref.read(cellarRepositoryProvider);
      final lat = double.tryParse(_latController.text.trim());
      final lon = double.tryParse(_lonController.text.trim());

      final newCellar = await repo.createCellar(
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
        locationName: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        latitude: lat,
        longitude: lon,
        wifiSsid: _wifiController.text.trim().isEmpty ? null : _wifiController.text.trim(),
        radiusMeters: _radiusMeters,
      );

      // Select new cellar
      ref.read(currentCellarIdProvider.notifier).state = newCellar.id;
      ref.read(currentCellarRoleProvider.notifier).state = 'admin';
      ref.invalidate(userCellarsProvider);
      ref.invalidate(bottlesProvider(newCellar.id));

      if (mounted) {
        Navigator.of(context).pop(newCellar);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Cave "${newCellar.name}" créée avec succès !'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_home_work, color: Color(0xFF8B1E3F)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Créer une nouvelle cave',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la cave *',
                    hintText: 'ex: Cave de Londres, Cave des Vosges',
                    prefixIcon: Icon(Icons.wine_bar),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Veuillez saisir un nom' : null,
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Lieu / Ville (optionnel)',
                    hintText: 'ex: Londres (UK), Vosges (FR)',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Surnom / Pièce (optionnel)',
                    hintText: 'ex: Sous-sol, Cave à vin principale',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnel)',
                    hintText: 'ex: Cave enterrée fraîche, hygrométrie 70%',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Wi-Fi SSID
                TextFormField(
                  controller: _wifiController,
                  decoration: InputDecoration(
                    labelText: 'Wi-Fi associé (optionnel)',
                    hintText: 'ex: Livebox-Cave',
                    prefixIcon: const Icon(Icons.wifi),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: _isDetectingWifi
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location, color: Color(0xFF8B1E3F)),
                      tooltip: 'Associer au Wi-Fi actuel',
                      onPressed: _isDetectingWifi ? null : _captureCurrentWifi,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // GPS button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isLocatingGps ? null : _captureCurrentGps,
                    icon: _isLocatingGps
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.gps_fixed, size: 16),
                    label: Text(
                      _latController.text.isNotEmpty ? 'GPS: ${_latController.text.substring(0, 7)}...' : 'Définir position GPS actuelle',
                      style: const TextStyle(fontSize: 12),
                    ),
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
          onPressed: _isCreating ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF8B1E3F),
            foregroundColor: Colors.white,
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Créer la cave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
