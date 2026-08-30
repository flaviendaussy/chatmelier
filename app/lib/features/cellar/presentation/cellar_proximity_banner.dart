import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/services/cellar_location_service.dart';
import '../domain/cellar.dart';

class CellarProximityBanner extends ConsumerStatefulWidget {
  const CellarProximityBanner({super.key});

  @override
  ConsumerState<CellarProximityBanner> createState() => _CellarProximityBannerState();
}

class _CellarProximityBannerState extends ConsumerState<CellarProximityBanner> {
  CellarProximityMatch? _proximityMatch;
  String? _dismissedCellarId;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocation();
    });
  }

  Future<void> _checkLocation() async {
    if (_isChecking) return;
    final rawList = ref.read(userCellarsProvider).value ?? [];
    final cellars = rawList.map((item) {
      final cMap = item['cellars'];
      if (cMap is Map<String, dynamic>) {
        return Cellar.fromJson(cMap);
      }
      return null;
    }).whereType<Cellar>().toList();

    final currentCellarId = ref.read(currentCellarIdProvider);

    if (cellars.isEmpty) return;

    setState(() => _isChecking = true);
    try {
      final match = await CellarLocationService.findProximityCellar(
        cellars: cellars,
        currentCellarId: currentCellarId,
      );

      if (mounted) {
        if (match != null &&
            match.cellar.id != currentCellarId &&
            match.cellar.id != _dismissedCellarId) {
          setState(() => _proximityMatch = match);
        } else {
          setState(() => _proximityMatch = null);
        }
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _dismiss() {
    setState(() {
      _dismissedCellarId = _proximityMatch?.cellar.id;
      _proximityMatch = null;
    });
  }

  void _switchToDetectedCellar() {
    final match = _proximityMatch;
    if (match == null) return;

    ref.read(currentCellarIdProvider.notifier).state = match.cellar.id;
    ref.invalidate(bottlesProvider(match.cellar.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📍 Basculé automatiquement vers "${match.cellar.displayName}"'),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 3),
      ),
    );

    setState(() => _proximityMatch = null);
  }

  @override
  Widget build(BuildContext context) {
    // Listen for cellar list changes or cellar switches to re-evaluate
    ref.listen(currentCellarIdProvider, (_, next) {
      if (_proximityMatch?.cellar.id == next) {
        setState(() => _proximityMatch = null);
      }
    });

    final match = _proximityMatch;
    if (match == null) return const SizedBox.shrink();

    final isWifi = match.matchType == ProximityMatchType.wifi;
    final accentColor = isWifi ? const Color(0xFF1976D2) : const Color(0xFF2E7D32);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWifi ? Icons.wifi : Icons.pin_drop,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Cave détectée : ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        match.cellar.displayName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  match.explanation,
                  style: TextStyle(
                    fontSize: 11,
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: _switchToDetectedCellar,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              backgroundColor: accentColor.withValues(alpha: 0.2),
              foregroundColor: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Basculer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            color: Colors.grey.shade600,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Ignorer',
            onPressed: _dismiss,
          ),
        ],
      ),
    );
  }
}
