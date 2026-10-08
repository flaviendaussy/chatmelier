import 'package:chatmelier/features/friends/domain/user_notification.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// Une notification entre amis se lit dans la langue de celui qui la reçoit, pas dans
/// celle de l'expéditeur — ni en français pour tous, comme elles étaient rangées (V2.3 · J8).
void main() {
  tearDown(() => Langue.code = 'fr');

  UserNotification recue(String type, Map<String, dynamic> data, {String? acteur}) => UserNotification.fromJson({
        'id': 'n1',
        'user_id': 'moi',
        'type': type,
        'title': 'Titre rangé en français',
        'body': 'Texte rangé en français',
        'data': data,
        if (acteur != null) 'actor': {'id': 'a1', 'display_name': acteur},
        'created_at': '2026-10-02T09:00:00Z',
      });

  test('une demande d\'accès à la cave, lue en anglais puis en espagnol', () {
    final n = recue('cellar_request', {'requester_name': 'Caro', 'requested_role': 'editor'});
    Langue.code = 'en';
    expect(n.titreLu, 'Request to access your cellar 🍷');
    expect(n.corpsLu, 'Caro would like to access your cellar: adding and removing bottles.');
    Langue.code = 'es';
    expect(n.titreLu, isNot(contains('cave')));
    expect(n.corpsLu, startsWith('Caro '));
    expect(n.corpsLu, isNot(contains('souhaite')));
  });

  test('l\'accès accordé nomme la cave et les droits ; le nom du compte prime', () {
    final n = recue('cellar_granted', {'role': 'viewer', 'cellar_name': 'Cave de Brest'}, acteur: 'Paul');
    Langue.code = 'fr';
    expect(n.corpsLu, 'Paul vous a ouvert sa cave « Cave de Brest » : en consultation.');
    Langue.code = 'en';
    expect(n.corpsLu, 'Paul gave you access to their cellar "Cave de Brest": view only.');
  });

  test('une demande d\'ami porte le pseudo quand on le connaît', () {
    Langue.code = 'en';
    final n = recue('friend_request', {'requester_name': 'Léa', 'requester_username': '@lea'});
    expect(n.corpsLu, 'Léa (@lea) sent you a friend request to share your taste and your cellars.');
  });

  test('un type inconnu garde ce qui a été rangé', () {
    Langue.code = 'en';
    final n = recue('nouveau_type', const {});
    expect((n.titreLu, n.corpsLu), ('Titre rangé en français', 'Texte rangé en français'));
  });

  test('la dégustation qu\'un ami a faite pour vous : à accepter (R4)', () {
    final n = recue('degustation_a_accepter',
        {'degustation_id': 'd1', 'vin': 'Bardos Reserva', 'millesime': 2020, 'note': 7.5, 'date': '2026-10-07T20:10:00Z'},
        acteur: 'Caro');
    Langue.code = 'fr';
    expect(n.titreLu, 'Une dégustation à ajouter à votre journal 🍷');
    expect(n.corpsLu, 'Caro a noté avec vous Bardos Reserva 2020 (7,5/10) le 07/10. L\'ajouter à votre journal ?');
    Langue.code = 'en';
    expect(n.corpsLu, 'Caro rated Bardos Reserva 2020 (7.5/10) with you on 07/10. Add it to your journal?');
    final bouchonnee = recue('degustation_a_accepter', {'degustation_id': 'd2', 'vin': 'Morgon', 'note': 3, 'defaut': 'cork'},
        acteur: 'Caro');
    Langue.code = 'fr';
    expect(bouchonnee.corpsLu, contains('(3/10)'));
    expect(bouchonnee.corpsLu, contains('votre palais n\'en apprendra rien'));
  });
}

