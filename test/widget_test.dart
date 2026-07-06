import 'package:flutter_test/flutter_test.dart';

import 'package:spike_dash_app/main.dart';

void main() {
  testWidgets('App inicializa corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(const SpikeDashApp());
    await tester.pumpAndSettle();

    // Verifica que a tela de autenticação é exibida
    expect(find.text('SPIKE'), findsOneWidget);
    expect(find.text('DASH'), findsOneWidget);
  });
}
