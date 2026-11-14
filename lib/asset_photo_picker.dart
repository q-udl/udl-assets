part of 'main.dart';

enum AssetPhotoSource { camera, gallery, file }

class SelectedAssetPhoto {
  final Uint8List bytes;
  final String fileName;
  final int originalBytes;
  const SelectedAssetPhoto(this.bytes, this.fileName, this.originalBytes);
}

/// Pure Dart validation and compression before browser-local storage.
class AssetPhotoProcessing {
  static const maxInputBytes = 15 * 1024 * 1024;

  static SelectedAssetPhoto normalize(Uint8List input, String name) {
    if (input.isEmpty || input.length > maxInputBytes) {
      throw const FormatException('Foto kosong atau melebihi 15 MB.');
    }
    final jpeg = input.length > 3 &&
      input[0] == 255 && input[1] == 216 && input[2] == 255;
    final png = input.length > 8 &&
      input[0] == 137 && input[1] == 80 && input[2] == 78;
    final webp = input.length > 12 &&
      String.fromCharCodes(input.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(input.sublist(8, 12)) == 'WEBP';
    if (!jpeg && !png && !webp) {
      throw const FormatException('Hanya JPEG, PNG, atau WebP.');
    }
    if (input.length <= AssetStore.maxPhotoBytes) {
      return SelectedAssetPhoto(input, name, input.length);
    }
    final decoded = img.decodeImage(input);
    if (decoded == null) {
      throw const FormatException('Foto tidak dapat dibaca.');
    }
    var picture = img.bakeOrientation(decoded);
    for (var side = 1280; side >= 480; side = (side * 0.8).round()) {
      final longest = picture.width > picture.height
        ? picture.width : picture.height;
      if (longest > side) {
        picture = picture.width >= picture.height
          ? img.copyResize(picture, width: side)
          : img.copyResize(picture, height: side);
      }
      for (final quality in [82, 72, 62, 50, 40]) {
        final bytes = Uint8List.fromList(img.encodeJpg(picture, quality: quality));
        if (bytes.length <= AssetStore.maxPhotoBytes) {
          return SelectedAssetPhoto(
            bytes, name.replaceFirst(RegExp(r'\.[^.]+$'), '') + '.jpg',
            input.length);
        }
      }
    }
    throw const FormatException('Foto masih melebihi 500 KB setelah kompresi.');
  }
}

/// Shared photo selector. Desktop: permission-free webcam detection and
/// a compact anchored menu. Mobile: a three-source bottom sheet.
class AssetPhotoPicker {
  @visibleForTesting
  static Future<bool?> Function()? debugCameraProbe;
  @visibleForTesting
  static Future<SelectedAssetPhoto?> Function(AssetPhotoSource)? debugReadPhoto;

  static Future<bool?> _cameraAvailable() async {
    if (debugCameraProbe != null) return debugCameraProbe!();
    return camera_probe.detectAvailableWebcam();
  }

