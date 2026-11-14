part of 'main.dart';

enum BulkImportKind { employees, assets }

class BulkImportRow {
  final int excelRow;
  final Map<String, String> values;
  final List<String> errors;
  const BulkImportRow(this.excelRow, this.values, this.errors);
  bool get valid => errors.isEmpty;
  String value(String key) => values[key]?.trim() ?? '';
}

class BulkImportPreview {
  final BulkImportKind kind;
  final String fileName;
  final Uint8List bytes;
  final List<BulkImportRow> rows;
  const BulkImportPreview(this.kind, this.fileName, this.bytes, this.rows);
  int get validCount => rows.where((r) => r.valid).length;
  int get invalidCount => rows.length - validCount;
  bool get hasErrors => invalidCount > 0;
}

/// Non-destructive XLSX preview, shared by the employee and asset modules.
class BulkImportService {
  static const maxFileBytes = 2 * 1024 * 1024;
  static const maxDataRows = 500;
  static const employeeColumns = <String>[
    'Kode Karyawan', 'Nama Lengkap', 'Unit', 'Departemen',
    'Jabatan', 'Lokasi Kerja', 'Tanggal Bergabung', 'Status Karyawan',
  ];
  static const assetColumns = <String>[
    'Nama Aset', 'Kategori', 'Subkategori', 'Jenis Aset',
    'Merek', 'Model/Tipe', 'Nomor Seri', 'Lokasi Utama',
    'Area', 'Titik Penempatan', 'Tanggal Perolehan',
    'Nilai Perolehan', 'Kondisi', 'Status Penggunaan',
  ];
  static List<String> columns(BulkImportKind kind) =>
    kind == BulkImportKind.employees ? employeeColumns : assetColumns;

  static String norm(String s) =>
    s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  static String _isoDate(int y, int m, int d) =>
    y.toString().padLeft(4, '0') + '-' +
    m.toString().padLeft(2, '0') + '-' +
    d.toString().padLeft(2, '0');

  static String _cell(xls.CellValue? v) {
    if (v == null) return '';
    if (v is xls.DateCellValue) return _isoDate(v.year, v.month, v.day);
    if (v is xls.DateTimeCellValue) return _isoDate(v.year, v.month, v.day);
    if (v is xls.IntCellValue) return v.value.toString();
    if (v is xls.DoubleCellValue) {
      final value = v.value;
      return value.isFinite && value == value.roundToDouble()
        ? value.toInt().toString() : value.toString();
    }
    if (v is xls.FormulaCellValue) return '#FORMULA_NOT_ALLOWED';
    return v.toString().trim();
  }

  static bool validDate(String value) {
    if (value.isEmpty) return true;
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
    final y = int.parse(value.substring(0,4));
    final m = int.parse(value.substring(5,7));
    final d = int.parse(value.substring(8,10));
    if (y < 1900 || y > 2200) return false;
    final date = DateTime.utc(y,m,d);
    return date.year == y && date.month == m && date.day == d;
  }

  static String canonical(String input, Iterable<String> values) {
    for (final value in values) {
      if (norm(value) == norm(input)) return value;
    }
    return input.trim();
  }

