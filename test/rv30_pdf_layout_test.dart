import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final proofBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGMMmHaJgYGBiYGBgYGBAQAUSAG8NMsrTwAAAABJRU5ErkJggg==');

  SelectedAssetPhoto proof(int index) =>
      SelectedAssetPhoto(proofBytes, 'bukti-aset-$index.png',
        proofBytes.length);

  test('RV030 PDF: multiphoto BAST and partial return produce renderable PDFs',
      () async {
    final store = AssetStore();
    await store.initialize();
    final employee = await store.addEmployee(
      name: 'Dimas Nugroho', unit: 'Distribusi',
      department: 'Operasional', jobTitle: 'Supervisor',
      workLocation: 'Gudang Pusat');
    final records = await store.registerUnits(
      quantity: 8, name: 'Kursi Operasional',
      category: 'Furnitur', subcategory: 'Kursi',
      assetType: 'Kursi Kerja', brand: 'Lokal', model: '',
      serial: '', location: 'Gudang Pusat', holder: '',
      status: 'Tersedia', condition: 'Baik',
      cost: null, acquisitionDate: '');
    final batch = await store.createAssignment(
      employeeId: employee.id,
      kind: 'Berkelanjutan',
      assetIds: records.map((asset) => asset.id).toList(),
      accessories: {});
    await store.confirmAssignment(
      batch, true, '',
      handedOverByName: 'Petugas GA',
      handoverLocation: 'Gudang Pusat', bastNumber: 'BAST-PDF-QA-001',
      proofPhotos: {
        for (var index = 0; index < records.length; index++)
          records[index].id: proof(index),
      });
    expect(batch.handedOverByName, 'Petugas GA');
    expect(batch.bastNumber, 'BAST-PDF-QA-001');
    expect(batch.canPrintBast, isTrue);
    expect(batch.employeeSnapshot['name'], 'Dimas Nugroho');
    final bast = await AssetBastPdf.handover(batch, store: store);
    expect(utf8.decode(bast.take(5).toList()), '%PDF-');

    final selected = records.take(4).toList();
    final receipt = await store.returnAssignedAssets(
      record: batch,
      inspections: {
        for (final line in batch.lines)
          if (selected.any((a) => a.id == line.assetId))
            line.id: const AssetReturnInput(
              condition: 'Baik', accessories: 'Lengkap'),
      },
      receivingLocation: 'Gudang Pusat',
      receivedByName: 'Petugas Penerimaan GA',
      proofPhotos: {
        for (var index = 0; index < selected.length; index++)
          selected[index].id: proof(index + 10),
      },
    );
    expect(receipt.lines.length, 4);
    expect(batch.activeCount, 4);
    final returned = await AssetBastPdf.assetReturn(
      batch, receipt, store: store);
    expect(utf8.decode(returned.take(5).toList()), '%PDF-');

    final single = (await store.registerUnits(
      quantity: 1, name: 'Printer Operasional',
      category: 'Furnitur', subcategory: 'Kursi',
      assetType: 'Kursi Kerja', brand: 'Lokal', model: '',
      serial: 'PR-UNIT-01', location: 'Gudang Pusat', holder: '',
      status: 'Tersedia', condition: 'Baik', cost: null,
      acquisitionDate: '')).single;
    final one = await store.createAssignment(
      employeeId: employee.id, kind: 'Berkelanjutan',
      assetIds: [single.id], accessories: {});
    await store.confirmAssignment(one, true, '',
      handedOverByName: 'Petugas GA',
      handoverLocation: 'Gudang Pusat',
      bastNumber: 'BAST-PDF-QA-002',
      proofPhotos: {single.id: proof(99)});
    final singleBast = await AssetBastPdf.handover(one, store: store);
    expect(utf8.decode(singleBast.take(5).toList()), '%PDF-');

    // Persist fixtures for CI's independent pdfinfo/pdftoppm visual checks.
    final directory = Directory('build/rv030-pdf-qa');
    await directory.create(recursive: true);
    await File('${directory.path}/BAST-multi-photo.pdf').writeAsBytes(bast);
    await File('${directory.path}/BAST-single-photo.pdf').writeAsBytes(singleBast);
    await File('${directory.path}/BA-Pengembalian-parsial.pdf')
      .writeAsBytes(returned);
  });
}
