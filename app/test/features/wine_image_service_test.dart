import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine_image_service.dart';

void main() {
  group('WineImageService & Auto-Enrichment Unit Tests', () {
    test('Specific estate matching for Bordeaux, Chablis, Bandol, and Loire', () {
      const margaux = Wine(
        id: 'w_margaux',
        name: 'Château Margaux Premier Grand Cru',
        producer: 'Château Margaux',
        region: 'Bordeaux',
        country: 'France',
        type: 'red',
      );
      final margauxImg = WineImageService.resolveWineImageUrl(margaux);
      expect(margauxImg, isNotEmpty);
      expect(margauxImg.startsWith('http'), isTrue);

      const chablis = Wine(
        id: 'w_chablis',
        name: 'Chablis Grand Cru Les Clos',
        producer: 'Domaine Laroche',
        region: 'Bourgogne',
        country: 'France',
        type: 'white',
      );
      final chablisImg = WineImageService.resolveWineImageUrl(chablis);
      expect(chablisImg, isNotEmpty);
      expect(chablisImg.startsWith('http'), isTrue);

      const bandol = Wine(
        id: 'w_bandol',
        name: 'Grande Réserve Rouge',
        producer: 'Domaine du Paternel',
        appellation: 'Bandol',
        region: 'Provence',
        country: 'France',
        type: 'red',
      );
      final bandolImg = WineImageService.resolveWineImageUrl(bandol);
      expect(bandolImg, isNotEmpty);
      expect(bandolImg.startsWith('http'), isTrue);
    });

    test('Archetype fallback for any wine region / type', () {
      const genericRed = Wine(
        id: 'w_generic',
        name: 'Cuvée Inconnue',
        region: 'Bordeaux',
        country: 'France',
        type: 'red',
      );
      final redImg = WineImageService.resolveWineImageUrl(genericRed);
      expect(redImg, isNotEmpty);

      const genericWhite = Wine(
        id: 'w_white',
        name: 'Blanc Mystère',
        region: 'Alsace',
        country: 'France',
        type: 'white',
      );
      final whiteImg = WineImageService.resolveWineImageUrl(genericWhite);
      expect(whiteImg, isNotEmpty);

      const genericChamp = Wine(
        id: 'w_champ',
        name: 'Bulles d\'Or',
        region: 'Champagne',
        country: 'France',
        type: 'sparkling',
      );
      final champImg = WineImageService.resolveWineImageUrl(genericChamp);
      expect(champImg, isNotEmpty);
    });

    test('Existing valid image is preserved without overwriting', () {
      const customWine = Wine(
        id: 'w_custom',
        name: 'Vin Perso',
        region: 'Rhône',
        country: 'France',
        type: 'red',
        imageUrl: 'https://my-custom-server.com/photo.jpg',
      );
      final resolved = WineImageService.resolveWineImageUrl(customWine);
      expect(resolved, equals('https://my-custom-server.com/photo.jpg'));
    });

    test('Bottle.fromJson gracefully auto-resolves image if none was provided', () {
      final bottle = Bottle.fromJson({
        'id': 'b_test',
        'cellar_id': 'c1',
        'wine_id': 'w_test',
        'added_by': 'user1',
        'owner_id': 'user1',
        'wines': {
          'id': 'w_test',
          'name': 'Château Noaillac',
          'producer': 'Château Noaillac',
          'region': 'Bordeaux',
          'country': 'France',
          'wine_type': 'red',
        },
      });

      expect(bottle.photoUrl, isNotNull);
      expect(bottle.photoUrl!.startsWith('http'), isTrue);
    });
  });
}
