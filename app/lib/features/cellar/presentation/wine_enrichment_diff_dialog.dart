import 'package:flutter/material.dart';
import '../domain/wine.dart';

class WineFieldDiff {
  final String key;
  final String label;
  final IconData icon;
  final String currentDisplay;
  final String aiDisplay;
  final dynamic aiRawValue;
  bool useAi;

  WineFieldDiff({
    required this.key,
    required this.label,
    required this.icon,
    required this.currentDisplay,
    required this.aiDisplay,
    required this.aiRawValue,
    this.useAi = false,
  });
}

class WineEnrichmentDiffDialog extends StatefulWidget {
  final Wine currentWine;
  final Map<String, dynamic> enrichedData;
  final List<Grape> enrichedGrapes;
  final Function(Map<String, dynamic> updatePayload, List<String> updatedOverrides) onApply;

  const WineEnrichmentDiffDialog({
    super.key,
    required this.currentWine,
    required this.enrichedData,
    required this.enrichedGrapes,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required Wine currentWine,
    required Map<String, dynamic> enrichedData,
    required List<Grape> enrichedGrapes,
    required Function(Map<String, dynamic> updatePayload, List<String> updatedOverrides) onApply,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WineEnrichmentDiffDialog(
        currentWine: currentWine,
        enrichedData: enrichedData,
        enrichedGrapes: enrichedGrapes,
        onApply: onApply,
      ),
    );
  }

  @override
  State<WineEnrichmentDiffDialog> createState() => _WineEnrichmentDiffDialogState();
}

class _WineEnrichmentDiffDialogState extends State<WineEnrichmentDiffDialog> {
  late List<WineFieldDiff> _diffs;
  late Map<String, dynamic> _autoApplyPayload;

  @override
  void initState() {
    super.initState();
    _computeDifferences();
  }

