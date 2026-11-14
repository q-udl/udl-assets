part of 'main.dart';

extension AssetBulkImportOperations on AssetStore {
  /// All accepted rows are committed using one SharedPreferences write.
  /// No existing asset, employee, assignment or photo is overwritten.
  Future<int> confirmBulkImport(BulkImportPreview preview) async {
    if (loadError != null) {
      throw StateError(
        'Penyimpanan lokal bermasalah; jangan impor sebelum dipulihkan.');
    }
    final refreshed = BulkImportService.inspect(
      this, preview.kind, preview.bytes, fileName: preview.fileName);
    if (refreshed.rows.length != preview.rows.length ||
        refreshed.rows.asMap().entries.any((entry) {
          final old = preview.rows[entry.key];
          final fresh = entry.value;
          return old.excelRow != fresh.excelRow ||
            jsonEncode(old.values) != jsonEncode(fresh.values) ||
            jsonEncode(old.errors) != jsonEncode(fresh.errors);
        })) {
      throw StateError(
        'Master Data berubah sejak pratinjau. Unggah ulang untuk validasi.');
    }
    final valid = refreshed.rows.where((row) => row.valid).toList();
    if (valid.isEmpty) {
      throw const FormatException(
        'Tidak ada baris valid. Perbaiki template dan upload ulang.');
    }

    final oldAssets = assets, oldStaff = employees, oldEvents = events;
    final oldNextAsset = nextNumber, oldNextEmployee = nextEmployeeNumber;
    try {
      final now = DateTime.now().toIso8601String();
      final importedEvents = <EventRecord>[];
      if (preview.kind == BulkImportKind.employees) {
        // Reserve every supplied code before assigning generated codes.
        final reserved = <String>{
          for (final staff in employees) staff.code.toLowerCase(),
          for (final row in valid)
            if (row.value('Kode Karyawan').isNotEmpty)
              row.value('Kode Karyawan').toLowerCase(),
        };
        final imported = <AssetEmployee>[];
        for (final row in valid) {
          var code = row.value('Kode Karyawan');
          if (code.isEmpty) {
            while (true) {
              final candidate = 'KRY-' +
                nextEmployeeNumber.toString().padLeft(6, '0');
              nextEmployeeNumber++;
              if (reserved.add(candidate.toLowerCase())) {
                code = candidate;
                break;
              }
            }
          } else if (code.toUpperCase().startsWith('KRY-')) {
            final number = int.tryParse(code.substring(4));
            if (number != null && number >= nextEmployeeNumber) {
              nextEmployeeNumber = number + 1;
            }
          }
          final site = siteByName(row.value('Lokasi Kerja'))!;
          final staff = AssetEmployee(
            id: uuid.v4(), code: code,
            name: row.value('Nama Lengkap'),
            unit: row.value('Unit'),
            department: row.value('Departemen'),
            jobTitle: row.value('Jabatan'),
            workLocation: site.name,
            startDate: row.value('Tanggal Bergabung'),
            active: BulkImportService.norm(
              row.value('Status Karyawan')) != 'tidak aktif',
            createdAt: now, updatedAt: now,
          );
          imported.add(staff);
          importedEvents.add(EventRecord('', 'Impor Karyawan',
            'Baris ' + row.excelRow.toString() + ': ' +
              staff.name + ' (' + staff.code + ')', now));
        }
        employees = [...imported, ...employees];
      } else {
        final imported = <AssetRecord>[];
        for (final row in valid) {
          final c = categories.firstWhere((category) =>
            BulkImportService.norm(category.name) ==
              BulkImportService.norm(row.value('Kategori')));
          final sub = c.subcategories.firstWhere((item) =>
            BulkImportService.norm(item.name) ==
              BulkImportService.norm(row.value('Subkategori')));
          final type = BulkImportService.canonical(
            row.value('Jenis Aset'), sub.types);
          final site = siteByName(row.value('Lokasi Utama'))!;
          final condition = BulkImportService.canonical(
            row.value('Kondisi'),
            const ['Baru','Baik','Cukup','Kurang Baik','Rusak']);
          final status = BulkImportService.canonical(
            row.value('Status Penggunaan'),
            const ['Tersedia','Dalam Perbaikan','Hilang']);
          final textCost = row.value('Nilai Perolehan');
          final cost = textCost.isEmpty ? null : int.parse(textCost);
          final asset = AssetRecord(
            uuid.v4(),
            'UDL-AST-' + nextNumber.toString().padLeft(6,'0'),
            row.value('Nama Aset'), c.name, row.value('Merek'),
            row.value('Nomor Seri'), site.name, '',
            condition.isEmpty ? 'Baik' : condition,
            status.isEmpty ? 'Tersedia' : status,
            cost ?? 0,
            subcategory: sub.name, assetType: type,
          );
          asset.model = row.value('Model/Tipe');
          asset.acquisitionDate = row.value('Tanggal Perolehan');
          asset.acquisitionCost = cost;
          asset.categoryId = c.code;
          asset.subcategoryId = sub.id;
          asset.typeId = sub.typeId(type);
          applyPlacement(asset, BulkImportService.placement(this, row));
          imported.add(asset);
          nextNumber++;
          importedEvents.add(EventRecord(asset.id, 'Registrasi',
            'Impor Excel baris ' + row.excelRow.toString() +
              ' · ' + preview.fileName, now));
        }
        assets = [...imported, ...assets];
      }
      events = [...importedEvents, ...events];
      await persist();
      return valid.length;
    } catch (_) {
      assets = oldAssets;
      employees = oldStaff;
      events = oldEvents;
      nextNumber = oldNextAsset;
      nextEmployeeNumber = oldNextEmployee;
      rethrow;
    }
  }
}
