import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/cellar/domain/bottle.dart';
import '../../features/cellar/domain/wine.dart';
import '../utils/currency_helper.dart';
import 'wine_type_badge.dart';
import 'maturity_colorbar.dart';
import 'bottle_image_view.dart';

class BottleCard extends StatelessWidget {
  final Bottle bottle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const BottleCard({
    super.key,
    required this.bottle,
    this.onTap,
    this.onLongPress,
  });

  Color _getMaturityColor(DrinkWindowStatus status) {
    switch (status) {
      case DrinkWindowStatus.inPeak:
        return const Color(0xFF2E7D32); // Vert émeraude apogée
      case DrinkWindowStatus.drinkSoon:
        return const Color(0xFFE65100); // Orange alerte
      case DrinkWindowStatus.aging:
        return const Color(0xFF1565C0); // Bleu garde
      case DrinkWindowStatus.tooYoung:
        return const Color(0xFF0288D1); // Cyan jeune
      case DrinkWindowStatus.pastPeak:
        return const Color(0xFF757575); // Gris passé
    }
  }

  String _getMaturityLabel(DrinkWindowStatus status, bool isFr) {
    switch (status) {
      case DrinkWindowStatus.inPeak:
        return isFr ? 'Apogée ✨' : 'In Peak ✨';
      case DrinkWindowStatus.drinkSoon:
        return isFr ? 'À boire ⏰' : 'Drink Soon ⏰';
      case DrinkWindowStatus.aging:
        return isFr ? 'En garde ⏳' : 'Aging ⏳';
      case DrinkWindowStatus.tooYoung:
        return isFr ? 'Trop jeune' : 'Too Young';
      case DrinkWindowStatus.pastPeak:
        return isFr ? 'Passé' : 'Past Peak';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFr = Localizations.localeOf(context).languageCode != 'en';
    final wine = bottle.wine;
    final wineName = wine?.name ?? (isFr ? 'Vin' : 'Wine');
    final vintageStr = wine?.vintage != null ? '${wine!.vintage}' : (isFr ? 'NM' : 'NV');
    final producer = wine?.producer;
    final photo = bottle.photoUrl ?? wine?.imageUrl;
    final status = wine?.windowStatus ?? DrinkWindowStatus.inPeak;
    final maturityColor = _getMaturityColor(status);
    final maturityText = _getMaturityLabel(status, isFr);
    final displayPrice = bottle.purchasePrice ?? wine?.estimatedMarketValue;
    final hasAppellation = wine != null && (wine.appellation?.isNotEmpty ?? false);
    final hasRegion = wine != null && wine.region.isNotEmpty;
    final hasRack = bottle.rack != null && bottle.rack!.isNotEmpty;
    final hasLocationInfo = hasAppellation || hasRegion || hasRack;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.4),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push('/cellar/${bottle.id}'),
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Image Banner with Overlay Badges
            Stack(
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: BottleImageView(
                    imagePath: photo,
                    wineType: wine?.type,
                    width: double.infinity,
                    height: 120,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                  ),
                ),
                // Gradient for contrast
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                // Top-Left: Wine Type Badge
                if (wine != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: WineTypeBadge(type: wine.type),
                  ),
                // Top-Right: Apogée status capsule
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: maturityColor.withValues(alpha: 0.8), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: maturityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          maturityText,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: maturityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom-Right: Quantity Capsule
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1E3F),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '${bottle.quantity} btl',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Card Body with Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Producer
                    if (producer != null && producer.isNotEmpty)
                      Text(
                        producer,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 2),

                    // Wine Name & Vintage
                    Text(
                      '$wineName ($vintageStr)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    if (hasLocationInfo)
                      Row(
                        children: [
                          Icon(Icons.place, size: 11, color: isDark ? Colors.white60 : Colors.black54),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              [
                                if (hasAppellation)
                                  wine.appellation!
                                else if (hasRegion)
                                  wine.region,
                                if (hasRack)
                                  'Casier ${bottle.rack}',
                              ].join(' • '),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    const Spacer(),

                    // Maturity Color Bar
                    if (wine != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: MaturityColorbar(
                              wine: wine,
                              width: double.infinity,
                              height: 5,
                            ),
                          ),
                          if (wine.peakStart != null && wine.peakEnd != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${wine.peakStart}-${wine.peakEnd}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Bottom Row: Price & Rating / Details hint
                    Row(
                      children: [
                        if (displayPrice != null && displayPrice > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              CurrencyHelper.formatPrice(displayPrice, currency: bottle.currency),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD4AF37),
                              ),
                            ),
                          )
                        else
                          Text(
                            'En cave',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
