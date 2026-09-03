import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/vineyard_knowledge.dart';
import 'package:chatmelier/features/cellar/data/vineyard_knowledge_service.dart';

void main() {
  group('Vineyard Knowledge Transversal Cache Tests', () {
    test('Key normalization strips accents, spaces, punctuation and lowercases', () {
      expect(VineyardKnowledgeService.normalizeKey('Château Margaux'), equals('chateau_margaux'));
      expect(VineyardKnowledgeService.normalizeKey('Domaine de la Romanée-Conti'), equals('domaine_de_la_romanee_conti'));
      expect(VineyardKnowledgeService.normalizeKey('M. Chapoutier & Fils'), equals('m_chapoutier_fils'));
    });

    test('1-year rule: entry verified today is NOT expired and has ~365 days left', () {
      final vk = VineyardKnowledge(
        key: 'chateau_latour',
        producerName: 'Château Latour',
        region: 'Bordeaux',
        appellation: 'Pauillac',
        country: 'France',
        terroirDescription: 'Terroir d\'exception de graves profondes.',
        verifiedAt: DateTime.now(),
      );

      expect(vk.isExpired, isFalse);
      expect(vk.daysUntilExpiry, inInclusiveRange(364, 365));
    });

    test('1-year rule: entry verified 366 days ago IS expired and needs re-verification', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 366));
      final vk = VineyardKnowledge(
        key: 'chateau_latour',
        producerName: 'Château Latour',
        region: 'Bordeaux',
        appellation: 'Pauillac',
        country: 'France',
        terroirDescription: 'Description archivée.',
        verifiedAt: oldDate,
      );

      expect(vk.isExpired, isTrue);
      expect(vk.daysUntilExpiry, equals(0));
    });

    test('JSON serialization preserves verification date and terroir details', () {
      final date = DateTime(2026, 9, 3, 14, 30);
      final vk = VineyardKnowledge(
        key: 'domaine_leflaive',
        producerName: 'Domaine Leflaive',
        region: 'Bourgogne',
        appellation: 'Puligny-Montrachet',
        country: 'France',
        terroirDescription: 'Calcaire et marnes blanches, biodynamie.',
        soilType: 'Argilo-calcaire',
        viticultureStyle: 'Biodynamie certifiée',
        verifiedAt: date,
        source: 'sommelier_encyclopedia',
      );

      final json = vk.toJson();
      final revived = VineyardKnowledge.fromJson(json);

      expect(revived.key, equals('domaine_leflaive'));
      expect(revived.producerName, equals('Domaine Leflaive'));
      expect(revived.soilType, equals('Argilo-calcaire'));
      expect(revived.viticultureStyle, equals('Biodynamie certifiée'));
      expect(revived.verifiedAt.year, equals(2026));
      expect(revived.verifiedAt.month, equals(9));
      expect(revived.verifiedAt.day, equals(3));
    });
  });
}
