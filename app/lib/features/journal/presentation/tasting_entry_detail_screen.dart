import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/tasting_entry.dart';
import '../../cellar/domain/wine.dart';
import '../../cellar/domain/wine_image_service.dart';
import '../../cellar/domain/wine_service_advisor.dart';
import '../../cellar/presentation/terroir_map_view.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/widgets/wine_type_badge.dart';
import '../../../shared/widgets/gaussian_drinking_curve.dart';
import '../../../shared/widgets/grape_chart.dart';
import '../domain/tasting_pedagogy_engine.dart';
import 'tasting_pedagogy_sheet.dart';
import 'journal_screen.dart';
import '../data/tasting_deletion_service.dart';
import '../../offline/presentation/sync_provider.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../../config/router.dart';

class TastingEntryDetailScreen extends ConsumerStatefulWidget {
  final TastingEntry entry;

  const TastingEntryDetailScreen({super.key, required this.entry});

  @override
  ConsumerState<TastingEntryDetailScreen> createState() => _TastingEntryDetailScreenState();
}

class _TastingEntryDetailScreenState extends ConsumerState<TastingEntryDetailScreen> {
  Wine? _wine;

  /// Le lieu corrigé, tant que l'écran est ouvert. L'entrée reçue est immuable ; recharger
  /// tout le journal pour un champ texte serait disproportionné.
  String? _lieu;

  @override
  void initState() {
    super.initState();
    _loadFullWineData();
  }

  Future<void> _loadFullWineData() async {
    final wineId = widget.entry.wineId;
    if (wineId.isEmpty) {
      return;
    }

    try {
      final supabase = ref.read(supabaseProvider);
      final res = await supabase
          .from('wines')
          .select('*')
          .eq('id', wineId)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

      if (res != null && mounted) {
        setState(() {
          _wine = Wine.fromJson(res);
        });
        return;
      }
    } catch (_) {}

    // Fallback: construct Wine from entry metadata
    if (mounted) {
      setState(() {
        _wine = Wine(
          id: widget.entry.wineId,
          name: widget.entry.wineName ?? 'Vin dégusté',
          vintage: widget.entry.vintage,
          region: widget.entry.region ?? '',
          country: widget.entry.country ?? 'France',
          appellation: widget.entry.appellation,
          type: widget.entry.wineType ?? 'red',
        );
      });
    }
  }

