import 'package:flutter/material.dart';
import '../domain/bottle.dart';
import '../domain/cellar_filter_state.dart';
import '../../../shared/widgets/grape_chart.dart';
import '../../../shared/utils/langue.dart';
import '../../../shared/utils/valeurs_rangees.dart';

class CellarFilterSheet extends StatefulWidget {
  final CellarFilterState initialFilter;
  final List<Bottle> bottles;
  final ValueChanged<CellarFilterState> onApply;

  const CellarFilterSheet({
    super.key,
    required this.initialFilter,
    this.bottles = const [],
    required this.onApply,
  });

  @override
  State<CellarFilterSheet> createState() => _CellarFilterSheetState();
}

class _CellarFilterSheetState extends State<CellarFilterSheet> {
  late CellarFilterState _current;

  late List<String> _continents;
  late List<String> _countries;
  late List<String> _grapes;
  late List<String> _appellations;
  late List<int> _vintages;

  @override
  void initState() {
    super.initState();
    _current = widget.initialFilter;
    _extractDynamicFilters();
  }

  void _extractDynamicFilters() {
    final Set<String> grapeSet = {};
    final Set<String> appSet = {};
    final Set<String> countrySet = {};
    final Set<String> continentSet = {};
    final Set<int> vintageSet = {};

    for (final b in widget.bottles) {
      final wine = b.wine;
      if (wine == null) continue;

      // 1. Grapes (from wine.grapes and GrapeBlendResolver)
      final resolvedGrapes = GrapeBlendResolver.resolveGrapes(
        existingGrapes: wine.grapes,
        wineType: wine.type,
        appellation: wine.appellation,
        region: wine.region,
        wineName: wine.name,
        producer: wine.producer,
        cuveeParcel: wine.cuveeParcel,
      );

      for (final g in resolvedGrapes) {
        if (g.name.trim().isNotEmpty) {
          grapeSet.add(g.name.trim());
        }
      }

      // Also add explicit wine.grapes if any
      for (final g in wine.grapes) {
        if (g.name.trim().isNotEmpty) {
          grapeSet.add(g.name.trim());
        }
      }

      // 2. Appellations & Regions
      if (wine.appellation != null && wine.appellation!.trim().isNotEmpty) {
        appSet.add(wine.appellation!.trim());
      }
      if (wine.subRegion != null && wine.subRegion!.trim().isNotEmpty) {
        appSet.add(wine.subRegion!.trim());
      }
      if (wine.region.trim().isNotEmpty) {
        appSet.add(wine.region.trim());
      }

      // 3. Countries
      if (wine.country.trim().isNotEmpty) {
        countrySet.add(wine.country.trim());
      }

      // 4. Continents
      final cont = _mapCountryToContinent(wine.country);
      if (cont.isNotEmpty) {
        continentSet.add(cont);
      }

      // 5. Vintages
      if (wine.vintage != null && wine.vintage! > 1900) {
        vintageSet.add(wine.vintage!);
      }
    }

    // Canonical Fallback if cellar is empty
    if (grapeSet.isEmpty) {
      grapeSet.addAll([
        'Cabernet Sauvignon',
        'Merlot',
        'Pinot Noir',
        'Chardonnay',
        'Syrah',
        'Mourvèdre',
        'Grenache',
        'Cinsault',
        'Sauvignon Blanc',
        'Chenin',
        'Riesling',
        'Tempranillo',
        'Nebbiolo',
        'Sangiovese',
        'Malbec',
      ]);
    }

    if (appSet.isEmpty) {
      appSet.addAll([
        'Bandol',
        'Bordeaux',
        'Bourgogne',
        'Chablis',
        'Champagne',
        'Vallée du Rhône',
        'Val de Loire',
        'Alsace',
        'Saint-Julien',
        'Pic Saint-Loup',
        'Cassis',
        'Rioja',
        'Ribera del Duero',
        'Toscana',
        'Piemonte',
        'Napa Valley',
        'Mendoza',
      ]);
    }

    if (countrySet.isEmpty) {
      countrySet.addAll([
        'France',
        'Italie',
        'Espagne',
        'États-Unis',
        'Portugal',
        'Chili',
        'Argentine',
        'Australie',
        'Allemagne',
        'Afrique du Sud',
      ]);
    }

    if (continentSet.isEmpty) {
      continentSet.addAll(['Europe', 'Amériques', 'Océanie', 'Afrique']);
    }

    // Sort alphabetically / descending
    _grapes = grapeSet.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _appellations = appSet.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _countries = countrySet.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _continents = continentSet.toList()..sort();
    _vintages = vintageSet.toList()..sort((a, b) => b.compareTo(a));
  }

