import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/cellar/domain/bottle.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFr = Localizations.localeOf(context).languageCode != 'en';
    final wine = bottle.wine;
    final wineName = wine?.name ?? (isFr ? 'Vin' : 'Wine');
    final vintage = wine?.vintage != null ? '${wine!.vintage}' : (isFr ? 'NM' : 'NV');
    final producer = wine?.producer;
    final photo = bottle.photoUrl ?? wine?.imageUrl;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push('/cellar/${bottle.id}'),
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header image or color
            SizedBox(
              height: 100,
              width: double.infinity,
              child: BottleImageView(
                imagePath: photo,
                wineType: wine?.type,
                width: double.infinity,
                height: 100,
                borderRadius: 0,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (wine != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WineTypeBadge(type: wine.type),
                        const Spacer(),
                        MaturityColorbar(wine: wine, width: 68, height: 6),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (producer != null && producer.isNotEmpty)
                    Text(
                      producer,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    '$wineName ($vintage)',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('${isFr ? "Qté" : "Qty"} : ${bottle.quantity}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (bottle.purchasePrice != null)
                        Text(
                          CurrencyHelper.formatPrice(bottle.purchasePrice, currency: bottle.currency),
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade700),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
