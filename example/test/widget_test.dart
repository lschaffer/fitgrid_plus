import 'package:flutter_test/flutter_test.dart';

import 'package:fitgrid_plus_example/main.dart';

void main() {
  testWidgets('FitGridPlusShowcaseApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FitGridPlusShowcaseApp());
    await tester.pumpAndSettle();

    // Verify that the showcase app renders with the flagship demo.
    expect(find.byType(FitGridPlusShowcaseApp), findsOneWidget);
    expect(find.text('Flagship Superstore Grid'), findsOneWidget);
  });
}
