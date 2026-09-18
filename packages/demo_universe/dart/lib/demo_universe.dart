import 'dart:convert';

import 'universe_json.dart';

/// Loads the shared offline demo universe JSON (same graph as the TS package).
///
/// Default [load] uses the embedded [kUniverseJson] so Flutter web/Chrome works
/// without `dart:io`. The filesystem copy under `data/universe.json` remains
/// the authoring source of truth (regenerate `universe_json.dart` after edits).
class DemoUniverse {
  DemoUniverse._(this.data);

  final Map<String, dynamic> data;

  /// Deep-cloned universe from the embedded seed (web-safe).
  static DemoUniverse load({String? json}) {
    return fromJsonString(json ?? kUniverseJson);
  }

  static DemoUniverse fromJsonString(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return DemoUniverse._(_deepCloneMap(decoded));
  }

  List<dynamic> get customers => data['customers'] as List<dynamic>? ?? const [];
  List<dynamic> get wallets => data['wallets'] as List<dynamic>? ?? const [];
  List<dynamic> get agents => data['agents'] as List<dynamic>? ?? const [];
  List<dynamic> get employers => data['employers'] as List<dynamic>? ?? const [];
  List<dynamic> get journals => data['journals'] as List<dynamic>? ?? const [];
  List<dynamic> get loans => data['loans'] as List<dynamic>? ?? const [];
  List<dynamic> get pendingApprovals =>
      data['pendingApprovals'] as List<dynamic>? ?? const [];
  List<dynamic> get cases => data['cases'] as List<dynamic>? ?? const [];

  static Map<String, dynamic> _deepCloneMap(Map<String, dynamic> src) {
    return jsonDecode(jsonEncode(src)) as Map<String, dynamic>;
  }
}