  static Uint8List makeTemplate(BulkImportKind kind, AssetStore store) {
    final book = xls.Excel.createExcel();
    book.rename('Sheet1', 'DATA');
    final data = book['DATA'];
    final keys = columns(kind);
    data.appendRow([for (final key in keys) xls.TextCellValue(key)]);
    for (var i=0; i<keys.length; i++) data.setColumnWidth(i, 23);

    final guide = book['PANDUAN'];
    final instructions = <List<String>>[
      ['CARA PAKAI', 'Isi hanya sheet DATA mulai baris 2.'],
      ['BATAS', 'Maksimal 500 baris dan 2 MB untuk pratinjau lokal.'],
      ['KOLOM', 'Jangan mengganti nama kolom. Kolom opsional boleh kosong.'],
      ['MASTER DATA', 'Gunakan nilai aktif dari sheet REFERENSI.'],
      ['TANGGAL', 'Format YYYY-MM-DD atau tanggal asli Excel.'],
      ['CEK DULU', 'Upload hanya melakukan validasi, belum menyimpan data.'],
      ['DUPLIKAT', 'Tidak ada pembaruan otomatis terhadap data yang sudah ada.'],
      ['KESALAHAN', 'Baris salah ditolak; laporan kesalahan dapat diunduh.'],
      if (kind == BulkImportKind.employees) ...[
        ['KODE KARYAWAN', 'Opsional. Jika kosong, dibuat otomatis.'],
        ['STATUS', 'Aktif (default) atau Tidak Aktif.'],
        ['TANGGAL BERGABUNG', 'Tidak sama dengan tanggal penerimaan aset.'],
      ] else ...[
        ['UNIT ASET', 'Satu baris adalah SATU unit aset fisik.'],
        ['KODE ASET', 'Dibuat otomatis; kode UDL-AST tidak boleh diinput.'],
        ['STATUS', 'Tersedia (default), Dalam Perbaikan, atau Hilang.'],
        ['DIGUNAKAN', 'Harus melalui Assigned Assets / BAST, bukan impor.'],
        ['FOTO', 'Foto aktual diunggah melalui Detail Aset setelah impor.'],
        ['NILAI PEROLEHAN', 'Angka rupiah bulat tanpa titik atau pemisah.'],
        ['AREA/TITIK', 'Opsional. Titik wajib berada di Area yang dipilih.'],
      ],
    ];
    for (final item in instructions) {
      guide.appendRow([for (final text in item) xls.TextCellValue(text)]);
    }
    guide.setColumnWidth(0, 26);
    guide.setColumnWidth(1, 88);

    final reference = book['REFERENSI'];
    if (kind == BulkImportKind.employees) {
      reference.appendRow([
        xls.TextCellValue('Lokasi Kerja'), xls.TextCellValue('Status Karyawan')]);
      for (final site in store.activeSites) {
        reference.appendRow([
          xls.TextCellValue(site.name),
          xls.TextCellValue('Aktif / Tidak Aktif'),
        ]);
      }
    } else {
      reference.appendRow([
        for (final name in ['Kategori','Subkategori','Jenis Aset',
          'Lokasi Utama','Area','Titik Penempatan'])
          xls.TextCellValue(name),
      ]);
      final classes = <List<String>>[];
      for (final c in store.categories.where((c) => c.active)) {
        for (final s in c.subcategories.where((s) => s.active)) {
          for (final t in s.types.where(s.typeIsActive)) {
            classes.add([c.name,s.name,t]);
          }
        }
      }
      final places = <List<String>>[];
      for (final site in store.activeSites) {
        places.add([site.name,'','']);
        for (final area in site.areas.where((a) => a.active)) {
          places.add([site.name, area.name, '']);
          for (final point in area.spots.where((s) => s.active)) {
            places.add([site.name,area.name,point.name]);
          }
        }
      }
      final count = classes.length > places.length ?
        classes.length : places.length;
      for (var i=0; i<count; i++) {
        reference.appendRow([
          for (final text in [
            ...(i < classes.length ? classes[i] : ['', '', '']),
            ...(i < places.length ? places[i] : ['', '', '']),
          ]) xls.TextCellValue(text),
        ]);
      }
    }
    for (var i=0; i < (kind == BulkImportKind.assets ? 6 : 2); i++) {
      reference.setColumnWidth(i, 30);
    }
    return Uint8List.fromList(book.encode()!);
  }

