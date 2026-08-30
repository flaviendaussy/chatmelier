import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/match_result.dart';

class CheckoutService {
  final SupabaseClient _client;
  CheckoutService(this._client);

  Future<List<MatchResult>> matchByPhoto(String photoUrl) async {
    final res = await _client.functions.invoke('match-bottle', body: {'photoUrl': photoUrl});
    return (res.data as List).map((j) => MatchResult.fromJson(j)).toList();
  }

  Future<void> consumeBottle(String bottleId, Map<String, dynamic> tastingData) async {
    await _client.from('bottles').update({'status': 'consumed'}).eq('id', bottleId);
    await _client.from('tasting_log').insert(tastingData);
  }
}
