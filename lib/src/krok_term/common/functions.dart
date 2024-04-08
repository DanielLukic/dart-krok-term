import 'extensions.dart';

String joinPath(List<String> elements) => elements.joinPath();

List<dynamic> listIn(dynamic it, String key) =>
    (it as Map<String, dynamic>)[key] as List<dynamic>;

List<(A, B)> zip<A, B>(List<A> a, List<B> b) =>
    [for (int i = 0; i < a.length; i++) (a[i], b[i])];
