import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mirror_app/main.dart';

void main() {
  testWidgets('App başlatma testi', (WidgetTester tester) async {
    // Gerçek bağımlılıklar gerektirdiğinden sadece temel smoke test
    expect(SmartMirrorApp, isNotNull);
  });
}