  static Widget _mobileChoice(BuildContext context,
      AssetPhotoSource source, IconData icon, String title, String detail,
      String testKey) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Material(
      color: const Color(0xFFF8FAFD),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: border),
        borderRadius: BorderRadius.circular(11)),
      child: InkWell(
        key: ValueKey(testKey),
        borderRadius: BorderRadius.circular(11),
        onTap: () => Navigator.pop(context, source),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: const Color(0xFFECF3FC)),
              child: Icon(icon, color: blue, size: 22)),
            const SizedBox(width: 13),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  fontSize: 13.5, color: ink, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(detail, style: const TextStyle(
                  fontSize: 11.5, color: muted)),
              ])),
            const Icon(Icons.chevron_right_rounded,
              color: muted, size: 18),
          ]),
        ),
      ),
    ),
  );

  static Future<AssetPhotoSource?> _mobileSheet(
      BuildContext context) => showModalBottomSheet<AssetPhotoSource>(
    context: context, isScrollControlled: true, useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheet) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheet).height * 0.83),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 3, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tambahkan Foto Aset',
                      style: TextStyle(fontSize: 19, color: ink,
                        fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('Pilih sumber dokumentasi foto',
                      style: TextStyle(fontSize: 12, color: muted)),
                  ])),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(sheet),
                  icon: const Icon(Icons.close_rounded)),
              ]),
              const SizedBox(height: 14),
              _mobileChoice(sheet, AssetPhotoSource.camera,
                Icons.camera_alt_outlined, 'Ambil Foto',
                'Buka kamera perangkat', 'rv25-camera'),
              _mobileChoice(sheet, AssetPhotoSource.gallery,
                Icons.photo_library_outlined, 'Pilih dari Galeri',
                'Foto yang telah tersimpan', 'rv25-gallery'),
              _mobileChoice(sheet, AssetPhotoSource.file,
                Icons.folder_open_outlined, 'Pilih File',
                'Telusuri berkas gambar', 'rv25-file'),
              const SizedBox(height: 8),
              const Row(children: [
                Icon(Icons.info_outline_rounded, color: muted, size: 15),
                SizedBox(width: 5),
                Expanded(child: Text(
                  'JPEG, PNG atau WebP · foto dioptimalkan otomatis',
                  style: TextStyle(fontSize: 11, color: muted))),
              ]),
            ],
          ),
        ),
      ),
    ),
  );

  static RelativeRect _anchorPosition(BuildContext context) {
    final overlay = Overlay.of(context).context.findRenderObject();
    final anchor = context.findRenderObject();
    if (overlay is! RenderBox || !overlay.hasSize) {
      return const RelativeRect.fromLTRB(20, 130, 20, 0);
    }
    if (anchor is RenderBox && anchor.hasSize) {
      final start = anchor.localToGlobal(
        Offset.zero, ancestor: overlay);
      final position = Rect.fromLTWH(
        start.dx, start.dy, anchor.size.width, anchor.size.height);
      return RelativeRect.fromRect(
        position, Offset.zero & overlay.size);
    }
    return RelativeRect.fromLTRB(
      overlay.size.width / 2 - 160, 110,
      overlay.size.width / 2 - 160, 0);
  }

  static PopupMenuItem<AssetPhotoSource> _desktopChoice(
      AssetPhotoSource value, IconData icon, String title,
      String detail) => PopupMenuItem<AssetPhotoSource>(
    key: ValueKey('rv27-' + value.name),
    value: value, height: 72,
    child: Row(children: [
      Container(
        height: 39, width: 39,
        decoration: BoxDecoration(
          color: const Color(0xFFEDF4FC),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: blue, size: 21)),
      const SizedBox(width: 11),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(
            color: ink, fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(detail, style: const TextStyle(
            color: muted, fontSize: 11.5)),
        ],
      )),
    ]),
  );

  static Future<AssetPhotoSource?> _desktopMenu(
      BuildContext context) => showMenu<AssetPhotoSource>(
    context: context,
    position: _anchorPosition(context),
    color: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 8,
    constraints: const BoxConstraints(minWidth: 315, maxWidth: 345),
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: border),
      borderRadius: BorderRadius.circular(14)),
    items: [
      const PopupMenuItem<AssetPhotoSource>(
        enabled: false, height: 48,
        child: Text('Tambahkan Foto Aset',
          style: TextStyle(color: ink, fontSize: 14,
            fontWeight: FontWeight.w800))),
      _desktopChoice(AssetPhotoSource.camera,
        Icons.camera_alt_outlined, 'Ambil Foto', 'Gunakan webcam'),
      _desktopChoice(AssetPhotoSource.file,
        Icons.folder_open_outlined, 'Pilih File', 'Dari komputer'),
      const PopupMenuItem<AssetPhotoSource>(
        enabled: false, height: 35,
        child: Text('JPEG, PNG, atau WebP',
          style: TextStyle(color: muted, fontSize: 11))),
    ],
  );

  static Future<AssetPhotoSource?> _source(
      BuildContext context, BuildContext? anchor) async {
    if (MediaQuery.sizeOf(context).width < 650) {
      return _mobileSheet(context);
    }
    final available = await _cameraAvailable();
    if (!context.mounted) return null;
    if (available == false) return AssetPhotoSource.file;
    final trigger = (anchor != null && anchor.mounted) ? anchor : context;
    return _desktopMenu(trigger);
  }

  static Future<SelectedAssetPhoto?> _read(
      BuildContext context, AssetPhotoSource from) async {
    if (debugReadPhoto != null) return debugReadPhoto!(from);
    Uint8List? input;
    String name;
    if (from == AssetPhotoSource.file) {
      final selected = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false, withData: true);
      if (selected == null || selected.files.isEmpty) return null;
      final file = selected.files.single;
      if (file.size > AssetPhotoProcessing.maxInputBytes) {
        throw const FormatException('Foto melebihi 15 MB.');
      }
      name = file.name;
      input = file.bytes;
    } else if (from == AssetPhotoSource.gallery) {
      final selected = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      if (selected == null) return null;
      name = selected.name;
      input = await selected.readAsBytes();
    } else {
      final outcome = await showDialog<AssetCameraResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AssetCameraDialog());
      if (outcome == null) return null;
      if (outcome.chooseFile) {
        if (!context.mounted) return null;
        return _read(context, AssetPhotoSource.file);
      }
      return outcome.photo;
    }
    if (input == null) throw const FormatException('File tidak terbaca.');
    return AssetPhotoProcessing.normalize(input, name);
  }

  static Future<int?> _preview(
      BuildContext context, SelectedAssetPhoto photo) async {
    final size = MediaQuery.sizeOf(context);
    return showDialog<int>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520, maxHeight: size.height * 0.88),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Pratinjau Foto', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: size.height > 650 ? 260 : 170,
                    color: const Color(0xFFF1F5FA),
                    child: Image.memory(photo.bytes, fit: BoxFit.contain))),
                const SizedBox(height: 10),
                Text(photo.fileName, maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ink, fontSize: 12)),
                Text((photo.bytes.length / 1024).toStringAsFixed(0) +
                  ' KB · batas penyimpanan 500 KB',
                  style: const TextStyle(color: muted, fontSize: 12)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, 0),
                      child: const Text('Batal')),
                    OutlinedButton.icon(
                      key: const ValueKey('rv25-pick-again'),
                      onPressed: () => Navigator.pop(ctx, 2),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Pilih Ulang')),
                    FilledButton.icon(
                      key: const ValueKey('rv25-use-photo'),
                      onPressed: () => Navigator.pop(ctx, 1),
                      icon: const Icon(Icons.check),
                      label: const Text('Gunakan Foto')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<SelectedAssetPhoto?> choose(
      BuildContext context, {BuildContext? anchorContext}) async {
    AssetPhotoSource? repeatCamera;
    while (true) {
      if (!context.mounted) return null;
      final source = repeatCamera ??
        await _source(context, anchorContext);
      repeatCamera = null;
      if (source == null || !context.mounted) return null;
      SelectedAssetPhoto? picked;
      try {
        picked = await _read(context, source);
      } catch (e) {
        if (!context.mounted) return null;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Foto Tidak Bisa Dipilih'),
            content: Text(e is FormatException
              ? e.message : 'Pemilihan foto gagal: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup')),
            ],
          ),
        );
        continue;
      }
      if (picked == null || !context.mounted) return null;
      // The camera dialog has already shown and confirmed its captured photo.
      if (source == AssetPhotoSource.camera) return picked;
      final verdict = await _preview(context, picked);
      if (verdict == 1) return picked;
      if (verdict != 2) return null;
    }
  }
}
