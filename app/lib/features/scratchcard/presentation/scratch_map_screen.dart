import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../cellar/domain/bottle.dart';
import '../../journal/domain/tasting_entry.dart';
import '../../journal/presentation/journal_screen.dart';
import '../../offline/presentation/sync_provider.dart';
import 'scratch_map_canvas.dart';

final scratchMapModeProvider = StateProvider<String>((ref) => 'france');

final allUserBottlesProvider = FutureProvider<List<Bottle>>((ref) async {
  final repo = ref.watch(cellarRepositoryProvider);
  final offlineStorage = ref.watch(offlineStorageServiceProvider);
  final activeCellarId = ref.watch(currentCellarIdProvider);
  final Map<String, Bottle> bottleMap = {};

  final Set<String> targetCellarIds = {};
  if (activeCellarId != null && activeCellarId.isNotEmpty) {
    targetCellarIds.add(activeCellarId);
  }

  try {
    final cellars = await repo.getUserCellarsWithRole();
    for (final c in cellars) {
      if (c['id'] != null) targetCellarIds.add(c['id'].toString());
      if (c['cellar_id'] != null) targetCellarIds.add(c['cellar_id'].toString());
      final cMap = c['cellars'] as Map<String, dynamic>?;
      if (cMap != null && cMap['id'] != null) {
        targetCellarIds.add(cMap['id'].toString());
      }
    }
  } catch (e) {
    AppLogger.warning('GEO_MAP', 'Error fetching user cellars list for map: $e');
  }

  final cachedCellars = offlineStorage.getCachedCellars();
  for (final c in cachedCellars) {
    targetCellarIds.add(c.id);
  }

  for (final cId in targetCellarIds) {
    try {
      final bList = await repo.getBottles(cId);
      for (final b in bList) {
        bottleMap[b.id] = b;
      }
    } catch (_) {}

    final cachedList = offlineStorage.getCachedBottles(cId);
    for (final b in cachedList) {
      bottleMap.putIfAbsent(b.id, () => b);
    }
  }

  AppLogger.info('GEO_MAP', 'Map evaluated ${bottleMap.length} unique bottles across ${targetCellarIds.length} cellars');
  return bottleMap.values.toList();
});

class ScratchMapScreen extends ConsumerStatefulWidget {
  const ScratchMapScreen({super.key});

  @override
  ConsumerState<ScratchMapScreen> createState() => _ScratchMapScreenState();
}

class _ScratchMapScreenState extends ConsumerState<ScratchMapScreen> {
  bool _showExplorer = false;
  String _explorerSearch = '';
  String _explorerFilter = 'all';

  void _showRegionDetails(BuildContext context, MapRegionData region) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color badgeColor;
    String badgeLabel;
    IconData badgeIcon;

    if (region.isOwned && region.isDrunk) {
      badgeColor = const Color(0xFFD4AF37);
      badgeLabel = 'En Cave & Dégusté 🌟';
      badgeIcon = Icons.stars;
    } else if (region.isOwned) {
      badgeColor = const Color(0xFFE5A93B);
      badgeLabel = 'En Cave uniquement 🏷️';
      badgeIcon = Icons.inventory_2;
    } else if (region.isDrunk) {
      badgeColor = const Color(0xFF8B1E3F);
      badgeLabel = 'Dégusté uniquement 🍷';
      badgeIcon = Icons.wine_bar;
    } else {
      badgeColor = Colors.grey;
      badgeLabel = 'Terroir inexploré 🔒';
      badgeIcon = Icons.lock_outline;
    }

    final badgeTextColor = (region.isOwned && region.isDrunk) || region.isOwned ? Colors.black87 : Colors.white;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(region.flag, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          region.name,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          region.country,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, color: badgeTextColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          badgeLabel,
                          style: TextStyle(color: badgeTextColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                region.description,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              if (region.soilType != null || region.climate != null || region.keyGrapes != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (region.soilType != null)
                      _buildDetailBadge('🪨 ${region.soilType}', isDark),
                    if (region.climate != null)
                      _buildDetailBadge('⛅ ${region.climate}', isDark),
                    if (region.keyGrapes != null)
                      _buildDetailBadge('🍇 ${region.keyGrapes}', isDark),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatTile(
                    label: 'Bouteilles en Cave',
                    value: '${region.ownedCount}',
                    icon: Icons.inventory_2,
                    color: const Color(0xFFE5A93B),
                  ),
                  _StatTile(
                    label: 'Dégustations',
                    value: '${region.drunkCount}',
                    icon: Icons.wine_bar,
                    color: const Color(0xFF8B1E3F),
                  ),
                  _StatTile(
                    label: 'Statut Terroir',
                    value: region.isUnlocked ? 'Exploré ✨' : 'À découvrir',
                    icon: Icons.explore,
                    color: const Color(0xFFD4AF37),
                  ),
                ],
              ),
              if (region.topWine != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF2A2030) : theme.colorScheme.primaryContainer.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cuvée de référence : ${region.topWine}',
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.menu_book),
                      label: const Text('Journal'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go('/journal');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.inventory_2),
                      label: const Text('Ma Cave'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go('/');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _normalizeDiacritics(String str) {
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ÿ]'), 'y')
        .replaceAll(RegExp(r'[\-]'), ' ');
  }

  bool _matchesKeywords(String text, List<String> keywords) {
    final normText = _normalizeDiacritics(text);
    return keywords.any((k) => normText.contains(_normalizeDiacritics(k)));
  }

