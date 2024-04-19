/// Simplified type for JSON list. Mostly to document intent.
typedef JsonList = List<dynamic>;

/// Simplified type for JSON objects/maps. Mostly to document intent.
typedef JsonObject = Map<String, dynamic>;

extension type AssetPair(String _wsname) {
  AssetPair.fromWsName(String wsname)
      : assert(wsname.contains("/")),
        _wsname = wsname;

  String get wsname => _wsname;
}