  /// Demande confirmation, en disant ce que la suppression emporte avec elle.
  ///
  /// Une dégustation n'est pas qu'une ligne de journal : elle a nourri le profil de goût.
  /// Annoncer « supprimer ? » sans le dire laisserait croire à un geste anodin.
  /// Corrige le lieu d'une dégustation.
  ///
  /// La devinette vaut mieux qu'un champ vide — on ouvre rarement une bouteille sans être
  /// quelque part — mais elle se trompe : un point à moins de quatre-vingts mètres peut
  /// être une rue plutôt qu'une maison. Le rattrapage est ici.
  Future<void> _modifierLeLieu({required bool isFr}) async {
    final champ = TextEditingController(
        text: _lieu ?? widget.entry.locationName ?? '');
    final nouveau = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isFr ? 'Lieu de dégustation' : 'Tasting location'),
        content: TextField(
          controller: champ,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: isFr ? 'Chez Paul, Le Comptoir…' : 'At Paul\'s, Le Comptoir…',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isFr ? 'Annuler' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, champ.text.trim()),
            child: Text(isFr ? 'Enregistrer' : 'Save'),
          ),
        ],
      ),
    );
    if (nouveau == null || !mounted) return;

    setState(() => _lieu = nouveau);
    try {
      await ref.read(supabaseProvider).from('tasting_log').update({
        'location_name': nouveau.isEmpty ? null : nouveau,
        'occasion': nouveau.isEmpty ? null : nouveau,
      }).eq('id', widget.entry.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isFr
            ? 'Le lieu n\'a pas pu être enregistré. Réessayez une fois connecté.'
            : 'The location could not be saved. Try again once online.'),
      ));
      return;
    }

    // Le cache local, sinon le journal réafficherait l'ancien lieu à la prochaine ouverture.
    final offline = ref.read(offlineStorageServiceProvider);
    final cache = offline.getCachedTastings();
    for (final t in cache) {
      if (t['id']?.toString() == widget.entry.id) {
        t['location_name'] = nouveau.isEmpty ? null : nouveau;
        t['occasion'] = nouveau.isEmpty ? null : nouveau;
      }
    }
    await offline.saveCachedTastings(cache);
    ref.invalidate(tastingLogProvider);
  }

  Future<void> _confirmerSuppression({required bool isFr}) async {
    final nom = widget.entry.wineName ?? (isFr ? 'ce vin' : 'this wine');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isFr ? 'Supprimer cette dégustation ?' : 'Delete this tasting?'),
        content: Text(isFr
            ? '$nom disparaîtra de votre journal, et ce qu\'il a appris à votre profil de '
                'goût sera défait autant que possible.'
            : '$nom will disappear from your journal, and what it taught your taste profile '
                'will be undone as far as possible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isFr ? 'Annuler' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isFr ? 'Supprimer' : 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final resultat =
        await ref.read(tastingDeletionServiceProvider).supprimer(widget.entry.id);
    ref.invalidate(tastingLogProvider);
    ref.invalidate(tasteProfilesListProvider);
    if (!mounted) return;

    final reste = TastingDeletionService.phraseDesRestes(resultat.restes);
    Navigator.of(context).pop();
    final messenger = rootNavigatorKey.currentContext;
    if (messenger != null && messenger.mounted) {
      ScaffoldMessenger.of(messenger).showSnackBar(SnackBar(
        content: Text(
          reste == null
              ? (isFr ? 'Dégustation supprimée.' : 'Tasting deleted.')
              : (isFr ? 'Dégustation supprimée. $reste' : 'Tasting deleted. $reste'),
        ),
        duration: reste == null ? const Duration(seconds: 3) : const Duration(seconds: 6),
      ));
    }
  }

  String _formatRatingScore(double? rating) {
    if (rating == null) return '-';
    // If rating was previously stored on a /5 scale (e.g. 4.5), normalize to /10
    final val = (rating <= 5.0 && rating > 0) ? rating * 2 : rating;
    return val % 1 == 0 ? '${val.toInt()} / 10' : '${val.toStringAsFixed(1)} / 10';
  }

  String _getSommelierVerdict(double? rating, {bool isFr = true}) {
    if (rating == null) return isFr ? 'Dégusté' : 'Tasted';
    final val = (rating <= 5.0 && rating > 0) ? rating * 2 : rating;
    if (val >= 9.5) return isFr ? 'Exceptionnel 🏆' : 'Exceptional 🏆';
    if (val >= 8.5) return isFr ? 'Remarquable ✨' : 'Remarkable ✨';
    if (val >= 7.5) return isFr ? 'Très bon vin 🍷' : 'Very good wine 🍷';
    if (val >= 6.0) return isFr ? 'Agréable 👍' : 'Pleasant 👍';
    return isFr ? 'Passable / Correct' : 'Fair / Decent';
  }

  void _shareTasting({bool isFr = true}) {
    final entry = widget.entry;
    final wineTitle = '${entry.wineName ?? (isFr ? "Vin" : "Wine")}${entry.vintage != null ? " ${entry.vintage}" : ""}';
    final ratingStr = _formatRatingScore(entry.rating);
    final buffer = StringBuffer();
    buffer.writeln(isFr ? '🍷 Souvenir de Dégustation : $wineTitle' : '🍷 Tasting Memory: $wineTitle');
    buffer.writeln(isFr ? '⭐ Note : $ratingStr (${_getSommelierVerdict(entry.rating, isFr: isFr)})' : '⭐ Rating: $ratingStr (${_getSommelierVerdict(entry.rating, isFr: isFr)})');
    if (entry.locationName != null && entry.locationName!.isNotEmpty) {
      buffer.writeln(isFr ? '📍 Lieu : ${entry.locationName}' : '📍 Location: ${entry.locationName}');
    }
    if (entry.coTasters.isNotEmpty) {
      buffer.writeln(isFr ? '👥 Partagé avec : ${entry.coTasters.join(", ")}' : '👥 Shared with: ${entry.coTasters.join(", ")}');
    }
    if (entry.foodPaired != null && entry.foodPaired!.isNotEmpty) {
      buffer.writeln(isFr ? '🍽️ Accord : ${entry.foodPaired}' : '🍽️ Pairing: ${entry.foodPaired}');
    }
    if (entry.tastingNotes != null && entry.tastingNotes!.isNotEmpty) {
      buffer.writeln(isFr ? '📝 Notes : ${entry.tastingNotes}' : '📝 Notes: ${entry.tastingNotes}');
    }
    buffer.writeln(isFr ? '\nPartagé depuis Chatmelier 🍇' : '\nShared from Chatmelier 🍇');

    Share.share(buffer.toString(), subject: isFr ? 'Dégustation : $wineTitle' : 'Tasting: $wineTitle');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final entry = widget.entry;
    final wine = _wine;

    final wineName = entry.wineName ?? wine?.name ?? (isFr ? 'Vin dégusté' : 'Tasted wine');
    final vintageStr = (entry.vintage != null && entry.vintage! > 0)
        ? '${entry.vintage}'
        : (isFr ? 'Non Millésimé (NM)' : 'Non-Vintage (NV)');
    final wineType = entry.wineType ?? wine?.type ?? 'red';
    final ratingStr = _formatRatingScore(entry.rating);
    final verdict = _getSommelierVerdict(entry.rating, isFr: isFr);
    final dateFormatted = DateFormat(
      isFr ? 'EEEE d MMMM yyyy à HH:mm' : 'EEEE, MMMM d, yyyy at h:mm a',
      isFr ? 'fr_FR' : 'en_US',
    ).format(entry.consumedAt);

    // Resolve wine / bottle image
    final resolvedImage = entry.photoUrl != null && entry.photoUrl!.isNotEmpty
        ? entry.photoUrl
        : (wine != null ? WineImageService.resolveWineImageUrl(wine) : null);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Sliver App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.wine_bar_outlined),
                tooltip: isFr ? 'Aller à Ma Cave' : 'Go to My Cellar',
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/');
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: isFr ? 'Partager cette dégustation' : 'Share this tasting',
                onPressed: () => _shareTasting(isFr: isFr),
              ),
              // La suppression vit dans le menu et non en clair : elle doit être atteignable
              // sans être à portée de pouce distrait.
              PopupMenuButton<String>(
                tooltip: isFr ? 'Plus d\'options' : 'More options',
                onSelected: (v) {
                  if (v == 'supprimer') _confirmerSuppression(isFr: isFr);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'supprimer',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 20),
                        const SizedBox(width: 12),
                        Text(isFr ? 'Supprimer' : 'Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (resolvedImage != null && WineImageService.isValidImagePath(resolvedImage))
                    Image.network(
                      resolvedImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderHeader(theme, wineType),
                    )
                  else
                    _buildPlaceholderHeader(theme, wineType),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),

                  // Header Information overlay
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            WineTypeBadge(type: wineType),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                vintageStr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          wineName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        if (wine?.producer != null && wine!.producer!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            wine.producer!,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Content Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION 1: FICHE DE DÉGUSTATION (SOUVENIR & CONTEXTE)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF2E1C24), const Color(0xFF1E1A1B)]
                            : [const Color(0xFFFDF4F6), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF8B1E3F).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.wine_bar, color: Color(0xFF8B1E3F), size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isFr ? 'FICHE DE DÉGUSTATION' : 'TASTING SHEET',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.1,
                                      color: Color(0xFF8B1E3F),
                                    ),
                                  ),
                                  Text(
                                    dateFormatted,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white60 : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Golden Rating Badge on 10
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 18, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    ratingStr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        // Sommelier Verdict
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(isFr ? 'Appréciation : ' : 'Rating: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(
                                verdict,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // Lieu de dégustation (Où)
                        //
                        // Modifiable, et affiché même vide. Il était deviné depuis la
                        // position — un lieu à moins de 80 m — et parfois à côté : « Joubert
                        // Street » pour un dîner chez des amis. Deviner est utile ; ne pas
                        // pouvoir corriger ne l'est pas.
                        _buildContextRow(
                          icon: Icons.place,
                          iconColor: Colors.blue,
                          label: isFr ? 'Lieu de dégustation' : 'Tasting location',
                          value: (_lieu ?? entry.locationName ?? '').isEmpty
                              ? (isFr ? 'Non renseigné' : 'Not set')
                              : (_lieu ?? entry.locationName!),
                          onEdit: () => _modifierLeLieu(isFr: isFr),
                        ),
                        const SizedBox(height: 12),

                        // Invités / Co-dégustateurs (Avec qui)
                        if (entry.coTasters.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.people_alt, size: 18, color: Color(0xFF8B1E3F)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isFr ? 'Partagé avec :' : 'Shared with:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: entry.coTasters.map((c) => Chip(
                                        avatar: const Text('🥂', style: TextStyle(fontSize: 12)),
                                        label: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: const Color(0xFF8B1E3F).withValues(alpha: 0.1),
                                      )).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Accord Mets & Vins
                        if (entry.foodPaired != null && entry.foodPaired!.isNotEmpty) ...[
                          _buildContextRow(
                            icon: Icons.restaurant,
                            iconColor: const Color(0xFF10B981),
                            label: isFr ? 'Accord mets & vin dégusté' : 'Food & wine pairing tasted',
                            value: entry.foodPaired!,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Notes de dégustation & Arômes
                        if (entry.tastingNotes != null && entry.tastingNotes!.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.format_quote, size: 20, color: Color(0xFFD4AF37)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isFr ? 'Impressions & Arômes :' : 'Impressions & Aromas:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.tastingNotes!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                        fontStyle: FontStyle.italic,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF722F37),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Text('🎓', style: TextStyle(fontSize: 18)),
                            label: Text(
                              isFr ? 'Débriefing Oenologique & Secrets Moléculaires' : 'Oenological Debrief & Molecular Insights',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () {
                              final wineObj = _wine ?? Wine(
                                id: entry.wineId,
                                name: entry.wineName ?? 'Vin',
                                vintage: entry.vintage,
                                region: entry.region ?? '',
                                country: entry.country ?? 'France',
                                appellation: entry.appellation,
                                type: entry.wineType ?? 'red',
                              );
                              final report = TastingPedagogyEngine.analyze(
                                wine: wineObj,
                                userRating: entry.rating ?? 8.0,
                                userComment: entry.tastingNotes,
                              );
                              TastingPedagogySheet.show(context, report: report);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SECTION 2: CARTE DU VIN (COMME DANS LA CAVE)
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF8B1E3F), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isFr ? 'Carte & Fiche du Vin' : 'Wine Identity & Details',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Terroir, Appellation, Pays Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (entry.appellation != null && entry.appellation!.isNotEmpty)
                            _buildInfoRow('Appellation', entry.appellation!),
                          if (entry.region != null && entry.region!.isNotEmpty)
                            _buildInfoRow(isFr ? 'Région' : 'Region', entry.region!),
                          if (entry.country != null && entry.country!.isNotEmpty)
                            _buildInfoRow(isFr ? 'Pays' : 'Country', entry.country!),
                          if (wine?.alcoholPct != null)
                            _buildInfoRow(isFr ? 'Alcool' : 'Alcohol', '${wine!.alcoholPct!.toStringAsFixed(1)}% vol'),
                          if (wine?.classification != null && wine!.classification!.isNotEmpty)
                            _buildInfoRow('Classification', wine.classification!),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Courbe d'Apogée & Maturité (si wine disponible)
                  if (wine != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.show_chart, color: Color(0xFF8B1E3F), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isFr ? 'Apogée & Maturité Sommelier' : 'Drinking Peak & Maturity',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GaussianDrinkingCurve(wine: wine),
                    const SizedBox(height: 16),

                    // Cépages (si disponibles)
                    if (wine.grapes.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.pie_chart_outline, color: Color(0xFF8B1E3F), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isFr ? 'Cépages & Assemblage' : 'Grape Varieties & Blend',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GrapeChart(grapes: wine.grapes),
                      const SizedBox(height: 16),
                    ],

                    // Conseils de service Sommelier
                    _buildSommelierServiceCard(wine, theme, isDark),
                    const SizedBox(height: 16),

                    // Scores & Critiques (si existants)
                    if (wine.criticScores.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.military_tech_outlined, color: Color(0xFFD4AF37), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isFr ? 'Notes des Critiques & Guides' : 'Critics Scores & Guides',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...wine.criticScores.map((score) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const Icon(Icons.star, color: Color(0xFFD4AF37)),
                          title: Text(score.source, style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              score.score,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                            ),
                          ),
                          subtitle: score.notes != null ? Text(score.notes!) : null,
                        ),
                      )),
                      const SizedBox(height: 16),
                    ],

                    // Carte Géographique du Terroir
                    if (wine.region.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.map_outlined, color: Color(0xFF8B1E3F), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isFr ? 'Terroir & Géographie' : 'Terroir & Geography',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TerroirMapView(
                        country: wine.country.isNotEmpty ? wine.country : 'France',
                        region: wine.region,
                        subRegion: wine.subRegion,
                        appellation: wine.appellation,
                        isSpirit: wine.isSpirit,
                        wineType: wine.type,
                        wineName: wine.name,
                        producer: wine.producer,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Décryptage Moléculaire & Science Œnologique
                    _buildMolecularScienceCard(wine, entry, theme, isDark, isFr),
                    const SizedBox(height: 20),

                    // Bouton de redirection vers Ma Cave
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/');
                        },
                        icon: const Icon(Icons.wine_bar, color: Colors.white),
                        label: Text(
                          isFr ? 'Voir mon stock dans Ma Cave 🍾' : 'View my stock in My Cellar 🍾',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1E3F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMolecularScienceCard(Wine wine, TastingEntry entry, ThemeData theme, bool isDark, bool isFr) {
    final wineType = (entry.wineType ?? wine.type).toLowerCase();
    final isRed = wineType.contains('red') || wineType.contains('rouge');
    final isSparkling = wineType.contains('sparkling') || wineType.contains('bulles') || wineType.contains('champagne');
    final region = wine.region.toLowerCase();
    final allGrapes = wine.grapes.map((g) => g.name.toLowerCase()).join(' ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E242C) : const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.science_outlined, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFr ? 'DÉCRYPTAGE MOLÉCULAIRE & SCIENCE' : 'MOLECULAR INSIGHTS & SCIENCE',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    Text(
                      isFr ? 'Biochimie & composés aromatiques du vin' : 'Wine biochemistry & aroma compounds',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Phénols & Couleur
          _buildMoleculeTopic(
            emoji: '🍇',
            title: isFr
                ? (isRed ? 'Anthocyanes & Tannins Polymérisés' : (isSparkling ? 'Mannoprotéines & Autolyse' : 'Acides Hydroxycinnamiques'))
                : (isRed ? 'Anthocyanins & Polymerized Tannins' : (isSparkling ? 'Mannoproteins & Autolysis' : 'Hydroxycinnamic Acids')),
            description: isFr
                ? (isRed
                    ? 'Malvidine-3-glucoside et tannins condensés (proanthocyanidines). Au fil des ans, les tannins se polymérisent, adoucissant l\'astringence en précipitant moins les protéines salivaires (proline).'
                    : (isSparkling
                        ? 'L\'élevage sur lies libère des mannoprotéines par autolyse des levures (Saccharomyces cerevisiae), stabilisant la texture crémeuse et la finesse de l\'effervescence.'
                        : 'Acide caftarique et flavonoïdes offrant la brillance jaune doré et agissant comme antioxydants naturels.'))
                : (isRed
                    ? 'Malvidin-3-glucoside and condensed tannins (proanthocyanidins). Over time, tannins polymerize, softening astringency by binding fewer salivary proteins (proline).'
                    : (isSparkling
                        ? 'Aging on lees releases mannoproteins through yeast autolysis (Saccharomyces cerevisiae), stabilizing creamy texture and bubble finesse.'
                        : 'Caftaric acid and flavonoids providing golden brilliance and acting as natural antioxidants.')),
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // 2. Molécules Aromatiques Clés
          _buildMoleculeTopic(
            emoji: '🧪',
            title: isFr ? 'Profil des Molécules Aromatiques' : 'Aromatic Molecules Profile',
            description: _getAromaticMoleculesSummary(allGrapes, region, isRed, isSparkling, isFr: isFr),
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // 3. Équilibre Acido-Basique
          _buildMoleculeTopic(
            emoji: '⚖️',
            title: isFr ? 'Équilibre Acide & Salinité Minérale' : 'Acid Balance & Mineral Salinity',
            description: isFr
                ? 'Acide tartrique (C₄H₆O₆) garantissant la vivacité et la longévité, complété par l\'acide malique ou lactique (C₃H₆O₃) adoucissant le volume en bouche.'
                : 'Tartaric acid (C₄H₆O₆) ensuring freshness and longevity, balanced by malic or lactic acid (C₃H₆O₃) softening roundness on the palate.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  String _getAromaticMoleculesSummary(String grapes, String region, bool isRed, bool isSparkling, {bool isFr = true}) {
    final list = <String>[];
    if (grapes.contains('sauvignon') || grapes.contains('cabernet') || grapes.contains('merlot')) {
      list.add('• Pyrazines (2-isobutyl-3-méthoxypyrazine) : notes végétales nobles, cassis frais.');
    }
    if (grapes.contains('syrah') || region.contains('rhône') || region.contains('rhone')) {
      list.add('• Rotundone (sesquiterpènes) : signature poivre noir et épices intenses.');
    }
    if (grapes.contains('chardonnay') || isSparkling) {
      list.add('• Diacétyle (2,3-butanedione) & acétates : arômes de beurre frais, brioche et noisette.');
    }
    if (grapes.contains('viognier') || grapes.contains('muscat') || grapes.contains('gewurz') || grapes.contains('riesling')) {
      list.add('• Monoterpènes (Linalol, Géraniol) : effluves florales de fleur d\'oranger et de rose.');
    }
    list.add('• Esters éthyliques & acétates d\'isoamyle : arômes fermentaires de fruits rouges et pulpeux.');
    list.add('• Lactones de chêne (si élevage bois) : vanilline et notes toastées subtiles.');
    return list.join('\n');
  }

  Widget _buildMoleculeTopic({
    required String emoji,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151921) : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderHeader(ThemeData theme, String wineType) {
    return Container(
      color: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
      child: Center(
        child: Icon(
          Icons.wine_bar,
          size: 80,
          color: const Color(0xFF8B1E3F).withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildContextRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Modifier',
            onPressed: onEdit,
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSommelierServiceCard(Wine wine, ThemeData theme, bool isDark) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final advice = WineServiceAdvisor.computeAdvice(
      wineType: wine.type,
      vintage: wine.vintage,
      region: wine.region,
      appellation: wine.appellation,
      producer: wine.producer,
      wineName: wine.name,
      isFr: isFr,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222232) : Colors.amber.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.room_service_outlined, color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 8),
              Text(
                isFr ? 'Conseils de Service du Sommelier' : 'Sommelier Service Advice',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildServiceItem(
                Icons.thermostat,
                isFr ? 'Température' : 'Temperature',
                '${advice.minTemp} - ${advice.maxTemp}°C',
              ),
              _buildServiceItem(
                Icons.air,
                isFr ? 'Carafage' : 'Decanting',
                advice.carafeMinutes > 0 ? '${advice.carafeMinutes} min' : (isFr ? 'Non requis' : 'Not required'),
              ),
              _buildServiceItem(
                Icons.wine_bar,
                isFr ? 'Verre' : 'Glassware',
                advice.glasswareType.split(' ').first,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFD4AF37)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
