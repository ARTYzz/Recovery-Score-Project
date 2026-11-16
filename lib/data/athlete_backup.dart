import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../domain/athlete_data.dart';

/// Portable, passphrase-protected backup. No account or network service is used.
class AthleteBackup {
  static const maxBytes = 128 * 1024 * 1024;
  final AesGcm _cipher = AesGcm.with256bits();

  Future<Uint8List> export(AthleteData athlete, String passphrase) async {
    _validatePassphrase(passphrase);
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final key = await _derive(passphrase, salt);
    final box = await _cipher.encrypt(utf8.encode(athlete.encode()),
        secretKey: key, nonce: nonce);
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({
      'format': 'boxer-recovery-backup',
      'version': 1,
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    })));
    if (bytes.length > maxBytes) {
      throw const FormatException('Backup is too large to export.');
    }
    return bytes;
  }

  Future<AthleteData> restore(Uint8List bytes, String passphrase) async {
    _validatePassphrase(passphrase);
    if (bytes.length > maxBytes) {
      throw const FormatException('Backup file is too large.');
    }
    try {
      final record = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (record['format'] != 'boxer-recovery-backup' ||
          record['version'] != 1) {
        throw const FormatException('Unsupported backup format.');
      }
      final salt = base64Decode(record['salt'] as String);
      final nonce = base64Decode(record['nonce'] as String);
      final mac = base64Decode(record['mac'] as String);
      if (salt.length != 16 || nonce.length != 12 || mac.length != 16) {
        throw const FormatException('Backup file is damaged.');
      }
      final key = await _derive(passphrase, salt);
      final plain = await _cipher.decrypt(
          SecretBox(base64Decode(record['ciphertext'] as String),
              nonce: nonce, mac: Mac(mac)),
          secretKey: key);
      final athlete = AthleteData.decode(utf8.decode(plain));
      if (athlete.profile == null) {
        throw const FormatException('Backup has no athlete profile.');
      }
      return athlete;
    } catch (_) {
      throw const FormatException(
          'Cannot open backup. Check the file and backup passphrase.');
    }
  }

  Future<SecretKey> _derive(String passphrase, List<int> salt) =>
      Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 210000, bits: 256)
          .deriveKeyFromPassword(password: passphrase, nonce: salt);

  List<int> _randomBytes(int count) {
    final random = Random.secure();
    return List.generate(count, (_) => random.nextInt(256));
  }

  void _validatePassphrase(String passphrase) {
    if (passphrase.length < 8) {
      throw const FormatException(
          'Use at least 8 characters for the backup passphrase.');
    }
  }
}
