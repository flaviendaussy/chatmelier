import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/bar_equipment.dart';

const String _kBarEquipmentStorageKey = 'chatmelier_bar_equipment_v1';

final barEquipmentServiceProvider = Provider<BarEquipmentService>((ref) {
  return BarEquipmentService();
});

final barEquipmentProvider =
    StateNotifierProvider<BarEquipmentNotifier, BarEquipment>((ref) {
  final service = ref.watch(barEquipmentServiceProvider);
  return BarEquipmentNotifier(service);
});

class BarEquipmentService {
  Future<BarEquipment> loadEquipment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kBarEquipmentStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return BarEquipment.fromJson(decoded);
      }
    } catch (_) {}
    return const BarEquipment();
  }

  Future<void> saveEquipment(BarEquipment equipment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(equipment.toJson());
      await prefs.setString(_kBarEquipmentStorageKey, jsonString);
    } catch (_) {}
  }
}

class BarEquipmentNotifier extends StateNotifier<BarEquipment> {
  final BarEquipmentService _service;

  BarEquipmentNotifier(this._service) : super(const BarEquipment()) {
    _load();
  }

  Future<void> _load() async {
    state = await _service.loadEquipment();
  }

  Future<void> setHasShaker(bool value) async {
    state = state.copyWith(hasShaker: value);
    await _service.saveEquipment(state);
  }

  Future<void> setHasJigger(bool value) async {
    state = state.copyWith(hasJigger: value);
    await _service.saveEquipment(state);
  }

  Future<void> setHasStrainer(bool value) async {
    state = state.copyWith(hasStrainer: value);
    await _service.saveEquipment(state);
  }

  Future<void> setHasMuddler(bool value) async {
    state = state.copyWith(hasMuddler: value);
    await _service.saveEquipment(state);
  }

  Future<void> setHasBarSpoon(bool value) async {
    state = state.copyWith(hasBarSpoon: value);
    await _service.saveEquipment(state);
  }

  Future<void> update(BarEquipment equipment) async {
    state = equipment;
    await _service.saveEquipment(state);
  }
}
