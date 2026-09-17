import 'dart:convert';
import 'dart:io';

/// Loads the shared offline demo universe JSON (same file as the TS package).
///
/// Prefer [DemoUniverse.loadFromFile] pointing at
/// `packages/demo_universe/data/universe.json` (single source of truth).
/// A synced copy also lives at `dart/assets/universe.json` for asset bundling.
class DemoUniverse {
  DemoUniverse._(this.data);

  final Map<String, dynamic> data;

  /// Deep-cloned universe from a filesystem path.
  static DemoUniverse loadFromFile(String path) {
    final raw = File(path).readAsStringSync();
    return fromJsonString(raw);
  }

  /// Default relative load from package layout (data/ sibling of dart/).
  static DemoUniverse load({String? path}) {
    final resolved = path ?? _defaultDataPath();
    return loadFromFile(resolved);
  }

  static DemoUniverse fromJsonString(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return DemoUniverse._(_deepCloneMap(decoded));
  }

  static String _defaultDataPath() {
    // When running from packages/demo_universe/dart, sibling is ../data/universe.json
    final candidates = <String>[
      '../data/universe.json',
      'data/universe.json',
      'assets/universe.json',
      'packages/demo_universe/data/universe.json',
    ];
    for (final c in candidates) {
      if (File(c).existsSync()) return c;
    }
    throw StateError(
      'universe.json not found. Pass an absolute path to DemoUniverse.load(path: ...).',
    );
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
