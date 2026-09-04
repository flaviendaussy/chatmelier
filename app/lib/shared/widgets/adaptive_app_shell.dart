import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../features/cellar/presentation/cellar_switcher_sheet.dart';
import '../../features/journal/presentation/external_tasting_dialog.dart';
import '../../features/voice/presentation/voice_dictation_sheet.dart';
import '../providers/cellar_provider.dart';
import '../providers/supabase_provider.dart';
import '../utils/responsive_layout.dart';

class AdaptiveAppShell extends ConsumerWidget {
  final Widget child;

  const AdaptiveAppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/chat')) {
      return 1;
    }
    if (location.startsWith('/journal') ||
        location.startsWith('/history') ||
        location.startsWith('/historique')) {
      return 2;
    }
    if (location.startsWith('/stats')) {
      return 3;
    }
    if (location.startsWith('/profile')) {
      return 4;
    }
    return 0;
  }

  void _onNavigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/chat');
        break;
      case 2:
        context.go('/history');
        break;
      case 3:
        context.go('/stats');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formFactor = Responsive.formFactor(context);

    if (formFactor == FormFactor.desktop) {
      return _DesktopAppShell(
        currentIndex: _currentIndex(context),
        onNavigate: (i) => _onNavigate(context, i),
        child: child,
      );
    }

    if (formFactor == FormFactor.tablet) {
      return _TabletAppShell(
        currentIndex: _currentIndex(context),
        onNavigate: (i) => _onNavigate(context, i),
        child: child,
      );
    }

    return _MobileAppShell(
      currentIndex: _currentIndex(context),
      onNavigate: (i) => _onNavigate(context, i),
      child: child,
    );
  }
}

