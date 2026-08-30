import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/bottle.dart';

class CellarExportService {
  static Future<void> exportToCsv({
    required String cellarName,
    required List<Bottle> bottles,
  }) async {
    final rows = <List<dynamic>>[];

    // CSV Header
    rows.add([
      'Nom du Vin',
      'Producteur / Domaine',
      'Millésime',
      'Type de Vin',
      'Pays',
      'Région',
      'Appellation',
      'Quantité',
      'Prix d\'Achat',
      'Devise',
      'Valeur Estimée',
      'Statut Apogée',
      'Apogée Début',
      'Apogée Fin',
      'Casier / Emplacement',
      'Étagère / Niveau',
      'Notes de Dégustation',
    ]);

    for (final b in bottles) {
      final w = b.wine;
      rows.add([
        w?.name ?? 'Bouteille',
        w?.producer ?? '',
        w?.vintage ?? '',
        w?.type ?? '',
        w?.country ?? '',
        w?.region ?? '',
        w?.appellation ?? '',
        b.quantity,
        b.purchasePrice ?? '',
        b.currency,
        w?.estimatedMarketValue ?? '',
        w?.windowStatus.name ?? b.status,
        w?.drinkStart ?? '',
        w?.drinkEnd ?? '',
        b.rack ?? '',
        b.shelf ?? '',
        w?.tastingNotes ?? '',
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'inventaire_${cellarName.replaceAll(RegExp(r'\s+'), '_').toLowerCase()}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(csvData);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Export de la cave "$cellarName" (${bottles.length} références) - Chatmelier',
    );
  }

  static Future<void> exportInsuranceReport({
    required String cellarName,
    required String userName,
    required List<Bottle> bottles,
  }) async {
    final dateStr = DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now());
    int totalBottles = 0;
    double totalPurchaseVal = 0.0;
    double totalEstimatedVal = 0.0;

    for (final b in bottles) {
      totalBottles += b.quantity;
      if (b.purchasePrice != null) {
        totalPurchaseVal += b.purchasePrice! * b.quantity;
      }
      final est = b.wine?.estimatedMarketValue ?? b.purchasePrice ?? 0.0;
      totalEstimatedVal += est * b.quantity;
    }

    final buffer = StringBuffer();
    buffer.writeln('===========================================================');
    buffer.writeln('          CHATMELIER - RAPPORT D\'EXPERTISE DE CAVE         ');
    buffer.writeln('               CERTIFICAT DE VALORISATION                  ');
    buffer.writeln('===========================================================');
    buffer.writeln('Cave : $cellarName');
    buffer.writeln('Propriétaire : $userName');
    buffer.writeln('Date d\'émission : $dateStr');
    buffer.writeln('-----------------------------------------------------------');
    buffer.writeln('SYNTHÈSE PATRIMONIALE :');
    buffer.writeln('• Nombre total de bouteilles en stock : $totalBottles');
    buffer.writeln('• Coût d\'acquisition cumulé : ${totalPurchaseVal.toStringAsFixed(2)} €');
    buffer.writeln('• Valeur marchande estimée (Assurance) : ${totalEstimatedVal.toStringAsFixed(2)} €');
    buffer.writeln('-----------------------------------------------------------');
    buffer.writeln('INVENTAIRE DÉTAILLÉ DU STOCK :');
    buffer.writeln('');

    int idx = 1;
    for (final b in bottles) {
      final w = b.wine;
      final priceStr = b.purchasePrice != null ? '${b.purchasePrice} ${b.currency}' : 'Non renseigné';
      final valStr = w?.estimatedMarketValue != null ? '${w!.estimatedMarketValue} €' : priceStr;
      final wineName = w?.name ?? 'Bouteille';
      final vintageStr = w?.vintage != null ? '(${w!.vintage})' : '(NV)';
      
      buffer.writeln('$idx. $wineName $vintageStr');
      buffer.writeln('   Domaine : ${w?.producer ?? "Inconnu"} | Terroir : ${w?.region ?? ""} (${w?.country ?? ""})');
      buffer.writeln('   Quantité : ${b.quantity} btl | Prix achat : $priceStr | Valeur estimée unitaire : $valStr');
      buffer.writeln('   Emplacement : Casier ${b.rack ?? "-"}, Niveau ${b.shelf ?? "-"}');
      buffer.writeln('   Fenêtre d\'apogée : ${w?.drinkStart ?? "?"} - ${w?.drinkEnd ?? "?"}');
      buffer.writeln('');
      idx++;
    }

    buffer.writeln('===========================================================');
    buffer.writeln('Document certifié généré par l\'application Chatmelier.');
    buffer.writeln('Ce rapport peut être transmis directement à votre compagnie d\'assurance habitation.');
    buffer.writeln('===========================================================');

    final tempDir = await getTemporaryDirectory();
    final fileName = 'rapport_assurance_${cellarName.replaceAll(RegExp(r'\s+'), '_').toLowerCase()}_${DateFormat('yyyyMMdd').format(DateTime.now())}.txt';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Rapport d\'assurance et valorisation de cave "$cellarName" ($totalEstimatedVal €)',
    );
  }
}
