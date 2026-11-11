import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'resources/register_intervention_resource.dart';

/// Interventions registered without connection, persisted on the phone so they
/// survive closing the app (US-31). Replayed oldest first.
class OfflineInterventionQueue {
  static const String _key = 'icetrack.pending_interventions';

  Future<List<RegisterInterventionResource>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => RegisterInterventionResource.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> add(RegisterInterventionResource resource) async {
    final items = await readAll();
    // One pending intervention per request: a newer one replaces the older.
    items.removeWhere((i) => i.serviceRequestId == resource.serviceRequestId);
    items.add(resource);
    await _write(items);
  }

  Future<void> remove(String clientGeneratedId) async {
    final items = await readAll();
    items.removeWhere((i) => i.clientGeneratedId == clientGeneratedId);
    await _write(items);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _write(List<RegisterInterventionResource> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((i) => i.toJson()).toList()));
  }
}
