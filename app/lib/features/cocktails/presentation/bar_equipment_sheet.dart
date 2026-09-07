import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/bar_equipment_service.dart';

class BarEquipmentSheet extends ConsumerWidget {
  const BarEquipmentSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const BarEquipmentSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final equipment = ref.watch(barEquipmentProvider);
    final notifier = ref.read(barEquipmentProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.handyman_outlined, color: Color(0xFF8B1E3F), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon Matériel de Bar',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Indiquez vos ustensiles pour adapter les recettes',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 1. Shaker
          _buildEquipmentSwitch(
            title: 'Shaker à cocktail',
            subtitle: 'Cobbler, Boston ou Parisien',
            diyTip: 'Alternative : Pot de confiture hermétique (Bonne Maman) ou shaker de sport.',
            icon: '🍸',
            value: equipment.hasShaker,
            onChanged: (val) => notifier.setHasShaker(val),
            isDark: isDark,
          ),

          // 2. Jigger / Doseur
          _buildEquipmentSwitch(
            title: 'Doseur gradué (Jigger)',
            subtitle: 'Doseur double (ex: 2cl / 4cl)',
            diyTip: 'Alternative : 1 cuillère à soupe = 15 ml (1,5 cl), 1 shooter = 30 ml.',
            icon: '⚖️',
            value: equipment.hasJigger,
            onChanged: (val) => notifier.setHasJigger(val),
            isDark: isDark,
          ),

          // 3. Strainer / Passoire
          _buildEquipmentSwitch(
            title: 'Passoire à cocktail (Strainer)',
            subtitle: 'Hawthorne, Julep ou fine passoire',
            diyTip: 'Alternative : Petite passoire à thé ou couvercle entrouvert.',
            icon: '🥄',
            value: equipment.hasStrainer,
            onChanged: (val) => notifier.setHasStrainer(val),
            isDark: isDark,
          ),

          // 4. Pilon / Muddler
          _buildEquipmentSwitch(
            title: 'Pilon (Muddler)',
            subtitle: 'Pour extraire les huiles des agrumes et herbes',
            diyTip: 'Alternative : Le manche plat d\'une cuillère en bois.',
            icon: '🪵',
            value: equipment.hasMuddler,
            onChanged: (val) => notifier.setHasMuddler(val),
            isDark: isDark,
          ),

          // 5. Cuillère à mélange
          _buildEquipmentSwitch(
            title: 'Cuillère à mélange torsadée',
            subtitle: 'Pour les cocktails remués sans bulles d\'air',
            diyTip: 'Alternative : Une cuillère à glace à long manche ou baguette propre.',
            icon: '🥢',
            value: equipment.hasBarSpoon,
            onChanged: (val) => notifier.setHasBarSpoon(val),
            isDark: isDark,
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Enregistrer mon matériel',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSwitch({
    required String title,
    required String subtitle,
    required String diyTip,
    required String icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? const Color(0xFF8B1E3F).withValues(alpha: 0.4)
              : (isDark ? Colors.white10 : Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Switch(
                value: value,
                activeColor: const Color(0xFF8B1E3F),
                onChanged: onChanged,
              ),
            ],
          ),
          if (!value) ...[
            Padding(
              padding: const EdgeInsets.only(left: 30, bottom: 4),
              child: Text(
                '💡 $diyTip',
                style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Colors.orange),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
