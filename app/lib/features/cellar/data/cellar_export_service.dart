import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/bottle.dart';
import '../../../shared/utils/langue.dart';

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
        w?.valeurFiable ?? '',
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
      text: tr('Export de la cave « {cave} » ({n} références) - Chatmelier', 'Export of the cellar "{cave}" ({n} wines) - Chatmelier', {'cave': cellarName, 'n': bottles.length}),
    );
  }

  /// L'inventaire de la cave, avec des valeurs INDICATIVES.
  ///
  /// Il s'intitulait « Rapport d'expertise — Certificat de valorisation » et se disait
  /// « document certifié, transmissible à votre assurance », alors que ses valeurs
  /// venaient d'estimations de l'IA sans source, ou du prix d'achat (30/09). Rien ici
  /// n'est une expertise : le document le dit, et renvoie à un professionnel.
  static Future<void> exportInsuranceReport({
    required String cellarName,
    required String userName,
    required List<Bottle> bottles,
  }) async {
    final dateStr = DateFormat(tr('dd/MM/yyyy à HH:mm', 'dd/MM/yyyy, HH:mm')).format(DateTime.now());
    int totalBottles = 0;
    double totalPurchaseVal = 0.0;
    double totalEstimatedVal = 0.0;

    // Seule une valeur sourcée ou saisie par la personne compte ; à défaut, le prix d'achat.
    double? valeurUnitaire(Bottle b) {
      final w = b.wine;
      final v = w?.estimatedMarketValue;
      if (w != null && v != null && (w.valeurSourcee || w.valeurSaisie)) return v;
      return b.purchasePrice;
    }

    for (final b in bottles) {
      totalBottles += b.quantity;
      if (b.purchasePrice != null) {
        totalPurchaseVal += b.purchasePrice! * b.quantity;
      }
      totalEstimatedVal += (valeurUnitaire(b) ?? 0.0) * b.quantity;
    }

    final buffer = StringBuffer();
    buffer.writeln('===========================================================');
    buffer.writeln(tr('          CHATMELIER - INVENTAIRE DE CAVE', '          CHATMELIER - CELLAR INVENTORY'));
    buffer.writeln(tr('          Valeurs indicatives, sans valeur d\'expertise', '          Indicative values, not a professional appraisal'));
    buffer.writeln('===========================================================');
    buffer.writeln(tr('Cave : {cave}', 'Cellar: {cave}', {'cave': cellarName}));
    buffer.writeln(tr('Propriétaire : {nom}', 'Owner: {nom}', {'nom': userName}));
    buffer.writeln(tr('Date : {date}', 'Date: {date}', {'date': dateStr}));
    buffer.writeln('-----------------------------------------------------------');
    buffer.writeln(tr('SYNTHÈSE :', 'SUMMARY:'));
    buffer.writeln(tr('• Bouteilles en stock : {n}', '• Bottles in stock: {n}', {'n': totalBottles}));
    buffer.writeln(tr('• Coût d\'acquisition cumulé : {v}', '• Total purchase cost: {v}', {'v': totalPurchaseVal.toStringAsFixed(2)}));
    buffer.writeln(tr('• Valeur indicative : {v}', '• Indicative value: {v}', {'v': totalEstimatedVal.toStringAsFixed(2)}));
    buffer.writeln('-----------------------------------------------------------');
    buffer.writeln(tr('INVENTAIRE DÉTAILLÉ :', 'DETAILED INVENTORY:'));
    buffer.writeln('');

    int idx = 1;
    for (final b in bottles) {
      final w = b.wine;
      final nonRenseigne = tr('Non renseigné', 'Not specified');
      final priceStr = b.purchasePrice != null ? '${b.purchasePrice} ${b.currency}' : nonRenseigne;
      final valeur = valeurUnitaire(b);
      final valStr = valeur != null ? valeur.toStringAsFixed(2) : nonRenseigne;
      final wineName = w?.name ?? tr('Bouteille', 'Bottle');
      final vintageStr = w?.vintage != null ? '(${w!.vintage})' : tr('(NM)', '(NV)');

      buffer.writeln('$idx. $wineName $vintageStr');
      buffer.writeln(tr('   Domaine : {d} | Origine : {r} ({p})', '   Producer: {d} | Origin: {r} ({p})',
          {'d': w?.producer ?? tr('Inconnu', 'Unknown'), 'r': w?.region ?? '', 'p': w?.country ?? ''}));
      buffer.writeln(tr('   Quantité : {q} | Prix d\'achat : {a} | Valeur indicative unitaire : {v}',
          '   Quantity: {q} | Purchase price: {a} | Indicative unit value: {v}', {'q': b.quantity, 'a': priceStr, 'v': valStr}));
      buffer.writeln(tr('   Emplacement : casier {c}, niveau {n}', '   Location: rack {c}, level {n}', {'c': b.rack ?? '-', 'n': b.shelf ?? '-'}));
      buffer.writeln(tr('   Fenêtre de dégustation : {d} - {f}', '   Drinking window: {d} - {f}', {'d': w?.drinkStart ?? '?', 'f': w?.drinkEnd ?? '?'}));
      buffer.writeln('');
      idx++;
    }

    buffer.writeln('===========================================================');
    buffer.writeln(tr('Document généré par l\'application Chatmelier.', 'Document generated by the Chatmelier app.'));
    buffer.writeln(tr('Les valeurs sont indicatives : valeur relevée avec sa source, valeur saisie, ou prix d\'achat.',
        'Values are indicative: a value found with its source, a value you entered, or the purchase price.'));
    buffer.writeln(tr('Pour une assurance, faites estimer votre cave par un expert.', 'For insurance purposes, have your cellar appraised by an expert.'));
    buffer.writeln('===========================================================');

    final tempDir = await getTemporaryDirectory();
    final fileName = 'inventaire_valeurs_${cellarName.replaceAll(RegExp(r'\s+'), '_').toLowerCase()}_${DateFormat('yyyyMMdd').format(DateTime.now())}.txt';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: tr('Inventaire de la cave « {cave} » (valeurs indicatives)', 'Inventory of the cellar "{cave}" (indicative values)', {'cave': cellarName}),
    );
  }
}
