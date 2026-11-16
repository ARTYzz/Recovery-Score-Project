import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/athlete_data.dart';
import 'athlete_store.dart';
import 'native_athlete_store_stub.dart'
    if (dart.library.io) 'native_athlete_store_io.dart' as native_store;

/// Mobile SQLCipher vault with a legacy encrypted-preferences reader for
/// migration and browser previews. Credentials remain in memory until lock.
class AthleteVault {
  AthleteVault({AthleteStore? store})
      : _native = store ?? native_store.createNativeAthleteStore();

  static const storageKey = 'boxer-flutter-v1';
  static const demoKey = 'boxer-flutter-demo-v1';
  final AesGcm _cipher = AesGcm.with256bits();
  SecretKey? _key;
  List<int>? _salt;
  String? _passphrase;
  final AthleteStore? _native;
  AthleteData? data;

  Future<bool> exists() async =>
      (await _native?.exists() ?? false) ||
      (await SharedPreferences.getInstance()).containsKey(storageKey);

  Future<bool> demoAutoUnlockEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(demoKey) == true;

  Future<SecretKey> _derive(String passphrase, List<int> salt) {
    final pbkdf2 =
        Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 210000, bits: 256);
    return pbkdf2.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  List<int> _randomBytes(int count) {
    final random = Random.secure();
    return List<int>.generate(count, (_) => random.nextInt(256));
  }

  Future<void> create(String passphrase, AthleteData athlete) async {
    if (passphrase.length < 8) {
      throw const FormatException(
          'Use at least 8 characters for the local passphrase.');
    }
    final store = _native;
    if (store != null) {
      if (await store.exists()) await store.delete();
      try {
        await store.write(passphrase, athlete);
        final verified = await store.read(passphrase);
        if (verified?.encode() != athlete.encode()) {
          throw StateError('Could not verify the new encrypted database.');
        }
      } catch (_) {
        await store.delete();
        rethrow;
      }
      _passphrase = passphrase;
      data = athlete;
      await (await SharedPreferences.getInstance()).remove(storageKey);
    } else {
      _salt = _randomBytes(16);
      _key = await _derive(passphrase, _salt!);
      data = athlete;
      await save();
    }
    await (await SharedPreferences.getInstance()).remove(demoKey);
  }

  Future<AthleteData> unlock(String passphrase) async {
    final store = _native;
    if (store != null) {
      try {
        if (await store.exists()) {
          final athlete = await store.read(passphrase);
          if (athlete != null) {
            _passphrase = passphrase;
            data = athlete;
            await (await SharedPreferences.getInstance()).remove(storageKey);
            return athlete;
          }
        }
      } catch (_) {
        throw const FormatException(
            'Passphrase is incorrect or data is damaged.');
      }
      // An older release kept one encrypted JSON blob in preferences. Keep it
      // until the new database round-trips successfully.
      final athlete = await _unlockLegacy(passphrase);
      try {
        await store.write(passphrase, athlete);
        final verified = await store.read(passphrase);
        if (verified?.encode() != athlete.encode()) {
          throw StateError(
              'Migration verification failed; original data kept.');
        }
      } catch (_) {
        await store.delete();
        rethrow;
      }
      _passphrase = passphrase;
      _key = null;
      _salt = null;
      await (await SharedPreferences.getInstance()).remove(storageKey);
      return athlete;
    }
    return _unlockLegacy(passphrase);
  }

  Future<AthleteData> _unlockLegacy(String passphrase) async {
    final encoded =
        (await SharedPreferences.getInstance()).getString(storageKey);
    if (encoded == null) {
      throw const FormatException('No athlete profile found.');
    }
    try {
      final record = jsonDecode(encoded) as Map<String, dynamic>;
      final salt = base64Decode(record['salt'] as String);
      final key = await _derive(passphrase, salt);
      final box = SecretBox(
        base64Decode(record['cipher'] as String),
        nonce: base64Decode(record['iv'] as String),
        mac: Mac(base64Decode(record['mac'] as String)),
      );
      final plain = await _cipher.decrypt(box, secretKey: key);
      final athlete = AthleteData.decode(utf8.decode(plain));
      _salt = salt;
      _key = key;
      data = athlete;
      return athlete;
    } catch (_) {
      throw const FormatException(
          'Passphrase is incorrect or data is damaged.');
    }
  }

  Future<void> save() async {
    final store = _native;
    if (store != null) {
      if (_passphrase == null || data == null) {
        throw StateError('Vault is locked.');
      }
      await store.write(_passphrase!, data!);
      return;
    }
    final key = _key;
    final athlete = data;
    if (key == null || athlete == null || _salt == null) {
      throw StateError('Vault is locked.');
    }
    final iv = _randomBytes(12);
    final box = await _cipher.encrypt(utf8.encode(athlete.encode()),
        secretKey: key, nonce: iv);
    await (await SharedPreferences.getInstance()).setString(
        storageKey,
        jsonEncode({
          'version': 1,
          'salt': base64Encode(_salt!),
          'iv': base64Encode(iv),
          'cipher': base64Encode(box.cipherText),
          'mac': base64Encode(box.mac.bytes),
        }));
  }

  /// Replace a whole athlete only after the chosen backend commits and verifies
  /// the restored data. The in-memory account stays usable if writing fails.
  Future<void> replace(AthleteData athlete) async {
    final previous = data;
    if (previous == null) throw StateError('Vault is locked.');
    data = athlete;
    try {
      await save();
      final store = _native;
      final restored = store == null
          ? await _readSavedLegacy()
          : await store.read(_passphrase!);
      if (restored?.encode() != athlete.encode()) {
        throw StateError('Restored data could not be verified.');
      }
    } catch (_) {
      data = previous;
      await save();
      rethrow;
    }
  }

  Future<AthleteData?> _readSavedLegacy() async {
    final encoded =
        (await SharedPreferences.getInstance()).getString(storageKey);
    if (encoded == null || _key == null) return null;
    final record = jsonDecode(encoded) as Map<String, dynamic>;
    final plain = await _cipher.decrypt(
        SecretBox(base64Decode(record['cipher'] as String),
            nonce: base64Decode(record['iv'] as String),
            mac: Mac(base64Decode(record['mac'] as String))),
        secretKey: _key!);
    return AthleteData.decode(utf8.decode(plain));
  }

  void lock() {
    _key = null;
    _salt = null;
    _passphrase = null;
    data = null;
  }

  Future<void> delete() async {
    await _native?.delete();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
    await prefs.remove(demoKey);
    lock();
  }
}
