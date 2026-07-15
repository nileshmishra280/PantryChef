import 'package:flutter_test/flutter_test.dart';
import 'package:pantrychef/main.dart';

void main() {
  testWidgets('shows PantryChef home screen', (tester) async {
    await tester.pumpWidget(const PantryChefApp());

    expect(find.text('PantryChef'), findsWidgets);
    expect(find.text('Cook Now'), findsOneWidget);
  });
}
