import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/athlete_vault.dart';
import '../data/athlete_backup.dart';
import '../data/fightcamp_demo_source.dart';
import '../data/apple_health_source.dart';
import '../data/wearable_history_merger.dart';
import '../domain/athlete_data.dart';
import '../domain/head_safety_tracker.dart';
import '../domain/health_source.dart';
import '../domain/recovery_engine.dart';

class BoxerController extends ChangeNotifier {
  BoxerController({AthleteVault? vault, AppleHealthSource? appleHealth})
      : vault = vault ?? AthleteVault(),
        appleHealth = appleHealth ?? AppleHealthSource();

  final AthleteVault vault;
  final AthleteBackup backups = AthleteBackup();
  final RecoveryEngine engine = RecoveryEngine();
  final FeedbackService feedback = FeedbackService();
  final AppleHealthSource appleHealth;
  static const _appleHealthHistory = WearableHistoryMerger();
  AthleteData? data;
  String route = 'setup';
  String? error;
  bool busy = true;
  bool _syncingAppleHealth = false;

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

  Future<void> refreshDailyGate() async {
    if (data?.profile?.archiveExpiredFight() == true) {
      try {
        await vault.save();
        notifyListeners();
      } catch (e) {
        showError(e);
      }
    }
    if (data?.morningDue == true) navigate('morning');
    if (data?.connections['apple'] == 'CONNECTED') syncAppleHealth();
  }

  Future<void> createProfile(
      {required String name,
      String? fightDate,
      required String passphrase,
      required bool privacyAccepted,
      double? currentWeight,
      double? heightCm,
      double? targetWeight}) async {
    if (fightDate?.trim().isEmpty == true) fightDate = null;
    final profile = AthleteProfile(
        name: name.trim(),
        fightDate: fightDate,
        currentWeight: currentWeight,
        heightCm: heightCm,
        targetWeight: targetWeight);
    _validateProfile(profile);
    if (!privacyAccepted) {
      throw const FormatException('Accept the Privacy Notice to continue.');
    }
    final athlete = AthleteData(
        profile: profile,
        privacyAcceptedAt: DateTime.now().toIso8601String(),
        onboardingStage: 'sources');
    await vault.create(passphrase, athlete);
    data = athlete;
    navigate('health-preview');
  }

  Future<void> unlock(String passphrase) async {
    data = await vault.unlock(passphrase);
    data!.profile?.archiveExpiredFight();
    if (data!.onboardingStage == 'connect') {
      data!.onboardingStage = 'ready';
    }
    _removeLegacySyntheticHealth(data!);
    if (data!.connections['apple'] == 'CONNECTED') {
      await syncAppleHealth();
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
    if (check.date == athlete.currentDay && check.weight != null) {
      athlete.profile?.currentWeight = check.weight;
    }
    final currentSamples = athlete.activeWearables
        .where((sample) => sample.date == check.date)
        .toList();
    final today = currentSamples.isEmpty ? null : currentSamples.last;
    final priorSamples = athlete.activeWearables
        .where((sample) =>
            sample.date.compareTo(check.date) < 0 &&
            (today == null || sample.source == today.source))
        .toList();
    final prior = priorSamples.isEmpty ? null : priorSamples.last;
    final currentAssessment = engine.assess(athlete);
    final domains = currentAssessment.domains
        .map((key, value) => MapEntry(key, value.status));
    var linkedAction = false;
    for (final action in athlete.actions.where((e) =>
        e.nextDay == null &&
        parsedDay(check.date) != null &&
        parsedDay(e.date) != null &&
        parsedDay(check.date)!.difference(parsedDay(e.date)!).inDays == 1)) {
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
        'targetDomain': action.targetDomain,
        'targetScore': action.targetDomain == null
            ? null
            : currentAssessment.domains[action.targetDomain]?.score,
        'targetScoreDelta': action.targetScore == null ||
                action.targetDomain == null ||
                currentAssessment.domains[action.targetDomain]?.score == null
            ? null
            : currentAssessment.domains[action.targetDomain]!.score! -
                action.targetScore!,
      };
    }
    await _persistAndGo(linkedAction ? 'feedback' : 'today');
  }

  Future<void> saveTraining(TrainingSession session) async {
    data!.sessions.add(session);
    await _persistAndGo('nutrition');
  }

