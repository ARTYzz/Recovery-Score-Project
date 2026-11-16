import '../domain/athlete_data.dart';

/// The mobile implementation uses encrypted SQLite. Browser and desktop
/// previews keep the older preference store, never a second mobile database.
abstract class AthleteStore {
  Future<bool> exists();
  Future<AthleteData?> read(String passphrase);
  Future<void> write(String passphrase, AthleteData athlete);
  Future<void> delete();
}
