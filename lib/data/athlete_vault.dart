import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/athlete_data.dart';

/// Encrypted local-only athlete store. The derived key stays in memory until lock.
class AthleteVault {
  static const storageKey = 'boxer-flutter-v1';
  static const demoKey = 'boxer-flutter-demo-v1';
  final AesGcm _cipher = AesGcm.with256bits();
  SecretKey? _key;
  List<int>? _salt;
  AthleteData? data;

  Future<bool> exists() async =>
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
    _salt = _randomBytes(16);
    _key = await _derive(passphrase, _salt!);
    data = athlete;
    await save();
    await (await SharedPreferences.getInstance())
        .setBool(demoKey, athlete.mockOnly);
  }

  Future<AthleteData> unlock(String passphrase) async {
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

  void lock() {
    _key = null;
    _salt = null;
    data = null;
  }

  Future<void> delete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
    await prefs.remove(demoKey);
    lock();
  }
}
