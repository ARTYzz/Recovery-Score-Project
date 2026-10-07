import 'package:flutter/material.dart';
import '../app/boxer_controller.dart';
import 'screens/home_screens.dart';
import 'screens/log_screens.dart';
import 'screens/onboarding_screens.dart';
import 'screens/other_screens.dart';
import 'components.dart';
import 'design.dart';

class AppScreens extends StatelessWidget {
  const AppScreens({super.key, required this.controller});
  final BoxerController controller;
  @override
  Widget build(BuildContext context) {
    if (controller.busy) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final route = controller.route;
    final onboarding =
        ['setup', 'unlock', 'health-preview', 'baseline-intro'].contains(route);
    Widget content = switch (route) {
      'setup' => SetupScreen(controller),
      'unlock' => UnlockScreen(controller),
      'health-preview' => HealthPreviewScreen(controller),
      'baseline-intro' => BaselineIntroScreen(controller),
      'morning' => MorningScreen(controller),
      'today' => TodayScreen(controller),
      'feedback' => FeedbackScreen(controller),
      'guidance' => TrainingGuidanceScreen(controller),
      'training' => TrainingScreen(controller),
      'nutrition' => NutritionScreen(controller),
      'food-photo' => FoodScreen(controller),
      'fightcamp' => FightCampScreen(controller),
      'brain' => BrainScreen(controller),
      'tonight' => TonightScreen(controller),
      'camp' => CampScreen(controller),
      'trends' => TrendsScreen(controller),
      'settings' => SettingsScreen(controller),
      'connections' => ConnectionsScreen(controller),
      _ => TodayScreen(controller),
    };
    final nav = !onboarding &&
        route != 'morning' &&
        route != 'tonight' &&
        route != 'brain' &&
        route != 'feedback';
    return Scaffold(
      body: SafeArea(
          child: Column(children: [
        if (controller.error != null)
          MaterialBanner(
              content: Text(controller.error!),
              backgroundColor: const Color(0xffffe4e2),
              actions: [
                TextButton(
                    onPressed: () => controller.navigate(route),
                    child: const Text('Dismiss'))
              ]),
        Expanded(
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                child: content)),
      ])),
      bottomNavigationBar: nav
          ? SafeArea(
              top: false,
              child: NavBar(current: route, go: controller.navigate))
          : null,
      backgroundColor:
          route == 'tonight' ? const Color(0xff1c1d22) : AppColors.background,
    );
  }
}
