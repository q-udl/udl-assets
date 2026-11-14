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
