part of 'main.dart';

/// RV28 adaptive modal shell: header/footer stay reachable; only body scrolls.
/// Outside clicks never discard data. Device Back / X prompt when isDirty.
extension _AssetV4Modal on _AssetScreenState {
  Future<T?> v4ShowModal<T>({
    required String title,
    String? subtitle,
    double maxWidth = 520,
    bool Function()? isDirty,
    required Widget Function(BuildContext, StateSetter) body,
    required List<Widget> Function(BuildContext, StateSetter) actions,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, update) {
          final size = MediaQuery.sizeOf(ctx);
          final keyboard = MediaQuery.viewInsetsOf(ctx).bottom;
          final mobile = size.width < 650;
          final width = size.width < maxWidth + (mobile ? 24 : 40)
              ? size.width - (mobile ? 24 : 32) : maxWidth;
          final height = (size.height - keyboard -
              (mobile ? 20 : 42)).clamp(150.0, size.height);
          final buttons = actions(ctx, update);
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                assetRequestModalClose(ctx, isDirty: isDirty);
              }
            },
            child: Dialog(
              key: const ValueKey('rv28-adaptive-modal'),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 10,
              insetPadding: EdgeInsets.symmetric(
                horizontal: mobile ? 12 : 16,
                vertical: mobile ? 10 : 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(mobile ? 16 : 18),
                side: const BorderSide(color: Color(0xFFE3EAF2)),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: width,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: height),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          mobile ? 16 : 24, mobile ? 14 : 18,
                          mobile ? 8 : 13, mobile ? 13 : 17),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: TextStyle(
                                  color: ink, fontSize: mobile ? 18 : 20,
                                  fontWeight: FontWeight.w800)),
                                if (subtitle != null && subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(subtitle, style: const TextStyle(
                                    color: muted, fontSize: 12.5)),
                                ],
                              ],
                            )),
                            IconButton(
                              key: const ValueKey('rv28-modal-close'),
                              tooltip: 'Tutup',
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => assetRequestModalClose(
                                ctx, isDirty: isDirty),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: border),
                      Flexible(
                        fit: FlexFit.loose,
                        child: SingleChildScrollView(
                          key: const ValueKey('rv28-modal-scroll'),
                          keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            mobile ? 16 : 24, mobile ? 16 : 20,
                            mobile ? 16 : 24, mobile ? 16 : 20),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: body(ctx, update),
                          ),
                        ),
                      ),
                      if (buttons.isNotEmpty) ...[
                        const Divider(height: 1, color: border),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            mobile ? 12 : 20, 11,
                            mobile ? 12 : 20, mobile ? 12 : 14),
                          child: mobile
                            ? Column(
                                key: const ValueKey('rv28-modal-mobile-actions'),
                                crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                children: [
                                  for (final action in buttons.reversed) ...[
                                    SizedBox(
                                      height: 48,
                                      width: double.infinity,
                                      child: action),
                                    if (action != buttons.first)
                                      const SizedBox(height: 8),
                                  ],
                                ],
                              )
                            : Align(
                                alignment: Alignment.centerRight,
                                child: Wrap(
                                  spacing: 8, runSpacing: 8,
                                  alignment: WrapAlignment.end,
                                  children: buttons),
                              ),
                        ),
                      ],
                    ],
                  ),
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
