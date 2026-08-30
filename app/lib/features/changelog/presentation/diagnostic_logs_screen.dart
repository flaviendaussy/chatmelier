import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/utils/app_logger.dart';

class DiagnosticLogsScreen extends StatefulWidget {
  const DiagnosticLogsScreen({super.key});

  @override
  State<DiagnosticLogsScreen> createState() => _DiagnosticLogsScreenState();
}

class _DiagnosticLogsScreenState extends State<DiagnosticLogsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'ALL';
  final _searchCtrl = TextEditingController();
  bool _isSyncing = false;

  // Remote server logs
  List<Map<String, dynamic>> _remoteLogs = [];
  bool _isLoadingRemote = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _remoteLogs.isEmpty) {
        _loadRemoteLogs();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _syncToServer() async {
    setState(() => _isSyncing = true);
    final count = await AppLogger.flushToServer();
    setState(() => _isSyncing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0 ? '$count log(s) synchronisés avec succès vers Supabase ☁️' : 'Tous les logs sont déjà à jour avec le serveur !'),
          backgroundColor: count > 0 ? const Color(0xFF10B981) : Colors.blueGrey,
        ),
      );
      if (_tabController.index == 1) {
        _loadRemoteLogs();
      }
    }
  }

  Future<void> _loadRemoteLogs() async {
    setState(() => _isLoadingRemote = true);
    final logs = await AppLogger.fetchServerLogs(limit: 150);
    if (mounted) {
      setState(() {
        _remoteLogs = logs;
        _isLoadingRemote = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs & Console de Diagnostic'),
        actions: [
          IconButton(
            tooltip: 'Estimation des Coûts IA 💰',
            icon: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
            onPressed: () => context.push('/ai-costs'),
          ),
          IconButton(
            tooltip: 'Synchroniser vers le serveur ☁️',
            icon: _isSyncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_upload_outlined),
            onPressed: _isSyncing ? null : _syncToServer,
          ),
          IconButton(
            tooltip: 'Copier tout le rapport',
            icon: const Icon(Icons.copy_all),
            onPressed: () {
              final report = AppLogger.exportDiagnosticReport();
              Clipboard.setData(ClipboardData(text: report));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rapport de diagnostic copié dans le presse-papiers 📋'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Effacer les logs locaux',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                AppLogger.clear();
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.smartphone, size: 18),
                  const SizedBox(width: 6),
                  const Text('Locaux (Appareil)'),
                  if (AppLogger.pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber.shade800, borderRadius: BorderRadius.circular(10)),
                      child: Text('${AppLogger.pendingCount}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Serveur Central ☁️'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Local logs
          _buildLocalLogsTab(theme, isDark),
          // Tab 2: Remote server logs
          _buildRemoteLogsTab(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildLocalLogsTab(ThemeData theme, bool isDark) {
    return ValueListenableBuilder<int>(
      valueListenable: AppLogger.logChangeNotifier,
      builder: (context, _, __) {
        final allLogs = AppLogger.logs.reversed.toList();
        final query = _searchCtrl.text.trim().toLowerCase();

        final filteredLogs = allLogs.where((entry) {
          if (_selectedFilter != 'ALL') {
            if (_selectedFilter == 'ERROR' && entry.level != LogLevel.error) return false;
            if (_selectedFilter == 'SCAN_AI' && !entry.tag.contains('SCAN')) return false;
            if (_selectedFilter == 'AUTH' && !entry.tag.contains('AUTH')) return false;
            if (_selectedFilter == 'GEO_MAP' && !entry.tag.contains('GEO')) return false;
            if (_selectedFilter == 'CELLAR' && !entry.tag.contains('CELLAR')) return false;
          }
          if (query.isNotEmpty) {
            final text = '${entry.tag} ${entry.message} ${entry.error ?? ""}'.toLowerCase();
            if (!text.contains(query)) return false;
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Search & Filter Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? Colors.black26 : Colors.grey.shade100,
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Filtrer les logs (ex: scan, error, auth)...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      isDense: true,
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', 'Tous (${allLogs.length})'),
                        const SizedBox(width: 6),
                        _buildFilterChip('ERROR', '🚨 Erreurs (${allLogs.where((e) => e.level == LogLevel.error).length})'),
                        const SizedBox(width: 6),
                        _buildFilterChip('SCAN_AI', '🤖 Scan IA'),
                        const SizedBox(width: 6),
                        _buildFilterChip('AUTH', '🔒 Auth'),
                        const SizedBox(width: 6),
                        _buildFilterChip('CELLAR', '🍷 Cave'),
                        const SizedBox(width: 6),
                        _buildFilterChip('GEO_MAP', '🗺️ Cartes'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Log entries list
            Expanded(
              child: filteredLogs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('Aucun log disponible pour ce filtre.', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredLogs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        return _buildLogCard(log, theme);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRemoteLogsTab(ThemeData theme, bool isDark) {
    if (_isLoadingRemote) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des logs du serveur Supabase...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isDark ? Colors.black26 : Colors.grey.shade100,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Logs centraux reçus (${_remoteLogs.length} événements)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _loadRemoteLogs,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Actualiser'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _remoteLogs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucun log distant trouvé sur le serveur.\nCliquez sur "Synchroniser" pour pousser vos logs locaux.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _syncToServer,
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Pousser les logs locaux maintenant'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRemoteLogs,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _remoteLogs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = _remoteLogs[index];
                      final tag = item['tag'] ?? 'GENERAL';
                      final level = item['level'] ?? 'info';
                      final message = item['message'] ?? '';
                      final errorDetails = item['error_details'];
                      final platform = item['platform'] ?? 'unknown';
                      final createdAt = item['created_at'] ?? '';

                      Color cardBorderColor = Colors.transparent;
                      IconData levelIcon = Icons.info_outline;
                      Color levelColor = Colors.blue;

                      if (level == 'error') {
                        cardBorderColor = Colors.red.shade400;
                        levelIcon = Icons.error_outline;
                        levelColor = Colors.red;
                      } else if (level == 'warning') {
                        cardBorderColor = Colors.orange.shade400;
                        levelIcon = Icons.warning_amber_outlined;
                        levelColor = Colors.orange;
                      }

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: cardBorderColor, width: cardBorderColor != Colors.transparent ? 1.5 : 0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(levelIcon, size: 16, color: levelColor),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: levelColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: levelColor),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '📱 $platform',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    createdAt.length > 19 ? createdAt.substring(11, 19) : createdAt,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              if (errorDetails != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    errorDetails.toString(),
                                    style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.red.shade900),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = key);
      },
    );
  }

  Widget _buildLogCard(LogEntry log, ThemeData theme) {
    Color cardBorderColor = Colors.transparent;
    Color tagBgColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.5);
    Color tagTextColor = theme.colorScheme.primary;

    if (log.level == LogLevel.error) {
      cardBorderColor = Colors.red.shade400;
      tagBgColor = Colors.red.shade100;
      tagTextColor = Colors.red.shade900;
    } else if (log.level == LogLevel.warning) {
      cardBorderColor = Colors.orange.shade400;
      tagBgColor = Colors.orange.shade100;
      tagTextColor = Colors.orange.shade900;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cardBorderColor, width: cardBorderColor != Colors.transparent ? 1.5 : 0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showLogDetail(log),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(log.levelIcon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagBgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.tag,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tagTextColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (log.isSyncedToServer)
                    const Tooltip(message: 'Synchronisé vers Supabase ☁️', child: Icon(Icons.cloud_done, size: 14, color: Colors.teal))
                  else
                    const Tooltip(message: 'En attente de synchronisation', child: Icon(Icons.cloud_queue, size: 14, color: Colors.grey)),
                  const Spacer(),
                  Text(
                    log.formattedTime,
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                log.message,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              if (log.error != null) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${log.error}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.red.shade900),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLogDetail(LogEntry log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(log.levelIcon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text('${log.level.name.toUpperCase()} [${log.tag}]', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  Text(log.formattedTime, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const Divider(height: 24),
              const Text('Message:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              SelectableText(log.message),
              if (log.error != null) ...[
                const SizedBox(height: 16),
                const Text('Erreur:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 4),
                SelectableText('${log.error}', style: const TextStyle(fontFamily: 'monospace', color: Colors.red)),
              ],
              if (log.stackTrace != null) ...[
                const SizedBox(height: 16),
                const Text('Trace de la pile (Stack Trace):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                SelectableText('${log.stackTrace}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: log.toString()));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Log copié !')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier ce log'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
