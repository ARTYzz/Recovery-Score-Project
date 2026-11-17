/// Stable codes for the seven visual choices in the morning check-in.
/// Values 1–5 belong to the previous yellow-shade scale and remain readable.
enum UrineColour {
  yellow(11),
  red(12),
  purple(13),
  brown(14),
  cloudyGrey(15),
  orange(16),
  tealGreen(17);

  const UrineColour(this.code);
  final int code;

  static UrineColour? fromCode(int code) {
    for (final colour in values) {
      if (colour.code == code) return colour;
    }
    return null;
  }

  static bool isLegacyDark(int code) => code == 4 || code == 5;

  /// An unusual hue is not, by itself, a measure of hydration.
  static double? fuelScore(int code) {
    if (code == yellow.code) return 100;
    if (code >= 1 && code <= 2) return 100;
    if (code == 3) return 85;
    if (code == 4) return 55;
    if (code == 5) return 20;
    return null;
  }

  bool get isUnusual => this != yellow;
  bool get mayLookLikeBlood => this == red || this == brown;
}
