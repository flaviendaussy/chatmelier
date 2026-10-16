import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/auth/domain/user_profile.dart';
import 'package:chatmelier/features/auth/presentation/mandatory_username_dialog.dart';

/// 15/10, Pascal (iPhone) : « impossibilité de créer un pseudo ». Il avait tapé « Pascal l
/// ecureuil », le message d'erreur était tronqué, et il a renoncé.
void main() {
  test('ce qu\'on tape devient un pseudo valable', () {
    expect(UserProfile.normaliserPseudo('Pascal l ecureuil'), 'pascal_l_ecureuil');
    expect(UserProfile.normaliserPseudo('Pascal l’Écureuil'), 'pascal_l_ecureuil');
    expect(UserProfile.normaliserPseudo('@Flavien.Daussy'), 'flavien_daussy');
    expect(UserProfile.normaliserPseudo('  caro  '), 'caro');
    expect(UserProfile.normaliserPseudo('jean--luc'), 'jean_luc');
    expect(UserProfile.normaliserPseudo('vin🍷rouge'), 'vinrouge');
    expect(UserProfile.normaliserPseudo('a' * 40), hasLength(30));
    expect(UserProfile.validateUsername(UserProfile.normaliserPseudo('Pascal l ecureuil')), isNull);
  });

  test('pendant la frappe, le tiret bas du mot suivant reste', () {
    expect(UserProfile.normaliserPseudo('pascal ', enCours: true), 'pascal_');
    expect(UserProfile.normaliserPseudo('pascal ', enCours: false), 'pascal');
  });

  testWidgets('le champ écrit le pseudo comme il sera enregistré', (tester) async {
    final controleur = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TextField(controller: controleur, inputFormatters: const [FormatDuPseudo()])),
    ));
    await tester.enterText(find.byType(TextField), 'Pascal l écureuil');
    expect(controleur.text, 'pascal_l_ecureuil');
  });
}
