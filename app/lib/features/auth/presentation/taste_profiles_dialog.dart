import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/taste_profile_service.dart';
import '../domain/taste_profile.dart';
import 'taste_profile_radar_screen.dart';

class TasteProfilesDialog extends ConsumerStatefulWidget {
  const TasteProfilesDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const TasteProfilesDialog(),
    );
  }

  @override
  ConsumerState<TasteProfilesDialog> createState() => _TasteProfilesDialogState();
}

class _TasteProfilesDialogState extends ConsumerState<TasteProfilesDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profilesAsync = ref.watch(tasteProfilesListProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1622) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_alt_outlined, color: Color(0xFF8B1E3F), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profils de Goût & Co-Dégustateurs',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Le Chatmelier personnalise ses conseils pour vous et vos proches (ex: Caro)',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Spider Chart CTA Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F).withAlpha(20),
                foregroundColor: const Color(0xFF8B1E3F),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.radar, color: Color(0xFF8B1E3F), size: 20),
              label: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spider Chart des Goûts (Radar 3 Modes)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
              onPressed: () {
                TasteProfileRadarScreen.show(context);
              },
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Expanded(
            child: profilesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erreur: $err')),
              data: (profiles) {
                return ListView.builder(
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: profile.isPrimary
                              ? const Color(0xFF8B1E3F).withValues(alpha: 0.5)
                              : theme.dividerColor.withValues(alpha: 0.2),
                          width: profile.isPrimary ? 1.5 : 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: profile.isPrimary
                                      ? const Color(0xFF8B1E3F)
                                      : const Color(0xFFD4AF37),
                                  radius: 18,
                                  child: Text(
                                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            profile.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          if (profile.isPrimary) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Principal',
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8B1E3F)),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (profile.notes.isNotEmpty)
                                        Text(
                                          profile.notes,
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _showEditProfileSheet(profile),
                                ),
                                if (!profile.isPrimary)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    onPressed: () async {
                                      final service = ref.read(tasteProfileServiceProvider);
                                      await service.deleteProfile(profile.id);
                                      ref.invalidate(tasteProfilesListProvider);
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (profile.favoriteTypes.isNotEmpty || profile.favoriteRegions.isNotEmpty) ...[
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  ...profile.favoriteTypes.map((t) => _buildTag(t, const Color(0xFF8B1E3F))),
                                  ...profile.favoriteRegions.map((r) => _buildTag(r, const Color(0xFFD4AF37))),
                                  ...profile.favoriteGrapes.map((g) => _buildTag(g, const Color(0xFF2E7D32))),
                                ],
                              ),
                            ],
                            if (profile.dislikedCharacteristics.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.thumb_down_alt_outlined, size: 14, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Évite : ${profile.dislikedCharacteristics.join(", ")}',
                                      style: const TextStyle(fontSize: 11.5, color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => TasteProfileRadarScreen.show(context, initialProfileId: profile.id),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.radar, size: 15, color: Color(0xFF8B1E3F)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Voir le Spider Chart de ce profil',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF8B1E3F)),
                                    ),
                                    Spacer(),
                                    Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF8B1E3F)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Ajouter un profil (ex: Caro, Invité)', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _showEditProfileSheet(null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Future<void> _showEditProfileSheet(TasteProfile? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final typesCtrl = TextEditingController(text: existing?.favoriteTypes.join(', ') ?? '');
    final regionsCtrl = TextEditingController(text: existing?.favoriteRegions.join(', ') ?? '');
    final grapesCtrl = TextEditingController(text: existing?.favoriteGrapes.join(', ') ?? '');
    final dislikesCtrl = TextEditingController(text: existing?.dislikedCharacteristics.join(', ') ?? '');

    try {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(existing == null ? 'Nouveau profil' : 'Modifier ${existing.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Prénom / Nom *', hintText: 'ex: Caro'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: typesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Types & Couleurs préférés (séparés par virgule)',
                    hintText: 'ex: Blanc sec, Rosé de Provence, Champagne',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: regionsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Régions & Terroirs aimés',
                    hintText: 'ex: Bourgogne, Rhône, Loire, Provence',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: grapesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cépages favoris',
                    hintText: 'ex: Pinot Noir, Chardonnay, Syrah',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dislikesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ce qu\'il / elle n\'aime pas',
                    hintText: 'ex: Trop tannique, Boisé excessif',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes & style général',
                    hintText: 'ex: Aime les vins frais et fruités pour l\'apéritif...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                List<String> parseList(String text) =>
                    text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

                final service = ref.read(tasteProfileServiceProvider);
                if (existing != null) {
                  await service.updateProfile(
                    existing.copyWith(
                      name: name,
                      favoriteTypes: parseList(typesCtrl.text),
                      favoriteRegions: parseList(regionsCtrl.text),
                      favoriteGrapes: parseList(grapesCtrl.text),
                      dislikedCharacteristics: parseList(dislikesCtrl.text),
                      notes: notesCtrl.text.trim(),
                    ),
                  );
                } else {
                  await service.addProfile(
                    name: name,
                    favoriteTypes: parseList(typesCtrl.text),
                    favoriteRegions: parseList(regionsCtrl.text),
                    favoriteGrapes: parseList(grapesCtrl.text),
                    dislikedCharacteristics: parseList(dislikesCtrl.text),
                    notes: notesCtrl.text.trim(),
                  );
                }

                ref.invalidate(tasteProfilesListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      );
    } finally {
      nameCtrl.dispose();
      notesCtrl.dispose();
      typesCtrl.dispose();
      regionsCtrl.dispose();
      grapesCtrl.dispose();
      dislikesCtrl.dispose();
    }
  }
}
