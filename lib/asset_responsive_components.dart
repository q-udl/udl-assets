part of 'main.dart';

/// Shared pager: controls move below the count at phone widths.
Widget responsiveAssetPager({
  required String description,
  required int perPage,
  required ValueChanged<int> onPerPage,
  required VoidCallback? onPrevious,
  required VoidCallback? onNext,
}) => LayoutBuilder(builder: (context, box) {
  final count = Text(description,
    style: const TextStyle(fontSize: 12, color: muted));
  final controls = Row(mainAxisSize: MainAxisSize.min, children: [
    DropdownButton<int>(
      value: perPage,
      items: [20, 40, 80].map((n) =>
        DropdownMenuItem(value: n, child: Text(n.toString() + ' / halaman')))
        .toList(),
      onChanged: (v) { if (v != null) onPerPage(v); },
    ),
    IconButton(
      tooltip: 'Halaman sebelumnya',
      onPressed: onPrevious,
      icon: const Icon(Icons.chevron_left_rounded)),
    IconButton(
      tooltip: 'Halaman berikutnya',
      onPressed: onNext,
      icon: const Icon(Icons.chevron_right_rounded)),
  ]);
  if (box.maxWidth < 520) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      count,
      const SizedBox(height: 2),
      Align(alignment: Alignment.centerRight, child: controls),
    ]);
  }
  return Row(children: [Expanded(child: count), controls]);
});
