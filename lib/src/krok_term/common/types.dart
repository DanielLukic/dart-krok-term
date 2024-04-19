import 'package:collection/collection.dart';

/// Simplified type for JSON list. Mostly to document intent.
typedef JsonList = List<dynamic>;

/// Simplified type for JSON objects/maps. Mostly to document intent.
typedef JsonObject = Map<String, dynamic>;

/// Attempt at simplifying the pair vs pair name vs wsname handling. Consider
/// this a first step in the right(?) direction.
extension type AssetPair._(String _wsname) {
  AssetPair.fromWsName(String wsname)
      : assert(wsname.contains("/")),
        _wsname = wsname;

  String get wsname => _wsname;
}

/// To handle "proper" equality checks on all models, this base class
/// requires each model to provide all data [fields]. It implements
/// [hashCode], [==] and [toString] using [DeepCollectionEquality] on the
/// this list of [fields].
abstract class BaseModel {
  List<dynamic> get fields;

  @override
  int get hashCode => Object.hashAll(fields);

  @override
  bool operator ==(Object other) {
    if (other is! BaseModel) return false;
    return DeepCollectionEquality().equals(fields, other.fields);
  }

  @override
  String toString() => fields.toString();
}
