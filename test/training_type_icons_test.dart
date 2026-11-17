import 'package:boxer_recovery/app/boxer_controller.dart';
import 'package:boxer_recovery/domain/athlete_data.dart';
import 'package:boxer_recovery/ui/screens/log_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('training types show distinct icons and keep selection working',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = BoxerController()..data = AthleteData();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TrainingScreen(controller)))));

    expect(find.byIcon(Icons.sports_mma_outlined), findsOneWidget);
    expect(find.byIcon(Icons.gps_fixed_outlined), findsOneWidget);
    expect(find.byIcon(Icons.directions_run_outlined), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center_outlined), findsOneWidget);
    expect(find.text('ROUNDS'), findsOneWidget);

    await tester.tap(find.text('Conditioning'));
    await tester.pumpAndSettle();
    expect(find.text('DURATION'), findsOneWidget);
    expect(find.text('ROUNDS'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
