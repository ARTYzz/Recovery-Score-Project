import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/athlete_vault.dart';
import '../data/fightcamp_demo_source.dart';
import '../data/huawei_apple_health_source.dart';
import '../domain/athlete_data.dart';
import '../domain/recovery_engine.dart';

class BoxerController extends ChangeNotifier {
  BoxerController({AthleteVault? vault}) : vault = vault ?? AthleteVault();

  final AthleteVault vault;
  final RecoveryEngine engine = RecoveryEngine();
  final FeedbackService feedback = FeedbackService();
  final HuaweiAppleHealthSource huaweiHealth = HuaweiAppleHealthSource();
  AthleteData? data;
  String route = 'setup';
  String? error;
  bool busy = true;
  bool _syncingHuawei = false;

  Assessment? get assessment => data == null ? null : engine.assess(data!);

  Future<void> initialize() async {
    busy = true;
    notifyListeners();
    if (!await vault.exists()) {
      route = 'setup';
    } else if (await vault.demoAutoUnlockEnabled()) {
      // An old demonstration account has a synthetic profile and history.
      // Creating a real profile replaces it; nothing is deleted on app open.
      route = 'setup';
      error =
          'The old synthetic demo account is retired. Create your real athlete profile to replace it.';
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
      if (current.onboardingStage == 'sources') {
        route = 'health-preview';
      } else if (current.onboardingStage == 'connect') {
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
    if (data?.connections['apple'] == 'CONNECTED') syncHuaweiHealth();
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
        onboardingStage: 'sources');
    await vault.create(passphrase, athlete);
    data = athlete;
    navigate('health-preview');
  }

  Future<void> unlock(String passphrase) async {
    data = await vault.unlock(passphrase);
    if (data!.onboardingStage == 'connect') {
      data!.onboardingStage = 'ready';
    }
    _removeLegacySyntheticHealth(data!);
    if (data!.connections['apple'] == 'CONNECTED') {
      await syncHuaweiHealth();
    }
    if (data!.onboardingStage == 'complete') {
      const MockFightCampSource().ensureDemoData(data!);
    }
    await vault.save();
    navigate('today');
  }

  void _removeLegacySyntheticHealth(AthleteData athlete) {
    athlete.wearables.removeWhere((sample) => sample.mode == 'DEMO');
    for (final kind in ['apple', 'android', 'mock']) {
      if (athlete.connections[kind] == 'MOCK_CONNECTED') {
        athlete.connections.remove(kind);
      }
    }
    athlete.connections.remove('android');
    athlete.connections.remove('mock');
    if (athlete.schemaVersion < 2) {
      // Historical evaluations and next-day comparisons could contain fake
      // wearable values even if demo samples were removed during a prior live
      // connection. Preserve the athlete's actual manual and live records.
      athlete.assessments.clear();
      for (final action in athlete.actions) {
        action.nextDay = null;
      }
      athlete.schemaVersion = 2;
    }
  }

  Future<void> start() async {
    final athlete = data!;
    athlete.onboardingStage = 'complete';
    const MockFightCampSource().ensureDemoData(athlete);
    await vault.save();
    navigate('morning');
  }

  Future<void> continueFromHealthPreview() async {
    final athlete = data!;
    if (athlete.onboardingStage != 'sources') return;
    athlete.onboardingStage = 'ready';
    await vault.save();
    navigate('baseline-intro');
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

  Future<void> connectHuaweiHealth() async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final samples = await huaweiHealth.connect();
      if (samples.isEmpty) {
        throw const FormatException(
            'No Huawei records were readable in Apple Health. Check Apple Health data sources and Boxer Recovery read permissions on your iPhone.');
      }
      final athlete = data!;
      athlete.healthAcceptedAt = DateTime.now().toIso8601String();
      athlete.connections['apple'] = 'CONNECTED';
      athlete.wearables.removeWhere((sample) =>
          sample.mode == 'DEMO' ||
          sample.source == HuaweiAppleHealthSource.sourceName);
      athlete.wearables.addAll(samples);
      athlete.wearables.sort((a, b) => a.date.compareTo(b.date));
      await vault.save();
    } catch (e) {
      showError(e);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> syncHuaweiHealth() async {
    if (_syncingHuawei || data?.connections['apple'] != 'CONNECTED') return;
    _syncingHuawei = true;
    busy = true;
    notifyListeners();
    try {
      final samples = await huaweiHealth.sync();
      final athlete = data!;
      if (samples.isEmpty) {
        athlete.connections['apple'] = 'DISCONNECTED';
        athlete.healthAcceptedAt = null;
        error =
            'No Huawei records are readable now. Check Apple Health read access.';
      }
      athlete.wearables.removeWhere(
          (sample) => sample.source == HuaweiAppleHealthSource.sourceName);
      athlete.wearables.addAll(samples);
      athlete.wearables.sort((a, b) => a.date.compareTo(b.date));
      await vault.save();
    } catch (e) {
      showError(e);
    } finally {
      _syncingHuawei = false;
      busy = false;
      notifyListeners();
    }
  }

  Future<void> disconnectHuaweiHealth() async {
    final athlete = data!;
    athlete.connections['apple'] = 'DISCONNECTED';
    athlete.healthAcceptedAt = null;
    athlete.wearables.removeWhere(
        (sample) => sample.source == HuaweiAppleHealthSource.sourceName);
    await _persistAndGo('connections');
  }

  Future<void> toggleNotifications() async {
    data!.notifications = !data!.notifications;
    await _persistAndGo('settings');
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
