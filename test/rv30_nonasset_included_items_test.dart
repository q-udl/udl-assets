import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final tinyPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGMMmHaJgYGBiYGBgYGBAQAUSAG8NMsrTwAAAABJRU5ErkJggg==');
  SelectedAssetPhoto proof(String name) =>
    SelectedAssetPhoto(tinyPng, name, tinyPng.length);

  Future<({AssetStore store, AssetAssignment batch, AssetRecord asset})>
      createCustody({String includedItems = ''}) async {
    final store = AssetStore();
    await store.initialize();
    final employee = await store.addEmployee(
      name: 'Bima Santosa', unit: 'Distribusi',
      department: 'Operasional', jobTitle: 'Staf Gudang',
      workLocation: 'Gudang Pusat');
    final asset = store.assets.firstWhere(store.canAssignAsset);
    final batch = await store.createAssignment(
      employeeId: employee.id, kind: 'Berkelanjutan',
      assetIds: [asset.id],
      accessories: {if (includedItems.isNotEmpty) asset.id: includedItems});
    return (store: store, batch: batch, asset: asset);
  }

  test('RV030-12: newly recorded non-asset items do not generate asset codes',
      () async {
    final fixture = await createCustody(
      includedItems: 'Buku panduan, kemasan bawaan');
    final beforeCodes = fixture.store.assets.map((a) => a.code).toSet();
    final line = fixture.batch.lines.single;
    expect(line.accessories, 'Buku panduan, kemasan bawaan');
    expect(line.accessoriesClassification, 'non_asset');
    expect(line.hasLegacyAccessories, isFalse);
    expect(line.itemRecordLabel, 'Item Penyerta Non-Aset');
    expect(fixture.store.assets.map((a) => a.code).toSet(), beforeCodes);
    final json = line.toJson();
    expect(json['accessories'], 'Buku panduan, kemasan bawaan');
    expect(json['accessoriesClassification'], 'non_asset');
    final restored = AssetStore()..restore(fixture.store.backup());
    expect(restored.assignments.single.lines.single.hasLegacyAccessories,
      isFalse);
    expect(restored.assets.map((a) => a.code).toSet(), beforeCodes);
  });

  test('RV030-12: return tracks actually returned included items separately',
      () async {
    final fixture = await createCustody(
      includedItems: 'Buku panduan, kemasan bawaan');
    await fixture.store.confirmAssignment(fixture.batch, true, '',
      handedOverByName: 'Petugas GA',
      handoverLocation: 'Gudang Pusat',
      bastNumber: 'BAST-ITEM-001',
      proofPhotos: {fixture.asset.id: proof('serah.png')});
    final receipt = await fixture.store.returnAssignedAssets(
      record: fixture.batch,
      inspections: {
        fixture.batch.lines.single.id: const AssetReturnInput(
          condition: 'Baik', accessories: 'Buku panduan',
          notes: 'Kemasan tidak ikut kembali'),
      },
      receivingLocation: 'Gudang Pusat',
      receivedByName: 'Petugas Penerimaan',
      proofPhotos: {fixture.asset.id: proof('kembali.png')});
    final returned = receipt.lines.single;
    expect(returned.accessoriesReturned, 'Buku panduan');
    expect(returned.accessoriesClassification, 'non_asset');
    expect(returned.hasLegacyAccessories, isFalse);
    expect(fixture.batch.lines.single.accessories,
      'Buku panduan, kemasan bawaan');
    expect(fixture.batch.status, 'Selesai');
    final recovered = AssetStore()..restore(fixture.store.backup());
    expect(recovered.returnReceipts.single.lines.single.accessoriesReturned,
      'Buku panduan');
    expect(recovered.returnReceipts.single.lines.single.hasLegacyAccessories,
      isFalse);
  });

  test('RV030-12: legacy Kelengkapan survives restore without reclassification',
      () async {
    final fixture = await createCustody(includedItems: 'Charger, case HP');
    await fixture.store.confirmAssignment(fixture.batch, true, '',
      handedOverByName: 'Petugas GA',
      handoverLocation: 'Gudang Pusat',
      bastNumber: 'BAST-ITEM-LEGACY',
      proofPhotos: {fixture.asset.id: proof('bukti.png')});
    final receipt = await fixture.store.returnAssignedAssets(
      record: fixture.batch,
      inspections: {
        fixture.batch.lines.single.id: const AssetReturnInput(
          condition: 'Baik', accessories: 'Charger'),
      },
      receivingLocation: 'Gudang Pusat',
      receivedByName: 'Petugas Penerimaan',
      proofPhotos: {fixture.asset.id: proof('retur.png')});
    final raw = jsonDecode(fixture.store.backup()) as Map<String, dynamic>;
    final assignment = (raw['assignments'] as List<dynamic>).single
      as Map<String, dynamic>;
    final line = (assignment['lines'] as List<dynamic>).single
      as Map<String, dynamic>;
    line.remove('accessoriesClassification');
    final returnJson = (raw['returnReceipts'] as List<dynamic>).single
      as Map<String, dynamic>;
    final returnLine = (returnJson['lines'] as List<dynamic>).single
      as Map<String, dynamic>;
    returnLine.remove('accessoriesClassification');
    final restored = AssetStore()..restore(jsonEncode(raw));
    final historicLine = restored.assignments.single.lines.single;
    expect(historicLine.accessories, 'Charger, case HP');
    expect(historicLine.hasLegacyAccessories, isTrue);
    expect(historicLine.itemRecordLabel, contains('Kelengkapan historis'));
    final historicReturn = restored.returnReceipts.single.lines.single;
    expect(historicReturn.accessoriesReturned, 'Charger');
    expect(historicReturn.hasLegacyAccessories, isTrue);
    expect(historicReturn.assignmentLineId, receipt.lines.single.assignmentLineId);
    final reencoded = AssetStore()..restore(restored.backup());
    expect(reencoded.assignments.single.lines.single.hasLegacyAccessories,
      isTrue);
    expect(reencoded.returnReceipts.single.lines.single.hasLegacyAccessories,
      isTrue);
    expect(reencoded.assignments.single.lines.single.accessories,
      'Charger, case HP');
  });

  test('RV030-12: registered physical items retain distinct asset identities',
      () async {
    final fixture = await createCustody();
    final registered = await fixture.store.registerUnits(
      quantity: 2, name: 'Kursi Kantor',
      category: 'Furnitur', subcategory: 'Kursi',
      assetType: 'Kursi Kerja', brand: 'Lokal', model: '',
      serial: '', location: 'Gudang Pusat', holder: '',
      status: 'Tersedia', condition: 'Baik',
      cost: null, acquisitionDate: '');
    final codes = [fixture.asset.code, ...registered.map((a) => a.code)];
    expect(codes.toSet(), hasLength(3));
    expect(registered[0].id, isNot(registered[1].id));
    expect(fixture.asset.id, isNot(registered[0].id));
    expect(fixture.batch.lines.single.assetId, fixture.asset.id);
    expect(fixture.batch.lines.single.accessories, isEmpty);
  });
}
