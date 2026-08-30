import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/cellar_provider.dart';
import '../data/cellar_export_service.dart';
import '../data/cellar_pdf_export_service.dart';

class CellarExportDialog extends ConsumerWidget {
  final String cellarName;

  const CellarExportDialog({super.key, required this.cellarName});

  static Future<void> show(BuildContext context, String cellarName) {
    return showDialog(
      context: context,
      builder: (ctx) => CellarExportDialog(cellarName: cellarName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeCellarId = ref.watch(currentCellarIdProvider);
    final bottlesAsync = ref.watch(bottlesProvider(activeCellarId));
    final bottles = bottlesAsync.value ?? [];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.file_download, color: Color(0xFF8B1E3F), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Exporter ma Cave',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exportez l\'inventaire complet de "$cellarName" (${bottles.length} références en stock) :',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),

          // Option 1: PDF Carte des Vins Sommelier
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
            ),
            tileColor: const Color(0xFFD4AF37).withValues(alpha: 0.08),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF722F37),
              child: Icon(Icons.picture_as_pdf, color: Color(0xFFD4AF37)),
            ),
            title: const Text('Carte des Vins Sommelier (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Document A4 élégant, classé par style, apogée et cépages (Partage & Impression)'),
            onTap: () async {
              Navigator.pop(context);
              await CellarPdfExportService.exportSommelierWineMenuPdf(
                cellarName: cellarName,
                userName: 'Propriétaire Chatmelier',
                bottles: bottles,
              );
            },
          ),
          const SizedBox(height: 12),

          // Option 3: CSV Tableur
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.table_chart, color: Color(0xFF2E7D32)),
            ),
            title: const Text('Export Tableur (CSV / Excel)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Compatible Excel, Google Sheets, Numbers'),
            onTap: () async {
              Navigator.pop(context);
              await CellarExportService.exportToCsv(
                cellarName: cellarName,
                bottles: bottles,
              );
            },
          ),
          const SizedBox(height: 12),

          // Option 4: Rapport d'Assurance
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEDE7F6),
              child: Icon(Icons.security, color: Color(0xFF512DA8)),
            ),
            title: const Text('Rapport d\'Assurance Certifié', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Certificat de valorisation patrimoniale'),
            onTap: () async {
              Navigator.pop(context);
              await CellarExportService.exportInsuranceReport(
                cellarName: cellarName,
                userName: 'Propriétaire Chatmelier',
                bottles: bottles,
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
