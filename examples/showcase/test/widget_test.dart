import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

import 'package:reacton_showcase/app.dart';

void main() {
  testWidgets('Showcase app renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      ReactonScope(child: const ShowcaseApp()),
    );

    // Verify the app shell renders with the first page (Counter).
    expect(find.text('Counter'), findsWidgets);
  });
}
