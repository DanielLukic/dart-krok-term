import 'package:krok_term/src/krok_term/repository/assets_repo.dart';
import 'package:test/test.dart';

void main() {
  test('AssetData equals', () {
    final a = AssetData.from("name", "altname", 1, 2);
    final b = AssetData.from("name", "altname", 1, 2);
    expect(a.name, equals(b.name));
    expect(a.altname, equals(b.altname));
    expect(a.decimals, equals(b.decimals));
    expect(a.display, equals(b.display));
    expect(a, equals(b));
  });
}
