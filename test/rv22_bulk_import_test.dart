import 'dart:typed_data';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

Uint8List fillTemplate(Uint8List bytes, List<List<xls.CellValue?>> rows) {
  final excel = xls.Excel.decodeBytes(bytes);
  final sheet = excel['DATA'];
  for (final row in rows) {
    sheet.appendRow(row);
  }
  return Uint8List.fromList(excel.encode()!);
}

List<xls.CellValue?> cells(List<String> values) =>
  [for (final value in values) xls.TextCellValue(value)];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('RV22 templates contain required headers, guide and master references',
      () async {
    final store = AssetStore();
    await store.initialize();
    for (final kind in BulkImportKind.values) {
      final bytes = BulkImportService.makeTemplate(kind, store);
      expect(bytes, isNotEmpty);
      final workbook = xls.Excel.decodeBytes(bytes);
      expect(workbook.tables.keys, containsAll(['DATA','PANDUAN','REFERENSI']));
      final header = workbook['DATA'].rows.first
        .map((v) => v?.value.toString()).toList();
      for (final required in BulkImportService.columns(kind)) {
        expect(header, contains(required));
      }
      expect(workbook['DATA'].rows.length, 1);
    }
  });

  test('RV22-A employee import is selective, atomic and survives backup',
      () async {
    final store = AssetStore();
    await store.initialize();
    final original = store.employees.length;
    final bytes = fillTemplate(
      BulkImportService.makeTemplate(BulkImportKind.employees, store), [
        cells(['','Karyawan Excel Satu','Distribusi','Operasional',
          'Staf Gudang','Gudang Pusat','2026-11-01','Aktif']),
        cells(['KRY-009991','Karyawan Excel Dua','Outlet','Sales',
          'Supervisor','Outlet Jepara','2026-10-04','Tidak Aktif']),
        cells(['KRY-009991','Karyawan Ganda','Outlet','Sales',
          'Supervisor','Outlet Jepara','2026-10-04','Aktif']),
        cells(['','Karyawan Lokasi Salah','Distribusi','Operasional',
          'Staf Gudang','Gudang Tidak Ada','2026-11-01','Aktif']),
      ]);
    final reviewed = BulkImportService.inspect(
      store, BulkImportKind.employees, bytes);
    expect(reviewed.rows, hasLength(4));
    expect(reviewed.validCount, 2);
    expect(reviewed.invalidCount, 2);
    expect(reviewed.rows[2].errors.join(' '), contains('Kode Karyawan'));
    expect(reviewed.rows[3].errors.join(' '), contains('Lokasi Kerja'));
    final report = BulkImportService.makeErrorReport(reviewed);
    expect(xls.Excel.decodeBytes(report)['KESALAHAN'].rows.length, 3);
    final imported = await store.confirmBulkImport(reviewed);
    expect(imported, 2);
    expect(store.employees.length, original + 2);
    final one = store.employees.firstWhere((e) => e.name == 'Karyawan Excel Satu');
    final two = store.employees.firstWhere((e) => e.name == 'Karyawan Excel Dua');
    expect(one.code, startsWith('KRY-'));
    expect(two.code, 'KRY-009991');
    expect(one.startDate, '2026-11-01');
    expect(two.active, false);
    expect(store.employees.where((e) => e.code == two.code), hasLength(1));
    final backup = AssetStore()..restore(store.backup());
    expect(backup.employees.length, original + 2);
    expect(backup.employeeById(one.id)?.startDate, '2026-11-01');
    expect(BulkImportService.inspect(store, BulkImportKind.employees, bytes)
      .validCount, 0);
  });

  test('RV22-B unit asset import uses global codes and validated three-level sites',
      () async {
    final store = AssetStore();
    await store.initialize();
    final site = store.siteByName('Gudang Pusat')!;
    final area = await store.addArea(site, 'Gudang Bawah');
    await store.addSpot(site, area, 'Rak C-3');
    final before = store.assets.length, first = store.nextNumber;
    final bytes = fillTemplate(
      BulkImportService.makeTemplate(BulkImportKind.assets, store), [
        cells(['Meja Excel Satu','Furnitur','Meja','Meja Kerja',
          'Lokal','','SCN-XLSX-1','Gudang Pusat','Gudang Bawah','Rak C-3',
          '2026-11-01','1200000','Baik','Tersedia']),
        cells(['Meja Excel Dua','Furnitur','Meja','Meja Kerja',
          'Lokal','','SCN-XLSX-2','Gudang Pusat','','',
          '','', 'Baru', 'Tersedia']),
        cells(['Laptop Tanpa BAST','Teknologi Informasi & Komunikasi',
          'Komputer','Laptop','Lenovo','','SCN-XLSX-3',
          'Gudang Pusat','','','','2500000','Baik','Digunakan']),
        cells(['Rak Salah Kategori','Kategori Nonexistent','Meja','Meja Kerja',
          'Lokal','','','Gudang Pusat','','','','10000','Baik','Tersedia']),
      ]);
    final preview = BulkImportService.inspect(
      store, BulkImportKind.assets, bytes);
    expect(preview.validCount, 2);
    expect(preview.invalidCount, 2);
    expect(preview.rows[2].errors.join(' '), contains('Assigned Assets'));
    expect(preview.rows[3].errors.join(' '), contains('Kategori'));
    expect(await store.confirmBulkImport(preview), 2);
    expect(store.assets.length, before + 2);
    expect(store.nextNumber, first + 2);
    final firstAdded = store.assets.firstWhere((a) => a.name == 'Meja Excel Satu');
    final secondAdded = store.assets.firstWhere((a) => a.name == 'Meja Excel Dua');
    expect(firstAdded.code, 'UDL-AST-' + first.toString().padLeft(6,'0'));
    expect(secondAdded.code, 'UDL-AST-' + (first+1).toString().padLeft(6,'0'));
    expect(store.locationPath(firstAdded), 'Gudang Pusat / Gudang Bawah / Rak C-3');
    expect(store.locationPath(secondAdded), 'Gudang Pusat');
    expect(firstAdded.acquisitionCost, 1200000);
    expect(secondAdded.acquisitionCost, null);
    expect(store.photosFor(firstAdded.id), isEmpty);
    expect(firstAdded.assignedEmployeeId, '');
    final restored = AssetStore()..restore(store.backup());
    final loaded = restored.assets.firstWhere((a) => a.id == firstAdded.id);
    expect(restored.locationPath(loaded),
      'Gudang Pusat / Gudang Bawah / Rak C-3');
  });

  test('RV22 prevents duplicates, stale previews and invalid dates', () async {
    final store = AssetStore();
    await store.initialize();
    final date = fillTemplate(
      BulkImportService.makeTemplate(BulkImportKind.employees, store), [
        cells(['','Tanggal Salah','Outlet','Penjualan',
          'Staf','Outlet Jepara','2026-02-30','Aktif']),
      ]);
    expect(BulkImportService.inspect(store, BulkImportKind.employees, date)
      .rows.single.errors.join(' '), contains('Tanggal Bergabung'));
    final duplicate = fillTemplate(
      BulkImportService.makeTemplate(BulkImportKind.assets, store), [
        cells(['Printer Duplikat','Teknologi Informasi & Komunikasi',
          'Periferal Komputer','Printer Dokumen','Brother','','DEMO-002',
          'Gudang Pusat','','','','2000000','Baik','Tersedia']),
      ]);
    final report = BulkImportService.inspect(store, BulkImportKind.assets, duplicate);
    expect(report.validCount, 0);
    expect(report.rows.single.errors.join(' '), contains('Nomor Seri'));
    await expectLater(store.confirmBulkImport(report), throwsFormatException);
    final valid = fillTemplate(
      BulkImportService.makeTemplate(BulkImportKind.employees, store), [
        cells(['KRY-STABLE','Karyawan Simulasi Stale','Outlet','Sales',
          'Sales','Outlet Jepara','','Aktif']),
      ]);
    final preview = BulkImportService.inspect(store, BulkImportKind.employees, valid);
    await store.addEmployee(code:'KRY-STABLE',
      name:'Karyawan Sudah Ada',
      unit:'Distribusi', department:'Operasional', jobTitle:'Staf',
      workLocation:'Gudang Pusat');
    final count = store.employees.length;
    await expectLater(store.confirmBulkImport(preview), throwsStateError);
    expect(store.employees.length, count);
  });

  testWidgets('RV22 import actions on title left of Add and open Excel modal',
      (tester) async {
    tester.view.physicalSize = const Size(1600,900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    expect(find.text('Impor Data Aset'), findsOneWidget);
    expect(find.text('Tambah Aset'), findsOneWidget);
    await tester.tap(find.text('Impor Data Aset'));
    await tester.pumpAndSettle();
    expect(find.text('Unduh Template'), findsOneWidget);
    expect(find.text('Upload Template'), findsOneWidget);
    expect(find.byKey(const ValueKey('rv22-confirm-import')), findsOneWidget);
    await tester.tap(find.byTooltip('Tutup').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Master Karyawan').first);
    await tester.pumpAndSettle();
    expect(find.text('Impor Data Karyawan'), findsOneWidget);
    expect(find.text('Tambah Karyawan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