  String _mapCountryToContinent(String country) {
    final c = country.toLowerCase();
    if (c.contains('france') ||
        c.contains('ital') ||
        c.contains('spain') ||
        c.contains('espag') ||
        c.contains('portug') ||
        c.contains('german') ||
        c.contains('allemag') ||
        c.contains('suisse') ||
        c.contains('austria') ||
        c.contains('autrich') ||
        c.contains('grèce') ||
        c.contains('greece')) {
      return 'Europe';
    }
    if (c.contains('state') ||
        c.contains('unis') ||
        c.contains('usa') ||
        c.contains('calif') ||
        c.contains('argentin') ||
        c.contains('chili') ||
        c.contains('canada') ||
        c.contains('mexiq') ||
        c.contains('oregon')) {
      return 'Amériques';
    }
    if (c.contains('austral') || c.contains('zealand') || c.contains('zélande')) {
      return 'Océanie';
    }
    if (c.contains('south africa') || c.contains('afrique')) {
      return 'Afrique';
    }
    return 'Europe';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title and Reset
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune, color: Color(0xFF8B1E3F), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          tr('Filtres avancés', 'Advanced filters'),
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (_current.isActive)
                      TextButton.icon(
                        onPressed: () => setState(() => _current = const CellarFilterState()),
                        icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF8B1E3F)),
                        label: Text(tr('Réinitialiser', 'Reset'), style: const TextStyle(color: Color(0xFF8B1E3F), fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              const Divider(),

              // Scrollable Filter Sections
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 1. STATUT DE MATURITÉ / APOGÉE
                    _buildSectionHeader(tr('Fenêtre de Dégustation / Apogée', 'Drinking window / peak'), icon: Icons.hourglass_top),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip(tr('✨ À l\'apogée (Peak)', '✨ At its peak'), 'peak', _current.maturityStatus, (v) {
                          setState(() => _current = _current.copyWith(maturityStatus: () => v ? 'peak' : null));
                        }),
                        _buildChoiceChip(tr('⏳ À boire vite', '⏳ Drink soon'), 'drink_soon', _current.maturityStatus, (v) {
                          setState(() => _current = _current.copyWith(maturityStatus: () => v ? 'drink_soon' : null));
                        }),
                        _buildChoiceChip(tr('🍷 En garde', '🍷 Ageing'), 'aging', _current.maturityStatus, (v) {
                          setState(() => _current = _current.copyWith(maturityStatus: () => v ? 'aging' : null));
                        }),
                        _buildChoiceChip(tr('🌱 Trop jeune', '🌱 Too young'), 'young', _current.maturityStatus, (v) {
                          setState(() => _current = _current.copyWith(maturityStatus: () => v ? 'young' : null));
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. CÉPAGES DYNAMIQUES DE LA CAVE
                    _buildSectionHeader(tr('Cépages de votre Cave ({grapes_length})', 'Grapes in your cellar ({grapes_length})', {'grapes_length': _grapes.length}), icon: Icons.grain),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _grapes.map((grape) {
                        return _buildChoiceChip(grape, grape, _current.grape, (v) {
                          setState(() => _current = _current.copyWith(grape: () => v ? grape : null));
                        });
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // 3. RÉGIONS & APPELLATIONS DE LA CAVE
                    _buildSectionHeader(tr('Régions & Appellations ({appellations_length})', 'Regions & appellations ({appellations_length})', {'appellations_length': _appellations.length}), icon: Icons.map_outlined),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _appellations.map((appellation) {
                        return _buildChoiceChip(valeurAffichee(appellation), appellation, _current.appellation, (v) {
                          setState(() => _current = _current.copyWith(appellation: () => v ? appellation : null));
                        });
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // 4. MILLÉSIMES DISPONIBLES
                    if (_vintages.isNotEmpty) ...[
                      _buildSectionHeader(tr('Millésimes ({vintages_length})', 'Vintages ({vintages_length})', {'vintages_length': _vintages.length}), icon: Icons.calendar_today_outlined),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _vintages.map((vintage) {
                          final isSelected = _current.vintage == vintage;
                          return FilterChip(
                            label: Text('$vintage'),
                            selected: isSelected,
                            selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                            checkmarkColor: const Color(0xFF8B1E3F),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF8B1E3F) : null,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (v) {
                              setState(() => _current = _current.copyWith(vintage: () => v ? vintage : null));
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 5. PAYS D'ORIGINE
                    _buildSectionHeader(tr('Pays d\'origine ({countries_length})', 'Country of origin ({countries_length})', {'countries_length': _countries.length}), icon: Icons.flag_outlined),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _countries.map((country) {
                        return _buildChoiceChip(valeurAffichee(country), country, _current.country, (v) {
                          setState(() => _current = _current.copyWith(country: () => v ? country : null));
                        });
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // 6. CONTINENT
                    _buildSectionHeader(tr('Continent', 'Continent'), icon: Icons.public),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _continents.map((continent) {
                        return _buildChoiceChip(valeurAffichee(continent), continent, _current.continent, (v) {
                          setState(() => _current = _current.copyWith(continent: () => v ? continent : null));
                        });
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // Bottom Apply Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2)),
                  ],
                ),
                child: SafeArea(
                  child: FilledButton(
                    onPressed: () {
                      widget.onApply(_current);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _current.isActive
                          ? (_current.activeFilterCount > 1
                              ? tr('Appliquer ({n} filtres actifs)', 'Apply ({n} active filters)', {'n': _current.activeFilterCount})
                              : tr('Appliquer ({n} filtre actif)', 'Apply ({n} active filter)', {'n': _current.activeFilterCount}))
                          : tr('Voir toutes les bouteilles', 'See all bottles'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: const Color(0xFF8B1E3F)),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF8B1E3F)),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(
    String label,
    String value,
    String? selectedValue,
    ValueChanged<bool> onSelected,
  ) {
    final isSelected = selectedValue?.toLowerCase() == value.toLowerCase();
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
      checkmarkColor: const Color(0xFF8B1E3F),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF8B1E3F) : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: onSelected,
    );
  }
}