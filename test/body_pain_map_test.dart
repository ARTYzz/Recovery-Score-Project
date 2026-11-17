import 'package:boxer_recovery/ui/body_pain_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('body map selects and clears front and back locations',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final selected = <String>{};
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
      return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: BodyPainMap(
              selected: selected,
              onToggle: (area) => setState(() {
                    if (!selected.add(area)) selected.remove(area);
                  })));
    }))));

    await tester.tap(find.byKey(const ValueKey('body-Shoulders')));
    await tester.pumpAndSettle();
    expect(selected, contains('Shoulders'));

    await tester.tap(find.text('Back view'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('body-Lower back')));
    await tester.pumpAndSettle();
    expect(selected, containsAll(['Shoulders', 'Lower back']));

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();
    expect(selected.length, 1);
    expect(tester.takeException(), isNull);
  });
}
