/// Identifies the HealthKit writer from the provenance Apple Health reports.
/// A source may be an app or device; its name does not prove a specific watch.
class HealthSource {
  static const _prefix = 'healthkit:';

  // Older imports keep their keys so saved history remains readable.
  static const huawei = 'Huawei via Apple Health';
  static const garmin = 'Garmin via Apple Health';
  static const appleWatch = 'Apple Watch via Apple Health';
  static const _legacy = {huawei, garmin, appleWatch};

  static String? fromProvenance({required String name, required String id}) {
    final normalizedName = name.trim().toLowerCase();
    final normalizedId = id.trim().toLowerCase();
    if (normalizedName.isEmpty && normalizedId.isEmpty) return null;

    // Apple's generic Health bundle ID can also label phone-entered records.
    // Keep its named sources apart rather than treating them as one device.
    final identity = normalizedId.isEmpty || normalizedId == 'com.apple.health'
        ? '$normalizedId|$normalizedName'
        : normalizedId;
    return '$_prefix${Uri.encodeComponent(identity)}';
  }

  static bool isImported(String source) =>
      source.startsWith(_prefix) || _legacy.contains(source);

  static bool isLegacy(String source) => _legacy.contains(source);

  static String label(String source, {String? name, String? id}) {
    if (name != null && name.trim().isNotEmpty) return name.trim();
    if (id != null && id.trim().isNotEmpty) return id.trim();
    return isLegacy(source) ? source : 'Apple Health source';
  }
}
