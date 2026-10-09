import 'package:chatmelier/features/auth/domain/user_profile.dart';
import 'package:chatmelier/shared/utils/avatar_et_pseudo.dart';
import 'package:chatmelier/shared/widgets/owner_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const photo = 'https://fvnybncauhbpsnikzeeq.supabase.co/storage/v1/object/public/avatars/u/photo.jpg?t=1';

  test('le pseudo et la photo voyagent ensemble, et chacun se relit', () {
    final range = AvatarEtPseudo.composer(pseudo: '@Flavien', image: photo)!;
    expect(range, startsWith('meta://?u=flavien&avatar='));
    expect(AvatarEtPseudo.pseudo(range), 'flavien');
    expect(AvatarEtPseudo.image(range), photo);
    // Ce que lit la recherche des membres (062, pseudo_du_profil) : u= jusqu'au prochain &.
    expect(RegExp(r'^meta://\?(?:.*&)?u=([^&]*)').firstMatch(range)!.group(1), 'flavien');
  });

  test('sans pseudo, la photo seule ; sans photo, le pseudo seul ; sans rien, rien', () {
    expect(AvatarEtPseudo.composer(image: photo), photo);
    expect(AvatarEtPseudo.composer(pseudo: 'caro'), 'meta://?u=caro');
    expect(AvatarEtPseudo.composer(pseudo: 'caro', image: ''), 'meta://?u=caro', reason: 'photo retirée');
    expect(AvatarEtPseudo.composer(), isNull);
    expect(AvatarEtPseudo.image('meta://?u=caro'), isNull);
    expect(AvatarEtPseudo.composer(pseudo: 'caro', image: 'emoji:🍷'), 'meta://?u=caro&avatar=${Uri.encodeComponent('emoji:🍷')}');
  });

  test('une adresse déjà rangée ne s\'emboîte pas dans une autre', () {
    final range = AvatarEtPseudo.composer(pseudo: 'caro', image: photo);
    final encore = AvatarEtPseudo.composer(pseudo: 'caro', image: range);
    expect(encore, range);
  });

  test('le profil relit le pseudo et la photo rangés ensemble', () {
    final p = UserProfile.fromJson({
      'id': 'x',
      'display_name': 'Flavien',
      'avatar_url': AvatarEtPseudo.composer(pseudo: 'flavien', image: photo),
    });
    expect(p.username, 'flavien');
    expect(p.avatarUrl, photo);
  });

  testWidgets('l\'avatar d\'un ami affiche l\'image rangée avec son pseudo', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          OwnerAvatar(displayName: 'Caro', avatarUrl: AvatarEtPseudo.composer(pseudo: 'caro', image: 'emoji:🍷')),
          const OwnerAvatar(displayName: 'Paul', avatarUrl: 'meta://?u=paul'),
        ]),
      ),
    ));
    expect(find.text('🍷'), findsOneWidget);
    expect(find.text('P'), findsOneWidget, reason: 'sans image, l\'initiale');
  });
}
