import 'package:boxer_recovery/app/boxer_controller.dart';
import 'package:boxer_recovery/ui/app_text.dart' as app;
import 'package:boxer_recovery/ui/screens/other_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('selected language survives controller restart', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = BoxerController();
    await controller.initialize();
    expect(controller.languageCode, 'en');
    await controller.setLanguage('th');
    expect(controller.languageCode, 'th');

    final reopened = BoxerController();
    await reopened.initialize();
    expect(reopened.languageCode, 'th');
    await reopened.setLanguage('en');
    expect((await SharedPreferences.getInstance()).getString('boxer_language'),
        'en');
  });

  testWidgets('visible app copy changes when locale changes', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        locale: Locale('en'),
        supportedLocales: [Locale('en'), Locale('th')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: app.Text('Today'))));
    expect(find.text('Today'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(
        locale: Locale('th'),
        supportedLocales: [Locale('en'), Locale('th')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: app.Text('Today'))));
    expect(find.text('วันนี้'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('Settings language control changes the displayed language',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = BoxerController();
    await controller.initialize();
    await tester.pumpWidget(AnimatedBuilder(
        animation: controller,
        builder: (context, _) => MaterialApp(
            locale: Locale(controller.languageCode),
            supportedLocales: const [Locale('en'), Locale('th')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
                body: SizedBox(
                    width: 390,
                    child: SingleChildScrollView(
                        child: LanguageSelector(controller)))))));
    expect(find.text('LANGUAGE'), findsOneWidget);
    await tester.tap(find.text('ไทย'));
    await tester.pumpAndSettle();
    expect(controller.languageCode, 'th');
    expect(find.text('ภาษา'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
