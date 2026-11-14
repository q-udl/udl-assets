part of 'main.dart';

/// Shared confirmation surface for the local UDL Assets preview.
///
/// A destructive decision intentionally emphasizes the SAFE action. Dialogs do
/// not dismiss on outside taps, so losing input is never an accidental tap.
Future<bool> assetConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Batal',
  bool destructive = false,
  IconData? icon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final screen = MediaQuery.sizeOf(dialogContext);
      final mobile = screen.width < 650;
      final safeAction = OutlinedButton(
        key: const ValueKey('rv28-dialog-safe'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: blue),
        onPressed: () => Navigator.pop(dialogContext, false),
        child: Text(cancelLabel, textAlign: TextAlign.center));
      final safePrimary = FilledButton(
        key: const ValueKey('rv28-dialog-safe'),
        style: FilledButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48)),
        onPressed: () => Navigator.pop(dialogContext, false),
        child: Text(cancelLabel, textAlign: TextAlign.center));
      final proceed = destructive
        ? OutlinedButton(
            key: const ValueKey('rv28-dialog-destructive'),
            style: OutlinedButton.styleFrom(
              foregroundColor: danger,
              side: const BorderSide(color: danger),
              minimumSize: const Size(0, 48)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel, textAlign: TextAlign.center))
        : FilledButton(
            key: const ValueKey('rv28-dialog-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel, textAlign: TextAlign.center));
      final actionButtons = destructive
          ? <Widget>[safePrimary, proceed]
          : <Widget>[proceed, safeAction];
      return Dialog(
        key: const ValueKey('rv28-confirm-dialog'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(
          horizontal: mobile ? 16 : 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 450,
            maxHeight: screen.height * .88),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(mobile ? 18 : 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    height: 42, width: 42,
                    decoration: BoxDecoration(
                      color: destructive ? const Color(0xFFFFF3F0) :
                        const Color(0xFFEDF4FC),
                      borderRadius: BorderRadius.circular(11)),
                    child: Icon(icon ?? (destructive
                      ? Icons.warning_amber_rounded : Icons.help_outline_rounded),
                      color: destructive ? danger : blue, size: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(title, style: TextStyle(
                      fontSize: mobile ? 17 : 19, color: ink,
                      fontWeight: FontWeight.w800)))),
                ]),
                const SizedBox(height: 14),
                Text(message, style: const TextStyle(
                  color: ink, fontSize: 13.5, height: 1.5)),
                const SizedBox(height: 20),
                if (mobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final button in actionButtons) ...[
                        SizedBox(height: 48, width: double.infinity,
                          child: button),
                        if (button != actionButtons.last)
                          const SizedBox(height: 9),
                      ],
                    ],
                  )
                else
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 9,
                    runSpacing: 8,
                    children: destructive
                      ? <Widget>[proceed, safePrimary]
                      : <Widget>[safeAction, proceed]),
              ],
            ),
          ),
        ),
      );
    },
  );
  return result == true;
}

/// Used by both page-level navigation and modal X/Batal/system-back actions.
Future<bool> assetAllowDiscard(
    BuildContext context, {required bool isDirty}) async {
  if (!isDirty) return true;
  return assetConfirmDialog(
    context,
    title: 'Tinggalkan formulir?',
    message: 'Perubahan yang belum disimpan akan hilang '
      'jika Anda meninggalkan formulir ini.',
    cancelLabel: 'Tetap di Formulir',
    confirmLabel: 'Tinggalkan Tanpa Menyimpan',
    destructive: true);
}


/// Common close action for editable modals. Never blindly discard typed data.
Future<void> assetRequestModalClose(
    BuildContext context, {bool Function()? isDirty}) async {
  final allowed = await assetAllowDiscard(
    context, isDirty: isDirty?.call() ?? false);
  if (allowed && context.mounted) Navigator.of(context).pop();
}