  void _computeDifferences() {
    final wine = widget.currentWine;
    final enriched = widget.enrichedData;
    final userOverrides = wine.userOverrides.toSet();

    _diffs = [];
    _autoApplyPayload = {};

    void checkField({
      required String key,
      required String label,
      required IconData icon,
      required dynamic currentValue,
      required dynamic aiValue,
      required String Function(dynamic) formatVal,
    }) {
      if (aiValue == null) return;
      if (aiValue is String && aiValue.trim().isEmpty) return;

      final isManual = userOverrides.contains(key);
      final currentFormatted = formatVal(currentValue);
      final aiFormatted = formatVal(aiValue);

      if (!isManual) {
        // Automatic field -> auto apply
        _autoApplyPayload[key] = aiValue;
      } else {
        // Manually overridden field -> check for difference
        if (currentFormatted.trim().toLowerCase() != aiFormatted.trim().toLowerCase()) {
          _diffs.add(WineFieldDiff(
            key: key,
            label: label,
            icon: icon,
            currentDisplay: currentFormatted.isEmpty ? '(Non renseigné)' : currentFormatted,
            aiDisplay: aiFormatted,
            aiRawValue: aiValue,
            useAi: false, // Default: keep user's manual value
          ));
        }
      }
    }

    // 1. Apogee & Lifespan fields
    checkField(
      key: 'peak_drinking_start',
      label: 'Début d\'apogée',
      icon: Icons.auto_awesome,
      currentValue: wine.peakStart,
      aiValue: enriched['peak_drinking_start'],
      formatVal: (v) => v != null ? '$v' : '',
    );
    checkField(
      key: 'peak_drinking_end',
      label: 'Fin d\'apogée',
      icon: Icons.alarm,
      currentValue: wine.peakEnd,
      aiValue: enriched['peak_drinking_end'],
      formatVal: (v) => v != null ? '$v' : '',
    );
    checkField(
      key: 'ideal_drinking_start',
      label: 'Début de dégustation conseillée',
      icon: Icons.calendar_today,
      currentValue: wine.drinkStart,
      aiValue: enriched['ideal_drinking_start'],
      formatVal: (v) => v != null ? '$v' : '',
    );
    checkField(
      key: 'ideal_drinking_end',
      label: 'Fin de garde conseillée',
      icon: Icons.timelapse,
      currentValue: wine.drinkEnd,
      aiValue: enriched['ideal_drinking_end'],
      formatVal: (v) => v != null ? '$v' : '',
    );

    // 2. Identity & Region fields
    checkField(
      key: 'name',
      label: 'Nom du vin',
      icon: Icons.wine_bar,
      currentValue: wine.name,
      aiValue: enriched['name'],
      formatVal: (v) => v?.toString() ?? '',
    );
    checkField(
      key: 'producer',
      label: 'Domaine / Producteur',
      icon: Icons.business,
      currentValue: wine.producer,
      aiValue: enriched['producer'],
      formatVal: (v) => v?.toString() ?? '',
    );
    checkField(
      key: 'vintage',
      label: 'Millésime',
      icon: Icons.history,
      currentValue: wine.vintage,
      aiValue: enriched['vintage'],
      formatVal: (v) => v != null ? '$v' : '',
    );
    checkField(
      key: 'country',
      label: 'Pays',
      icon: Icons.public,
      currentValue: wine.country,
      aiValue: enriched['country'],
      formatVal: (v) => v?.toString() ?? '',
    );
    checkField(
      key: 'region',
      label: 'Région',
      icon: Icons.map,
      currentValue: wine.region,
      aiValue: enriched['region'],
      formatVal: (v) => v?.toString() ?? '',
    );
    checkField(
      key: 'sub_region',
      label: 'Sous-région',
      icon: Icons.location_on,
      currentValue: wine.subRegion,
      aiValue: enriched['sub_region'],
      formatVal: (v) => v?.toString() ?? '',
    );
    checkField(
      key: 'appellation',
      label: 'Appellation / AOC',
      icon: Icons.verified,
      currentValue: wine.appellation,
      aiValue: enriched['appellation'],
      formatVal: (v) => v?.toString() ?? '',
    );
    checkField(
      key: 'classification',
      label: 'Classification',
      icon: Icons.workspace_premium,
      currentValue: wine.classification,
      aiValue: enriched['classification'],
      formatVal: (v) => v?.toString() ?? '',
    );
    checkField(
      key: 'cuvee_parcel',
      label: 'Cuvée / Parcelle',
      icon: Icons.local_offer,
      currentValue: wine.cuveeParcel,
      aiValue: enriched['cuvee_parcel'],
      formatVal: (v) => v?.toString() ?? '',
    );
    checkField(
      key: 'alcohol_pct',
      label: 'Degré d\'alcool',
      icon: Icons.percent,
      currentValue: wine.alcoholPct,
      aiValue: enriched['alcohol_pct'],
      formatVal: (v) => v != null ? '${(v as num).toStringAsFixed(1)}%' : '',
    );
    checkField(
      key: 'estimated_market_value',
      label: 'Valeur marchande estimée',
      icon: Icons.euro,
      currentValue: wine.estimatedMarketValue,
      aiValue: enriched['estimated_market_value'],
      formatVal: (v) => v != null ? '${(v as num).toStringAsFixed(0)} €' : '',
    );

    // 3. Grapes (Encépagement)
    if (widget.enrichedGrapes.isNotEmpty) {
      final currentGrapesStr = wine.grapes.map((g) => g.pct != null ? '${g.name} (${g.pct!.toStringAsFixed(0)}%)' : g.name).join(', ');
      final aiGrapesStr = widget.enrichedGrapes.map((g) => g.pct != null ? '${g.name} (${g.pct!.toStringAsFixed(0)}%)' : g.name).join(', ');
      if (userOverrides.contains('grapes') && currentGrapesStr.trim() != aiGrapesStr.trim()) {
        _diffs.add(WineFieldDiff(
          key: 'grapes',
          label: 'Encépagement / Cépages',
          icon: Icons.grass,
          currentDisplay: currentGrapesStr.isEmpty ? '(Non renseigné)' : currentGrapesStr,
          aiDisplay: aiGrapesStr,
          aiRawValue: widget.enrichedGrapes.map((g) => g.toJson()).toList(),
          useAi: false,
        ));
      } else if (!userOverrides.contains('grapes')) {
        _autoApplyPayload['grapes'] = widget.enrichedGrapes.map((g) => g.toJson()).toList();
      }
    }

    // 4. Tasting notes
    checkField(
      key: 'tasting_notes',
      label: 'Notes de dégustation / Sommelier',
      icon: Icons.menu_book,
      currentValue: wine.tastingNotes,
      aiValue: enriched['tasting_notes'],
      formatVal: (v) => v?.toString() ?? '',
    );

    // 5. Food pairings & Summary (always auto-bundle if available)
    if (enriched['ai_summary'] != null && !userOverrides.contains('ai_summary')) {
      _autoApplyPayload['ai_summary'] = enriched['ai_summary'];
    }
    if (enriched['food_pairings'] != null && !userOverrides.contains('ai_food_pairings')) {
      _autoApplyPayload['ai_food_pairings'] = enriched['food_pairings'];
    }
  }

