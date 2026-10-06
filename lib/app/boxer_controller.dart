import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/athlete_vault.dart';
import '../data/mock_sources.dart';
import '../domain/athlete_data.dart';
import '../domain/recovery_engine.dart';

class BoxerController extends ChangeNotifier {
  BoxerController({AthleteVault? vault}) : vault = vault ?? AthleteVault();

  final AthleteVault vault;
  final RecoveryEngine engine = RecoveryEngine();
  final FeedbackService feedback = FeedbackService();
  AthleteData? data;
  String route = 'setup';
  String? error;
  bool busy = true;

  Assessment? get assessment => data == null ? null : engine.assess(data!);

  Future<void> initialize() async {
    busy = true;
    notifyListeners();
    if (!await vault.exists()) {
      route = 'setup';
    } else if (await vault.demoAutoUnlockEnabled()) {
      try {
        await unlock('demo-passphrase');
      } catch (_) {
        route = 'unlock';
      }
    } else {
      route = 'unlock';
    }
    busy = false;
    notifyListeners();
  }

  void navigate(String target) {
    error = null;
    final current = data;
    if (current != null) {
      if (current.onboardingStage == 'connect') {
        route = 'baseline-intro';
      } else if (current.onboardingStage == 'ready') {
        route = 'baseline-intro';
      } else if (current.morningDue) {
        route = 'morning';
      } else {
        route = target;
      }
    } else {
      route = target;
    }
    notifyListeners();
  }

  void refreshDailyGate() {
    if (data?.morningDue == true) navigate('morning');
  }

  Future<void> createProfile(
      {required String name,
      required String fightDate,
      required String passphrase,
      required bool privacyAccepted,
      double? officialWeight}) async {
    if (name.trim().isEmpty) {
      throw const FormatException('Enter a display name.');
    }
    if (!CampClock.isFuture(fightDate)) {
      throw const FormatException('Choose a fight date in the future.');
    }
    if (!privacyAccepted) {
      throw const FormatException('Accept the Privacy Notice to continue.');
    }
    final athlete = AthleteData(
        profile: AthleteProfile(
            name: name.trim(),
            fightDate: fightDate,
            officialWeighInWeight: officialWeight),
        privacyAcceptedAt: DateTime.now().toIso8601String(),
        onboardingStage: 'ready');
    _addAutomaticDemoWearable(athlete);
    await vault.create(passphrase, athlete);
    data = athlete;
    navigate('baseline-intro');
  }

  Future<void> tryDemo() async {
    final athlete = const DemoDataFactory().create();
    await vault.create('demo-passphrase', athlete);
    data = athlete;
    navigate('today');
  }

  Future<void> unlock(String passphrase) async {
    data = await vault.unlock(passphrase);
    if (data!.mockOnly && data!.demoAnchorDay == null) {
      data!.demoAnchorDay = data!.latestCheckIn?.date ?? localDay();
    }
    if (data!.onboardingStage == 'connect') {
      _addAutomaticDemoWearable(data!);
      data!.onboardingStage = 'ready';
      await vault.save();
    }
    if (data!.healthAcceptedAt != null) {
      const MockFightCampSource().ensureDemoData(data!);
      await vault.save();
    }
    navigate('today');
  }

  void _addAutomaticDemoWearable(AthleteData athlete) {
    const source = MockHealthSource('mock');
    source.connect(athlete);
    source.sync(
        athlete,
        WearableSample(
            date: athlete.currentDay,
            source: source.sourceName,
            mode: 'DEMO',
            sleepMinutes: 437,
            hrv: 66,
            restingHr: 48,
            heartRate: 74,
            workoutMinutes: 52));
  }

  Future<void> start() async {
    final athlete = data!;
    athlete.onboardingStage = 'complete';
    const MockFightCampSource().ensureDemoData(athlete);
    await vault.save();
    navigate('morning');
  }

  Future<void> _persistAndGo(String destination) async {
    final athlete = data!;
    athlete.assessments
        .add(engine.assess(athlete).snapshot(athlete.currentDay));
    await vault.save();
    navigate(destination);
  }

  Future<void> saveMorning(MorningCheckIn check) async {
    final athlete = data!;
    athlete.saveMorning(check);
    final currentSamples =
        athlete.wearables.where((sample) => sample.date == check.date).toList();
    final today = currentSamples.isEmpty ? null : currentSamples.last;
    final priorSamples = athlete.wearables
        .where((sample) =>
            sample.date.compareTo(check.date) < 0 &&
            (today == null || sample.source == today.source))
        .toList();
    final prior = priorSamples.isEmpty ? null : priorSamples.last;
    final domains = engine
        .assess(athlete)
        .domains
        .map((key, value) => MapEntry(key, value.status));
    var linkedAction = false;
    for (final action in athlete.actions
        .where((e) => e.nextDay == null && e.date.compareTo(check.date) < 0)) {
      linkedAction = true;
      action.nextDay = {
        'hrvDelta': today?.hrv != null && prior?.hrv != null
            ? today!.hrv! - prior!.hrv!
            : null,
        'sleepMinutes': today?.sleepMinutes,
        'sleepDelta': today?.sleepMinutes != null && prior?.sleepMinutes != null
            ? today!.sleepMinutes! - prior!.sleepMinutes!
            : null,
        'restingHr': today?.restingHr,
        'restingHrDelta': today?.restingHr != null && prior?.restingHr != null
            ? today!.restingHr! - prior!.restingHr!
            : null,
        'mood': check.mood,
        'domains': domains,
      };
    }
    await _persistAndGo(linkedAction ? 'feedback' : 'today');
  }

