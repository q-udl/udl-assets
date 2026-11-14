part of 'main.dart';

/// Consistent desktop/mobile modal chrome for all v0.4 operational actions.
/// Header and footer stay visible; only the content scrolls.
extension _AssetV4Modal on _AssetScreenState {
  Future<T?> v4ShowModal<T>({
    required String title,
    String? subtitle,
    double maxWidth = 520,
    required Widget Function(BuildContext, StateSetter) body,
    required List<Widget> Function(BuildContext, StateSetter) actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, update) {
          final size = MediaQuery.sizeOf(ctx);
          final width = size.width < maxWidth + 40
              ? size.width - 32
              : maxWidth;
          return Dialog(
            backgroundColor: Colors.white,
            elevation: 12,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE3EAF2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: width,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: size.height * 0.85),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 13, 17),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(
                                  color: ink, fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                )),
                                if (subtitle != null && subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(subtitle, style: const TextStyle(
                                    color: muted, fontSize: 12.5,
                                  )),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Tutup',
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: border),
                    Flexible(
                      fit: FlexFit.loose,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: body(ctx, update),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: border),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          for (final action in actions(ctx, update)) ...[
                            const SizedBox(width: 8),
                            action,
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration v4ModalDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      alignLabelWithHint: true,
      filled: true,
      fillColor: const Color(0xFFFAFCFE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
    );
  }

  Widget v4ModalPair(Widget first, Widget second, {double breakpoint = 575}) {
    return LayoutBuilder(builder: (ctx, box) {
      if (box.maxWidth < breakpoint) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, const SizedBox(height: 15), second],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 14),
          Expanded(child: second),
        ],
      );
    });
  }

  Widget v4ReadonlyField(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minHeight: 55),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(9),
        color: const Color(0xFFF4F7FB),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: muted)),
          const SizedBox(height: 3),
          Text(value.isEmpty ? 'Belum ditetapkan' : value,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: ink,
              fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget v4ModalError(String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4F3),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: danger, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
          style: const TextStyle(color: danger, fontSize: 12))),
      ],
    ),
  );
}
