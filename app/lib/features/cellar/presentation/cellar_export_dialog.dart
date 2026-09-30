import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/cellar_provider.dart';
import '../data/cellar_export_service.dart';
import '../data/cellar_pdf_export_service.dart';
import '../../../shared/utils/langue.dart';

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
              tr('Exporter ma Cave', 'Export my cellar'),
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
            tr('Exportez l\'inventaire complet de "{cellarName}" ({bottles_length} références en stock) :', 'Export the full inventory of "{cellarName}" ({bottles_length} wines in stock):', {'cellarName': cellarName, 'bottles_length': bottles.length}),
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
            title: Text(tr('Carte des Vins Sommelier (PDF)', 'Sommelier wine list (PDF)'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(tr('Document A4 élégant, classé par style, apogée et cépages (Partage & Impression)', 'An elegant A4 document, sorted by style, peak and grapes (share & print)')),
            onTap: () async {
              Navigator.pop(context);
              await CellarPdfExportService.exportSommelierWineMenuPdf(
                cellarName: cellarName,
                userName: tr('Propriétaire Chatmelier', 'Chatmelier owner'),
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
            title: Text(tr('Export Tableur (CSV / Excel)', 'Spreadsheet export (CSV / Excel)'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(tr('Compatible Excel, Google Sheets, Numbers', 'Works with Excel, Google Sheets, Numbers')),
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
            title: Text(tr('Rapport d\'Assurance Certifié', 'Certified insurance report'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(tr('Certificat de valorisation patrimoniale', 'Valuation certificate')),
            onTap: () async {
              Navigator.pop(context);
              await CellarExportService.exportInsuranceReport(
                cellarName: cellarName,
                userName: tr('Propriétaire Chatmelier', 'Chatmelier owner'),
                bottles: bottles,
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('Fermer', 'Close')),
        ),
      ],
    );
  }
}