  List<MapRegionData> _buildRegions(String mode, List<Bottle> bottles, List<TastingEntry> tastings) {
    if (mode == 'france') {
      final bdxKeys = ['bordeaux', 'margaux', 'pauillac', 'pomerol', 'saint-émilion', 'saint-emilion', 'saint-julien', 'pessac', 'grave', 'médoc', 'medoc', 'sauternes', 'barsac', 'saint-estèphe'];
      final bouKeys = ['bourgogne', 'burgundy', 'chablis', 'meursault', 'beaune', 'nuits', 'vosne', 'pommard', 'volnay', 'gevrey', 'chassagne', 'puligny', 'corton', 'mâcon', 'chalonnaise'];
      final beauKeys = ['beaujolais', 'morgon', 'fleurie', 'moulin-à-vent', 'moulin a vent', 'brouilly', 'chénas', 'juliénas', 'chiroubles', 'saint-amour', 'régnié'];
      final rhoKeys = ['rhône', 'rhone', 'châteauneuf', 'chateauneuf', 'saint-joseph', 'hermitage', 'côte-rôtie', 'cote-rotie', 'gigondas', 'vacqueyras', 'cornas', 'crozes', 'luberon', 'ventoux'];
      final chaKeys = ['champagne', 'reims', 'épernay', 'epernay', 'ay', 'avize', 'bouzy'];
      final loiKeys = ['loire', 'sancerre', 'pouilly', 'chinon', 'vouvray', 'saumur', 'muscadet', 'anjou', 'bourgueil', 'menetou', 'cheverny'];
      final alsKeys = ['alsace', 'riesling', 'gewurztraminer', 'pinot gris', 'colmar', 'sylvaner'];
      final juraKeys = ['jura', 'savoie', 'arbois', 'château-chalon', 'chateau chalon', 'vin jaune', 'bugey', 'mondeuse', 'savagnin'];
      final langKeys = ['languedoc', 'roussillon', 'pic saint-loup', 'pic saint loup', 'corbières', 'corbieres', 'minervois', 'larzac', 'faugères', 'collioure', 'banyuls', 'limoux'];
      final sudOuestKeys = ['sud-ouest', 'sud ouest', 'cahors', 'madiran', 'jurançon', 'jurancon', 'bergerac', 'monbazillac', 'gaillac', 'irouléguy', 'fronton'];
      final proKeys = ['provence', 'bandol', 'cassis', 'coteaux d\'aix', 'palette', 'bellet', 'côtes de provence'];
      final corKeys = ['corse', 'corsica', 'patrimonio', 'ajaccio', 'calvi', 'sartène', 'sartene', 'niellucciu', 'sciaccarellu', 'vermentinu'];

      return [
        _createRegion(
          id: 'champagne',
          name: 'Champagne',
          country: 'France',
          flag: '🇫🇷',
          normalizedBounds: const Rect.fromLTWH(0.44, 0.14, 0.22, 0.14),
          keywords: chaKeys,
          bottles: bottles,
          tastings: tastings,
          description: 'Effervescents de classe mondiale issus de sols de craie millénaires (Montagne de Reims, Côte des Blancs, Vallée de la Marne).',
          soilType: 'Craie blanche campanienne & marnes',
          climate: 'Océanique frais & septentrional',
          keyGrapes: 'Chardonnay, Pinot Noir, Pinot Meunier',
        ),
        _createRegion(
          id: 'alsace',
          name: 'Alsace',
          country: 'France',
          flag: '🇫🇷',
          normalizedBounds: const Rect.fromLTWH(0.72, 0.20, 0.16, 0.18),
          keywords: alsKeys,
          bottles: bottles,
          tastings: tastings,
          description: 'Mosaïque géologique produisant des Rieslings ciselés, Gewurztraminers opulents et Grands Crus d\'exception.',
          soilType: 'Mosaïque (Granit, Grès, Calcaire)',
          climate: 'Semi-continental ensoleillé (Vosges)',
          keyGrapes: 'Riesling, Gewurztraminer, Pinot Gris',
        ),
        _createRegion(
          id: 'bourgogne',
          name: 'Bourgogne',
          country: 'France',
          flag: '🇫🇷',
          normalizedBounds: const Rect.fromLTWH(0.55, 0.31, 0.20, 0.18),
          keywords: bouKeys,
          bottles: bottles,
          tastings: tastings,
          topWine: 'Domaine Laroche Chablis Grand Cru',
          description: 'Le berceau absolu du Pinot Noir et du Chardonnay, subdivisé en Climats d\'exception classés au patrimoine de l\'UNESCO.',
          soilType: 'Argilo-calcaire kimméridgien & marnes',
          climate: 'Semi-continental modéré',
          keyGrapes: 'Pinot Noir, Chardonnay',
        ),
        _createRegion(
          id: 'beaujolais',
          name: 'Beaujolais',
          country: 'France',
          flag: '🇫🇷',
          normalizedBounds: const Rect.fromLTWH(0.57, 0.48, 0.10, 0.08),
          keywords: beauKeys,
          bottles: bottles,
          tastings: tastings,
          description: 'L\'expression sublime du Gamay sur arènes granitiques et schistes bleus à travers ses 10 Crus renommés (Morgon, Fleurie, Moulin-à-Vent...).',
          soilType: 'Arènes granitiques & schistes bleus',
          climate: 'Semi-continental tempéré',
          keyGrapes: 'Gamay noir à jus blanc',
        ),
        _createRegion(
          id: 'jura_savoie',
          name: 'Jura & Savoie',
          country: 'France',
          flag: '🇫🇷',
          normalizedBounds: const Rect.fromLTWH(0.70, 0.46, 0.12, 0.14),
          keywords: juraKeys,
          bottles: bottles,
          tastings: tastings,
          description: 'Terroirs alpins et jurassiens singuliers : Vin Jaune sous voile oxydatif, cépages Savagnin, Poulsard, Trousseau et Mondeuse.',
          soilType: 'Marnes bleues, éboulis calcaires alpins',
          climate: 'Montagnard & préalpin',
          keyGrapes: 'Savagnin, Poulsard, Trousseau, Mondeuse',
        ),
        _createRegion(
          id: 'loire',
          name: 'Vallée de la Loire',
          country: 'France',
          flag: '🇫🇷',
          normalizedBounds: const Rect.fromLTWH(0.18, 0.34, 0.38, 0.14),
          keywords: loiKeys,
          bottles: bottles,
          tastings: tastings,
          description: 'Chenin blanc magistral, Sauvignon frais de Sancerre et Cabernets Francs gouleyants de Chinon et Saumur.',
          soilType: 'Tuffeau calcaire, silex & schistes',
          climate: 'Océanique doux',
          keyGrapes: 'Chenin Blanc, Sauvignon, Cabernet Franc',
        ),
        _createRegion(
          id: 'bordeaux',
          name: 'Bordeaux',
          country: 'France',
          flag: '🇫🇷',
          normalizedBounds: const Rect.fromLTWH(0.18, 0.52, 0.20, 0.18),
          keywords: bdxKeys,
          bottles: bottles,
          tastings: tastings,
          topWine: 'Château Margaux 2015',
          description: 'Royaume des grands assemblages Cabernet Sauvignon, Merlot et Cabernet Franc. Rive gauche graveleuse et Rive droite soyeuse.',
          soilType: 'Graves garonnaises & argilo-calcaire',
          climate: 'Océanique tempéré océan/Gironde',
          keyGrapes: 'Cabernet Sauvignon, Merlot, Cabernet Franc',
        ),
        _createRegion(
          id: 'sud_ouest',
          name: 'Sud-Ouest',
          country: 'France',
          flag: '🇫🇷',
          normalizedBounds: const Rect.fromLTWH(0.24, 0.72, 0.22, 0.16),
          keywords: sudOuestKeys,
          bottles: bottles,
          tastings: tastings,
          description: 'Vignobles de caractère et cépages d\'antan : Malbecs sombres de Cahors, Tannats puissants de Madiran et Mansengs de Jurançon.',
          soilType: 'Causse calcaire & terrasses de galets',
          climate: 'Océanique à influences pyrénéennes',
          keyGrapes: 'Malbec (Côt), Tannat, Gros Manseng',
        ),
        _createRegion(
          id: 'rhone',
          name: 'Vallée du Rhône',
          country: 'France',
          flag: '🇫🇷',
          normalizedBounds: const Rect.fromLTWH(0.58, 0.51, 0.18, 0.24),
          keywords: rhoKeys,
          bottles: bottles,
          tastings: tastings,
          topWine: 'Saint-Joseph / Côte-Rôtie',
          description: 'Des Syrahs septentrionales minérales et poivrées aux chaleureux assemblages Grenache-Mourvèdre de Châteauneuf-du-Pape.',
          soilType: 'Granit (Nord) & Galets roulés (Sud)',
          climate: 'Méditerranéen balayé par le Mistral',
          keyGrapes: 'Syrah, Grenache, Mourvèdre, Viognier',
        ),
        _createRegion(
          id: 'languedoc_roussillon',
          name: 'Languedoc & Roussillon',
          country: 'France',
          flag: '🇫🇷',
          normalizedBounds: const Rect.fromLTWH(0.46, 0.76, 0.18, 0.16),
          keywords: langKeys,
          bottles: bottles,
          tastings: tastings,
          description: 'Grands vins de soleil et terroirs d\'altitude (Pic Saint-Loup, Terrasses du Larzac, Collioure), vignerons audacieux et nature.',
          soilType: 'Schistes noirs, calcaires durs & terrasses',
          climate: 'Méditerranéen chaud et aride',
          keyGrapes: 'Grenache, Syrah, Mourvèdre, Carignan',
        ),
        _createRegion(
          id: 'provence',
          name: 'Provence',
          country: 'France',
          flag: '🇫🇷',
          normalizedBounds: const Rect.fromLTWH(0.62, 0.72, 0.22, 0.14),
          keywords: proKeys,
          bottles: bottles,
          tastings: tastings,
          description: 'Grands rouges de garde à base de Mourvèdre à Bandol, blancs iodés de Cassis et rosés de gastronomie.',
          soilType: 'Calcaires urgoniens & micaschistes',
          climate: 'Méditerranéen maritime',
          keyGrapes: 'Mourvèdre, Grenache, Cinsault, Vermentino',
        ),
        _createRegion(
          id: 'corse',
          name: 'Corse',
          country: 'France',
          flag: '🇫🇷',
          normalizedBounds: const Rect.fromLTWH(0.88, 0.78, 0.10, 0.20),
          keywords: corKeys,
          bottles: bottles,
          tastings: tastings,
          description: 'L\'Île de Beauté et ses terroirs insulaires granitiques et calcaires (Patrimonio, Ajaccio, Calvi) aux cépages nobles Niellucciu et Sciaccarellu.',
          soilType: 'Granites rouges & calcaires de Bonifacio',
          climate: 'Insulaire méditerranéen venté',
          keyGrapes: 'Niellucciu, Sciaccarellu, Vermentinu',
        ),
      ];
    } else if (mode == 'italy') {
      return [
        _createRegion(
          id: 'piemonte',
          name: 'Piémont (Barolo, Barbaresco)',
          country: 'Italie',
          flag: '🇮🇹',
          normalizedBounds: const Rect.fromLTWH(0.20, 0.15, 0.25, 0.25),
          keywords: ['piemonte', 'piemont', 'barolo', 'barbaresco', 'langhe', 'nebbiolo', 'alba', 'barbera', 'roero', 'gavi', 'dogliani', 'asti'],
          bottles: bottles,
          tastings: tastings,
          description: 'Royaume aristocratique du Nebbiolo, des grands terroirs de Barolo et Barbaresco, et des collines des Langhe classées UNESCO.',
          soilType: 'Marnes de Sant\'Agata & grès de Diano',
          climate: 'Continental avec brumes automnales (Nebbia)',
          keyGrapes: 'Nebbiolo, Barbera, Dolcetto',
        ),
        _createRegion(
          id: 'toscana',
          name: 'Toscane (Brunello, Chianti, Bolgheri)',
          country: 'Italie',
          flag: '🇮🇹',
          normalizedBounds: const Rect.fromLTWH(0.40, 0.35, 0.25, 0.25),
          keywords: ['toscana', 'toscane', 'tuscany', 'chianti', 'brunello', 'montalcino', 'bolgheri', 'sassicaia', 'ornellaia', 'sangiovese', 'vino nobile', 'montepulciano', 'maremma'],
          bottles: bottles,
          tastings: tastings,
          description: 'Terres mythiques du Sangiovese, des Brunellos de garde centenaire, des Chiantis Classicos et des prestigieux Super Toscans.',
          soilType: 'Galestro (schiste argileux) & Alberese (calcaire)',
          climate: 'Méditerranéen vallonné',
          keyGrapes: 'Sangiovese, Cabernet Sauvignon, Merlot',
        ),
        _createRegion(
          id: 'veneto',
          name: 'Vénétie (Amarone, Valpolicella, Soave)',
          country: 'Italie',
          flag: '🇮🇹',
          normalizedBounds: const Rect.fromLTWH(0.48, 0.12, 0.25, 0.22),
          keywords: ['veneto', 'vénétie', 'venetie', 'valpolicella', 'amarone', 'ripasso', 'soave', 'prosecco', 'valdobbiadene', 'bardolino'],
          bottles: bottles,
          tastings: tastings,
          description: 'Berceau de l\'Amarone della Valpolicella issu de raisins passerillés, des Soaves minéraux et des collines du Prosecco Superiore.',
          soilType: 'Alluvions calcaires & basaltes volcaniques',
          climate: 'Tempéré doux par le lac de Garde',
          keyGrapes: 'Corvina, Rondinella, Garganega, Glera',
        ),
        _createRegion(
          id: 'trentino_alto_adige',
          name: 'Trentin-Haut-Adige & Frioul',
          country: 'Italie',
          flag: '🇮🇹',
          normalizedBounds: const Rect.fromLTWH(0.45, 0.05, 0.28, 0.18),
          keywords: ['trentino', 'alto adige', 'sudtirol', 'friuli', 'frioul', 'collio', 'teroldego', 'pinot grigio', 'gewurztraminer'],
          bottles: bottles,
          tastings: tastings,
          description: 'Vins alpins et dolomitiques d\'une pureté cristalline : blancs ciselés du Collio, Teroldego noble et rouges d\'altitude.',
          soilType: 'Porphyre volcanique, dolomie calcaire & flysch',
          climate: 'Alpin avec ensoleillement méridional',
          keyGrapes: 'Pinot Grigio, Teroldego, Lagrein, Gewürz',
        ),
        _createRegion(
          id: 'emilia_abruzzo',
          name: 'Émilie-Romagne & Abruzzes',
          country: 'Italie',
          flag: '🇮🇹',
          normalizedBounds: const Rect.fromLTWH(0.55, 0.38, 0.22, 0.24),
          keywords: ['emilia', 'romagna', 'abruzzo', 'abruzzes', 'montepulciano d\'abruzzo', 'trebbiano', 'verdicchio', 'marche', 'lambrusco'],
          bottles: bottles,
          tastings: tastings,
          description: 'Montepulciano d\'Abruzzo velouté, Verdicchio iodé des Marches et Lambruscos gastronomiques artisanaux.',
          soilType: 'Argiles lourdes & dépôts marins',
          climate: 'Méditerranéen adriatique',
          keyGrapes: 'Montepulciano, Lambrusco, Trebbiano',
        ),
        _createRegion(
          id: 'puglia_campania',
          name: 'Pouilles & Campanie (Taurasi, Primitivo)',
          country: 'Italie',
          flag: '🇮🇹',
          normalizedBounds: const Rect.fromLTWH(0.68, 0.58, 0.24, 0.24),
          keywords: ['puglia', 'pouilles', 'primitivo', 'manduria', 'negroamaro', 'salice salentino', 'campania', 'campanie', 'taurasi', 'aglianico', 'greco di tufo', 'fiano'],
          bottles: bottles,
          tastings: tastings,
          description: 'Chaleur du Sud et terroirs volcaniques : Aglianico puissant de Taurasi, Primitivos solaires et grands blancs de Campanie.',
          soilType: 'Tufs volcaniques (Vésuve) & terres rouges',
          climate: 'Méditerranéen chaud et lumineux',
          keyGrapes: 'Aglianico, Primitivo, Negroamaro, Fiano',
        ),
        _createRegion(
          id: 'sicilia_etna',
          name: 'Sicile & Terroirs de l\'Etna',
          country: 'Italie',
          flag: '🇮🇹',
          normalizedBounds: const Rect.fromLTWH(0.60, 0.82, 0.28, 0.16),
          keywords: ['sicilia', 'sicile', 'sicily', 'etna', 'nerello mascalese', 'nero d\'avola', 'grillo', 'vittoria', 'frappato', 'marsala', 'pantelleria'],
          bottles: bottles,
          tastings: tastings,
          description: 'Magie volcanique de l\'Etna (Nerello Mascalese), Nero d\'Avola d\'orfèvre et grands vins insulaires de caractère.',
          soilType: 'Sables volcaniques & laves basaltiques',
          climate: 'Méditerranéen d\'altitude sur l\'Etna',
          keyGrapes: 'Nerello Mascalese, Nero d\'Avola, Grillo',
        ),
      ];
    } else if (mode == 'spain') {
      return [
        _createRegion(
          id: 'rioja',
          name: 'La Rioja (Alta, Alavesa, Oriental)',
          country: 'Espagne',
          flag: '🇪🇸',
          normalizedBounds: const Rect.fromLTWH(0.48, 0.12, 0.20, 0.18),
          keywords: ['rioja', 'haro', 'logroño', 'alavesa', 'alta', 'oriental', 'tempranillo', 'graciano', 'garnacha rioja'],
          bottles: bottles,
          tastings: tastings,
          description: 'L\'appellation reine d\'Espagne, célèbre pour ses élevages de longue garde (Crianzas, Reservas, Gran Reservas) en fûts de chêne.',
          soilType: 'Argilo-calcaire, argilo-ferreux & alluvions',
          climate: 'Continental modéré par l\'Atlantique',
          keyGrapes: 'Tempranillo, Graciano, Garnacha',
        ),
        _createRegion(
          id: 'ribera_del_duero',
          name: 'Ribera del Duero & Toro',
          country: 'Espagne',
          flag: '🇪🇸',
          normalizedBounds: const Rect.fromLTWH(0.38, 0.26, 0.24, 0.20),
          keywords: ['ribera del duero', 'ribera', 'tinto fino', 'pesquera', 'aranda', 'toro', 'tinta de toro', 'vega sicilia', 'pingus'],
          bottles: bottles,
          tastings: tastings,
          description: 'Hauts plateaux castillans produisant des Tempranillos (Tinto Fino) d\'une intensité, d\'une profondeur et d\'une longévité exceptionnelles.',
          soilType: 'Calcaire crayeux, marnes & terrasses du Duero',
          climate: 'Continental extrême (grandes amplitudes)',
          keyGrapes: 'Tinto Fino (Tempranillo), Tinta de Toro',
        ),
        _createRegion(
          id: 'priorat_catalunya',
          name: 'Priorat & Catalogne (Penedès, Cava)',
          country: 'Espagne',
          flag: '🇪🇸',
          normalizedBounds: const Rect.fromLTWH(0.78, 0.28, 0.18, 0.22),
          keywords: ['priorat', 'montsant', 'cataluna', 'catalunya', 'penedes', 'cava', 'licorella', 'gratallops', 'costers del segre', 'terra alta'],
          bottles: bottles,
          tastings: tastings,
          description: 'Schistes noirs de Licorella au Priorat (Grenache et Carignan centenaires d\'anthologie) et grands effervescents de Cava.',
          soilType: 'Schistes noirs ardoisiers (Licorella)',
          climate: 'Méditerranéen aride de montagne',
          keyGrapes: 'Garnacha Tinta, Cariñena, Macabeo',
        ),
        _createRegion(
          id: 'galicia_rias_baixas',
          name: 'Galice & Rías Baixas (Albariño)',
          country: 'Espagne',
          flag: '🇪🇸',
          normalizedBounds: const Rect.fromLTWH(0.12, 0.10, 0.22, 0.20),
          keywords: ['rias baixas', 'galicia', 'galice', 'albarino', 'albariño', 'ribeiro', 'ribeira sacra', 'mencia', 'valdeorras', 'godello'],
          bottles: bottles,
          tastings: tastings,
          description: 'Espagne verte et océanique : Albariño salin et vibrant des Rías Baixas, Godellos complexes et Mencias de coteaux abrupts.',
          soilType: 'Granite décomposé (Xabre) & alluvions',
          climate: 'Océanique très humide et frais',
          keyGrapes: 'Albariño, Godello, Mencía',
        ),
        _createRegion(
          id: 'castilla_rueda',
          name: 'Rueda, Bierzo & Castille',
          country: 'Espagne',
          flag: '🇪🇸',
          normalizedBounds: const Rect.fromLTWH(0.28, 0.22, 0.22, 0.22),
          keywords: ['rueda', 'verdejo', 'bierzo', 'castilla y leon', 'castille', 'cigales'],
          bottles: bottles,
          tastings: tastings,
          description: 'Verdejos aromatiques et minéraux de Rueda, et Mencias d\'altitude du Bierzo.',
          soilType: 'Sols graveleux, sablo-limoneux',
          climate: 'Continental sec d\'altitude',
          keyGrapes: 'Verdejo, Mencía',
        ),
        _createRegion(
          id: 'andalucia_jerez',
          name: 'Andalousie & Jerez / Xérès',
          country: 'Espagne',
          flag: '🇪🇸',
          normalizedBounds: const Rect.fromLTWH(0.35, 0.74, 0.28, 0.22),
          keywords: ['jerez', 'sherry', 'xeres', 'manzanilla', 'sanlucar', 'fino', 'amontillado', 'oloroso', 'pedro ximenez', 'andalucia', 'montilla'],
          bottles: bottles,
          tastings: tastings,
          description: 'Terres blanches d\'Albariza et élevage sous voile (Solera) : Finos tranchants, Manzanillas salines et riches Pedro Ximénez.',
          soilType: 'Craie blanche éblouissante (Albariza)',
          climate: 'Méditerranéen chaud (vent Levante)',
          keyGrapes: 'Palomino Fino, Pedro Ximénez',
        ),
        _createRegion(
          id: 'levante_murcia',
          name: 'Levant, Valence & Murcie (Jumilla)',
          country: 'Espagne',
          flag: '🇪🇸',
          normalizedBounds: const Rect.fromLTWH(0.66, 0.54, 0.24, 0.24),
          keywords: ['jumilla', 'murcia', 'murcie', 'yecla', 'bullas', 'valencia', 'alicante', 'monastrell', 'mourvedre espagne', 'bobal', 'utiel requena'],
          bottles: bottles,
          tastings: tastings,
          description: 'Vignobles solaires de la côte est : Monastrell puissant et velouté à Jumilla et Bobal fruité d\'Utiel-Requena.',
          soilType: 'Sols arides calcaires et caillouteux',
          climate: 'Semi-aride méditerranéen',
          keyGrapes: 'Monastrell, Bobal',
        ),
      ];
    } else if (mode == 'portugal') {
      return [
        _createRegion(
          id: 'douro_porto',
          name: 'Vallée du Douro & Portos (Cima Corgo)',
          country: 'Portugal',
          flag: '🇵🇹',
          normalizedBounds: const Rect.fromLTWH(0.40, 0.15, 0.35, 0.22),
          keywords: ['douro', 'porto', 'port', 'cima corgo', 'touriga nacional', 'touriga franca', 'tinta roriz', 'quinta do noval', 'taylor'],
          bottles: bottles,
          tastings: tastings,
          description: 'Coteaux abrupts de schistes du fleuve Douro, berceau des vieux Portos de légende et de grands vins rouges puissants.',
          soilType: 'Schistes verticaux en terrasses abruptes',
          climate: 'Continental chaud et abrité',
          keyGrapes: 'Touriga Nacional, Touriga Franca, Tinta Roriz',
        ),
        _createRegion(
          id: 'alentejo',
          name: 'Alentejo & Terres du Sud',
          country: 'Portugal',
          flag: '🇵🇹',
          normalizedBounds: const Rect.fromLTWH(0.35, 0.50, 0.40, 0.28),
          keywords: ['alentejo', 'aragonez', 'alicante bouschet', 'trincadeira', 'evora', 'borba', 'esporao'],
          bottles: bottles,
          tastings: tastings,
          description: 'Vignobles solaires produisant des rouges intenses, riches en fruits noirs et épices sur sols d\'argiles et de granites.',
          soilType: 'Argiles rouges, granites & schistes',
          climate: 'Méditerranéen chaud et ensoleillé',
          keyGrapes: 'Aragonez, Alicante Bouschet, Trincadeira',
        ),
        _createRegion(
          id: 'vinho_verde',
          name: 'Vinho Verde & Région du Minho',
          country: 'Portugal',
          flag: '🇵🇹',
          normalizedBounds: const Rect.fromLTWH(0.20, 0.05, 0.30, 0.18),
          keywords: ['vinho verde', 'minho', 'alvarinho', 'albarino portugal', 'loureiro', 'trajadura', 'moncao'],
          bottles: bottles,
          tastings: tastings,
          description: 'Fraîcheur océanique et sols granitiques : grands blancs d\'Alvarinho et de Loureiro éclatants et minéraux.',
          soilType: 'Granitique pauvre & acide',
          climate: 'Atlantique frais et très arrosé',
          keyGrapes: 'Alvarinho, Loureiro, Trajadura',
        ),
        _createRegion(
          id: 'dao_bairrada',
          name: 'Dão & Bairrada',
          country: 'Portugal',
          flag: '🇵🇹',
          normalizedBounds: const Rect.fromLTWH(0.25, 0.28, 0.35, 0.20),
          keywords: ['dão', 'dao', 'bairrada', 'baga', 'serra da estrela', 'encruzado'],
          bottles: bottles,
          tastings: tastings,
          description: 'Vins d\'altitude du Dão (Encruzado minéral) et rouges de garde mythiques de Bairrada sur cépage Baga.',
          soilType: 'Granite d\'altitude & argiles calcaires',
          climate: 'Tempéré de montagne & maritime',
          keyGrapes: 'Encruzado, Touriga Nacional, Baga',
        ),
        _createRegion(
          id: 'madeira_acores',
          name: 'Madère & Îles des Açores',
          country: 'Portugal',
          flag: '🇵🇹',
          normalizedBounds: const Rect.fromLTWH(0.10, 0.78, 0.35, 0.18),
          keywords: ['madere', 'madeira', 'acores', 'azores', 'pico', 'sercial', 'verdelho', 'bual', 'malvasia'],
          bottles: bottles,
          tastings: tastings,
          description: 'Terroirs volcaniques insulaires : vins fortifiés chauffés en estufas centenaires et blancs iodés de l\'île de Pico.',
          soilType: 'Laves et tufs volcaniques basaltiques',
          climate: 'Subtropical océanique',
          keyGrapes: 'Sercial, Verdelho, Bual, Malvasia',
        ),
      ];
    } else if (mode == 'germany_austria') {
      return [
        _createRegion(
          id: 'mosel',
          name: 'Moselle / Mosel (Saar, Ruwer)',
          country: 'Allemagne',
          flag: '🇩🇪',
          normalizedBounds: const Rect.fromLTWH(0.20, 0.20, 0.30, 0.25),
          keywords: ['mosel', 'moselle', 'saar', 'ruwer', 'piesport', 'bernkastel', 'wehlener', 'riesling kabinett', 'spatlese'],
          bottles: bottles,
          tastings: tastings,
          description: 'Coteaux vertigineux de schistes bleus et dévoniens produisant les Rieslings les plus ciselés et digestes du monde.',
          soilType: 'Schistes bleus dévoniens en pentes (60°)',
          climate: 'Continental frais tempéré par la rivière',
          keyGrapes: 'Riesling',
        ),
        _createRegion(
          id: 'rheingau_pfalz',
          name: 'Rheingau & Palatinat (Pfalz)',
          country: 'Allemagne',
          flag: '🇩🇪',
          normalizedBounds: const Rect.fromLTWH(0.35, 0.35, 0.30, 0.25),
          keywords: ['rheingau', 'pfalz', 'palatinat', 'johannisberg', 'rudesheim', 'grosses gewachs', 'gg', 'spatburgunder'],
          bottles: bottles,
          tastings: tastings,
          description: 'Le temple des Grands Crus secs (Grosses Gewächs) et de somptueux Pinots Noirs (Spätburgunder).',
          soilType: 'Grès rouge, quartzites, loess & calcaires',
          climate: 'Microclimat doux protégé (Taunus)',
          keyGrapes: 'Riesling, Spätburgunder (Pinot Noir)',
        ),
        _createRegion(
          id: 'baden_franken',
          name: 'Bade (Baden) & Franconie',
          country: 'Allemagne',
          flag: '🇩🇪',
          normalizedBounds: const Rect.fromLTWH(0.30, 0.60, 0.30, 0.25),
          keywords: ['baden', 'franken', 'kaiserstuhl', 'silvaner', 'bocksbeutel', 'grauburgunder'],
          bottles: bottles,
          tastings: tastings,
          description: 'Pinots Noirs solaires sur sols volcaniques du Kaiserstuhl et Silvaners racés en flacons traditionnels Bocksbeutel.',
          soilType: 'Volcanique (Kaiserstuhl) & calcaire',
          climate: 'Le plus chaud d\'Allemagne',
          keyGrapes: 'Spätburgunder, Silvaner, Grauburgunder',
        ),
        _createRegion(
          id: 'wachau_kremstal',
          name: 'Wachau & Kremstal (Danube)',
          country: 'Autriche',
          flag: '🇦🇹',
          normalizedBounds: const Rect.fromLTWH(0.65, 0.30, 0.30, 0.25),
          keywords: ['wachau', 'kremstal', 'kamptal', 'gruner veltliner', 'smaragd', 'federspiel', 'donau'],
          bottles: bottles,
          tastings: tastings,
          description: 'Terrasses de lœss et de gneiss dominant le Danube : Grüner Veltliners Smaragd opulents et minéraux.',
          soilType: 'Gneiss primaire (Gföhl) & terrasses de loess',
          climate: 'Rencontre atlantique et pannonienne',
          keyGrapes: 'Grüner Veltliner, Riesling',
        ),
        _createRegion(
          id: 'burgenland',
          name: 'Burgenland & Terres Pannoniennes',
          country: 'Autriche',
          flag: '🇦🇹',
          normalizedBounds: const Rect.fromLTWH(0.70, 0.55, 0.25, 0.30),
          keywords: ['burgenland', 'blaufrankisch', 'zweigelt', 'neusiedlersee', 'trockenbeerenauslese', 'ruster'],
          bottles: bottles,
          tastings: tastings,
          description: 'Grands rouges de Blaufränkisch profonds et vins botrytisés liquoreux autour du lac de Neusiedl.',
          soilType: 'Argiles lourdes, sables & micaschistes',
          climate: 'Pannonien chaud (Botrytis lacustre)',
          keyGrapes: 'Blaufränkisch, Zweigelt, Furmint',
        ),
      ];
    } else if (mode == 'usa') {
      return [
        _createRegion(
          id: 'napa_valley',
          name: 'Napa Valley (Oakville, Rutherford, Stag\'s Leap)',
          country: 'USA',
          flag: '🇺🇸',
          normalizedBounds: const Rect.fromLTWH(0.15, 0.25, 0.30, 0.25),
          keywords: ['napa', 'oakville', 'rutherford', 'stag\'s leap', 'howell mountain', 'screaming eagle', 'opus one', 'caymus'],
          bottles: bottles,
          tastings: tastings,
          description: 'La vallée mythique du Cabernet Sauvignon américain, alliant richesse voluptueuse, notes de cassis et élevage d\'orfèvre.',
          soilType: 'Alluvions graveleuses & roches volcaniques',
          climate: 'Méditerranéen tempéré par brumes de San Pablo',
          keyGrapes: 'Cabernet Sauvignon, Merlot, Sauvignon Blanc',
        ),
        _createRegion(
          id: 'sonoma_county',
          name: 'Sonoma County & Côte Pacifique',
          country: 'USA',
          flag: '🇺🇸',
          normalizedBounds: const Rect.fromLTWH(0.10, 0.45, 0.30, 0.25),
          keywords: ['sonoma', 'russian river', 'dry creek', 'sonoma coast', 'alexander valley', 'zinfandel', 'kistler'],
          bottles: bottles,
          tastings: tastings,
          description: 'Pinots Noirs maritimes et Chardonnays d\'exception de Russian River Valley, et vieux Zinfandels de Dry Creek.',
          soilType: 'Goldridge sablo-limoneux & basaltes',
          climate: 'Maritime frais (Pacifique)',
          keyGrapes: 'Pinot Noir, Chardonnay, Zinfandel',
        ),
        _createRegion(
          id: 'oregon_willamette',
          name: 'Oregon & Willamette Valley',
          country: 'USA',
          flag: '🇺🇸',
          normalizedBounds: const Rect.fromLTWH(0.12, 0.05, 0.30, 0.20),
          keywords: ['oregon', 'willamette', 'dundee hills', 'jory', 'drouhin oregon', 'pinot noir usa'],
          bottles: bottles,
          tastings: tastings,
          description: 'Terres rouges volcaniques Jory donnant naissance à des Pinots Noirs d\'une finesse et d\'une élégance purement bourguignonnes.',
          soilType: 'Terres rouges volcaniques Jory & grès',
          climate: 'Maritime frais océanique',
          keyGrapes: 'Pinot Noir, Chardonnay',
        ),
        _createRegion(
          id: 'washington_columbia',
          name: 'Washington State & Columbia Valley',
          country: 'USA',
          flag: '🇺🇸',
          normalizedBounds: const Rect.fromLTWH(0.35, 0.05, 0.35, 0.22),
          keywords: ['washington', 'columbia valley', 'walla walla', 'red mountain', 'yakima'],
          bottles: bottles,
          tastings: tastings,
          description: 'Climat continental sec et amplitudes thermiques idéales pour des Syrahs intenses et des assemblages bordelais concentrés.',
          soilType: 'Sables éoliens sur basaltes de Missoula',
          climate: 'Désertique frais d\'ombre pluviométrique',
          keyGrapes: 'Cabernet Sauvignon, Syrah, Merlot',
        ),
      ];
    } else if (mode == 'south_america') {
      return [
        _createRegion(
          id: 'mendoza_uco',
          name: 'Mendoza & Valle de Uco (Argentine)',
          country: 'Argentine',
          flag: '🇦🇷',
          normalizedBounds: const Rect.fromLTWH(0.35, 0.40, 0.35, 0.30),
          keywords: ['mendoza', 'valle de uco', 'gualtallary', 'paraje altamira', 'lujan de cuyo', 'malbec argentine', 'catena', 'zuccardi'],
          bottles: bottles,
          tastings: tastings,
          description: 'Vignobles d\'altitude extrême au pied de la Cordillère des Andes (1200m-1500m), sol calcaire et Malbecs soyeux.',
          soilType: 'Alluvions sableuses, graviers calcaires & argiles',
          climate: 'Semi-désertique d\'altitude (Andes)',
          keyGrapes: 'Malbec, Cabernet Franc, Torrontés',
        ),
        _createRegion(
          id: 'salta_patagonia',
          name: 'Salta & Patagonie (Argentine)',
          country: 'Argentine',
          flag: '🇦🇷',
          normalizedBounds: const Rect.fromLTWH(0.40, 0.10, 0.30, 0.25),
          keywords: ['salta', 'cafayate', 'calchaqui', 'torrontes', 'colome', 'patagonie', 'rio negro'],
          bottles: bottles,
          tastings: tastings,
          description: 'Vignes perchées à plus de 2000m d\'altitude : Torrontés explosif de fleurs blanches et Malbecs sombres.',
          soilType: 'Sableux alluviaux & graviers fluviatiles',
          climate: 'Hyper-aride d\'altitude & vents froids',
          keyGrapes: 'Torrontés, Malbec, Pinot Noir',
        ),
        _createRegion(
          id: 'chile_central',
          name: 'Vallée Centrale du Chili (Maipo, Colchagua)',
          country: 'Chili',
          flag: '🇨🇱',
          normalizedBounds: const Rect.fromLTWH(0.10, 0.45, 0.30, 0.30),
          keywords: ['chili', 'chile', 'maipo', 'colchagua', 'puente alto', 'carmenere', 'almaviva', 'concha y toro', 'clos apalta', 'casablanca', 'leyda'],
          bottles: bottles,
          tastings: tastings,
          description: 'Le berceau historique du Cabernet Sauvignon chilien à Puente Alto et le royaume du Carménère à Apalta.',
          soilType: 'Cônes de déjection alluviaux andins & granites',
          climate: 'Méditerranéen protégé par la Cordillère',
          keyGrapes: 'Carménère, Cabernet Sauvignon, Syrah',
        ),
      ];
    } else if (mode == 'oceania') {
      return [
        _createRegion(
          id: 'barossa_valley',
          name: 'Barossa Valley & McLaren Vale (Australie)',
          country: 'Australie',
          flag: '🇦🇺',
          normalizedBounds: const Rect.fromLTWH(0.35, 0.45, 0.35, 0.28),
          keywords: ['barossa', 'mclaren vale', 'shiraz australie', 'penfolds', 'grange', 'henschke', 'eden valley'],
          bottles: bottles,
          tastings: tastings,
          description: 'Vieilles vignes de Shiraz centenaires non greffées, offrant une concentration aromatique et une opulence légendaires.',
          soilType: 'Argiles rouges profondes & loams ferrugineux',
          climate: 'Méditerranéen chaud et ensoleillé',
          keyGrapes: 'Shiraz, Grenache, Mataro (Mourvèdre)',
        ),
        _createRegion(
          id: 'margaret_river',
          name: 'Margaret River (Australie)',
          country: 'Australie',
          flag: '🇦🇺',
          normalizedBounds: const Rect.fromLTWH(0.08, 0.50, 0.28, 0.28),
          keywords: ['margaret river', 'leeuwin estate', 'cabernet margaret', 'chardonnay margaret', 'cullen'],
          bottles: bottles,
          tastings: tastings,
          description: 'Climat océanique tempéré idéal pour des Cabernets Sauvignons racés et des Chardonnays parmi les plus réputés au monde.',
          soilType: 'Graviers latéritiques sur socle granitique',
          climate: 'Maritime tempéré par l\'Océan Indien',
          keyGrapes: 'Cabernet Sauvignon, Chardonnay',
        ),
        _createRegion(
          id: 'marlborough_nz',
          name: 'Marlborough & Central Otago (Nouvelle-Zélande)',
          country: 'Nouvelle-Zélande',
          flag: '🇳🇿',
          normalizedBounds: const Rect.fromLTWH(0.68, 0.35, 0.28, 0.28),
          keywords: ['marlborough', 'cloudy bay', 'sauvignon nz', 'wairau', 'awatere', 'central otago', 'felton road', 'pinot noir nz'],
          bottles: bottles,
          tastings: tastings,
          description: 'L\'icône mondiale du Sauvignon Blanc éclatant à Marlborough et les Pinots Noirs d\'altitude envoûtants de Central Otago.',
          soilType: 'Graviers alluviaux & micaschistes',
          climate: 'Océanique aux nuits fraîches & semi-continental',
          keyGrapes: 'Sauvignon Blanc, Pinot Noir',
        ),
      ];
    } else if (mode == 'south_africa') {
      return [
        _createRegion(
          id: 'stellenbosch',
          name: 'Stellenbosch, Swartland & Franschhoek',
          country: 'Afrique du Sud',
          flag: '🇿🇦',
          normalizedBounds: const Rect.fromLTWH(0.40, 0.30, 0.35, 0.30),
          keywords: ['stellenbosch', 'franschhoek', 'kanonkop', 'meerlust', 'pinotage', 'chenin blanc afrique', 'cape winelands', 'swartland', 'sadie family'],
          bottles: bottles,
          tastings: tastings,
          description: 'Le cœur battant des Cape Winelands : granites décomposés, Cabernets de classe mondiale, Pinotages nobles et vieux Chenins de brousse.',
          soilType: 'Granites décomposés de Table Mountain & schistes',
          climate: 'Méditerranéen maritime tempéré par False Bay',
          keyGrapes: 'Cabernet Sauvignon, Pinotage, Chenin Blanc, Syrah',
        ),
      ];
    } else {
      // International & World Planisphere Wine Regions
      return [
        // 1. Europe Viticole
        _createRegion(
          id: 'france_all',
          name: 'France (Bordeaux, Bourgogne, Rhône...)',
          country: 'France',
          flag: '🇫🇷',
          normalizedBounds: const Rect.fromLTWH(0.485, 0.250, 0.05, 0.05),
          keywords: ['france', 'bordeaux', 'bourgogne', 'champagne', 'rhône', 'rhone', 'loire', 'alsace', 'provence'],
          bottles: bottles,
          tastings: tastings,
          description: 'Berceau des grands terroirs historiques, AOC séculaires et élevage sous bois d\'exception.',
        ),
        _createRegion(
          id: 'italie_all',
          name: 'Italie (Toscane, Piémont, Vénétie)',
          country: 'Italie',
          flag: '🇮🇹',
          normalizedBounds: const Rect.fromLTWH(0.520, 0.275, 0.04, 0.04),
          keywords: ['italie', 'italy', 'toscane', 'piémont', 'barolo', 'barbaresco', 'brunello', 'chianti', 'vénétie', 'valpolicella'],
          bottles: bottles,
          tastings: tastings,
          description: 'Le royaume du Sangiovese, du Nebbiolo noble et des grands vins de la péninsule italienne.',
        ),
        _createRegion(
          id: 'espagne_portugal',
          name: 'Espagne & Portugal (Rioja, Douro)',
          country: 'Espagne & Portugal',
          flag: '🇪🇸',
          normalizedBounds: const Rect.fromLTWH(0.460, 0.290, 0.05, 0.05),
          keywords: ['espagne', 'spain', 'portugal', 'rioja', 'ribera', 'priorat', 'douro', 'porto', 'alentejo'],
          bottles: bottles,
          tastings: tastings,
          description: 'Tempranillos intenses de Rioja, Ribera del Duero et vieux Portos de la vallée du Douro.',
        ),
        _createRegion(
          id: 'germany_austria_world',
          name: 'Allemagne & Europe Centrale',
          country: 'Allemagne & Autriche',
          flag: '🇩🇪',
          normalizedBounds: const Rect.fromLTWH(0.515, 0.235, 0.04, 0.04),
          keywords: ['allemagne', 'germany', 'autriche', 'austria', 'mosel', 'moselle', 'rheingau', 'wachau'],
          bottles: bottles,
          tastings: tastings,
          description: 'Rieslings d\'anthologie sur schistes de la Moselle et Grüner Veltliners minéraux du Danube.',
        ),

        // 2. North America
        _createRegion(
          id: 'napa_california',
          name: 'Californie & Pacific NW (Napa, Sonoma)',
          country: 'États-Unis',
          flag: '🇺🇸',
          normalizedBounds: const Rect.fromLTWH(0.135, 0.285, 0.06, 0.06),
          keywords: ['usa', 'états-unis', 'californie', 'california', 'napa', 'sonoma', 'oregon', 'washington', 'columbia'],
          bottles: bottles,
          tastings: tastings,
          description: 'Cabernets mythiques de Napa Valley, Pinots Noirs d\'Oregon et grands Chardonnays côtiers.',
        ),

        // 3. South America
        _createRegion(
          id: 'mendoza_andes',
          name: 'Argentine & Chili (Mendoza, Maipo)',
          country: 'Argentine & Chili',
          flag: '🇦🇷',
          normalizedBounds: const Rect.fromLTWH(0.285, 0.740, 0.06, 0.06),
          keywords: ['argentine', 'argentina', 'mendoza', 'salta', 'malbec', 'chili', 'chile', 'maipo', 'colchagua'],
          bottles: bottles,
          tastings: tastings,
          description: 'Malbecs d\'altitude au pied des Andes et Cabernets d\'exception de la vallée de Maipo.',
        ),

        // 4. Africa
        _createRegion(
          id: 'south_africa_world',
          name: 'Cape Winelands & Stellenbosch',
          country: 'Afrique du Sud',
          flag: '🇿🇦',
          normalizedBounds: const Rect.fromLTWH(0.535, 0.750, 0.05, 0.05),
          keywords: ['afrique', 'south africa', 'stellenbosch', 'swartland', 'franschhoek', 'chenin', 'pinotage'],
          bottles: bottles,
          tastings: tastings,
          description: 'Chenins d\'exception, Syrahs maritimes et vieilles vignes de Swartland et Stellenbosch.',
        ),

        // 5. Oceania
        _createRegion(
          id: 'oceania_wines',
          name: 'Australie & Nouvelle-Zélande (Barossa, Marlborough)',
          country: 'Australie & NZ',
          flag: '🇦🇺',
          normalizedBounds: const Rect.fromLTWH(0.860, 0.760, 0.08, 0.08),
          keywords: ['australie', 'australia', 'zélande', 'zealand', 'barossa', 'marlborough', 'shiraz', 'otago'],
          bottles: bottles,
          tastings: tastings,
          description: 'Shiraz centenaires de Barossa, Pinots Noirs de Central Otago et Sauvignons de Marlborough.',
        ),

        // 6. Asia
        _createRegion(
          id: 'asia_wines',
          name: 'Asie (Ningxia, Yamanashi)',
          country: 'Chine & Japon',
          flag: '🇨🇳',
          normalizedBounds: const Rect.fromLTWH(0.770, 0.310, 0.06, 0.06),
          keywords: ['chine', 'china', 'ningxia', 'japon', 'japan', 'yamanashi', 'nagano', 'koshu'],
          bottles: bottles,
          tastings: tastings,
          description: 'Vignobles émergents du mont Helan à Ningxia et délicats cépages Koshu du mont Fuji.',
        ),
      ];
    }
  }