  Future<void> recordExternalHeadPlan() async {
    final athlete = data!;
    final head = HeadSafetyTracker(athlete);
    final incident = head.latestIncidentDate;
    if (incident == null || !head.needsProfessionalFollowUp) {
      throw const FormatException(
          'No unresolved head-impact report was found.');
    }
    athlete.headSafetyReviews.add(HeadSafetyReview(
        incidentDate: incident, recordedAt: DateTime.now().toIso8601String()));
    await _persistAndGo('brain');
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
        completedAt: DateTime.now().toIso8601String(),
        targetDomain: assessment!.limiter ?? 'sleep',
        targetScore:
            assessment!.domains[assessment!.limiter ?? 'sleep']?.score));
    await _persistAndGo('today');
  }

  Future<void> updateProfile(AthleteProfile profile) async {
    if (profile.fightDate?.trim().isEmpty == true) profile.fightDate = null;
    _validateProfile(profile);
    final history = data!.profile?.pastFightPlans ?? [];
    if (profile.pastFightPlans.isEmpty && history.isNotEmpty) {
      profile.pastFightPlans.addAll(history);
    }
    data!.profile = profile;
    await _persistAndGo('settings');
  }

  void _validateProfile(AthleteProfile profile) {
    if (profile.name.trim().isEmpty) {
      throw const FormatException('Enter a display name.');
    }
    if (profile.fightDate != null &&
        profile.fightDate!.isNotEmpty &&
        !CampClock.isFuture(profile.fightDate)) {
      throw const FormatException('Choose a fight date in the future.');
    }
    if (profile.currentWeight == null ||
        !profile.currentWeight!.isFinite ||
        profile.currentWeight! <= 0) {
      throw const FormatException('Enter a valid current weight in kg.');
    }
    if (profile.heightCm == null ||
        !profile.heightCm!.isFinite ||
        profile.heightCm! <= 0) {
      throw const FormatException('Enter a valid height in cm.');
    }
    if (profile.targetWeight != null &&
        (!profile.targetWeight!.isFinite || profile.targetWeight! <= 0)) {
      throw const FormatException('Enter a valid target weight in kg.');
    }
  }

  Future<void> connectAppleHealth() async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final samples = await appleHealth.connect();
      if (samples.isEmpty) {
        throw const FormatException(
            'No records with an identifiable source were readable in Apple Health. Check the Health app data sources and Boxer Recovery read permissions.');
      }
      final athlete = data!;
      athlete.healthAcceptedAt = DateTime.now().toIso8601String();
      athlete.connections['apple'] = 'CONNECTED';
      athlete.wearables.removeWhere((sample) => sample.mode == 'DEMO');
      _appleHealthHistory.merge(athlete, samples);
      final selected = athlete.connections['healthSource'];
      if (selected == null ||
          !samples.any((sample) => sample.source == selected)) {
        athlete.connections.remove('healthSource');
        athlete.connections['healthSource'] =
            athlete.activeHealthSource ?? samples.last.source;
      }
      await vault.save();
    } catch (e) {
      showError(e);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> syncAppleHealth() async {
    if (_syncingAppleHealth || data?.connections['apple'] != 'CONNECTED') {
      return;
    }
    _syncingAppleHealth = true;
    busy = true;
    notifyListeners();
    try {
      final samples = await appleHealth.sync();
      final athlete = data!;
      if (samples.isEmpty) {
        error =
            'No records with an identifiable source were readable in this sync. Saved history is unchanged; check Apple Health data and read access.';
      } else {
        error = null;
        _appleHealthHistory.merge(athlete, samples);
        final selected = athlete.connections['healthSource'];
        if (selected == null ||
            (HealthSource.isLegacy(selected) &&
                !samples.any((sample) => sample.source == selected))) {
          athlete.connections.remove('healthSource');
          athlete.connections['healthSource'] =
              athlete.activeHealthSource ?? samples.last.source;
        }
        await vault.save();
      }
    } catch (e) {
      showError(e);
    } finally {
      _syncingAppleHealth = false;
      busy = false;
      notifyListeners();
    }
  }

  Future<void> disconnectAppleHealth() async {
    final athlete = data!;
    athlete.connections['apple'] = 'DISCONNECTED';
    athlete.healthAcceptedAt = null;
    athlete.wearables
        .removeWhere((sample) => HealthSource.isImported(sample.source));
    athlete.connections.remove('healthSource');
    await _persistAndGo('connections');
  }

  Future<void> selectHealthSource(String source) async {
    if (!HealthSource.isImported(source) ||
        !data!.wearables.any((sample) => sample.source == source)) {
      throw const FormatException(
          'This health source has no imported records.');
    }
    data!.connections['healthSource'] = source;
    await _persistAndGo('connections');
  }

  Future<void> toggleNotifications() async {
    data!.notifications = !data!.notifications;
    await _persistAndGo('settings');
  }

  Future<Uint8List> exportBackup(String passphrase) async {
    if (data == null) throw StateError('Unlock the app first.');
    return backups.export(data!, passphrase);
  }

  Future<AthleteData> decodeBackup(Uint8List bytes, String passphrase) =>
      backups.restore(bytes, passphrase);

  void _resetRestoredHealthConnection(AthleteData restored) {
    // Permissions never travel with a backup, even when past samples do.
    restored.connections['apple'] = 'DISCONNECTED';
    restored.connections['android'] = 'DISCONNECTED';
    restored.healthAcceptedAt = null;
  }

  Future<void> restoreNewAccount(
      AthleteData restored, String localPassphrase) async {
    _resetRestoredHealthConnection(restored);
    await vault.create(localPassphrase, restored);
    data = restored;
    navigate('today');
  }

  Future<void> restoreBackup(AthleteData restored) async {
    _resetRestoredHealthConnection(restored);
    await vault.replace(restored);
    data = restored;
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
