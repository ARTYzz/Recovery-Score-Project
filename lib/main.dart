import 'package:flutter/material.dart';
import 'app/boxer_controller.dart';
import 'ui/design.dart';
import 'ui/screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BoxerRecoveryApp());
}

class BoxerRecoveryApp extends StatefulWidget {
  const BoxerRecoveryApp({super.key});
  @override
  State<BoxerRecoveryApp> createState() => _BoxerRecoveryAppState();
}

class _BoxerRecoveryAppState extends State<BoxerRecoveryApp>
    with WidgetsBindingObserver {
  final BoxerController controller = BoxerController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) controller.refreshDailyGate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Boxer Recovery',
        debugShowCheckedModeBanner: false,
        theme: boxerTheme(),
        home: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: ClipRect(
                        child: AppScreens(
                            controller: controller,
                            key: ValueKey(controller.route)))))),
      );
}
