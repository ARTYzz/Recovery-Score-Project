import 'package:boxer_recovery/ui/nutrition_check_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('nutrition check records three answers on a phone-sized screen',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? meal;
    String? protein;
    String? carbs;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
      return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: NutritionCheckForm(
              meal: meal,
              protein: protein,
              carbs: carbs,
              onMeal: (v) => setState(() => meal = v),
              onProtein: (v) => setState(() => protein = v),
              onCarbs: (v) => setState(() => carbs = v)));
    }))));

    await tester.tap(find.text('Yes').first);
    await tester.tap(find.text('No').last);
    await tester.tap(find.text('Medium'));
    await tester.pumpAndSettle();

    expect(meal, 'Yes');
    expect(protein, 'No');
    expect(carbs, 'Medium');
    expect(tester.takeException(), isNull);
  });
}
