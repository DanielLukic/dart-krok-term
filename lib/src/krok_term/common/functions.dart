import 'extensions.dart';

String joinPath(List<String> elements) => elements.joinPath();

List<(A, B)> zip<A, B>(List<A> a, List<B> b) =>
    [for (int i = 0; i < a.length; i++) (a[i], b[i])];