  void _submit() {
    final finalPayload = Map<String, dynamic>.from(_autoApplyPayload);
    final updatedOverrides = List<String>.from(widget.currentWine.userOverrides);

    for (final diff in _diffs) {
      if (diff.useAi) {
        // User explicitly chose to overwrite their manual value with the AI proposal
        finalPayload[diff.key] = diff.aiRawValue;
        updatedOverrides.remove(diff.key);
      } else {
        // User retains manual entry: do not touch payload, keep override
        if (!updatedOverrides.contains(diff.key)) {
          updatedOverrides.add(diff.key);
        }
      }
    }

    finalPayload['is_verified_online'] = true;
    finalPayload['user_overrides'] = updatedOverrides;
    finalPayload['external_links'] = {'user_overrides': updatedOverrides};

    Navigator.pop(context);
    widget.onApply(finalPayload, updatedOverrides);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Différences Détectées',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Color(0xFF8B1E3F)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vous avez personnalisé certains champs manuellement. L\'analyse en ligne propose des données différentes. Choisissez champ par champ ce que vous souhaitez conserver ou adopter :',
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick Bulk Selection Bar
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.lock_outline, size: 16),
                    label: const Text('Tout conserver', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        for (final d in _diffs) {
                          d.useAi = false;
                        }
                      });
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFD4AF37)),
                    label: const Text('Tout accepter (IA)', style: TextStyle(fontSize: 12, color: Color(0xFFD4AF37))),
                    onPressed: () {
                      setState(() {
                        for (final d in _diffs) {
                          d.useAi = true;
                        }
                      });
                    },
                  ),
                ],
              ),
              const Divider(),

              // Diff Items List
              ..._diffs.map((diff) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: diff.useAi
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.08)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: diff.useAi
                          ? const Color(0xFFD4AF37)
                          : theme.dividerColor.withValues(alpha: 0.6),
                      width: diff.useAi ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(diff.icon, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              diff.label,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Switch(
                            value: diff.useAi,
                            activeThumbColor: const Color(0xFFD4AF37),
                            onChanged: (val) {
                              setState(() => diff.useAi = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Values comparison
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User value
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: !diff.useAi
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !diff.useAi ? Colors.green.shade600 : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 12, color: !diff.useAi ? Colors.green.shade800 : Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Votre valeur',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: !diff.useAi ? Colors.green.shade800 : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    diff.currentDisplay,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: !diff.useAi ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // AI value
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: diff.useAi
                                    ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: diff.useAi ? const Color(0xFFD4AF37) : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.auto_awesome, size: 12, color: diff.useAi ? const Color(0xFFD4AF37) : Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Suggestion IA',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: diff.useAi ? const Color(0xFFD4AF37) : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    diff.aiDisplay,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: diff.useAi ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF8B1E3F),
            foregroundColor: Colors.white,
          ),
          child: const Text('Appliquer la sélection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
