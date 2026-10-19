import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../domain/cadrage_du_terroir.dart';
import '../domain/terroir_geo_data.dart';
import '../../../shared/utils/pays.dart';
import '../../../shared/utils/langue.dart';

/// Assombrit les tuiles d'OpenTopoMap pour l'ambiance sombre, sans en changer les couleurs.
///
/// Un seul fournisseur sert les deux ambiances, ce qui évite d'en dépendre de deux et garde
/// l'attribution unique. Le filtre baisse la lumière et désature un peu : la mer reste bleue
/// et le relief garde ses teintes. L'inversion de luminance qu'il remplace (V2.5 · F7)
/// faisait des mers orange et des terres violettes.
const ColorFilter kDarkTerroirTileFilter = ColorFilter.matrix(<double>[
  0.60,
  0.06,
  0.02,
  0,
  0,
  0.04,
  0.62,
  0.02,
  0,
  0,
  0.04,
  0.06,
  0.64,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

/// Attribution exigée par la licence CC-BY-SA d'OpenTopoMap. Elle doit rester
/// « deutlich sichtbar » — clairement visible — sur toute carte affichée.
String get kTerroirTileAttribution => tr('© OpenStreetMap · SRTM · rendu © OpenTopoMap (CC-BY-SA)',
    '© OpenStreetMap · SRTM · style © OpenTopoMap (CC-BY-SA)');

/// L'origine d'un vin en deux cartes fixes (V2.5 · F7) : le pays, pour situer, puis la zone
/// de l'appellation, pour voir — ou environ un département quand le vin n'est reconnu que
/// par sa région. Aucun geste : une carte qu'on peut glisser et zoomer finit par ne plus
/// montrer son sujet (voir [CadrageDuTerroir]).
class TerroirMapView extends StatefulWidget {
  final String country;
  final String region;
  final String? subRegion;
  final String? appellation;
  final bool isSpirit;
  final String? wineType;
  final String? wineName;
  final String? producer;

  const TerroirMapView({
    super.key,
    required this.country,
    required this.region,
    this.subRegion,
    this.appellation,
    this.isSpirit = false,
    this.wineType,
    this.wineName,
    this.producer,
  });

  @override
  State<TerroirMapView> createState() => _TerroirMapViewState();
}

class _TerroirMapViewState extends State<TerroirMapView> {
  /// Nul quand le terroir n'est pas dans l'atlas : la carte le dit au lieu de montrer une
  /// appellation approchante (V2.4 · R1).
  TerroirGeoProfile? _terroir;

  /// Vrai quand c'est l'appellation elle-même qui a été reconnue : la seconde carte en
  /// dessine la zone. Sinon, environ un département, sans contour ni point.
  bool _parAppellation = false;
  List<LatLng> _contour = const [];

  @override
  void initState() {
    super.initState();
    _resolveTerroir();
  }

  @override
  void didUpdateWidget(covariant TerroirMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.country != widget.country ||
        oldWidget.region != widget.region ||
        oldWidget.subRegion != widget.subRegion ||
        oldWidget.appellation != widget.appellation ||
        oldWidget.isSpirit != widget.isSpirit ||
        oldWidget.wineType != widget.wineType ||
        oldWidget.wineName != widget.wineName ||
        oldWidget.producer != widget.producer) {
      _resolveTerroir();
    }
  }

  void _resolveTerroir() {
    _terroir = TerroirGeoResolver.trouver(
      country: widget.country,
      region: widget.region,
      subRegion: widget.subRegion,
      appellation: widget.appellation,
      isSpirit: widget.isSpirit,
      wineType: widget.wineType,
      wineName: widget.wineName,
      producer: widget.producer,
    );
    final t = _terroir;
    _parAppellation = t != null && TerroirGeoResolver.parAppellation(t, widget.appellation);
    _contour = _parAppellation ? t!.generateAppellationBoundary() : const [];
  }

  @override
  Widget build(BuildContext context) {
    final t = _terroir;
    if (t == null) return _nonRepertorie(context);
    return _carte(context, t);
  }

  /// Un terroir hors de l'atlas : on le nomme tel que l'étiquette le donne, sans rien en
  /// dire de plus.
  Widget _nonRepertorie(BuildContext context) {
    final theme = Theme.of(context);
    final lieu = [widget.appellation, widget.subRegion, widget.region, widget.country]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .join(', ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.travel_explore, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              lieu.isEmpty
                  ? tr('Ce terroir n\'est pas encore dans notre atlas.', 'This terroir is not in our atlas yet.')
                  : tr('{lieu} : ce terroir n\'est pas encore dans notre atlas.',
                      '{lieu}: this terroir is not in our atlas yet.', {'lieu': lieu}),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carte(BuildContext context, TerroirGeoProfile profil) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dansLePays = CadrageDuTerroir.dansLePays(profil);
    final region = [widget.subRegion, widget.region]
        .whereType<String>()
        .map((s) => s.trim())
        .firstWhere((s) => s.isNotEmpty, orElse: () => profil.region);

    final pays = _CarteFixe(
      key: ValueKey('pays_${profil.id}'),
      cadrage: CadrageDuTerroir.pays(profil),
      legende: '${profil.flag} ${dansLePays ? Pays.nom(profil.country) : profil.region}',
      sombre: isDark,
      couches: [_point(profil)],
    );
    final zone = _CarteFixe(
      key: ValueKey('zone_${profil.id}_$_parAppellation'),
      cadrage: CadrageDuTerroir.zone(profil, appellationReconnue: _parAppellation),
      legende: _parAppellation ? profil.appellation : region,
      sombre: isDark,
      couches: [
        if (_parAppellation) ...[
          // Remplissage franc : sur un fond topographique chargé, une teinte à 15 %
          // disparaissait et l'appellation devenait indiscernable.
          PolygonLayer(polygons: [
            Polygon(
              points: _contour,
              color: profil.accentColor.withValues(alpha: 0.28),
              borderColor: profil.accentColor,
              borderStrokeWidth: 2.5,
            ),
          ]),
          _point(profil),
        ],
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      // Posée dans une hauteur bornée, la fiche défile au lieu de déborder.
      child: LayoutBuilder(
        builder: (context, contraintes) {
          final contenu = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  // Côte à côte : la carte du pays n'est qu'un repère, elle se lit encore sur 120 px
                  // (un téléphone de 360 px laisse à la fiche 288 px). L'une sous l'autre en deçà.
                  if (constraints.maxWidth >= 240) {
                    return SizedBox(
                      height: 190,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [Expanded(child: pays), const SizedBox(width: 2), Expanded(child: zone)],
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 170, child: pays),
                      const SizedBox(height: 2),
                      SizedBox(height: 170, child: zone)
                    ],
                  );
                },
              ),
              // La licence CC-BY-SA d'OpenTopoMap exige une attribution « clairement visible » :
              // en clair sous les deux cartes, plutôt que repliée derrière un bouton.
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                child: Text(
                  kTerroirTileAttribution,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Flag, Appellation Name & Classification
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profil.flag,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profil.nomAffiche,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${profil.region}${profil.subRegion != null ? ' • ${profil.subRegion}' : ''} (${profil.country})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              profil.classementAffiche.split('(').first.trim(),
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Terroir Attribute Chips (Soil, Climate, Exposure/Altitude, Grapes)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTerroirChip(
                          icon: Icons.layers_outlined,
                          label: tr('Sol', 'Soil'),
                          value: profil.solAffiche,
                          theme: theme,
                        ),
                        _buildTerroirChip(
                          icon: Icons.wb_sunny_outlined,
                          label: tr('Climat', 'Climate'),
                          value: profil.climatAffiche,
                          theme: theme,
                        ),
                        _buildTerroirChip(
                          icon: Icons.landscape_outlined,
                          label: tr('Relief', 'Relief'),
                          value: '${profil.expositionAffichee} • ${profil.altitudeAffichee}',
                          theme: theme,
                        ),
                        _buildTerroirChip(
                          icon: Icons.bubble_chart_outlined,
                          label: tr('Cépages', 'Grapes'),
                          value: profil.cepagesAffiches,
                          theme: theme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Sommelier Geological Notes Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1B24) : const Color(0xFFFBF8F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.format_quote,
                            size: 20,
                            color: Color(0xFFD4AF37),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              profil.notesAffichees,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                height: 1.35,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          if (!contraintes.hasBoundedHeight) return contenu;
          return SingleChildScrollView(physics: const ClampingScrollPhysics(), primary: false, child: contenu);
        },
      ),
    );
  }

  /// Le lieu, en un point doré : sur la carte du pays, et au centre de l'appellation.
  MarkerLayer _point(TerroirGeoProfile p) => MarkerLayer(markers: [
        Marker(
          point: p.center,
          width: 16,
          height: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4AF37),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 4),
              ],
            ),
          ),
        ),
      ]);

  Widget _buildTerroirChip({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1A26) : const Color(0xFFF2EFE9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFD4AF37)),
          const SizedBox(width: 6),
          Flexible(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                children: [
                  TextSpan(
                    text: tr('{label} : ', '{label}: ', {'label': label}),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une carte figée : cadrée une fois, sans aucun geste, et transparente au doigt pour que
/// la fiche défile par-dessus.
/// Le centre et le zoom qui font tenir [cadrage] dans une carte de [taille].
///
/// Calculés ici plutôt que confiés à `initialCameraFit` : avec des tuiles déjà en cache
/// (une fiche rouverte, une page rechargée), flutter_map 8.3 chargeait celles du cadrage
/// sans jamais les afficher, et la carte restait vide. Le centre et le zoom donnés d'emblée
/// n'ont pas ce défaut ; le calcul reste celui de flutter_map.
@visibleForTesting
(LatLng, double) cadrer(LatLngBounds cadrage, Size taille) {
  if (!taille.isFinite || taille.isEmpty) return (cadrage.center, 5);
  final camera = CameraFit.bounds(bounds: cadrage, padding: const EdgeInsets.all(6))
      .fit(MapCamera.initialCamera(const MapOptions()).withNonRotatedSize(taille));
  return (camera.center, camera.zoom);
}

class _CarteFixe extends StatelessWidget {
  final LatLngBounds cadrage;
  final String legende;
  final bool sombre;
  final List<Widget> couches;

  const _CarteFixe({
    super.key,
    required this.cadrage,
    required this.legende,
    required this.sombre,
    required this.couches,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: LayoutBuilder(builder: (context, contraintes) {
              final (centre, zoom) = cadrer(cadrage, contraintes.biggest);
              return FlutterMap(
                // Une autre taille (le téléphone tourné), un autre cadrage.
                key: ValueKey(contraintes.biggest),
                options: MapOptions(
                  initialCenter: centre,
                  initialZoom: zoom,
                  // Le fond pendant que les tuiles arrivent : pas un pavé clair dans l'ambiance sombre.
                  backgroundColor: sombre ? const Color(0xFF26232B) : const Color(0xFFE8E4DC),
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  // OpenTopoMap, sans clé et utilisable commercialement (CC-BY-SA) ; le rendu
                  // sombre est un filtre sur les mêmes tuiles (voir `kDarkTerroirTileFilter`).
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.chatmelier.app',
                    maxZoom: 17,
                    tileBuilder: sombre
                        ? (context, tileWidget, tile) =>
                            ColorFiltered(colorFilter: kDarkTerroirTileFilter, child: tileWidget)
                        : null,
                  ),
                  ...couches,
                ],
              );
            }),
          ),
        ),
        Positioned(
          top: 6,
          left: 6,
          right: 6,
          child: Align(
            alignment: Alignment.topLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  legende,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
