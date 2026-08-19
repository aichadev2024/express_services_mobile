// Basic smoke test: the app boots to the role selector screen.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:express_services_mobile/main.dart';

void main() {
  testWidgets('App boots and shows the role selector', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ExpressServicesApp()));
    await tester.pump();

    expect(find.text('Livreur'), findsOneWidget);
    expect(find.text('Partenaire résident'), findsOneWidget);
    expect(find.text('Particulier'), findsOneWidget);
  });
}