  MapRegionData _createRegion({
    required String id,
    required String name,
    required String country,
    required String flag,
    required Rect normalizedBounds,
    required List<String> keywords,
    required List<Bottle> bottles,
    required List<TastingEntry> tastings,
    String? topWine,
    required String description,
    String? soilType,
    String? climate,
    String? keyGrapes,
  }) {
    // 1. Calculate Owned bottles
    final matchingBottles = bottles.where((b) {
      final region = b.wine?.region ?? '';
      final country = b.wine?.country ?? '';
      final app = b.wine?.appellation ?? '';
      final name = b.wine?.name ?? '';
      return _matchesKeywords(region, keywords) ||
          _matchesKeywords(country, keywords) ||
          _matchesKeywords(app, keywords) ||
          _matchesKeywords(name, keywords);
    }).toList();

    int ownedCount = 0;
    for (final b in matchingBottles) {
      ownedCount += b.quantity;
    }
    final isOwned = ownedCount > 0;

    // 2. Calculate Drunk / Tasted bottles
    final matchingTastings = tastings.where((t) {
      final region = t.region ?? '';
      final country = t.country ?? '';
      final app = t.appellation ?? '';
      final name = t.wineName ?? '';
      return _matchesKeywords(region, keywords) ||
          _matchesKeywords(country, keywords) ||
          _matchesKeywords(app, keywords) ||
          _matchesKeywords(name, keywords);
    }).toList();

    final drunkCount = matchingTastings.length;
    final isDrunk = drunkCount > 0;

    // Determine top cuvée if not specified
    String? resolvedTopWine = topWine;
    if (resolvedTopWine == null) {
      if (matchingTastings.isNotEmpty) {
        resolvedTopWine = matchingTastings.first.wineName;
      } else if (matchingBottles.isNotEmpty) {
        resolvedTopWine = matchingBottles.first.wine?.name;
      }
    }

    return MapRegionData(
      id: id,
      name: name,
      country: country,
      flag: flag,
      normalizedBounds: normalizedBounds,
      isOwned: isOwned,
      isDrunk: isDrunk,
      ownedCount: ownedCount,
      drunkCount: drunkCount,
      topWine: resolvedTopWine,
      description: description,
      soilType: soilType,
      climate: climate,
      keyGrapes: keyGrapes,
    );
  }