/// 📱 Mobile Layout: Bottom Navigation Bar + FAB
class _MobileAppShell extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final Widget child;

  const _MobileAppShell({
    required this.currentIndex,
    required this.onNavigate,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final tabs = [
      (
        icon: Icons.wine_bar_outlined,
        activeIcon: Icons.wine_bar,
        label: l10n?.navCellar ?? 'Ma Cave'
      ),
      (
        icon: Icons.auto_awesome_outlined,
        activeIcon: Icons.auto_awesome,
        label: l10n?.navChat ?? 'Chatmelier'
      ),
      (
        icon: Icons.history_outlined,
        activeIcon: Icons.history,
        label: l10n?.navJournal ?? 'Historique'
      ),
      (
        icon: Icons.insights_outlined,
        activeIcon: Icons.insights,
        label: l10n?.navStats ?? 'Statistiques'
      ),
      (
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profil'
      ),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onNavigate,
        destinations: tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showCellarActionMenu(context),
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  void _showCellarActionMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.actionMenuTitle ?? 'Actions Cave',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            _ActionMenuItem(
              icon: Icons.add_a_photo_outlined,
              color: const Color(0xFF8B1E3F),
              title: l10n?.actionAddBottle ?? 'Ajouter une bouteille',
              subtitle: l10n?.actionAddBottleSub ??
                  'Scanner une étiquette ou saisie manuelle',
              onTap: () {
                Navigator.pop(ctx);
                context.push('/scan');
              },
            ),
            const SizedBox(height: 8),
            _ActionMenuItem(
              icon: Icons.restaurant_menu_rounded,
              color: const Color(0xFFC2185B),
              title: 'Scanner la Carte des Vins (Restaurant)',
              subtitle: 'Capture multi-pages, radar sensoriel, filtres & comparateur',
              onTap: () {
                Navigator.pop(ctx);
                context.push('/scan/menu');
              },
            ),
            const SizedBox(height: 8),
            _ActionMenuItem(
              icon: Icons.mic_outlined,
              color: Colors.purple.shade700,
              title: 'Ajout Rapide à la Voix (Sommelier)',
              subtitle: 'Dictez vos bouteilles naturellement à l\'IA',
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const VoiceDictationSheet(),
                );
              },
            ),
            const SizedBox(height: 8),
            _ActionMenuItem(
              icon: Icons.wine_bar_outlined,
              color: const Color(0xFFD4AF37),
              title: l10n?.actionCheckoutBottle ??
                  'Déguster / Sortir une bouteille',
              subtitle: l10n?.actionCheckoutBottleSub ??
                  'Enregistrer une dégustation et sortir du stock',
              onTap: () {
                Navigator.pop(ctx);
                context.push('/checkout');
              },
            ),
            const SizedBox(height: 8),
            _ActionMenuItem(
              icon: Icons.restaurant_outlined,
              color: const Color(0xFFE65100),
              title: 'Déguster Hors-Cave (Restaurant, Amis)',
              subtitle: 'Noter un vin bu à l\'extérieur sans toucher au stock',
              onTap: () {
                Navigator.pop(ctx);
                ExternalTastingDialog.show(context);
              },
            ),
            const SizedBox(height: 8),
            _ActionMenuItem(
              icon: Icons.auto_awesome_outlined,
              color: const Color(0xFF2E7D32),
              title: l10n?.actionLookupWine ?? 'Consulter / Identifier un vin',
              subtitle: l10n?.actionLookupWineSub ??
                  'Découverte et analyse instantanée par l\'IA',
              onTap: () {
                Navigator.pop(ctx);
                context.push('/chat');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// 📟 Tablet Layout: Sleek Side Navigation Rail
class _TabletAppShell extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final Widget child;

  const _TabletAppShell({
    required this.currentIndex,
    required this.onNavigate,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onNavigate,
            labelType: NavigationRailLabelType.all,
            backgroundColor: isDark ? const Color(0xFF141318) : const Color(0xFFFBF8F6),
            leading: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B1E3F).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/icons/app_icon_512.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add, size: 22),
                    tooltip: 'Ajouter une bouteille',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                      foregroundColor: const Color(0xFF8B1E3F),
                    ),
                    onPressed: () => context.push('/scan'),
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.person_outline),
                    tooltip: 'Mon Profil & Paramètres',
                    onPressed: () => context.push('/profile'),
                  ),
                ),
              ),
            ),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.wine_bar_outlined),
                selectedIcon: const Icon(Icons.wine_bar, color: Color(0xFF8B1E3F)),
                label: Text(l10n?.navCellar ?? 'Ma Cave'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.auto_awesome_outlined),
                selectedIcon: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
                label: Text(l10n?.navChat ?? 'Chatmelier'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.history_outlined),
                selectedIcon: const Icon(Icons.history, color: Color(0xFF8B1E3F)),
                label: Text(l10n?.navJournal ?? 'Historique'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.insights_outlined),
                selectedIcon: const Icon(Icons.insights, color: Color(0xFF8B1E3F)),
                label: Text(l10n?.navStats ?? 'Statistiques'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: Color(0xFF8B1E3F)),
                label: Text('Profil'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// 💻 Desktop / Computer Web Layout: Permanent Sidebar Navigation Drawer
class _DesktopAppShell extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final Widget child;

  const _DesktopAppShell({
    required this.currentIndex,
    required this.onNavigate,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final cellarsAsync = ref.watch(userCellarsProvider);
    final currentCellarId = ref.watch(currentCellarIdProvider);
    final supabase = ref.watch(supabaseProvider);
    final user = supabase.auth.currentUser;

    String currentCellarName = 'Ma Cave';
    final cellarsList = cellarsAsync.value ?? const [];
    for (final item in cellarsList) {
      final cMap = item['cellars'];
      if (cMap is Map && cMap['id']?.toString() == currentCellarId) {
        currentCellarName = cMap['name']?.toString() ?? 'Ma Cave';
        break;
      }
    }

    return Scaffold(
      body: Row(
        children: [
          // Sidebar (260px fixed width)
          Container(
            width: 270,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141318) : const Color(0xFFFAF7F5),
              border: Border(
                right: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. App Brand Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B1E3F).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/icons/app_icon_512.png',
                            width: 42,
                            height: 42,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chatmelier',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Sommelier & Cave à Vin',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Active Cellar Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: InkWell(
                    onTap: () => CellarSwitcherSheet.show(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFF8B1E3F).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront, size: 18, color: Color(0xFF8B1E3F)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              currentCellarName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.unfold_more, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 3. Primary Navigation Menu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _SidebarNavItem(
                        icon: Icons.wine_bar_outlined,
                        activeIcon: Icons.wine_bar,
                        label: l10n?.navCellar ?? 'Ma Cave',
                        isSelected: currentIndex == 0,
                        onTap: () => onNavigate(0),
                      ),
                      const SizedBox(height: 4),
                      _SidebarNavItem(
                        icon: Icons.auto_awesome_outlined,
                        activeIcon: Icons.auto_awesome,
                        label: l10n?.navChat ?? 'Chatmelier IA',
                        isSelected: currentIndex == 1,
                        activeColor: const Color(0xFFD4AF37),
                        onTap: () => onNavigate(1),
                      ),
                      const SizedBox(height: 4),
                      _SidebarNavItem(
                        icon: Icons.history_outlined,
                        activeIcon: Icons.history,
                        label: l10n?.navJournal ?? 'Historique',
                        isSelected: currentIndex == 2,
                        onTap: () => onNavigate(2),
                      ),
                      const SizedBox(height: 4),
                      _SidebarNavItem(
                        icon: Icons.insights_outlined,
                        activeIcon: Icons.insights,
                        label: l10n?.navStats ?? 'Statistiques',
                        isSelected: currentIndex == 3,
                        onTap: () => onNavigate(3),
                      ),
                      const SizedBox(height: 4),
                      _SidebarNavItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Profil & Goûts',
                        isSelected: currentIndex == 4,
                        onTap: () => onNavigate(4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: theme.dividerColor.withValues(alpha: 0.15)),
                ),
                const SizedBox(height: 8),

                // 4. Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'ACTIONS RAPIDES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _SidebarActionItem(
                        icon: Icons.add_circle_outline,
                        label: 'Ajouter une bouteille',
                        color: const Color(0xFF8B1E3F),
                        onTap: () => context.push('/scan'),
                      ),
                      _SidebarActionItem(
                        icon: Icons.mic_none,
                        label: 'Dictée vocale (Sommelier)',
                        color: Colors.purple.shade700,
                        onTap: () => VoiceDictationSheet.show(context),
                      ),
                      _SidebarActionItem(
                        icon: Icons.wine_bar,
                        label: 'Déguster / Sortir un vin',
                        color: const Color(0xFFD4AF37),
                        onTap: () => context.push('/checkout'),
                      ),
                      _SidebarActionItem(
                        icon: Icons.restaurant,
                        label: 'Déguster Hors-Cave',
                        color: const Color(0xFFE65100),
                        onTap: () => ExternalTastingDialog.show(context),
                      ),
                      _SidebarActionItem(
                        icon: Icons.public,
                        label: 'Carte des Terroirs',
                        color: const Color(0xFF2E7D32),
                        onTap: () => context.push('/scratchcard'),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 5. User Profile Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: theme.dividerColor.withValues(alpha: 0.15)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                  child: InkWell(
                    onTap: () => context.push('/profile'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                            child: const Icon(Icons.person, size: 20, color: Color(0xFF8B1E3F)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.userMetadata?['full_name'] as String? ??
                                      user?.email?.split('@').first ??
                                      'Mon Profil',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  user?.email ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.settings_outlined,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Screen Content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    this.activeColor = const Color(0xFF8B1E3F),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isSelected
          ? (isDark
              ? activeColor.withValues(alpha: 0.22)
              : activeColor.withValues(alpha: 0.12))
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: isSelected ? activeColor : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : activeColor)
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SidebarActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionMenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionMenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