  static BulkImportPreview inspect(AssetStore store, BulkImportKind kind,
      Uint8List bytes, {String fileName = 'template.xlsx'}) {
    if (!fileName.toLowerCase().endsWith('.xlsx')) {
      throw const FormatException('Gunakan file Excel .xlsx.');
    }
    if (bytes.isEmpty || bytes.length > maxFileBytes) {
      throw const FormatException('File kosong atau lebih dari 2 MB.');
    }
    late xls.Excel book;
    try {
      book = xls.Excel.decodeBytes(bytes);
    } catch (_) {
      throw const FormatException('File Excel tidak dapat dibaca.');
    }
    final sheet = book.tables['DATA'] ?? book.tables['Sheet1'];
    if (sheet == null || sheet.rows.isEmpty) {
      throw const FormatException('Sheet DATA tidak ditemukan atau kosong.');
    }
    final required = columns(kind);
    final header = <String, int>{};
    for (var i=0; i<sheet.rows.first.length; i++) {
      final key = norm(_cell(sheet.rows.first[i]?.value));
      if (key.isEmpty) continue;
      if (header.containsKey(key)) {
        throw FormatException('Kolom duplikat: ' + key);
      }
      header[key] = i;
    }
    final absent = required.where((key) => !header.containsKey(norm(key)));
    if (absent.isNotEmpty) {
      throw FormatException(
        'Kolom wajib template tidak ditemukan: ' + absent.join(', '));
    }
    final seenCode = {for (final e in store.employees) norm(e.code)};
    final seenEmployee = {for (final e in store.employees)
      norm(e.name) + '|' + norm(e.unit) + '|' + norm(e.department)};
    final seenSerial = {for (final a in store.assets)
      if (a.serial.trim().isNotEmpty) norm(a.serial)};
    final rows = <BulkImportRow>[];
    for (var i=1; i<sheet.rows.length; i++) {
      final values = <String, String>{};
      final errors = <String>[];
      for (final key in required) {
        final col = header[norm(key)]!;
        final cell = col < sheet.rows[i].length ? sheet.rows[i][col] : null;
        final value = _cell(cell?.value).trim();
        values[key] = value;
        if (value == '#FORMULA_NOT_ALLOWED') {
          errors.add(key + ': rumus tidak didukung');
        }
      }
      if (values.values.every((v) => v.isEmpty)) continue;
      if (rows.length >= maxDataRows) {
        throw const FormatException(
          'Maksimal 500 baris. Pecah menjadi beberapa file.');
      }
      if (kind == BulkImportKind.employees) {
        _checkEmployee(store, values, errors, seenCode, seenEmployee);
      } else {
        _checkAsset(store, values, errors, seenSerial);
      }
      rows.add(BulkImportRow(i+1, values, errors));
    }
    if (rows.isEmpty) {
      throw const FormatException('Sheet DATA belum berisi baris data.');
    }
    return BulkImportPreview(kind, fileName, bytes, rows);
  }

  static void _checkEmployee(
    AssetStore store, Map<String, String> row, List<String> errors,
    Set<String> codes, Set<String> identities) {
    String val(String x) => row[x]!.trim();
    for (final key in ['Nama Lengkap','Unit','Departemen','Jabatan',
      'Lokasi Kerja']) {
      if (val(key).isEmpty) errors.add(key + ' wajib diisi');
    }
    if (val('Nama Lengkap').isNotEmpty && val('Nama Lengkap').length < 3) {
      errors.add('Nama Lengkap minimal 3 karakter');
    }
    final code = val('Kode Karyawan');
    if (code.isNotEmpty) {
      if (code.length < 3 || !RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(code)) {
        errors.add('Kode Karyawan minimal 3 karakter tanpa spasi');
      }
      if (!codes.add(norm(code))) errors.add('Kode Karyawan sudah ada/berulang');
    }
    final identity = norm(val('Nama Lengkap')) + '|' +
      norm(val('Unit')) + '|' + norm(val('Departemen'));
    if (val('Nama Lengkap').isNotEmpty && val('Unit').isNotEmpty &&
        val('Departemen').isNotEmpty && !identities.add(identity)) {
      errors.add('Karyawan dengan nama, unit dan departemen sama sudah ada');
    }
    final site = store.siteByName(val('Lokasi Kerja'));
    if (site == null || !site.active) {
      errors.add('Lokasi Kerja tidak tersedia/aktif di Master Lokasi');
    }
    if (!validDate(val('Tanggal Bergabung'))) {
      errors.add('Tanggal Bergabung bukan YYYY-MM-DD yang valid');
    }
    final status = norm(val('Status Karyawan'));
    if (status.isNotEmpty && status != 'aktif' && status != 'tidak aktif') {
      errors.add('Status Karyawan harus Aktif atau Tidak Aktif');
    }
  }

