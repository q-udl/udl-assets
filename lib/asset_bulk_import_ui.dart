part of 'main.dart';

extension _AssetBulkImportUI on _AssetScreenState {
  Future<void> v22OpenImport(BulkImportKind kind) async {
    final count = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BulkImportDialog(store: store, kind: kind),
    );
    if (count != null && mounted) {
      repaint();
      notify(count.toString() + (kind == BulkImportKind.assets
        ? ' unit aset berhasil diimpor.' : ' karyawan berhasil diimpor.'));
    }
  }
}

/// Shared import workflow. Uploading does not write to storage.
class BulkImportDialog extends StatefulWidget {
  final AssetStore store;
  final BulkImportKind kind;
  const BulkImportDialog({
    super.key, required this.store, required this.kind,
  });

  @override
  State<BulkImportDialog> createState() => _BulkImportDialogState();
}

class _BulkImportDialogState extends State<BulkImportDialog> {
  BulkImportPreview? preview;
  bool busy = false;
  String? error;

  String get entityName =>
    widget.kind == BulkImportKind.assets ? 'Aset' : 'Karyawan';
  String get filePrefix => widget.kind == BulkImportKind.assets
    ? 'UDL_Template_Impor_Aset' : 'UDL_Template_Impor_Karyawan';

  Future<void> downloadTemplate() async {
    if (busy) return;
    setState(() { busy = true; error = null; });
    try {
      final bytes = BulkImportService.makeTemplate(widget.kind, widget.store);
      await FilePicker.saveFile(
        dialogTitle: 'Unduh Template ' + entityName,
        fileName: filePrefix + '.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );
    } catch (e) {
      if (mounted) { setState(() =>
        error = 'Gagal mengunduh template: ' + e.toString()); }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> selectTemplate() async {
    if (busy) return;
    setState(() { busy = true; error = null; });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (file.size > BulkImportService.maxFileBytes) {
        throw const FormatException('File melebihi 2 MB.');
      }
      final bytes = file.bytes;
      if (bytes == null) {
        throw const FormatException(
          'Berkas tidak terbaca. Pilih kembali file XLSX.');
      }
      final reviewed = BulkImportService.inspect(
        widget.store, widget.kind, bytes, fileName: file.name);
      if (mounted) setState(() => preview = reviewed);
    } catch (e) {
      if (mounted) { setState(() =>
        error = 'Gagal membaca template: ' + e.toString()); }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> downloadErrors() async {
    final current = preview;
    if (current == null || !current.hasErrors || busy) return;
    setState(() { busy = true; error = null; });
    try {
      final bytes = BulkImportService.makeErrorReport(current);
      await FilePicker.saveFile(
        dialogTitle: 'Unduh laporan kesalahan',
        fileName: 'UDL_Kesalahan_Impor_' + entityName + '.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );
    } catch (e) {
      if (mounted) { setState(() =>
        error = 'Gagal mengunduh laporan: ' + e.toString()); }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> requestClose() async {
    if (busy) return;
    final allowed = await assetAllowDiscard(
      context, isDirty: preview != null);
    if (allowed && mounted) Navigator.of(context).pop();
  }

  Future<void> confirm() async {
    final current = preview;
    if (current == null || current.validCount == 0 || busy) return;
    setState(() { busy = true; error = null; });
    try {
      final total = await widget.store.confirmBulkImport(current);
      if (mounted) Navigator.of(context).pop(total);
    } catch (e) {
      if (mounted) { setState(() =>
        error = 'Impor tidak disimpan: ' + e.toString()); }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _stepTile(IconData icon, String title, String text) =>
    Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(11)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: blue, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(
            color: ink, fontWeight: FontWeight.w700, fontSize: 12.5)),
          const SizedBox(height: 3),
          Text(text, style: const TextStyle(color: muted, fontSize: 11)),
        ]),
    ));

  Widget _record(BulkImportRow row) {
    final description = widget.kind == BulkImportKind.assets
      ? row.value('Nama Aset') : row.value('Nama Lengkap');
    final secondary = widget.kind == BulkImportKind.assets
      ? row.value('Kategori') + ' · ' + row.value('Lokasi Utama')
      : row.value('Unit') + ' · ' + row.value('Departemen');
    final status = Text(row.valid ? 'Valid' : 'Perlu perbaikan',
      textAlign: TextAlign.right,
      style: TextStyle(
        color: row.valid ? const Color(0xFF147B63) : danger,
        fontWeight: FontWeight.w700, fontSize: 11));
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(description, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 12.5)),
        if (secondary.trim().isNotEmpty)
          Text(secondary, style: const TextStyle(
            fontSize: 11, color: muted),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        if (!row.valid) Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(row.errors.join('; '),
            style: const TextStyle(color: danger, fontSize: 11.5))),
      ]);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 9),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(child: Text('Baris ' + row.excelRow.toString(),
                  style: const TextStyle(fontSize: 11.5, color: muted))),
                status,
              ]),
              const SizedBox(height: 5),
              details,
            ]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 67,
              child: Text('Baris ' + row.excelRow.toString(),
                style: const TextStyle(fontSize: 11.5, color: muted))),
            Expanded(child: details),
            const SizedBox(width: 12),
            SizedBox(width: 105, child: status),
          ]);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mobile = size.width < 650;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final width = mobile ? size.width - 16 :
      (size.width > 950 ? 900.0 : size.width - 28);
    final height = (mobile
      ? size.height - keyboard - 16
      : (size.height > 780 ? 690.0 : size.height - 42))
      .clamp(180.0, size.height).toDouble();
    final current = preview;
    final importTools = <Widget>[
      OutlinedButton.icon(
        key: const ValueKey('rv22-download-template'),
        onPressed: busy ? null : downloadTemplate,
        icon: const Icon(Icons.file_download_outlined),
        label: const Text('Unduh Template')),
      OutlinedButton.icon(
        key: const ValueKey('rv22-upload-template'),
        onPressed: busy ? null : selectTemplate,
        icon: const Icon(Icons.upload_file_outlined),
        label: const Text('Upload Template')),
      if (current != null && current.hasErrors)
        TextButton.icon(
          key: const ValueKey('rv22-error-report'),
          onPressed: busy ? null : downloadErrors,
          icon: const Icon(Icons.report_outlined),
          label: const Text('Unduh Laporan Kesalahan')),
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) requestClose();
      },
      child: Dialog(
      key: const ValueKey('rv28-import-dialog'),
      insetPadding: EdgeInsets.all(mobile ? 8 : 14),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)),
      child: SizedBox(width: width, height: height,
        child: Padding(
          padding: EdgeInsets.all(mobile ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                const Icon(Icons.file_upload_outlined, color: blue, size: 26),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Impor Data ' + entityName,
                      style: const TextStyle(color: ink,
                        fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    const Text('Unduh template, lengkapi, unggah, '
                      'lalu periksa sebelum menyimpan.',
                      style: TextStyle(color: muted, fontSize: 12)),
                  ],
                )),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: busy ? null : requestClose,
                  icon: const Icon(Icons.close_rounded)),
              ]),
              Expanded(
                child: SingleChildScrollView(
                  key: const ValueKey('rv28-import-scroll'),
                  keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 14),
              if (size.width >= 600)
                Row(children: [
                  _stepTile(Icons.download_rounded,
                    '1. Unduh Template', 'Isi data di sheet DATA'),
                  const SizedBox(width: 8),
                  _stepTile(Icons.upload_file_rounded,
                    '2. Upload Template', 'Pilih Excel XLSX'),
                  const SizedBox(width: 8),
                  _stepTile(Icons.fact_check_outlined,
                    '3. Pratinjau', 'Konfirmasi baris valid'),
                ])
              else
                const Text('1. Unduh template  →  2. Upload  →  '
                  '3. Validasi & Konfirmasi',
                  style: TextStyle(fontSize: 12, color: muted)),
              const SizedBox(height: 13),
              if (mobile)
                Column(
                  key: const ValueKey('rv28-import-mobile-tools'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < importTools.length; i++) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: importTools[i]),
                      if (i < importTools.length - 1)
                        const SizedBox(height: 8),
                    ],
                  ],
                )
              else
                Wrap(spacing: 9, runSpacing: 9, children: importTools),
              const SizedBox(height: 10),
              if (busy) const LinearProgressIndicator(),
              if (error != null) Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(error!, style: const TextStyle(
                  color: danger, fontSize: 12))),
              const SizedBox(height: 10),
              SizedBox(
                height: (mobile ? height * .35 : height * .49)
                  .clamp(140.0, 340.0).toDouble(),
                child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border)),
                child: current == null
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Belum ada file dipilih.\n'
                        'Template Excel memuat panduan dan referensi Master Data.\n'
                        'Tidak ada data yang disimpan sebelum konfirmasi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 12.5))))
                  : Column(children: [
                    Padding(padding: const EdgeInsets.all(11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(current.fileName, maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700, color: ink)),
                          const SizedBox(height: 6),
                          Wrap(spacing: 12, runSpacing: 4, children: [
                            Text(current.rows.length.toString() + ' baris diperiksa',
                              style: const TextStyle(fontSize: 12)),
                            Text(current.validCount.toString() + ' valid',
                              style: const TextStyle(fontSize: 12,
                                color: Color(0xFF147B63))),
                            Text(current.invalidCount.toString() + ' bermasalah',
                              style: const TextStyle(fontSize: 12, color: danger)),
                          ]),
                        ])),
                    const Divider(height: 1, color: border),
                    Expanded(child: ListView.separated(
                      itemCount: current.rows.length,
                      itemBuilder: (_, i) => _record(current.rows[i]),
                      separatorBuilder: (_, i) =>
                        const Divider(height: 1, color: border),
                    )),
                  ]),
              )),
              const SizedBox(height: 10),
              const Text('Hanya baris valid yang akan disimpan. Data lama '
                'tidak ditimpa. Penyimpanan masih lokal di browser.',
                style: TextStyle(color: muted, fontSize: 11.5)),
              const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (mobile) ...[
                SizedBox(width: double.infinity, height: 48,
                  child: FilledButton.icon(
                    key: const ValueKey('rv28-import-confirm'),
                    onPressed: busy || current == null ||
                      current.validCount == 0 ? null : confirm,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text('Konfirmasi Impor' +
                      (current == null ? '' :
                        ' (' + current.validCount.toString() + ')')),
                  )),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, height: 48,
                  child: OutlinedButton(
                     style: assetOutlinedStyle(AssetActionTone.secondary),
                     onPressed: busy ? null : requestClose,
                    child: const Text('Batal'))),
              ] else
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(
                     style: assetOutlinedStyle(AssetActionTone.secondary),
                     onPressed: busy ? null : requestClose,
                  child: const Text('Batal')),
                const SizedBox(width: 10),
                FilledButton.icon(
                  key: const ValueKey('rv22-confirm-import'),
                  onPressed: busy || current == null ||
                    current.validCount == 0 ? null : confirm,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('Konfirmasi Impor' +
                    (current == null ? '' :
                      ' (' + current.validCount.toString() + ')')),
                ),
              ]),
            ],
          ),
        ),
      ),
    ));
  }
}
