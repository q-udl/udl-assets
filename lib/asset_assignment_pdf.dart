part of 'main.dart';

/// All PDF output is explicitly a LOCAL DRAFT. No digital signatures,
/// identity verification or official document registration are implied.
class AssetBastPdf {
  static pw.TextStyle regular(double size) =>
    pw.TextStyle(fontSize: size, color: PdfColors.blueGrey900);
  static pw.TextStyle bold(double size) =>
    pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey900);

  static String text(dynamic value) {
    final valueText = value?.toString().trim() ?? '';
    return valueText.isEmpty ? '-' : valueText;
  }

  static String date(String raw) {
    final value = DateTime.tryParse(raw);
    if (value == null) return text(raw);
    final local = value.toLocal();
    return local.day.toString().padLeft(2, '0') + '/' +
      local.month.toString().padLeft(2, '0') + '/' +
      local.year.toString() + ' ' +
      local.hour.toString().padLeft(2, '0') + ':' +
      local.minute.toString().padLeft(2, '0');
  }

  static pw.Widget item(String key, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(width: 125, child: pw.Text(key, style: regular(9))),
        pw.Text(':  ', style: regular(9)),
        pw.Expanded(child: pw.Text(value, style: bold(9))),
      ],
    ),
  );

  static pw.Widget header(String heading, String draftReference) =>
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('UD. LUTHFI  |  UDL ASSETS',
          style: bold(12)),
        pw.SizedBox(height: 5),
        pw.Text(heading.toUpperCase(), style: bold(16)),
        pw.SizedBox(height: 5),
        pw.Text('DRAF - TANDA TANGAN DILAKUKAN TERPISAH',
          style: pw.TextStyle(
            color: PdfColors.red700, fontSize: 9,
            fontWeight: pw.FontWeight.bold)),
        pw.Text('Referensi lokal: ' + draftReference,
          style: regular(9)),
        pw.Text('Nomor dokumen resmi: _________________________',
          style: regular(9)),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.blueGrey200),
        pw.SizedBox(height: 10),
      ],
    );

  static pw.Widget footer(pw.Context ctx) => pw.Column(children: [
    pw.Divider(color: PdfColors.blueGrey200),
    pw.Text('Nama pihak berasal dari catatan transaksi. '
      'Penandatanganan dan persetujuan tidak diverifikasi otomatis.',
      style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
    pw.SizedBox(height: 4),
    pw.Align(alignment: pw.Alignment.centerRight,
      child: pw.Text('Halaman ' + ctx.pageNumber.toString() +
        ' dari ' + ctx.pagesCount.toString(),
        style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700))),
  ]);

  static pw.Widget signing(String left, String right,
      String leftName, String rightName) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 20),
    child: pw.Row(
      children: [
        pw.Expanded(child: pw.Column(children: [
          pw.Text(left, style: bold(9)),
          pw.SizedBox(height: 60),
          pw.Text(leftName, style: bold(9)),
          pw.Text('Tanda tangan: __________________', style: regular(8)),
        ])),
        pw.SizedBox(width: 20),
        pw.Expanded(child: pw.Column(children: [
          pw.Text(right, style: bold(9)),
          pw.SizedBox(height: 60),
          pw.Text(rightName, style: bold(9)),
          pw.Text('Tanda tangan: __________________', style: regular(8)),
        ])),
      ],
    ),
  );

  static List<pw.Widget> photoAppendix(
    AssetStore? store, Map<String, List<String>> references, String heading,
  ) {
    if (store == null) return [];
    final items = <pw.Widget>[];
    for (final entry in references.entries) {
      for (final photoId in entry.value) {
        final matching = store.photos.where((p) => p.id == photoId);
        if (matching.isEmpty) continue;
        final photo = matching.first;
        if (!(photo.mimeType.contains('jpeg') ||
            photo.mimeType.contains('png'))) {
          continue;
        }
        try {
          final picture = pw.MemoryImage(photo.bytes);
          items.add(pw.Container(
            margin: const pw.EdgeInsets.only(right: 10, bottom: 12),
            width: 205,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColors.blueGrey200)),
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Image(picture, width: 190,
                    height: 122, fit: pw.BoxFit.contain)),
                pw.SizedBox(height: 5),
                pw.Text(entry.key + ' / ' + photo.kind,
                  style: bold(8)),
                pw.Text(date(photo.timestamp),
                  style: regular(7.5)),
              ],
            ),
          ));
        } catch (_) {
          // Unsupported or damaged photos remain in storage but are skipped
          // in the printable PDF rather than breaking document generation.
        }
      }
    }
    if (items.isEmpty) {
      return [
        pw.SizedBox(height: 14),
        pw.Text(heading, style: bold(10)),
        pw.SizedBox(height: 6),
        pw.Text('Tidak ada foto JPG/PNG tersimpan untuk tahap ini.',
          style: regular(8.5)),
      ];
    }
    return [
      pw.SizedBox(height: 17),
      pw.Text(heading, style: bold(10)),
      pw.SizedBox(height: 8),
      pw.Wrap(spacing: 12, runSpacing: 10, children: items),
    ];
  }

  /// Only event-linked photos are proof. Catalog photos must not be silently
  /// substituted for a real handover/return photograph.
  static List<pw.Widget> evidenceAppendix(
    AssetStore? store,
    String transactionType,
    String transactionId,
    Map<String, String> assetCodes,
    String heading, {
    required bool completed,
  }) {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 17),
      pw.Text(heading, style: bold(10)),
      pw.SizedBox(height: 8),
    ];
    if (!completed) {
      widgets.add(pw.Text(
        'Belum ada serah terima yang dikonfirmasi. '
        'Foto bukti wajib ditambahkan saat transaksi berlangsung.',
        style: regular(8.5)));
      return widgets;
    }
    if (store == null) {
      widgets.add(pw.Text(
        'Foto bukti tersedia melalui penyimpanan UDL Assets; '
        'cetak ulang dari aplikasi yang menyimpan data transaksi.',
        style: regular(8.5)));
      return widgets;
    }
    final pictures = <pw.Widget>[];
    var count = 0;
    for (final entry in assetCodes.entries) {
      final proofs = store.evidenceFor(
        transactionType, transactionId, entry.key);
      for (final photo in proofs) {
        Uint8List bytes = photo.bytes;
        if (photo.mimeType == 'image/webp') {
          final decoded = img.decodeImage(bytes);
          if (decoded == null) {
            throw const FormatException('Foto bukti WebP tidak dapat dibaca.');
          }
          bytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
        }
        final picture = pw.MemoryImage(bytes);
        pictures.add(pw.Container(
          width: 205, margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(
                  color: PdfColors.blueGrey200)),
                padding: const pw.EdgeInsets.all(5),
                child: pw.Image(picture, width: 190,
                  height: 122, fit: pw.BoxFit.contain)),
              pw.SizedBox(height: 5),
              pw.Text('Aset: ' + entry.value, style: bold(8)),
              pw.Text('Bukti: ' + text(photo.fileName),
                style: regular(7.5)),
              pw.Text('Dicatat: ' + date(photo.recordedAt),
                style: regular(7.5)),
            ],
          ),
        ));
        count++;
      }
    }
    if (count == 0) {
      widgets.add(pw.Text(
        'Foto bukti tidak tersedia pada transaksi historis ini. '
        'Data lama dipertahankan sebagaimana tercatat.',
        style: regular(8.5)));
    } else {
      widgets.add(pw.Wrap(spacing: 10, runSpacing: 10,
        children: pictures));
      if (count < assetCodes.length) {
        widgets.add(pw.Text(
          'Perhatian: sebagian aset belum memiliki foto bukti '
          'pada data historis ini.',
          style: regular(8.5)));
      }
    }
    return widgets;
  }

  /// Append proof photographs on their own page so the appendix heading
  /// can never be orphaned below the signatures on the preceding page.
  static void addEvidencePages(
    pw.Document document, AssetStore? store, String transactionType,
    String transactionId, Map<String, String> assetCodes, String heading,
  ) {
    if (store == null || !assetCodes.keys.any((id) =>
        store.evidenceFor(transactionType, transactionId, id).isNotEmpty)) {
      return; // Never produce an empty photo appendix.
    }
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 45, 42, 46),
      footer: footer,
      build: (ctx) => evidenceAppendix(
        store, transactionType, transactionId, assetCodes, heading,
        completed: true),
    ));
  }

  static pw.Widget assetTable(
      List<List<String>> rows, List<String> columnHeaders) {
    return pw.Table.fromTextArray(
      headers: columnHeaders,
      data: rows,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
      headerStyle: bold(8.2),
      cellStyle: regular(8.2),
      cellPadding: const pw.EdgeInsets.symmetric(
        horizontal: 6, vertical: 8),
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(color: PdfColors.blueGrey200),
        bottom: const pw.BorderSide(color: PdfColors.blueGrey200)),
      cellAlignments: {
        0: pw.Alignment.center,
      },
    );
  }

  static Future<Uint8List> handover(AssetAssignment record, {AssetStore? store}) async {
    final doc = pw.Document(
      title: 'DRAF BAST ' + record.draftReference,
      author: 'UDL Assets');
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 45, 42, 46),
      footer: footer,
      build: (ctx) => [
        header('Berita Acara Serah Terima Aset', record.draftReference),
        item('Dibuat pada', date(record.createdAt)),
        item('Jenis penugasan', record.kind),
        item('Tanggal kembali', record.kind == 'Sementara'
          ? text(record.dueDate) : 'Tidak ditentukan'),
        pw.SizedBox(height: 10),
        pw.Text('PIHAK YANG MENERIMA', style: bold(10)),
        pw.SizedBox(height: 7),
        item('Nama', text(record.employeeSnapshot['name'])),
        item('Yang Menyerahkan', text(record.handedOverByName)),
        item('Jabatan', text(record.employeeSnapshot['jobTitle'])),
        item('Unit / Departemen',
          text(record.employeeSnapshot['unit']) + ' / ' +
          text(record.employeeSnapshot['department'])),
        item('Lokasi kerja', text(record.employeeSnapshot['workLocation'])),
        pw.SizedBox(height: 12),
        pw.Text('DAFTAR ASET DAN KONDISI PENYERAHAN', style: bold(10)),
        pw.SizedBox(height: 8),
        assetTable([
          for (var i = 0; i < record.lines.length; i++)
            [
              (i + 1).toString(),
              record.lines[i].assetCode,
              record.lines[i].assetName,
              text(record.lines[i].serial),
              text(record.lines[i].handoverCondition),
              text(record.lines[i].accessories),
            ],
        ], ['No', 'Kode', 'Nama Aset', 'No Seri',
            'Kondisi', 'Kelengkapan']),
        pw.SizedBox(height: 13),
        item('Catatan', text(record.notes)),
        item('Status sistem', record.status +
          ' (pencatatan, bukan tanda tangan terverifikasi)'),
        pw.SizedBox(height: 12),
        pw.Text('PERNYATAAN', style: bold(10)),
        pw.SizedBox(height: 5),
        pw.Text(
          'Pihak yang menyerahkan dan pihak penerima wajib memeriksa '
          'kesesuaian identitas aset, kelengkapan, serta kondisi fisik '
          'yang tercantum sebelum menandatangani dokumen ini. '
          'Penerima bertanggung jawab menjaga dan mengembalikan aset '
          'sesuai ketentuan perusahaan. Dokumen ini menjadi bukti '
          'serah terima hanya setelah proses perusahaan dilaksanakan '
          'dan para pihak menandatangani sesuai kewenangannya.',
          style: regular(9),
        ),
        signing('Yang Menyerahkan', 'Yang Menerima',
          text(record.handedOverByName), text(record.employeeSnapshot['name'])),
      ],
    ));
    addEvidencePages(doc, store, 'assignment_handover', record.id, {
      for (final line in record.lines) line.assetId: line.assetCode,
    }, 'LAMPIRAN FOTO BUKTI SERAH TERIMA');
    return doc.save();
  }

  static Future<Uint8List> assetReturn(
    AssetAssignment original, AssetReturnReceipt receipt,
    {AssetStore? store}
  ) async {
    final doc = pw.Document(
      title: 'DRAF Pengembalian ' + receipt.draftReference,
      author: 'UDL Assets');
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 45, 42, 46),
      footer: footer,
      build: (ctx) => [
        header('Berita Acara Pengembalian Aset', receipt.draftReference),
        item('Dibuat pada', date(receipt.createdAt)),
        item('Referensi penyerahan', original.draftReference),
        item('Lokasi penerimaan',
          receipt.receivingLocationPath.isEmpty
            ? receipt.receivingLocation : receipt.receivingLocationPath),
        pw.SizedBox(height: 10),
        pw.Text('PIHAK YANG MENGEMBALIKAN', style: bold(10)),
        pw.SizedBox(height: 7),
        item('Nama', text(receipt.employeeSnapshot['name'])),
        item('Unit / Departemen',
          text(receipt.employeeSnapshot['unit']) + ' / ' +
          text(receipt.employeeSnapshot['department'])),
        item('Yang Menerima', text(receipt.receivedByName)),
        pw.SizedBox(height: 12),
        pw.Text('HASIL PEMERIKSAAN PENGEMBALIAN', style: bold(10)),
        pw.SizedBox(height: 8),
        assetTable([
          for (var i = 0; i < receipt.lines.length; i++)
            [
              (i + 1).toString(),
              receipt.lines[i].assetCode,
              receipt.lines[i].assetName,
              receipt.lines[i].handoverCondition,
              receipt.lines[i].returnCondition,
              text(receipt.lines[i].accessoriesReturned),
              text(receipt.lines[i].notes),
            ],
        ], ['No', 'Kode', 'Nama Aset', 'Kondisi Awal',
            'Kondisi Kembali', 'Kelengkapan', 'Catatan']),
        pw.SizedBox(height: 13),
        item('Catatan umum', text(receipt.notes)),
        item('Jumlah dikembalikan', receipt.lines.length.toString() +
          ' dari ' + original.lines.length.toString() + ' unit penugasan'),
        pw.SizedBox(height: 12),
        pw.Text('PERNYATAAN PEMERIKSAAN', style: bold(10)),
        pw.SizedBox(height: 5),
        pw.Text(
          'Pihak yang mengembalikan dan pihak yang menerima wajib '
          'mengecek jumlah, identitas, kondisi fisik serta kelengkapan '
          'aset. Selisih, kerusakan atau kehilangan yang ditemukan '
          'ditindaklanjuti sesuai prosedur perusahaan. '
          'Pengembalian sebagian tidak menutup tanggung jawab '
          'atas aset lainnya yang belum dikembalikan.',
          style: regular(9),
        ),
        signing('Yang Mengembalikan', 'Yang Menerima',
          text(receipt.employeeSnapshot['name']), text(receipt.receivedByName)),
      ],
    ));
    addEvidencePages(doc, store, 'assignment_return', receipt.id, {
      for (final line in receipt.lines) line.assetId: line.assetCode,
    }, 'LAMPIRAN FOTO BUKTI PENGEMBALIAN');
    return doc.save();
  }

  static Future<void> printHandover(AssetAssignment batch, {AssetStore? store}) async {
    final content = await handover(batch, store: store);
    await Printing.layoutPdf(
      name: batch.draftReference + '.pdf',
      onLayout: (format) async => content);
  }

  static Future<void> printReturn(
      AssetAssignment batch, AssetReturnReceipt receipt,
      {AssetStore? store}) async {
    final content = await assetReturn(batch, receipt, store: store);
    await Printing.layoutPdf(
      name: receipt.draftReference + '.pdf',
      onLayout: (format) async => content);
  }
}