  static void _checkAsset(AssetStore store,
      Map<String, String> row, List<String> errors,
      Set<String> serials) {
    String val(String x) => row[x]!.trim();
    for (final key in ['Nama Aset','Kategori','Subkategori',
      'Jenis Aset','Lokasi Utama']) {
      if (val(key).isEmpty) errors.add(key + ' wajib diisi');
    }
    if (val('Nama Aset').isNotEmpty && val('Nama Aset').length < 3) {
      errors.add('Nama Aset minimal 3 karakter');
    }
    AssetCategory? category;
    for (final c in store.categories) {
      if (norm(c.name) == norm(val('Kategori'))) category = c;
    }
    AssetSubcategory? sub;
    if (category == null || !category.active) {
      errors.add('Kategori tidak tersedia/aktif');
    } else {
      for (final s in category.subcategories) {
        if (norm(s.name) == norm(val('Subkategori'))) sub = s;
      }
      if (sub == null || !sub.active) {
        errors.add('Subkategori tidak tersedia/aktif pada kategori');
      } else if (!sub.types.any((t) =>
          norm(t) == norm(val('Jenis Aset')) && sub!.typeIsActive(t))) {
        errors.add('Jenis Aset tidak tersedia/aktif pada subkategori');
      }
    }
    final serial = norm(val('Nomor Seri'));
    if (serial.isNotEmpty && !serials.add(serial)) {
      errors.add('Nomor Seri sudah ada/berulang');
    }
    final site = store.siteByName(val('Lokasi Utama'));
    if (site == null || !site.active) {
      errors.add('Lokasi Utama tidak tersedia/aktif');
    } else {
      AssetArea? area;
      if (val('Area').isNotEmpty) {
        for (final a in site.areas) {
          if (norm(a.name) == norm(val('Area'))) area = a;
        }
        if (area == null || !area.active) {
          errors.add('Area tidak tersedia/aktif pada Lokasi Utama');
        }
      }
      if (val('Titik Penempatan').isNotEmpty) {
        if (val('Area').isEmpty) {
          errors.add('Titik Penempatan membutuhkan Area');
        } else if (area != null && !area.spots.any((p) =>
            norm(p.name) == norm(val('Titik Penempatan')) && p.active)) {
          errors.add('Titik Penempatan tidak tersedia/aktif pada Area');
        }
      }
    }
    if (!validDate(val('Tanggal Perolehan'))) {
      errors.add('Tanggal Perolehan bukan YYYY-MM-DD yang valid');
    }
    final cost = val('Nilai Perolehan');
    if (cost.isNotEmpty && (!RegExp(r'^\d+$').hasMatch(cost) ||
        int.tryParse(cost) == null)) {
      errors.add('Nilai Perolehan harus angka bulat tanpa pemisah');
    }
    if (val('Kondisi').isNotEmpty &&
        !['baru','baik','cukup','kurang baik','rusak']
          .contains(norm(val('Kondisi')))) {
      errors.add('Kondisi tidak dikenal');
    }
    final status = norm(val('Status Penggunaan'));
    if (status == 'digunakan') {
      errors.add('Status Digunakan harus melalui Assigned Assets/BAST');
    } else if (status.isNotEmpty &&
        !['tersedia','dalam perbaikan','hilang'].contains(status)) {
      errors.add('Status Penggunaan tidak dikenal');
    }
  }

  static Uint8List makeErrorReport(BulkImportPreview preview) {
    final book = xls.Excel.createExcel();
    book.rename('Sheet1','KESALAHAN');
    final sheet = book['KESALAHAN'];
    final fields = columns(preview.kind);
    sheet.appendRow([
      xls.TextCellValue('Baris Excel'),
      for (final field in fields) xls.TextCellValue(field),
      xls.TextCellValue('Masalah / Tindakan'),
    ]);
    for (final row in preview.rows.where((r) => !r.valid)) {
      sheet.appendRow([
        xls.IntCellValue(row.excelRow),
        for (final field in fields) xls.TextCellValue(row.value(field)),
        xls.TextCellValue(row.errors.join('; ')),
      ]);
    }
    sheet.setColumnWidth(0, 14);
    for (var i=1; i<=fields.length; i++) sheet.setColumnWidth(i, 22);
    sheet.setColumnWidth(fields.length+1, 66);
    return Uint8List.fromList(book.encode()!);
  }

  static AssetPlacement placement(AssetStore store, BulkImportRow row) {
    final site = store.siteByName(row.value('Lokasi Utama'))!;
    var areaId = '', pointId = '';
    for (final area in site.areas) {
      if (norm(area.name) == norm(row.value('Area'))) {
        areaId = area.id;
        for (final point in area.spots) {
          if (norm(point.name) == norm(row.value('Titik Penempatan'))) {
            pointId = point.id;
          }
        }
      }
    }
    return AssetPlacement(site.id, areaId: areaId, spotId: pointId);
  }
}
