import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../domain/bottle.dart';
import '../domain/wine.dart';

class CellarPdfExportService {
  /// Generate and share / export the prestige Sommelier Wine Menu PDF
  static Future<void> exportSommelierWineMenuPdf({
    required String cellarName,
    required String userName,
    required List<Bottle> bottles,
  }) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final activeBottles = bottles.where((b) => !b.isConsumed).toList();

    int totalBottleCount = 0;
    double totalEstValue = 0.0;
    int readyToDrinkCount = 0;

    for (final b in activeBottles) {
      totalBottleCount += b.quantity;
      final est = b.wine?.estimatedMarketValue ?? b.purchasePrice ?? 0.0;
      totalEstValue += est * b.quantity;
      final status = b.wine?.windowStatus;
      if (status == DrinkWindowStatus.inPeak || status == DrinkWindowStatus.drinkSoon) {
        readyToDrinkCount += b.quantity;
      }
    }

    // Color definitions
    const primaryBurgundy = PdfColor.fromInt(0xFF722F37);
    const goldAccent = PdfColor.fromInt(0xFFC2A649);
    const darkSlate = PdfColor.fromInt(0xFF1E1E2A);
    const lightBg = PdfColor.fromInt(0xFFF9F7F4);
    const rowAltBg = PdfColor.fromInt(0xFFF2EFEB);

    // Group bottles by wine type
    final sparklings = activeBottles.where((b) => (b.wine?.type ?? '').toLowerCase() == 'sparkling').toList();
    final whites = activeBottles.where((b) => (b.wine?.type ?? '').toLowerCase() == 'white').toList();
    final roses = activeBottles.where((b) => (b.wine?.type ?? '').toLowerCase() == 'rose' || (b.wine?.type ?? '').toLowerCase() == 'rosé').toList();
    final reds = activeBottles.where((b) => (b.wine?.type ?? '').toLowerCase() == 'red').toList();
    final others = activeBottles.where((b) => !sparklings.contains(b) && !whites.contains(b) && !roses.contains(b) && !reds.contains(b)).toList();

    final sections = <Map<String, dynamic>>[
      if (sparklings.isNotEmpty) {'title': 'CHAMPAGNES & EFFERVESCENTS', 'bottles': sparklings},
      if (whites.isNotEmpty) {'title': 'VINS BLANCS', 'bottles': whites},
      if (roses.isNotEmpty) {'title': 'VINS ROSÉS', 'bottles': roses},
      if (reds.isNotEmpty) {'title': 'VINS ROUGES', 'bottles': reds},
      if (others.isNotEmpty) {'title': 'AUTRES VINS & SPIRITUEUX', 'bottles': others},
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: goldAccent, width: 1.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CHATMELIER',
                      style: pw.TextStyle(
                        color: primaryBurgundy,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.Text(
                      'CARTE DES VINS & LIVRE DE CAVE',
                      style: pw.TextStyle(
                        color: goldAccent,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      cellarName.toUpperCase(),
                      style: pw.TextStyle(color: darkSlate, fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Édition du $dateStr',
                      style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Chatmelier • Sommelier Privé & Gestionnaire de Cave',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                ),
                pw.Text(
                  'Page ${context.pageNumber} sur ${context.pagesCount}',
                  style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 12),

            // Summary KPI Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: goldAccent.shade(0.4), width: 1),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('RÉFÉRENCES', '${activeBottles.length}', primaryBurgundy),
                  _buildSummaryItem('BOUTEILLES', '$totalBottleCount', primaryBurgundy),
                  _buildSummaryItem('À BOIRE / APOGÉE', '$readyToDrinkCount', goldAccent),
                  _buildSummaryItem('VALEUR ESTIMÉE', '${totalEstValue.toStringAsFixed(0)} €', primaryBurgundy),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Wine Sections
            ...sections.map((section) {
              final sBottles = section['bottles'] as List<Bottle>;
              final title = section['title'] as String;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    margin: const pw.EdgeInsets.only(top: 10, bottom: 6),
                    decoration: const pw.BoxDecoration(
                      color: primaryBurgundy,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          title,
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 1),
                        ),
                        pw.Text(
                          '${sBottles.fold<int>(0, (sum, b) => sum + b.quantity)} bouteilles (${sBottles.length} réf.)',
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
                        ),
                      ],
                    ),
                  ),

                  // Table of bottles
                  pw.TableHelper.fromTextArray(
                    border: null,
                    headerStyle: pw.TextStyle(color: darkSlate, fontSize: 8, fontWeight: pw.FontWeight.bold),
                    headerDecoration: const pw.BoxDecoration(color: rowAltBg),
                    cellHeight: 22,
                    cellStyle: const pw.TextStyle(fontSize: 7.5, color: darkSlate),
                    cellAlignment: pw.Alignment.centerLeft,
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3.2), // Vin / Domaine
                      1: const pw.FlexColumnWidth(0.8), // Millésime
                      2: const pw.FlexColumnWidth(2.2), // Appellation / Région
                      3: const pw.FlexColumnWidth(2.0), // Cépages
                      4: const pw.FlexColumnWidth(1.2), // Apogée
                      5: const pw.FlexColumnWidth(1.0), // Casier
                      6: const pw.FlexColumnWidth(0.6), // Qté
                      7: const pw.FlexColumnWidth(1.0), // Prix
                    },
                    headers: ['Vin & Domaine', 'Mil.', 'Région / Appellation', 'Cépages', 'Apogée', 'Casier', 'Qté', 'Valeur'],
                    data: sBottles.map((b) {
                      final w = b.wine;
                      final prod = w?.producer ?? '';
                      final wineName = w?.name ?? 'Vin';
                      final name = prod.isNotEmpty ? '$prod • $wineName' : wineName;
                      final vintage = w?.vintage != null ? '${w!.vintage}' : 'NM';
                      final regionApp = '${w?.appellation ?? w?.region ?? "-"}';
                      final grapes = (w?.grapes != null && w!.grapes.isNotEmpty)
                          ? w.grapes.map((g) => g.name).take(2).join(', ')
                          : '-';
                      final apogee = (w?.drinkStart != null && w?.drinkEnd != null)
                          ? '${w!.drinkStart}-${w.drinkEnd}'
                          : (w?.windowStatus.labelFr ?? '-');
                      final location = b.rack != null ? '${b.rack}${b.shelf != null ? "-${b.shelf}" : ""}' : '-';
                      final qte = '${b.quantity}';
                      final price = w?.estimatedMarketValue != null
                          ? '${w!.estimatedMarketValue!.toStringAsFixed(0)} €'
                          : (b.purchasePrice != null ? '${b.purchasePrice!.toStringAsFixed(0)} €' : '-');

                      return [name, vintage, regionApp, grapes, apogee, location, qte, price];
                    }).toList(),
                  ),
                  pw.SizedBox(height: 10),
                ],
              );
            }),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final fileName = 'Carte_Vins_${cellarName.replaceAll(RegExp(r'\s+'), '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Carte des Vins Sommelier • Cave "$cellarName" (${activeBottles.length} références) - Chatmelier',
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(color: color, fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 7, letterSpacing: 0.5),
        ),
      ],
    );
  }
}
