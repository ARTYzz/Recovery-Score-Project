import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the database key in the device's protected credential store.
/// Backup files use a separate passphrase chosen only when exporting them.
abstract class DeviceCredentialStore {
  Future<String?> read();
  Future<void> write(String key);
  Future<void> delete();
}

class SecureDeviceCredentialStore implements DeviceCredentialStore {
  const SecureDeviceCredentialStore();

  static const _key = 'boxer_athlete_database_key_v1';
  static const _storage = FlutterSecureStorage();
  static const _ios =
      IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device);

  @override
  Future<String?> read() => _storage.read(key: _key, iOptions: _ios);

  @override
  Future<void> write(String key) =>
      _storage.write(key: _key, value: key, iOptions: _ios);

  @override
  Future<void> delete() => _storage.delete(key: _key, iOptions: _ios);
}
