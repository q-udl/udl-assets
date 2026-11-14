part of 'main.dart';

/// QR scanning is an action for locating an asset from the catalog.
/// It must never appear in breadcrumbs, settings, master data, or history.
bool assetQrScanVisible({
  required bool cameraAvailable,
  required int page,
  required bool showingAssetDetail,
}) => cameraAvailable && page == 1 && !showingAssetDetail;

/// Camera scanning is only available when the device has a detected camera.
/// No permissions or camera stream are opened by the availability probe.
extension _AssetSecureQrScanner on _AssetScreenState {
  Future<void> v4ScanQrCode() async {
    if (!_scanQrAvailable) return;
    final scanner = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    var processed = false;
    String? value;
    try {
      value = await v4ShowModal<String>(
        title: 'Scan QR Code',
        subtitle: 'Arahkan kamera ke label aset UDL Assets.',
        maxWidth: 580,
        body: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 320,
                child: MobileScanner(
                  controller: scanner,
                  fit: BoxFit.cover,
                  onDetect: (capture) {
                    if (processed || capture.barcodes.isEmpty) return;
                    final code = capture.barcodes.first.rawValue;
                    if (code == null || code.isEmpty) return;
                    processed = true;
                    Navigator.of(ctx).pop(code);
                  },
                  errorBuilder: (context, exception) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Kamera tidak dapat digunakan. Periksa izin kamera '
                        'pada browser atau tutup aplikasi lain yang sedang '
                        'memakai kamera.\n\n' + exception.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: danger, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hanya QR dengan token UDL Assets yang terdaftar dapat dibaca. '
              'Pencocokan UAT lokal bukan verifikasi keamanan server.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
        actions: (ctx, update) => [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batalkan'),
          ),
        ],
      );
    } catch (error) {
      if (mounted) notify('Pemindaian gagal: ' + error.toString());
    } finally {
      try { await scanner.stop(); } catch (_) {}
      await scanner.dispose();
    }
    if (!mounted || value == null) return;
    final asset = store.resolveQrPayload(value);
    if (asset == null) {
      notify('QR tidak valid, tidak terdaftar, atau sudah dicabut.');
      return;
    }
    v4Change(() {
      selected = asset;
      selectedEmployee = null;
      selectedAssignment = null;
      page = 1;
    });
    notify('Identitas aset ditemukan: ' + asset.code);
  }
}
