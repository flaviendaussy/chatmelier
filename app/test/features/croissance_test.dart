import 'package:chatmelier/shared/services/croissance.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le chemin d'un invité web jusqu'à l'app (V2.3 · J6).
void main() {
  test('le lien mène au Play Store de Chatmelier, avec sa provenance', () {
    final lien = Uri.parse(Croissance.lienPlayStore(source: 'page_invite', tableCode: 'KYZ3YZ'));
    expect(lien.host, 'play.google.com');
    expect(lien.queryParameters['id'], 'com.chatmelier.chatmelier');
    expect(lien.queryParameters['referrer'], 'utm_source=page_invite&utm_campaign=KYZ3YZ');
  });

  test('sans session ni Supabase, noter ne lève rien', () async {
    await Croissance.noter('clic_installer', source: 'page_invite');
  });
}
