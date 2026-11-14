part of 'main.dart';

/// Shared pager with a compact phone layout and separate count line.
Widget responsiveAssetPager({
  required String description,
  required int perPage,
  required ValueChanged<int> onPerPage,
  required VoidCallback? onPrevious,
  required VoidCallback? onNext,
}) => LayoutBuilder(builder: (context, box) {
  final count = Text(description,
    style: const TextStyle(fontSize: 12, color: muted));
  final compact = box.maxWidth < 520;
  final dropdown = DropdownButton<int>(
    value: perPage,
    isDense: compact,
    iconSize: compact ? 18 : 24,
    underline: compact ? const SizedBox.shrink() : null,
    items: [20, 40, 80].map((n) => DropdownMenuItem(
      value: n,
      child: Text(compact ? n.toString() : n.toString() + ' / halaman'),
    )).toList(),
    onChanged: (v) { if (v != null) onPerPage(v); },
  );
  Widget navButton(String tooltip, VoidCallback? onPressed, IconData icon) =>
    IconButton(
      tooltip: tooltip, onPressed: onPressed,
      icon: Icon(icon, size: compact ? 20 : 24),
      padding: compact ? EdgeInsets.zero : const EdgeInsets.all(8),
      constraints: compact ?
        const BoxConstraints(minWidth: 38, minHeight: 40) : null,
    );
  final prev = navButton('Halaman sebelumnya',
    onPrevious, Icons.chevron_left_rounded);
  final next = navButton('Halaman berikutnya',
    onNext, Icons.chevron_right_rounded);
  if (compact) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      count,
      const SizedBox(height: 5),
      Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          const Text('Per halaman',
            style: TextStyle(fontSize: 11, color: muted)),
          dropdown,
          prev,
          next,
        ],
      ),
    ]);
  }
  return Row(children: [
    Expanded(child: count),
    dropdown, prev, next,
  ]);
});

/// Compact row shared between custody views. Unlike a large ListTile card,
/// it gives photo, identity, metadata and navigation a stable desktop alignment
/// while stacking secondary details on phone-sized viewports.
Widget compactCustodyAssetRow({
  required String name,
  required String code,
  required String condition,
  required String accessories,
  required String status,
  required AssetPhoto? photo,
  required VoidCallback onTap,
}) => LayoutBuilder(builder: (context, bounds) {
  final mobile = bounds.maxWidth < 540;
  final tone = switch (status) {
    'Aktif' || 'Dikembalikan' => const Color(0xFF168366),
    'Dibatalkan' => danger,
    'Menunggu Serah Terima' => amber,
    _ => muted,
  };
  final badge = Container(
    constraints: const BoxConstraints(maxWidth: 165),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: tone.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(20)),
    child: Text(status, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 10.5, color: tone,
        fontWeight: FontWeight.w700)),
  );
  final thumbnail = ClipRRect(
    borderRadius: BorderRadius.circular(9),
    child: Container(
      height: 52, width: 52, color: const Color(0xFFF1F5FA),
      alignment: Alignment.center,
      child: photo == null
        ? const Icon(Icons.inventory_2_outlined, color: blue, size: 25)
        : Image.memory(photo.bytes, width: 52, height: 52,
            fit: BoxFit.cover),
    ),
  );
  final content = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: ink, fontSize: 13, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(code, style: const TextStyle(
        fontSize: 11.5, color: blue, fontWeight: FontWeight.w600)),
      const SizedBox(height: 3),
      Text('Kondisi: ' + condition +
        (accessories.isEmpty ? '' : ' · ' + accessories),
        maxLines: mobile ? 3 : 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: muted)),
      if (mobile) ...[
        const SizedBox(height: 7),
        badge,
      ],
    ],
  );
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      hoverColor: const Color(0xFFEDF5FE),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 11),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: border))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            thumbnail, const SizedBox(width: 12),
            Expanded(child: content),
            if (!mobile) ...[
              const SizedBox(width: 12), badge,
            ],
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
              size: 19, color: muted),
          ],
        ),
      ),
    ),
  );
});