  Widget _buildDetailBadge(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFFD4AF37).withValues(alpha: 0.15) : const Color(0xFFD4AF37).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFFFE082) : const Color(0xFF8B1E3F),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(scratchMapModeProvider);
    final bottlesAsync = ref.watch(allUserBottlesProvider);
    final tastingAsync = ref.watch(tastingLogProvider);

    final bottles = bottlesAsync.value ?? [];
    final tastings = tastingAsync.value ?? [];
    final regions = _buildRegions(mode, bottles, tastings);

    final unlockedCount = regions.where((r) => r.isUnlocked).length;
    final totalCount = regions.length;
    final progress = totalCount > 0 ? (unlockedCount / totalCount) : 0.0;

    final bothCount = regions.where((r) => r.isOwned && r.isDrunk).length;
    final ownedOnlyCount = regions.where((r) => r.isOwned && !r.isDrunk).length;
    final drunkOnlyCount = regions.where((r) => !r.isOwned && r.isDrunk).length;
    final unexploredCount = regions.where((r) => !r.isOwned && !r.isDrunk).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.scratchcardTitle ?? 'Carte des Terroirs'),
        actions: [
          // Dual-View Toggle
          IconButton(
            icon: Icon(_showExplorer ? Icons.map_outlined : Icons.view_list_rounded),
            tooltip: _showExplorer ? 'Vue Planisphère' : 'Explorateur Terroirs',
            onPressed: () => setState(() => _showExplorer = !_showExplorer),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'france',
                    icon: Icon(Icons.flag, size: 16),
                    label: Text('France 🇫🇷'),
                  ),
                  ButtonSegment<String>(
                    value: 'italy',
                    icon: Icon(Icons.wine_bar, size: 16),
                    label: Text('Italie 🇮🇹'),
                  ),
                  ButtonSegment<String>(
                    value: 'spain',
                    icon: Icon(Icons.wb_sunny, size: 16),
                    label: Text('Espagne 🇪🇸'),
                  ),
                  ButtonSegment<String>(
                    value: 'portugal',
                    icon: Icon(Icons.sailing, size: 16),
                    label: Text('Portugal 🇵🇹'),
                  ),
                  ButtonSegment<String>(
                    value: 'germany_austria',
                    icon: Icon(Icons.castle, size: 16),
                    label: Text('Allemagne & Autriche 🇩🇪🇦🇹'),
                  ),
                  ButtonSegment<String>(
                    value: 'usa',
                    icon: Icon(Icons.star, size: 16),
                    label: Text('États-Unis 🇺🇸'),
                  ),
                  ButtonSegment<String>(
                    value: 'south_america',
                    icon: Icon(Icons.landscape, size: 16),
                    label: Text('Amérique du Sud 🇦🇷🇨🇱'),
                  ),
                  ButtonSegment<String>(
                    value: 'oceania',
                    icon: Icon(Icons.nature, size: 16),
                    label: Text('Océanie 🇦🇺🇳🇿'),
                  ),
                  ButtonSegment<String>(
                    value: 'south_africa',
                    icon: Icon(Icons.wb_twilight, size: 16),
                    label: Text('Afrique du Sud 🇿🇦'),
                  ),
                  ButtonSegment<String>(
                    value: 'international',
                    icon: Icon(Icons.terrain, size: 16),
                    label: Text('Terroirs Clés'),
                  ),
                  ButtonSegment<String>(
                    value: 'world',
                    icon: Icon(Icons.public, size: 16),
                    label: Text('Planisphère Mondial 🌍'),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (Set<String> newSelection) {
                  ref.read(scratchMapModeProvider.notifier).state = newSelection.first;
                },
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress & Exploration Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Color(0xFFD4AF37), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Exploration : $unlockedCount / $totalCount terroirs',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFD4AF37),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              color: const Color(0xFFD4AF37),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (!_showExplorer) ...[
            // Interactive Color Legend Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _LegendChip(
                        color: const Color(0xFFE5A93B),
                        label: 'En Cave ($ownedOnlyCount)',
                        icon: Icons.inventory_2,
                      ),
                      _LegendChip(
                        color: const Color(0xFF8B1E3F),
                        label: 'Dégusté ($drunkOnlyCount)',
                        icon: Icons.wine_bar,
                      ),
                      _LegendHatchedChip(
                        c1: const Color(0xFFE5A93B),
                        c2: const Color(0xFF8B1E3F),
                        label: 'Cave & Bu ($bothCount)',
                      ),
                      _LegendChip(
                        color: Colors.grey.shade500,
                        label: 'Inexploré ($unexploredCount)',
                        icon: Icons.lock_outline,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Interactive Map Canvas
            Expanded(
              child: ScratchMapCanvas(
                mapMode: mode,
                regions: regions,
                onRegionTapped: (region) => _showRegionDetails(context, region),
              ),
            ),
          ] else ...[
            // 📜 Explorateur de Terroirs — Filterable cards list view
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un terroir, une région...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                onChanged: (val) => setState(() => _explorerSearch = val.toLowerCase()),
              ),
            ),
            // Filter chips row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Tous',
                      selected: _explorerFilter == 'all',
                      onTap: () => setState(() => _explorerFilter = 'all'),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: '🌟 Explorés',
                      selected: _explorerFilter == 'unlocked',
                      onTap: () => setState(() => _explorerFilter = 'unlocked'),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: '🏷️ En Cave',
                      selected: _explorerFilter == 'owned',
                      onTap: () => setState(() => _explorerFilter = 'owned'),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: '🍷 Dégustés',
                      selected: _explorerFilter == 'drunk',
                      onTap: () => setState(() => _explorerFilter = 'drunk'),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: '🔒 À découvrir',
                      selected: _explorerFilter == 'locked',
                      onTap: () => setState(() => _explorerFilter = 'locked'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _buildExplorerList(context, regions),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExplorerList(BuildContext context, List<MapRegionData> regions) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Apply filters
    var filtered = regions.where((r) {
      if (_explorerFilter == 'unlocked') return r.isUnlocked;
      if (_explorerFilter == 'owned') return r.isOwned;
      if (_explorerFilter == 'drunk') return r.isDrunk;
      if (_explorerFilter == 'locked') return !r.isUnlocked;
      return true;
    }).toList();

    // Apply search
    if (_explorerSearch.isNotEmpty) {
      filtered = filtered.where((r) {
        final search = _explorerSearch;
        return r.name.toLowerCase().contains(search) ||
            r.country.toLowerCase().contains(search) ||
            r.description.toLowerCase().contains(search) ||
            (r.topWine?.toLowerCase().contains(search) ?? false);
      }).toList();
    }

    // Sort: unlocked first, then by owned count desc
    filtered.sort((a, b) {
      if (a.isUnlocked && !b.isUnlocked) return -1;
      if (!a.isUnlocked && b.isUnlocked) return 1;
      return b.ownedCount.compareTo(a.ownedCount);
    });

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Aucun terroir trouvé',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final r = filtered[index];
        return _TerroirExplorerCard(
          region: r,
          isDark: isDark,
          onTap: () => _showRegionDetails(context, r),
        );
      },
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;

  const _LegendChip({
    required this.color,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black26, width: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _LegendHatchedChip extends StatelessWidget {
  final Color c1;
  final Color c2;
  final String label;

  const _LegendHatchedChip({
    required this.c1,
    required this.c2,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black26, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2.5),
            child: CustomPaint(
              painter: _HatchedChipPainter(c1: c1, c2: c2),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _HatchedChipPainter extends CustomPainter {
  final Color c1;
  final Color c2;

  _HatchedChipPainter({required this.c1, required this.c2});

  @override
  void paint(Canvas canvas, Size size) {
    // Fill c1
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = c1);
    // Draw stripes c2
    final stripePaint = Paint()
      ..color = c2
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    for (double d = -size.height; d < size.width + size.height; d += 5.0) {
      canvas.drawLine(Offset(d, size.height), Offset(d + size.height, 0), stripePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color = const Color(0xFFD4AF37),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
      ],
    );
  }
}

// ============================================================================
// Explorateur de Terroirs — Beautiful Card for List View
// ============================================================================
class _TerroirExplorerCard extends StatelessWidget {
  final MapRegionData region;
  final bool isDark;
  final VoidCallback onTap;

  const _TerroirExplorerCard({
    required this.region,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (region.isOwned && region.isDrunk) {
      statusColor = const Color(0xFFD4AF37);
      statusLabel = 'En Cave & Dégusté';
      statusIcon = Icons.stars;
    } else if (region.isOwned) {
      statusColor = const Color(0xFFE5A93B);
      statusLabel = 'En Cave';
      statusIcon = Icons.inventory_2;
    } else if (region.isDrunk) {
      statusColor = const Color(0xFF8B1E3F);
      statusLabel = 'Dégusté';
      statusIcon = Icons.wine_bar;
    } else {
      statusColor = Colors.grey;
      statusLabel = 'À découvrir';
      statusIcon = Icons.lock_outline;
    }

    final isUnlocked = region.isUnlocked;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isUnlocked ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isUnlocked
            ? BorderSide(color: statusColor.withValues(alpha: 0.5), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Flag & Status indicator
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isUnlocked ? 0.15 : 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: statusColor.withValues(alpha: isUnlocked ? 0.5 : 0.15),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(region.flag, style: const TextStyle(fontSize: 22)),
                    if (isUnlocked)
                      Icon(statusIcon, size: 12, color: statusColor),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Region info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            region.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? null : Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      region.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Stats row
                    Row(
                      children: [
                        if (region.ownedCount > 0) ...[
                          const Icon(Icons.inventory_2, size: 13, color: Color(0xFFE5A93B)),
                          const SizedBox(width: 3),
                          Text(
                            '${region.ownedCount} btl',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (region.drunkCount > 0) ...[
                          const Icon(Icons.wine_bar, size: 13, color: Color(0xFF8B1E3F)),
                          const SizedBox(width: 3),
                          Text(
                            '${region.drunkCount} dég.',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (region.topWine != null) ...[
                          const Icon(Icons.star, size: 13, color: Colors.amber),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              region.topWine!,
                              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Filter Chip for Explorateur de Terroirs
// ============================================================================
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF8B1E3F).withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF8B1E3F) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? const Color(0xFF8B1E3F) : null,
          ),
        ),
      ),
    );
  }
}
