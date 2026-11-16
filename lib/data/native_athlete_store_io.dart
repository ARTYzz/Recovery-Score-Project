import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../domain/athlete_data.dart';
import 'athlete_store.dart';

AthleteStore? createNativeAthleteStore() =>
    Platform.isIOS || Platform.isAndroid ? SqlCipherAthleteStore() : null;

/// A single athlete database whose changes commit atomically. Photos are BLOBs
/// in encrypted rows, rather than Base64 inside the profile JSON document.
class SqlCipherAthleteStore implements AthleteStore {
  Future<String> get _path async {
    final directory = await getApplicationSupportDirectory();
    return '${directory.path}${Platform.pathSeparator}boxer_athlete.db';
  }

  @override
  Future<bool> exists() async => File(await _path).exists();

  Future<Database> _open(String passphrase) async => openDatabase(
        await _path,
        password: passphrase,
        version: 1,
        onCreate: (db, _) async {
          await db.execute(
              'CREATE TABLE athlete_root (id INTEGER PRIMARY KEY CHECK (id = 1), payload TEXT NOT NULL)');
          await db.execute(
              'CREATE TABLE athlete_records (kind TEXT NOT NULL, position INTEGER NOT NULL, payload TEXT NOT NULL, photo BLOB, PRIMARY KEY (kind, position))');
        },
      );

  @override
  Future<AthleteData?> read(String passphrase) async {
    if (!await exists()) return null;
    final db = await _open(passphrase);
    try {
      final roots =
          await db.query('athlete_root', columns: ['payload'], limit: 1);
      if (roots.isEmpty) return null;
      final root =
          jsonDecode(roots.single['payload'] as String) as Map<String, dynamic>;
      final rows =
          await db.query('athlete_records', orderBy: 'kind ASC, position ASC');
      for (final row in rows) {
        final kind = row['kind'] as String;
        final value =
            jsonDecode(row['payload'] as String) as Map<String, dynamic>;
        if (kind == 'foodMeals' && row['photo'] != null) {
          value['photoBase64'] = base64Encode(row['photo'] as List<int>);
        }
        root.putIfAbsent(kind, () => <dynamic>[]);
        (root[kind] as List<dynamic>).add(value);
      }
      return AthleteData.fromJson(root);
    } finally {
      await db.close();
    }
  }

  @override
  Future<void> write(String passphrase, AthleteData athlete) async {
    final root = athlete.toJson();
    final records = <(String, int, String, Uint8List?)>[];
    for (final kind in const [
      'wearables',
      'checkins',
      'headSafetyReviews',
      'sessions',
      'nutrition',
      'foodMeals',
      'fightCampSessions',
      'actions',
      'assessments'
    ]) {
      final items = root.remove(kind) as List<dynamic>? ?? [];
      for (var i = 0; i < items.length; i++) {
        final item = Map<String, dynamic>.from(items[i] as Map);
        Uint8List? photo;
        if (kind == 'foodMeals') {
          final encoded = item.remove('photoBase64') as String?;
          if (encoded != null) photo = base64Decode(encoded);
        }
        records.add((kind, i, jsonEncode(item), photo));
      }
    }
    final db = await _open(passphrase);
    try {
      await db.transaction((txn) async {
        await txn.delete('athlete_records');
        await txn.insert('athlete_root', {'id': 1, 'payload': jsonEncode(root)},
            conflictAlgorithm: ConflictAlgorithm.replace);
        final batch = txn.batch();
        for (final row in records) {
          batch.insert('athlete_records', {
            'kind': row.$1,
            'position': row.$2,
            'payload': row.$3,
            'photo': row.$4,
          });
        }
        await batch.commit(noResult: true);
      });
    } finally {
      await db.close();
    }
  }

  @override
  Future<void> delete() async {
    await deleteDatabase(await _path);
  }
}
