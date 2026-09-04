import 'package:flutter/material.dart';
import '../domain/bottle.dart';
import '../domain/wine.dart';
import '../../../shared/widgets/bottle_image_view.dart';

class BottleListItem extends StatelessWidget {
  final Bottle bottle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isUltraCompact;

  const BottleListItem({
    super.key,
    required this.bottle,
    required this.onTap,
    this.onLongPress,
    this.isUltraCompact = false,
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
        return isFr ? 'À l\'apogée ✨' : 'In Peak ✨';
      case DrinkWindowStatus.drinkSoon:
        return isFr ? 'À boire ⏰' : 'Drink Soon ⏰';
      case DrinkWindowStatus.aging:
        return isFr ? 'En garde ⏳' : 'Aging ⏳';
      case DrinkWindowStatus.tooYoung:
        return isFr ? 'Trop jeune' : 'Too Young';
      case DrinkWindowStatus.pastPeak:
        return isFr ? 'Passé l\'apogée' : 'Past Peak';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFr = Localizations.localeOf(context).languageCode != 'en';
    final wine = bottle.wine;
    final vintageStr = wine?.vintage != null ? '${wine!.vintage}' : (isFr ? 'NM' : 'NV');
    final photo = bottle.photoUrl ?? wine?.imageUrl;
    final status = wine?.windowStatus ?? DrinkWindowStatus.inPeak;
    final maturityColor = _getMaturityColor(status);
    final maturityText = _getMaturityLabel(status, isFr);

    final displayPrice = bottle.purchasePrice ?? wine?.estimatedMarketValue;
    final currencySymbol = bottle.currency == 'USD' ? '\$' : (bottle.currency == 'GBP' ? '£' : '€');

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isUltraCompact ? 8 : 12,
        vertical: isUltraCompact ? 2 : 4,
      ),
      elevation: isUltraCompact ? 0.5 : 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isUltraCompact ? 8 : 12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.5),
          width: 0.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(isUltraCompact ? 8 : 12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isUltraCompact ? 8 : 12,
            vertical: isUltraCompact ? 6 : 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Bottle Photo / Image thumbnail
              BottleImageView(
                imagePath: photo,
                wineType: wine?.type,
                width: isUltraCompact ? 36 : 44,
                height: isUltraCompact ? 36 : 44,
                borderRadius: isUltraCompact ? 6 : 8,
              ),
              const SizedBox(width: 10),

              // 2. Middle Structured Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Nom du vin + Millésime
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            wine?.name ?? (isFr ? 'Vin' : 'Wine'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isUltraCompact ? 13.5 : 14.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            vintageStr,
                            style: TextStyle(
                              fontSize: isUltraCompact ? 11 : 12,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Row 2: Domaine • Appellation / Région
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            wine?.producer ?? (isFr ? 'Domaine inconnu' : 'Unknown producer'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: isUltraCompact ? 11.5 : 12,
                              color: isDark ? Colors.grey.shade300 : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (wine?.appellation != null || wine?.region != null) ...[
                          Text(
                            ' • ',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                          Flexible(
                            child: Text(
                              wine?.appellation ?? wine?.region ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: isUltraCompact ? 11 : 11.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (!isUltraCompact) const SizedBox(height: 3),

                    // Row 3: Statut d'apogée (wines) or Fill Level (spirits & fortified) & Emplacement
                    Row(
                      children: [
                        if (bottle.tracksFillLevel) ...[
                          Icon(Icons.local_bar, size: 12, color: Colors.amber.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '${bottle.fillLevel}% restant',
                            style: TextStyle(
                              fontSize: isUltraCompact ? 10 : 11,
                              fontWeight: FontWeight.w600,
                              color: bottle.fillLevel <= 20
                                  ? Colors.red.shade600
                                  : bottle.fillLevel <= 50
                                      ? Colors.orange.shade700
                                      : Colors.green.shade600,
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: maturityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            maturityText,
                            style: TextStyle(
                              fontSize: isUltraCompact ? 10 : 11,
                              fontWeight: FontWeight.w600,
                              color: maturityColor,
                            ),
                          ),
                        ],
                        if (bottle.rack != null && bottle.rack!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.location_on, size: 11, color: Colors.grey.shade600),
                          const SizedBox(width: 1),
                          Text(
                            bottle.rack! + (bottle.shelf != null ? ' - ${bottle.shelf}' : ''),
                            style: TextStyle(
                              fontSize: isUltraCompact ? 10 : 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 3. Right: Quantity Badge + Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isUltraCompact ? 6 : 8,
                      vertical: isUltraCompact ? 2 : 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1E3F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'x${bottle.quantity}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isUltraCompact ? 11 : 12,
                      ),
                    ),
                  ),
                  if (displayPrice != null && displayPrice > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${displayPrice.toStringAsFixed(displayPrice.truncateToDouble() == displayPrice ? 0 : 2)} $currencySymbol',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: isUltraCompact ? 10 : 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}