import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AssetEmployee> employee(AssetStore store) => store.addEmployee(
    code: 'KRY-TES-001', name: 'Karyawan Uji Aset',
    unit: 'Outlet', department: 'Penjualan',
    jobTitle: 'Supervisor', workLocation: 'Outlet Jepara');

  Future<List<AssetRecord>> availableAssets(AssetStore store) =>
    store.registerUnits(quantity: 2, name: 'Kursi Kerja Uji',
      category: 'Furnitur', subcategory: 'Kursi',
      assetType: 'Kursi Kerja', brand: 'Uji', model: '',
      serial: '', location: 'Gudang Pusat', holder: '',
      status: 'Tersedia', condition: 'Baik',
      cost: null, acquisitionDate: '');

  SelectedAssetPhoto uatProof() {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGMMmHaJgYGBiYGBgYGBAQAUSAG8NMsrTwAAAABJRU5ErkJggg==');
    return SelectedAssetPhoto(bytes, 'bukti-uat.png', bytes.length);
  }

  test('Master karyawan menggunakan kode unik dan status aktif', () async {
    final store = AssetStore();
    await store.initialize();
    final person = await employee(store);
    expect(person.code, 'KRY-TES-001');
    expect(person.active, true);
    await expectLater(
      employee(store), throwsFormatException);
    await store.updateEmployee(person,
      name: 'Karyawan Uji Aset Baru',
      unit: 'Outlet', department: 'Penjualan',
      jobTitle: 'Supervisor', workLocation: 'Outlet Jepara',
      startDate: '', reason: 'Koreksi identitas');
    expect(person.name, 'Karyawan Uji Aset Baru');
    await store.setEmployeeActive(person, false, 'Sudah berhenti');
    expect(person.active, false);
    expect(store.events.first.type, 'Master Karyawan');
    final saved = AssetStore()..restore(store.backup());
    expect(saved.employeeById(person.id)?.active, false);
  });

  test('Penugasan multiaset, cegah duplikat, pengembalian sebagian dan BA', () async {
    final store = AssetStore();
    await store.initialize();
    final person = await employee(store);
    final records = await availableAssets(store);
    final batch = await store.createAssignment(
      employeeId: person.id,
      kind: 'Berkelanjutan',
      assetIds: records.map((a) => a.id).toList(),
      accessories: {records[0].id: 'Kunci cadangan'},
      notes: 'Fasilitas kerja');
    expect(batch.lines, hasLength(2));
    expect(batch.status, 'Menunggu Penerimaan');
    expect(records[0].status, 'Tersedia');
    expect(records[0].assignedEmployeeId, isEmpty);
    expect(store.canAssignAsset(records[0]), false);
    await expectLater(
      store.createAssignment(employeeId: person.id,
        kind: 'Berkelanjutan',
        assetIds: [records[0].id], accessories: {}),
      throwsFormatException);
    final ba = await AssetBastPdf.handover(batch);
    expect(utf8.decode(ba.take(5).toList()), '%PDF-');
    expect(ba.length, greaterThan(1700));
    await store.confirmAssignment(batch, true, '', proofPhotos: {
      for (final line in batch.lines) line.assetId: uatProof(),
    });
    expect(batch.status, 'Aktif');
    expect(records[0].assignedEmployeeId, person.id);
    expect(records[0].holder, person.name);
    final firstReceipt = await store.returnAssignedAssets(
      record: batch,
      inspections: {
        batch.lines[0].id: const AssetReturnInput(
          condition: 'Rusak',
          accessories: 'Kunci cadangan',
          notes: 'Dudukan patah'),
      },
      receivingLocation: 'Gudang Pusat',
      receivedByName: 'Petugas GA Simulasi',
      notes: 'Pengembalian parsial',
      proofPhotos: {records[0].id: uatProof()});
    expect(batch.status, 'Aktif');
    expect(batch.activeCount, 1);
    expect(records[0].status, 'Dalam Perbaikan');
    expect(records[0].assignedEmployeeId, isEmpty);
    expect(records[1].assignedEmployeeId, person.id);
    expect(firstReceipt.lines.single.returnCondition, 'Rusak');
    final returnPdf = await AssetBastPdf.assetReturn(batch, firstReceipt);
    expect(utf8.decode(returnPdf.take(5).toList()), '%PDF-');
    await store.returnAssignedAssets(
      record: batch,
      inspections: {
        batch.lines[1].id: const AssetReturnInput(
          condition: 'Baik', accessories: 'Lengkap'),
      },
      receivingLocation: 'Kantor Pusat',
      proofPhotos: {records[1].id: uatProof()});
    expect(batch.status, 'Selesai');
    expect(records[1].status, 'Tersedia');
    expect(records[1].holder, isEmpty);
    expect(store.returnReceipts, hasLength(2));
    expect(store.returnReceipts
      .map((r) => r.draftReference).toSet().length, 2);
    final saved = AssetStore()..restore(store.backup());
    expect(saved.assignments.single.status, 'Selesai');
    expect(saved.returnReceipts, hasLength(2));
    expect(saved.assets.any((a) =>
      a.id == records[0].id && a.status == 'Dalam Perbaikan'), true);
  });

  test('Karyawan nonaktif tidak menerima penugasan baru; BAST historis tetap', () async {
    final store = AssetStore();
    await store.initialize();
    final person = await employee(store);
    final item = store.assets.firstWhere((a) => a.status == 'Tersedia');
    final batch = await store.createAssignment(employeeId: person.id,
      kind: 'Berkelanjutan', assetIds: [item.id], accessories: {});
    final snapshot = batch.employeeSnapshot['name'];
    await store.setEmployeeActive(person, false, 'Keluar perusahaan');
    expect(batch.employeeSnapshot['name'], snapshot);
    await expectLater(
      store.confirmAssignment(batch, true, ''),
      throwsFormatException);
    await store.confirmAssignment(batch, false, 'Penerima nonaktif');
    expect(batch.status, 'Ditolak');
    expect(store.canAssignAsset(item), true);
  });

  test('BAST PDF menyimpan bukti foto penyerahan dan pengembalian', () async {
    final store = AssetStore();
    await store.initialize();
    final person = await employee(store);
    final asset = store.assets.firstWhere((a) => a.status == 'Tersedia');
    const png = 'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGMMmHaJgYGBiYGBgYGBAQAUSAG8NMsrTwAAAABJRU5ErkJggg==';
    final bytes = Uint8List.fromList(base64Decode(png));
    await store.addPhoto(asset, bytes, 'serah-terima.png',
      'Tampak Fisik Aset');
    final batch = await store.createAssignment(
      employeeId: person.id, kind: 'Berkelanjutan',
      assetIds: [asset.id], accessories: {});
    expect(batch.lines.single.photoIds, hasLength(1));
    final pdf = await AssetBastPdf.handover(batch, store: store);
    expect(utf8.decode(pdf.take(5).toList()), '%PDF-');
    await store.confirmAssignment(batch, true, '', proofPhotos: {
      for (final line in batch.lines) line.assetId: uatProof(),
    });
    await store.addPhoto(asset, bytes, 'kembali.png',
      'Dokumentasi Kondisi', note: 'Kondisi saat dikembalikan');
    final receipt = await store.returnAssignedAssets(
      record: batch,
      inspections: {
        batch.lines.single.id:
          const AssetReturnInput(condition: 'Baik'),
      },
      receivingLocation: 'Gudang Pusat',
      proofPhotos: {asset.id: uatProof()});
    expect(receipt.lines.single.proofPhotoIds, isNotEmpty);
    expect(store.evidenceFor('assignment_return', receipt.id, asset.id),
      hasLength(1));
    final returnPdf = await AssetBastPdf.assetReturn(
      batch, receipt, store: store);
    expect(utf8.decode(returnPdf.take(5).toList()), '%PDF-');
    final restored = AssetStore()..restore(store.backup());
    expect(restored.assignments.single.lines.single.photoIds, hasLength(1));
    expect(restored.returnReceipts.single.lines.single.proofPhotoIds, isNotEmpty);
    expect(restored.evidencePhotos, hasLength(2));
  });

  test('Data lama tetap terbaca tanpa auto-link PIC berdasarkan nama', () async {
    final store = AssetStore();
    await store.initialize();
    final old = store.assets.first;
    expect(old.holder, 'Staf Finance');
    expect(old.assignedEmployeeId, isEmpty);
    expect(store.canAssignAsset(old), false);
    final json = jsonDecode(store.backup()) as Map<String,dynamic>;
    json.remove('employees');
    json.remove('assignments');
    json.remove('returnReceipts');
    json.remove('nextEmployeeNumber');
    json.remove('nextAssignmentNumber');
    json.remove('nextReturnNumber');
    final restored = AssetStore()..restore(jsonEncode(json));
    expect(restored.assets.length, store.assets.length);
    expect(restored.employees, isEmpty);
    expect(restored.assignments, isEmpty);
  });
}
