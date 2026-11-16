/// HealthKit provenance labels used for imported, device-originated records.
/// These are Apple Health sources, not direct vendor API connections.
class HealthSource {
  static const huawei = 'Huawei via Apple Health';
  static const garmin = 'Garmin via Apple Health';
  static const appleWatch = 'Apple Watch via Apple Health';
  static const supported = [huawei, garmin, appleWatch];

  static bool isSupported(String source) => supported.contains(source);
}
