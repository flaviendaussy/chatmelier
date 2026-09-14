import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/auth_repository.dart';
import 'supabase_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseProvider));
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.session?.user ?? ref.watch(supabaseProvider).auth.currentUser;
});

/// Statut administrateur, **décidé par le serveur**.
///
/// Lit `profiles.is_admin`, une colonne que l'utilisateur peut lire mais jamais écrire
/// (triggers `protect_is_admin` — migration 029). Remplace l'ancien test client
/// `kDebugMode || email.contains('flavien')`, qui accordait les privilèges admin à
/// quiconque s'inscrivait avec une adresse contenant « flavien ».
///
/// Ferme par défaut : toute erreur, absence de session ou profil manquant donne `false`.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  try {
    final row = await ref
        .watch(supabaseProvider)
        .from('profiles')
        .select('is_admin')
        .eq('id', user.id)
        .maybeSingle();
    return row?['is_admin'] == true;
  } catch (_) {
    // Colonne absente (migration 029 non appliquée), hors ligne, RLS : on ferme.
    return false;
  }
});
