import 'dart:convert';
import 'dart:typed_data';

import 'package:boxer_recovery/app/boxer_controller.dart';
import 'package:boxer_recovery/data/athlete_backup.dart';
import 'package:boxer_recovery/data/athlete_store.dart';
import 'package:boxer_recovery/data/athlete_vault.dart';
import 'package:boxer_recovery/domain/athlete_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryAthleteStore implements AthleteStore {
  AthleteData? saved;
  String? password;
  bool failWrite = false;

  @override
  Future<bool> exists() async => saved != null;

  @override
  Future<AthleteData?> read(String passphrase) async {
    if (saved == null) return null;
    if (password != passphrase) throw StateError('Wrong key');
    return AthleteData.decode(saved!.encode());
  }

  @override
  Future<void> write(String passphrase, AthleteData athlete) async {
    if (failWrite) throw StateError('Write failed');
    password = passphrase;
    saved = AthleteData.decode(athlete.encode());
  }

  @override
  Future<void> delete() async {
    saved = null;
    password = null;
  }
}

AthleteData testAthlete() {
  final athlete = AthleteData(
      profile: AthleteProfile(name: 'Test boxer', fightDate: '2027-02-10'),
      onboardingStage: 'complete');
  athlete.saveMorning(
      MorningCheckIn(date: '2026-11-14', urine: 2, mood: 'OK', weight: 68.2));
  athlete.foodMeals.add(FoodMeal(
      id: 'meal-1',
      date: '2026-11-14',
      time: '12:00',
      mealType: 'Lunch',
      description: 'Rice',
      foodKey: 'rice',
      portions: 1,
      kcal: 100,
      protein: 2,
      carbs: 25,
      fat: 0,
      photoBase64: base64Encode([1, 2, 3, 4])));
  return athlete;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy encrypted data migrates and is verified before removal',
      () async {
    SharedPreferences.setMockInitialValues({});
    final athlete = testAthlete();
    await AthleteVault().create('local-passphrase', athlete);
    expect(
        (await SharedPreferences.getInstance())
            .containsKey(AthleteVault.storageKey),
        isTrue);

    final store = MemoryAthleteStore();
    final migrated =
        await AthleteVault(store: store).unlock('local-passphrase');
    expect(migrated.encode(), athlete.encode());
    expect(store.saved!.foodMeals.single.photoBase64,
        athlete.foodMeals.single.photoBase64);
    expect(
        (await SharedPreferences.getInstance())
            .containsKey(AthleteVault.storageKey),
        isFalse);
    final reopened =
        await AthleteVault(store: store).unlock('local-passphrase');
    expect(reopened.encode(), athlete.encode());
  });

  test('failed migration leaves the old encrypted account available', () async {
    SharedPreferences.setMockInitialValues({});
    await AthleteVault().create('local-passphrase', testAthlete());
    final store = MemoryAthleteStore()..failWrite = true;
    await expectLater(AthleteVault(store: store).unlock('local-passphrase'),
        throwsStateError);
    expect(
        (await SharedPreferences.getInstance())
            .containsKey(AthleteVault.storageKey),
        isTrue);
    expect((await AthleteVault().unlock('local-passphrase')).profile!.name,
        'Test boxer');
  });

  test('backup is encrypted, tamper checked, and restores history', () async {
    final backup = AthleteBackup();
    final athlete = testAthlete();
    final bytes = await backup.export(athlete, 'backup-passphrase');
    expect(utf8.decode(bytes), isNot(contains('Test boxer')));
    expect((await backup.restore(bytes, 'backup-passphrase')).encode(),
        athlete.encode());
    await expectLater(
        backup.restore(bytes, 'wrong-passphrase'), throwsFormatException);
    final damaged = Uint8List.fromList(bytes);
    damaged[damaged.length - 20] ^= 1;
    await expectLater(
        backup.restore(damaged, 'backup-passphrase'), throwsFormatException);
  });

  test('restoring a backup never restores wearable permission status',
      () async {
    SharedPreferences.setMockInitialValues({});
    final store = MemoryAthleteStore();
    final vault = AthleteVault(store: store);
    await vault.create('local-passphrase', testAthlete());
    final restored = testAthlete()
      ..connections['apple'] = 'CONNECTED'
      ..healthAcceptedAt = '2026-11-14T10:00:00';
    final controller = BoxerController(vault: vault)..data = vault.data;
    await controller.restoreBackup(restored);
    expect(controller.data!.connections['apple'], 'DISCONNECTED');
    expect(controller.data!.healthAcceptedAt, isNull);
    expect(
        (await AthleteVault(store: store).unlock('local-passphrase'))
            .checkins
            .single
            .weight,
        68.2);
  });

  test('a new mobile account can be created from an encrypted backup',
      () async {
    SharedPreferences.setMockInitialValues({});
    final bytes =
        await AthleteBackup().export(testAthlete(), 'backup-passphrase');
    final store = MemoryAthleteStore();
    final controller = BoxerController(vault: AthleteVault(store: store));
    final restored = await controller.decodeBackup(bytes, 'backup-passphrase');
    await controller.restoreNewAccount(restored, 'new-local-passphrase');
    expect(controller.data!.foodMeals.single.photoBase64,
        base64Encode([1, 2, 3, 4]));
    expect(
        (await AthleteVault(store: store).unlock('new-local-passphrase'))
            .profile!
            .name,
        'Test boxer');
  });
}
