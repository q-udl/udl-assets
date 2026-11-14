part of 'main.dart';

class AssetCameraResult {
  final SelectedAssetPhoto? photo;
  final bool chooseFile;
  const AssetCameraResult.photo(this.photo) : chooseFile = false;
  const AssetCameraResult.file() : photo = null, chooseFile = true;
}

/// Real camera preview: capture is initiated only after the user selects
/// "Ambil Foto". This does not use the browser file-input capture attribute.
class AssetCameraDialog extends StatefulWidget {
  const AssetCameraDialog({super.key});

  @override
  State<AssetCameraDialog> createState() => _AssetCameraDialogState();
}

class _AssetCameraDialogState extends State<AssetCameraDialog> {
  cam.CameraController? controller;
  List<cam.CameraDescription> cameras = [];
  SelectedAssetPhoto? captured;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  String cameraError(Object e) {
    if (e is cam.CameraException) {
      if (e.code.toLowerCase().contains('denied') ||
          e.code.toLowerCase().contains('permission')) {
        return 'Izin kamera belum diberikan atau telah diblokir. '
          'Periksa izin kamera pada bilah alamat browser, lalu coba lagi.';
      }
      if (e.code.toLowerCase().contains('notfound') ||
          e.code.toLowerCase().contains('notfounderror')) {
        return 'Kamera tidak ditemukan pada perangkat ini.';
      }
    }
    return 'Kamera tidak dapat digunakan: $e';
  }

  Future<void> initialize({cam.CameraDescription? chosen}) async {
    if (!mounted) return;
    setState(() { busy = true; error = null; captured = null; });
    cam.CameraController? next;
    try {
      final available = await cam.availableCameras();
      if (!mounted) return;
      cameras = available;
      if (available.isEmpty) {
        setState(() => error = 'Tidak ada kamera yang dapat digunakan.');
        return;
      }
      final selection = chosen ?? available.firstWhere(
        (c) => c.lensDirection == cam.CameraLensDirection.back,
        orElse: () => available.first);
      final previous = controller;
      controller = null;
      if (previous != null) await previous.dispose();
      next = cam.CameraController(
        selection, cam.ResolutionPreset.medium, enableAudio: false);
      controller = next;
      await next.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (mounted) setState(() => error = cameraError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> shoot() async {
    final active = controller;
    if (active == null || !active.value.isInitialized || busy) return;
    setState(() { busy = true; error = null; });
    try {
      final picture = await active.takePicture();
      final bytes = await picture.readAsBytes();
      final photo = AssetPhotoProcessing.normalize(bytes,
        picture.name.isEmpty ? 'foto-kamera.jpg' : picture.name);
      if (!mounted) return;
      setState(() => captured = photo);
    } catch (e) {
      if (mounted) setState(() => error = cameraError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> switchCamera() async {
    final active = controller;
    if (active == null || cameras.length < 2 || busy) return;
    final index = cameras.indexWhere(
      (c) => c.name == active.description.name);
    await initialize(chosen: cameras[(index + 1) % cameras.length]);
  }

  @override
  void dispose() {
    final active = controller;
    controller = null;
    // Releasing the controller also releases the browser's video stream.
    if (active != null) active.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final narrow = screen.width < 650;
    final active = controller;
    final ready = active != null && active.value.isInitialized;
    return Dialog(
      key: const ValueKey('rv27-camera-dialog'),
      insetPadding: EdgeInsets.symmetric(
        horizontal: narrow ? 12 : 22, vertical: 16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 700, maxHeight: screen.height * 0.90),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(narrow ? 14 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF4FC),
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt_outlined,
                    color: blue, size: 21)),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ambil Foto Aset',
                        style: TextStyle(fontSize: 18,
                          color: ink, fontWeight: FontWeight.w800)),
                      SizedBox(height: 3),
                      Text('Pratinjau kamera perangkat',
                        style: TextStyle(color: muted, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup Kamera',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded)),
              ]),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: screen.height * (narrow ? 0.43 : 0.49)),
                  color: const Color(0xFF182B40),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: captured != null
                      ? Image.memory(captured!.bytes,
                          fit: BoxFit.contain)
                      : ready && error == null
                        ? cam.CameraPreview(active)
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: busy && error == null
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.videocam_off_outlined,
                                        color: Colors.white70, size: 35),
                                      const SizedBox(height: 8),
                                      Text(error ?? 'Menyiapkan kamera...',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5)),
                                    ],
                                  ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (captured != null)
                const Text('Periksa hasil foto sebelum digunakan.',
                  style: TextStyle(fontSize: 12, color: muted))
              else
                const Text(
                  'Akses kamera hanya digunakan untuk mengambil foto aset. '
                  'Kamera berhenti saat jendela ditutup.',
                  style: TextStyle(fontSize: 12, color: muted)),
              const SizedBox(height: 13),
              Builder(builder: (ctx) {
                final actions = <Widget>[
                  if (captured != null)
                    FilledButton.icon(
                      key: const ValueKey('rv27-use-capture'),
                      onPressed: busy ? null : () => Navigator.pop(
                        context, AssetCameraResult.photo(captured)),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Gunakan Foto'))
                  else if (error == null)
                    FilledButton.icon(
                      key: const ValueKey('rv27-shutter'),
                      onPressed: ready && !busy ? shoot : null,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Ambil Foto')),
                  if (captured != null)
                    OutlinedButton.icon(
                      key: const ValueKey('rv27-retake'),
                      onPressed: busy ? null :
                        () => setState(() { captured = null; error = null; }),
                      icon: const Icon(Icons.refresh_outlined),
                      label: const Text('Foto Ulang')),
                  if (captured == null && error != null)
                    OutlinedButton.icon(
                      key: const ValueKey('rv27-file-fallback'),
                      onPressed: () => Navigator.pop(
                        context, const AssetCameraResult.file()),
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('Pilih File')),
                  if (captured == null && error != null)
                    OutlinedButton.icon(
                      key: const ValueKey('rv27-camera-retry'),
                      onPressed: busy ? null : initialize,
                      icon: const Icon(Icons.refresh_outlined),
                      label: const Text('Coba Lagi')),
                  if (captured == null && cameras.length > 1 && ready)
                    OutlinedButton.icon(
                      onPressed: busy ? null : switchCamera,
                      icon: const Icon(Icons.cameraswitch_outlined),
                      label: const Text('Ganti Kamera')),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal')),
                ];
                return narrow
                  ? Column(
                      key: const ValueKey('rv28-camera-mobile-actions'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < actions.length; i++) ...[
                          SizedBox(height: 48, width: double.infinity,
                            child: actions[i]),
                          if (i < actions.length - 1)
                            const SizedBox(height: 8),
                        ],
                      ],
                    )
                  : Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8, runSpacing: 8,
                      children: actions.reversed.toList(),
                    );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
