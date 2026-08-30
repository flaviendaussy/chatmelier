import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/voice/domain/voice_command_parser.dart';

void main() {
  group('VoiceCommandParser Tests', () {
    test('Should parse checkout command with wine name, vintage, and quantity', () {
      final res = VoiceCommandParser.parse('Sortir 2 bouteilles de Margaux 2015 pour ce soir');
      expect(res.actionType, VoiceActionType.checkout);
      expect(res.quantity, 2);
      expect(res.vintage, 2015);
      expect(res.wineName, contains('Margaux'));
    });

    test('Should parse single bottle checkout with verb déguster', () {
      final res = VoiceCommandParser.parse('Déguster un Chablis Grand Cru 2020');
      expect(res.actionType, VoiceActionType.checkout);
      expect(res.quantity, 1);
      expect(res.vintage, 2020);
      expect(res.wineName, contains('Chablis'));
    });

    test('Should parse batch addition with carton (6 bottles) and rack location', () {
      final res = VoiceCommandParser.parse('Ajouter un carton de Saint-Joseph 2019 casier B3');
      expect(res.actionType, VoiceActionType.add);
      expect(res.quantity, 6);
      expect(res.vintage, 2019);
      expect(res.wineName, contains('Saint-Joseph'));
      expect(res.location, 'casier B3');
    });

    test('Should parse wooden crate (12 bottles) addition', () {
      final res = VoiceCommandParser.parse('Ajoute 1 caisse de Champagne Roederer 2014');
      expect(res.actionType, VoiceActionType.add);
      expect(res.quantity, 12);
      expect(res.vintage, 2014);
      expect(res.wineType, 'sparkling');
      expect(res.wineName, contains('Roederer'));
    });

    test('Should identify wine color type for white and rose additions', () {
      final whiteRes = VoiceCommandParser.parse('Ajouter 3 bouteilles de Bourgogne blanc 2022');
      expect(whiteRes.actionType, VoiceActionType.add);
      expect(whiteRes.wineType, 'white');
      expect(whiteRes.quantity, 3);

      final roseRes = VoiceCommandParser.parse('Ajouter 2 bouteilles de Bandol rosé 2023');
      expect(roseRes.actionType, VoiceActionType.add);
      expect(roseRes.wineType, 'rose');
      expect(roseRes.quantity, 2);
    });

    test('Should route sommelier advice and food pairing questions', () {
      final q1 = VoiceCommandParser.parse('Quel vin servir avec un magret de canard aux airelles ?');
      expect(q1.actionType, VoiceActionType.sommelier);
      expect(q1.query, contains('magret'));

      final q2 = VoiceCommandParser.parse('Accord avec du fromage de chèvre');
      expect(q2.actionType, VoiceActionType.sommelier);
    });

    test('Empty command should return unknown', () {
      final res = VoiceCommandParser.parse('   ');
      expect(res.actionType, VoiceActionType.unknown);
    });
  });
}
