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

/// Camera capture on web depends on browser; file selection is a fallback.
class AssetPhotoPicker {
  static Future<AssetPhotoSource?> _source(BuildContext context) async {
    Widget choices(BuildContext ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Align(alignment: Alignment.centerLeft,
            child: Text('Pilih Sumber Foto', style: TextStyle(
              color: ink, fontSize: 18, fontWeight: FontWeight.w800))),
        ),
        ListTile(
          key: const ValueKey('rv25-camera'),
          leading: const Icon(Icons.camera_alt_outlined, color: blue),
          title: const Text('Ambil Foto'),
          subtitle: const Text('Gunakan kamera jika didukung browser'),
          onTap: () => Navigator.pop(ctx, AssetPhotoSource.camera)),
        ListTile(
          key: const ValueKey('rv25-gallery'),
          leading: const Icon(Icons.photo_library_outlined, color: blue),
          title: const Text('Pilih dari Galeri'),
          subtitle: const Text('Foto yang tersimpan di perangkat'),
          onTap: () => Navigator.pop(ctx, AssetPhotoSource.gallery)),
        ListTile(
          key: const ValueKey('rv25-file'),
          leading: const Icon(Icons.folder_open_outlined, color: blue),
          title: const Text('Pilih File'),
          subtitle: const Text('JPEG, PNG, atau WebP'),
          onTap: () => Navigator.pop(ctx, AssetPhotoSource.file)),
        const SizedBox(height: 12),
      ]),
    );
    if (MediaQuery.sizeOf(context).width < 650) {
      return showModalBottomSheet<AssetPhotoSource>(
        context: context, showDragHandle: true, useSafeArea: true,
        isScrollControlled: true, builder: choices);
    }
    return showDialog<AssetPhotoSource>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 410),
          child: choices(ctx))),
    );
  }

  static Future<SelectedAssetPhoto?> _read(AssetPhotoSource from) async {
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
    } else {
      final selected = await ImagePicker().pickImage(
        source: from == AssetPhotoSource.camera
          ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600, maxHeight: 1600, imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear);
      if (selected == null) return null;
      name = selected.name;
      input = await selected.readAsBytes();
    }
    if (input == null) {
      throw const FormatException('File tidak terbaca.');
    }
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

  static Future<SelectedAssetPhoto?> choose(BuildContext context) async {
    while (true) {
      if (!context.mounted) return null;
      final source = await _source(context);
      if (source == null || !context.mounted) return null;
      SelectedAssetPhoto? picked;
      try {
        picked = await _read(source);
      } catch (e) {
        if (!context.mounted) return null;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Foto Tidak Bisa Dipilih'),
            content: Text(e is FormatException
              ? e.message : 'Pemilihan foto gagal: ' + e.toString()),
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
      final verdict = await _preview(context, picked);
      if (verdict == 1) return picked;
      if (verdict != 2) return null;
    }
  }
}
