part of 'main.dart';

/// RV29: A shared semantic vocabulary for action buttons and their labels.
enum AssetActionTone {
  primary, success, warning, danger, secondary, informational,
}

Color assetActionColor(AssetActionTone tone) => switch (tone) {
  AssetActionTone.primary => blue,
  AssetActionTone.success => const Color(0xFF168366),
  AssetActionTone.warning => amber,
  AssetActionTone.danger => danger,
  AssetActionTone.secondary => const Color(0xFF54667A),
  AssetActionTone.informational => blue,
};

Color assetConditionColor(String condition) => switch (condition) {
  'Baru' || 'Baik' => const Color(0xFF168366),
  'Cukup' || 'Kurang Baik' => amber,
  'Rusak' => danger,
  _ => muted,
};

ButtonStyle assetFilledStyle(AssetActionTone tone) {
  final secondary = tone == AssetActionTone.secondary;
  return FilledButton.styleFrom(
    backgroundColor: secondary
      ? const Color(0xFFEFF2F6) : assetActionColor(tone),
    foregroundColor: secondary ? const Color(0xFF54667A) : Colors.white,
    disabledBackgroundColor: const Color(0xFFE8EDF3),
    disabledForegroundColor: const Color(0xFF718199),
    minimumSize: const Size(0, 48),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}

ButtonStyle assetOutlinedStyle(AssetActionTone tone) {
  final secondary = tone == AssetActionTone.secondary;
  final tint = assetActionColor(tone);
  return OutlinedButton.styleFrom(
    foregroundColor: tint,
    backgroundColor: Colors.white,
    disabledForegroundColor: const Color(0xFF718199),
    minimumSize: const Size(0, 48),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    side: BorderSide(
      color: secondary ? border : tint.withValues(alpha: 0.35)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}

ButtonStyle assetTextStyle(AssetActionTone tone) => TextButton.styleFrom(
  foregroundColor: assetActionColor(tone),
  minimumSize: const Size(0, 48),
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);

Widget assetMenuActionLabel(String label, AssetActionTone tone) =>
  Text(label, style: TextStyle(
    color: assetActionColor(tone), fontWeight: FontWeight.w600));
