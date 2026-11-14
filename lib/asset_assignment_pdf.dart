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
        pw.Text('DRAF / SIMULASI - BELUM DITANDATANGANI',
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
    pw.Text('Dokumen dibuat dari prototipe lokal tanpa autentikasi. '
      'Bukan bukti tanda tangan, persetujuan, atau serah terima yang sah.',
      style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
    pw.SizedBox(height: 4),
    pw.Align(alignment: pw.Alignment.centerRight,
      child: pw.Text('Halaman ' + ctx.pageNumber.toString() +
        ' dari ' + ctx.pagesCount.toString(),
        style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700))),
  ]);

  static pw.Widget signing(String left, String right) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 20),
    child: pw.Row(
      children: [
        pw.Expanded(child: pw.Column(children: [
          pw.Text(left, style: bold(9)),
          pw.SizedBox(height: 60),
          pw.Text('(__________________________)', style: regular(9)),
          pw.Text('Nama & tanda tangan manual', style: regular(8)),
        ])),
        pw.SizedBox(width: 20),
        pw.Expanded(child: pw.Column(children: [
          pw.Text(right, style: bold(9)),
          pw.SizedBox(height: 60),
          pw.Text('(__________________________)', style: regular(9)),
          pw.Text('Nama & tanda tangan manual', style: regular(8)),
        ])),
      ],
    ),
  );

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

  static Future<Uint8List> handover(AssetAssignment record) async {
    final doc = pw.Document(
      title: 'DRAF BAST ' + record.draftReference,
      author: 'UDL Assets - Simulasi Lokal');
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
        item('Kode karyawan', text(record.employeeSnapshot['code'])),
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
          ' (simulasi, bukan persetujuan terautentikasi)'),
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
        signing('Yang Menyerahkan (GA)', 'Yang Menerima (Karyawan)'),
      ],
    ));
    return doc.save();
  }

  static Future<Uint8List> assetReturn(
    AssetAssignment original, AssetReturnReceipt receipt,
  ) async {
    final doc = pw.Document(
      title: 'DRAF Pengembalian ' + receipt.draftReference,
      author: 'UDL Assets - Simulasi Lokal');
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 45, 42, 46),
      footer: footer,
      build: (ctx) => [
        header('Berita Acara Pengembalian Aset', receipt.draftReference),
        item('Dibuat pada', date(receipt.createdAt)),
        item('Referensi penyerahan', original.draftReference),
        item('Lokasi penerimaan', receipt.receivingLocation),
        pw.SizedBox(height: 10),
        pw.Text('PIHAK YANG MENGEMBALIKAN', style: bold(10)),
        pw.SizedBox(height: 7),
        item('Nama', text(receipt.employeeSnapshot['name'])),
        item('Kode karyawan', text(receipt.employeeSnapshot['code'])),
        item('Unit / Departemen',
          text(receipt.employeeSnapshot['unit']) + ' / ' +
          text(receipt.employeeSnapshot['department'])),
        item('Penerima di GA (isian)', text(receipt.receivedByName)),
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
        signing('Yang Mengembalikan', 'Yang Menerima (GA)'),
      ],
    ));
    return doc.save();
  }

  static Future<void> printHandover(AssetAssignment batch) async {
    final content = await handover(batch);
    await Printing.layoutPdf(
      name: batch.draftReference + '.pdf',
      onLayout: (format) async => content);
  }

  static Future<void> printReturn(
      AssetAssignment batch, AssetReturnReceipt receipt) async {
    final content = await assetReturn(batch, receipt);
    await Printing.layoutPdf(
      name: receipt.draftReference + '.pdf',
      onLayout: (format) async => content);
  }
}
