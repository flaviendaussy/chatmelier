import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Une erreur due au réseau, et non au serveur (V2.5 · Q2).
///
/// La création d'une cave basculait « hors ligne » sur n'importe quelle erreur, y compris un
/// refus du serveur (une colonne absente jusqu'à la migration 074) : la cave n'existait que
/// sur le téléphone, sous un identifiant que personne d'autre ne connaissait. Seule une
/// coupure justifie désormais le repli hors ligne ; un refus se dit.
bool estUneCoupureReseau(Object erreur) {
  if (erreur is TimeoutException || erreur is http.ClientException || erreur is AuthRetryableFetchException) {
    return true;
  }
  final texte = erreur.toString();
  const signes = [
    'SocketException', 'Failed host lookup', 'Connection refused', 'Connection closed', 'Connection reset',
    'Network is unreachable', 'HandshakeException', 'XMLHttpRequest error', 'Failed to fetch', 'ClientException',
  ];
  return signes.any(texte.contains);
}
