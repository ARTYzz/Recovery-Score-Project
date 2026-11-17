import 'package:boxer_recovery/domain/urine_colour.dart';
import 'package:boxer_recovery/ui/urine_colour_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('seven colours can be selected and the help guide opens',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var selected = UrineColour.yellow.code;
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('th'),
        supportedLocales: const [Locale('en'), Locale('th')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
            body: Padding(
                padding: const EdgeInsets.all(16),
                child: StatefulBuilder(
                    builder: (context, setState) => UrineColourPicker(
                        value: selected,
                        onChanged: (code) =>
                            setState(() => selected = code)))))));

    expect(find.byKey(const ValueKey('urine-yellow')), findsOneWidget);
    expect(find.byKey(const ValueKey('urine-tealGreen')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('urine-red')));
    await tester.pumpAndSettle();
    expect(selected, UrineColour.red.code);
    expect(find.text('สีแดง'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('ความหมายของสีปัสสาวะ'), findsOneWidget);
    expect(find.text('สีฟ้าหรือสีเขียว'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
