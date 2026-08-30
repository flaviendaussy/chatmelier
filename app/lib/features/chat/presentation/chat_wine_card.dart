import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/wine_type_badge.dart';
import '../../cellar/domain/wine_service_advisor.dart';

class ChatWineCardData {
  final String? id;
  final String name;
  final int? vintage;
  final String? producer;
  final String? region;
  final String? appellation;
  final String wineType;
  final String? location;
  final String? reason;

  const ChatWineCardData({
    this.id,
    required this.name,
    this.vintage,
    this.producer,
    this.region,
    this.appellation,
    this.wineType = 'red',
    this.location,
    this.reason,
  });

  factory ChatWineCardData.fromJson(Map<String, dynamic> json) {
    return ChatWineCardData(
      id: json['id']?.toString() ?? json['bottle_id']?.toString(),
      name: json['name']?.toString() ?? json['wine_name']?.toString() ?? 'Vin',
      vintage: json['vintage'] is int ? json['vintage'] : int.tryParse(json['vintage']?.toString() ?? ''),
      producer: json['producer']?.toString(),
      region: json['region']?.toString(),
      appellation: json['appellation']?.toString(),
      wineType: json['wine_type']?.toString() ?? json['color']?.toString() ?? 'red',
      location: json['location']?.toString() ?? json['rack']?.toString(),
      reason: json['reason']?.toString(),
    );
  }
}

class ChatWineCard extends StatelessWidget {
  final ChatWineCardData data;

  const ChatWineCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFr = Localizations.localeOf(context).languageCode != 'en';
    final vintageStr = data.vintage != null ? '${data.vintage}' : (isFr ? 'NM' : 'NV');
    final hasBottleId = data.id != null && data.id!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B1E3F).withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFF8B1E3F), size: 18),
                const SizedBox(width: 6),
                Text(
                  'Recommandation Chatmelier',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8B1E3F),
                  ),
                ),
                const Spacer(),
                WineTypeBadge(type: data.wineType),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Vintage
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.wine_bar, color: Color(0xFF8B1E3F), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data.name} ($vintageStr)',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (data.producer != null && data.producer!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              data.producer!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (data.region != null && data.region!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              '📍 ${data.region}${data.appellation != null ? " • ${data.appellation}" : ""}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                if (data.location != null && data.location!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          'Emplacement : ${data.location}',
                          style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],

                if (data.reason != null && data.reason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '💬 ${data.reason}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Action Buttons Row
                Row(
                  children: [
                    // Service & Decanting Sheet
                    IconButton.outlined(
                      icon: const Icon(Icons.thermostat_outlined, size: 18, color: Colors.amber),
                      tooltip: 'Température & Carafage',
                      onPressed: () => _showServiceModal(context),
                    ),
                    const SizedBox(width: 8),

                    // Quick detail
                    if (hasBottleId)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/cellar/bottle/${data.id}'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          child: const Text('Voir la fiche', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    if (hasBottleId) const SizedBox(width: 8),

                    // Checkout bottle
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: hasBottleId
                            ? () => context.push('/checkout?bottleId=${data.id}')
                            : () => context.push('/checkout'),
                        icon: const Icon(Icons.wine_bar, size: 14, color: Colors.white),
                        label: const Text('Sortir', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1E3F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showServiceModal(BuildContext context) {
    final advice = WineServiceAdvisor.computeAdvice(
      wineType: data.wineType,
      vintage: data.vintage,
      region: data.region,
      appellation: data.appellation,
      producer: data.producer,
      wineName: data.name,
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.thermostat, color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Conseils de Service & Dégustation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${data.name} (${data.vintage ?? "NV"})',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B1E3F)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.device_thermostat, color: Colors.amber),
                  const SizedBox(width: 10),
                  Text(
                    'Température idéale : ${advice.tempLabel}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('🍷 Verre conseillé : ${advice.glasswareType}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('⏳ Carafage : ${advice.decantingAdvice}'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
