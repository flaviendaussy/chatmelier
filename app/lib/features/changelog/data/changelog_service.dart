import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/changelog_entry.dart';

final changelogServiceProvider = Provider<ChangelogService>((ref) {
  return ChangelogService();
});

final changelogsFutureProvider = FutureProvider<List<ChangelogEntry>>((ref) async {
  final service = ref.watch(changelogServiceProvider);
  return service.loadChangelogs();
});

class ChangelogService {
  Future<List<ChangelogEntry>> loadChangelogs() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/changelogs.json');
      final List<dynamic> data = jsonDecode(jsonString);
      return data.map((e) => ChangelogEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}
