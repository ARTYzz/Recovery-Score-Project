import 'package:boxer_recovery/app/boxer_controller.dart';
import 'package:boxer_recovery/data/athlete_vault.dart';
import 'package:boxer_recovery/data/device_credential_store.dart';
import 'package:boxer_recovery/domain/athlete_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryDeviceCredentials implements DeviceCredentialStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String key) async => value = key;
  @override
  Future<void> delete() async => value = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new account opens on the device without a local passphrase', () async {
    SharedPreferences.setMockInitialValues({});
    final credentials = MemoryDeviceCredentials();
    final controller = BoxerController(deviceCredentials: credentials);
    await controller.initialize();
    await controller.createProfile(
        name: 'Boxer', privacyAccepted: true, currentWeight: 73, heightCm: 175);
    expect(credentials.value, isNotNull);
    expect(credentials.value!.length, greaterThanOrEqualTo(32));
    await controller.continueFromHealthPreview();
    await controller.start();
    await controller.saveMorning(
        MorningCheckIn(date: localDay(), weight: 73, urine: 2, mood: 'OK'));

    final reopened = BoxerController(deviceCredentials: credentials);
    await reopened.initialize();
    expect(reopened.route, 'today');
    expect(reopened.data!.checkins.single.weight, 73);
    expect(
        (await SharedPreferences.getInstance())
            .getBool(BoxerController.deviceKeyMarker),
        isTrue);
  });

  test('old account asks once and then opens with protected device key',
      () async {
    SharedPreferences.setMockInitialValues({});
    await AthleteVault()
        .create('old-passphrase', AthleteData(onboardingStage: 'complete'));
    final credentials = MemoryDeviceCredentials();
    final controller = BoxerController(deviceCredentials: credentials);
    await controller.initialize();
    expect(controller.route, 'unlock');
    await controller.unlock('old-passphrase', rememberOnDevice: true);
    expect(credentials.value, 'old-passphrase');

    final reopened = BoxerController(deviceCredentials: credentials);
    await reopened.initialize();
    expect(reopened.route, 'morning');
    expect(reopened.data, isNotNull);
  });

  test('missing device key preserves encrypted data for recovery', () async {
    SharedPreferences.setMockInitialValues({});
    final credentials = MemoryDeviceCredentials();
    final controller = BoxerController(deviceCredentials: credentials);
    await controller.initialize();
    await controller.createProfile(
        name: 'Boxer', privacyAccepted: true, currentWeight: 73, heightCm: 175);
    final originalKey = credentials.value!;
    await credentials.delete();

    final reopened = BoxerController(deviceCredentials: credentials);
    await reopened.initialize();
    expect(reopened.route, 'device-recovery');
    expect(reopened.data, isNull);
    expect((await AthleteVault().unlock(originalKey)).profile!.name, 'Boxer');
  });
}