  Future<void> saveTraining(TrainingSession session) async {
    data!.sessions.add(session);
    await _persistAndGo('nutrition');
  }

  Future<void> saveNutrition(NutritionCheck check) async {
    data!.nutrition.add(check);
    await _persistAndGo('today');
  }

  Future<void> saveFoodMeal(FoodMeal meal) async {
    data!.foodMeals.removeWhere((e) => e.id == meal.id);
    data!.foodMeals.add(meal);
    await _persistAndGo('food-photo');
  }

  Future<void> completeAction(DateTime startedAt) async {
    final action = assessment!.action;
    if (data!.actions.any(
        (entry) => entry.date == data!.currentDay && entry.id == action.id)) {
      navigate('today');
      return;
    }
    data!.actions.add(RecoveryActionLog(
        id: action.id,
        date: data!.currentDay,
        startedAt: startedAt.toIso8601String(),
        completedAt: DateTime.now().toIso8601String()));
    await _persistAndGo('today');
  }

  Future<void> updateProfile(AthleteProfile profile) async {
    if (!CampClock.isFuture(profile.fightDate)) {
      throw const FormatException('Choose a fight date in the future.');
    }
    data!.profile = profile;
    await _persistAndGo('camp');
  }

  Future<void> connectDemo(String kind) async {
    if (kind == 'mock') {
      _addAutomaticDemoWearable(data!);
      await _persistAndGo('connections');
      return;
    }
    if (data!.healthAcceptedAt == null) {
      throw const FormatException(
          'Grant local health-data consent before using demo data.');
    }
    MockHealthSource(kind).connect(data!);
    await _persistAndGo('connections');
  }

  Future<void> disconnectDemo(String kind) async {
    MockHealthSource(kind).disconnect(data!);
    await _persistAndGo('connections');
  }

  Future<void> revokeHealthConsent() async {
    final athlete = data!;
    athlete.healthAcceptedAt = null;
    athlete.wearables.clear();
    athlete.fightCampSessions.clear();
    athlete.connections['apple'] = 'DISCONNECTED';
    athlete.connections['android'] = 'DISCONNECTED';
    athlete.connections['fightcamp'] = 'DISCONNECTED';
    athlete.connections['mock'] = 'DISCONNECTED';
    await _persistAndGo('connections');
  }

  Future<void> seedHealthHistory(String kind) async {
    if (data!.healthAcceptedAt == null) {
      throw const FormatException(
          'Grant local health-data consent before using demo data.');
    }
    MockHealthSource(kind).seedHistory(data!);
    await _persistAndGo('connections');
  }

  Future<void> grantHealthConsent() async {
    data!.healthAcceptedAt = DateTime.now().toIso8601String();
    const MockFightCampSource().ensureDemoData(data!);
    await _persistAndGo('connections');
  }

  Future<void> toggleNotifications() async {
    data!.notifications = !data!.notifications;
    await _persistAndGo('settings');
  }

  Future<void> advanceMockDay() async {
    final athlete = data!;
    if (!athlete.mockOnly) return;
    if (!athlete.actions.any((action) => action.date == athlete.currentDay)) {
      throw const FormatException('Complete tonight’s recovery action first.');
    }
    final last = athlete.latestWearable;
    athlete.demoDayOffset += 1;
    if (athlete.healthAcceptedAt != null && last != null) {
      athlete.wearables.add(WearableSample(
          date: athlete.currentDay,
          source: 'Synthetic wearable demo',
          mode: 'DEMO',
          hrv: last.hrv == null ? null : last.hrv! + 5,
          restingHr: last.restingHr == null ? null : last.restingHr! - 2,
          sleepMinutes:
              last.sleepMinutes == null ? null : last.sleepMinutes! + 50,
          workoutMinutes: null));
    }
    await vault.save();
    navigate('morning');
  }

  Future<void> restartDemo() async {
    if (data?.mockOnly != true) return;
    final athlete = const DemoDataFactory().create();
    await vault.create('demo-passphrase', athlete);
    data = athlete;
    navigate('today');
  }

  void lock() {
    vault.lock();
    data = null;
    route = 'unlock';
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await vault.delete();
    data = null;
    route = 'setup';
    notifyListeners();
  }

  String newMealId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(999999)}';

  void showError(Object message) {
    error = message is FormatException ? message.message : message.toString();
    notifyListeners();
  }
}
