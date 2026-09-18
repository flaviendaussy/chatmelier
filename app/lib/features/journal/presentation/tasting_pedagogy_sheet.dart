import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/tasting_pedagogy_engine.dart';

class TastingPedagogySheet extends StatelessWidget {
  final TastingPedagogyReport report;

  const TastingPedagogySheet({super.key, required this.report});

  static Future<void> show(BuildContext context, {required TastingPedagogyReport report}) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TastingPedagogySheet(report: report),
    );
  }

  void _askSommelierQuestion(BuildContext context) {
    final wine = report.wine;
    final wineName = '${wine.producer} ${wine.name} ${wine.vintage ?? ""}';
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final prompt = isFr
        ? "Chatmelier, j'ai dégusté mon flacon de $wineName (${wine.region}, ${wine.grapes.map((g) => g.name).join(', ')}). Peux-tu m'expliquer en détail les secrets de vinification du domaine, le type de barrique utilisé, et pourquoi ces molécules aromatiques s'expriment ainsi ?"
        : "Chatmelier, I tasted my bottle of $wineName (${wine.region}, ${wine.grapes.map((g) => g.name).join(', ')}). Can you explain in detail the winemaking secrets of the domaine, the type of oak barrel used, and why these aromatic molecules express themselves this way?";

    Navigator.pop(context);
    context.go('/chat', extra: prompt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final wine = report.wine;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18151D) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 25,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🎓', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.tastingDebriefTitle ?? 'Débriefing Oenologique & Moléculaire',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            '${wine.producer} • ${wine.name} ${wine.vintage ?? ""}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Acuity Score & Praise Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: theme.brightness == Brightness.dark
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFF722F37).withValues(alpha: 0.25),
                                  const Color(0xFFD4AF37).withValues(alpha: 0.15),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  const Color(0xFF722F37).withValues(alpha: 0.1),
                                  const Color(0xFFD4AF37).withValues(alpha: 0.15),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.psychology, color: Color(0xFFD4AF37), size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n?.tastingSensoryAcuity ?? 'ACUITÉ SENSORIELLE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF8B1E3F),
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  l10n?.tastingPrecision(report.acuityScore) ?? '${report.acuityScore}% Précision',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            report.sommelierPraise,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SECTION 1: FLAVOR ORIGINS & WINE SECRETS (User explicit request)
                    if (report.flavorOrigins.isNotEmpty) ...[
                      _buildSectionHeader(
                        theme,
                        l10n?.tastingFlavorOriginsTitle ?? 'ORIGINE DES GOÛTS & SECRETS DU FLACON',
                        '🍇',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n?.tastingFlavorOriginsSubtitle ??
                            "Découvrez d'où viennent les arômes, la robe et la structure de votre vin",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...report.flavorOrigins.map((origin) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF231F2C) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(origin.icon, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      origin.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF722F37).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF722F37).withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      origin.category.name.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFD4AF37),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (origin.badgeText != null && origin.badgeText!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    origin.badgeText!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFD4AF37),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                origin.sensoryContribution,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                origin.detailedWhy,
                                style: theme.textTheme.bodySmall?.copyWith(height: 1.4, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                    ],

                    // SECTION 2: COMPARATIVE SENSORY ANALYSIS
                    _buildSectionHeader(
                      theme,
                      l10n?.tastingConcordanceTitle ?? 'CONCORDANCE & SIGNATURE DU CRU',
                      '🎯',
                    ),
                    const SizedBox(height: 12),

                    // User Inputs vs Archetype Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF221E29) : const Color(0xFFF9F7F4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // La confrontation, faite pour la personne plutôt que laissée
                          // à son œil : deux listes côte à côte demandaient de croiser de
                          // tête des pastilles dans deux vocabulaires. C'est le travail
                          // que la machine sait faire, et il était demandé.
                          if (report.comparaisonAromes.isNotEmpty) ...[
                            _blocAromes(
                              theme, isDark,
                              titre: 'BIEN VU',
                              couleur: const Color(0xFF2E7D32),
                              aromes: report.comparaisonAromes
                                  .where((a) => a.verdict == VerdictArome.bienVu)
                                  .toList(),
                            ),
                            _blocAromes(
                              theme, isDark,
                              titre: 'À CÔTÉ',
                              couleur: const Color(0xFFB3261E),
                              aromes: report.comparaisonAromes
                                  .where((a) => a.verdict == VerdictArome.aCote)
                                  .toList(),
                            ),
                            _blocAromes(
                              theme, isDark,
                              titre: 'À CHERCHER LA PROCHAINE FOIS',
                              couleur: const Color(0xFFE08B00),
                              aromes: report.comparaisonAromes
                                  .where((a) => a.verdict == VerdictArome.manque)
                                  .toList(),
                            ),
                            // Ni juste ni faux : un nez n'est pas un QCM, et sanctionner
                            // le plausible apprendrait à se taire plutôt qu'à sentir.
                            _blocAromes(
                              theme, isDark,
                              titre: 'VOTRE PART',
                              couleur: isDark ? Colors.white54 : Colors.black45,
                              aromes: report.comparaisonAromes
                                  .where((a) => a.verdict == VerdictArome.plausible)
                                  .toList(),
                            ),
                          ] else ...[
                            Text(
                              l10n?.tastingFreeTastingRecorded ?? 'Dégustation libre enregistrée.',
                              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                            ),
                          ],

                          if (report.userAppearance != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n?.tastingAppearanceLabel(report.userAppearance!) ??
                                  '• Robe : ${report.userAppearance}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                          if (report.userStructure != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n?.tastingStructureLabel(report.userStructure!, report.userCaudalies) ??
                                  '• Structure : ${report.userStructure} (${report.userCaudalies} caudalies)',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            report.archetypePalate,
                            style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Hidden Nuances To Spot Next Time
                    if (report.hiddenNuancesToDiscover.isNotEmpty) ...[
                      Text(
                        l10n?.tastingHiddenNuancesTitle ??
                            'SUBTILITÉS & NUANCES À CHERCHER AU PROCHAIN VERRE :',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white60 : Colors.black54,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...report.hiddenNuancesToDiscover.map((nuance) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF262130) : const Color(0xFFF4F0E8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          nuance.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF722F37).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            nuance.origin,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFD4AF37),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      nuance.explanation,
                                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 24),

                    // SECTION 3: ENOLOGICAL PROCESS & MOLECULAR SCIENCE
                    _buildSectionHeader(
                      theme,
                      l10n?.tastingPillarsTitle ?? 'SCIENCE OENOLOGIQUE & MOLÉCULES',
                      '🔬',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n?.tastingPillarsSubtitle ??
                          'Pourquoi ce vin possède-t-il cette structure, ces arômes et cette couleur ?',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Scientific Pillars
                    ...report.scientificPillars.map((pillar) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF221E2A) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(pillar.icon, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    pillar.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF722F37).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n?.tastingKeyMolecules(pillar.chemicalKey) ??
                                    'Molécules clés : ${pillar.chemicalKey}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD4AF37),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pillar.summary,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pillar.detailedExplanation,
                              style: theme.textTheme.bodySmall?.copyWith(height: 1.4, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // CTA to chat with sommelier
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF722F37),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: Text(
                          l10n?.tastingChatWithSommelier ?? 'Approfondir la vinification avec Chatmelier',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () => _askSommelierQuestion(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Une colonne de la confrontation : son titre, sa couleur, ses arômes.
  ///
  /// Rien ne s'affiche quand la colonne est vide — une rubrique « À côté » sans contenu
  /// installerait un reproche qui n'a pas lieu d'être.
  Widget _blocAromes(
    ThemeData theme,
    bool isDark, {
    required String titre,
    required Color couleur,
    required List<AromeCompare> aromes,
  }) {
    if (aromes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: couleur,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final a in aromes)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: couleur.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    a.libelle,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}
