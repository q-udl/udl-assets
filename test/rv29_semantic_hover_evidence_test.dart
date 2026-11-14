import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  SelectedAssetPhoto proof(String name) {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGMMmHaJgYGBiYGBgYGBAQAUSAG8NMsrTwAAAABJRU5ErkJggg==');
    return SelectedAssetPhoto(bytes, name, bytes.length);
  }

  test('RV29 semantic action colors and physical condition badges', () {
    expect(assetActionColor(AssetActionTone.primary),
      const Color(0xFF2766A2));
    expect(assetActionColor(AssetActionTone.success),
      const Color(0xFF168366));
    expect(assetActionColor(AssetActionTone.warning),
      const Color(0xFFB97813));
    expect(assetActionColor(AssetActionTone.danger),
      const Color(0xFFC04D53));
    expect(assetConditionColor('Cukup'), const Color(0xFFB97813));
    expect(assetConditionColor('Rusak'), const Color(0xFFC04D53));
    expect(assetFilledStyle(AssetActionTone.primary).minimumSize!
      .resolve({})!.height, greaterThanOrEqualTo(48));
  });

  test('RV29 proof is required per physical asset and persists only on approval',
      () async {
    final store = AssetStore();
    await store.initialize();
    final employee = await store.addEmployee(
      name: 'Karyawan Bukti UAT',
      unit: 'Distribusi', department: 'Gudang',
      jobTitle: 'Staf Gudang', workLocation: 'Gudang Pusat');
    final units = await store.registerUnits(
      quantity: 2, name: 'Laptop Bukti UAT',
      category: 'Teknologi Informasi & Komunikasi',
      subcategory: 'Komputer', assetType: 'Laptop',
      brand: 'UAT', model: '', serial: '',
      location: 'Gudang Pusat', holder: '',
      status: 'Tersedia', condition: 'Baik',
      cost: null, acquisitionDate: '');
    final batch = await store.createAssignment(
      employeeId: employee.id, kind: 'Berkelanjutan',
      assetIds: units.map((u) => u.id).toList(), accessories: {});
    expect(batch.status, 'Menunggu Serah Terima');
    await expectLater(
      store.confirmAssignment(batch, true, ''), throwsFormatException);
    expect(batch.status, 'Menunggu Serah Terima');
    expect(store.evidencePhotos, isEmpty);
    await expectLater(
      store.confirmAssignment(batch, true, '', proofPhotos: {
        units.first.id: proof('satu.png'),
      }), throwsFormatException);
    expect(store.evidencePhotos, isEmpty);

    await store.confirmAssignment(batch, true, '',
      handedOverByName: 'Petugas GA', proofPhotos: {
      for (final unit in units) unit.id: proof('serah-' + unit.code + '.png'),
    });
    expect(batch.status, 'Aktif');
    expect(store.evidencePhotos, hasLength(2));
    expect(store.photos, isEmpty,
      reason: 'Evidence must not consume the catalog-photo quota.');
    for (final line in batch.lines) {
      expect(line.handoverProofPhotoIds, hasLength(1));
      expect(store.evidenceFor('assignment_handover',
        batch.id, line.assetId), hasLength(1));
    }
    final handover = await AssetBastPdf.handover(batch, store: store);
    expect(utf8.decode(handover.take(5).toList()), '%PDF-');

    await expectLater(
      store.returnAssignedAssets(
        record: batch,
        inspections: {
          batch.lines.first.id: const AssetReturnInput(condition: 'Rusak'),
        }, receivingLocation: 'Gudang Pusat'),
      throwsFormatException);
    expect(store.returnReceipts, isEmpty);
    expect(batch.activeCount, 2);

    final returned = await store.returnAssignedAssets(
      record: batch,
      inspections: {
        batch.lines.first.id: const AssetReturnInput(condition: 'Rusak'),
      },
      receivingLocation: 'Gudang Pusat',
      receivedByName: 'Petugas GA',
      proofPhotos: {units.first.id: proof('kembali-satu.png')});
    expect(returned.lines.single.proofPhotoIds, hasLength(1));
    expect(batch.activeCount, 1);
    expect(store.evidencePhotos, hasLength(3));
    expect(store.evidenceFor('assignment_return',
      returned.id, units.first.id), hasLength(1));
    expect(store.evidenceFor('assignment_return',
      returned.id, units.last.id), isEmpty);
    final returnPdf = await AssetBastPdf.assetReturn(
      batch, returned, store: store);
    expect(utf8.decode(returnPdf.take(5).toList()), '%PDF-');

    final restored = AssetStore()..restore(store.backup());
    expect(restored.evidencePhotos, hasLength(3));
    expect(restored.assignments.single.lines
      .every((l) => l.handoverProofPhotoIds.length == 1), isTrue);
    expect(restored.returnReceipts.single.lines.single.proofPhotoIds,
      hasLength(1));
  });

  test('RV29 transfer acceptance requires a proof; rejection does not',
      () async {
    final store = AssetStore();
    await store.initialize();
    final asset = store.assets.first;
    final origin = asset.location;
    final transfer = await store.proposeTransfer(
      asset, 'Outlet Jepara', 'PIC Bukti', 'Perpindahan UAT');
    await expectLater(store.confirmTransfer(transfer, true, ''),
      throwsFormatException);
    expect(transfer.state, 'Menunggu Penerimaan');
    expect(asset.location, origin);
    await store.confirmTransfer(transfer, true, 'Diterima',
      proofPhoto: proof('bukti-mutasi.png'));
    expect(transfer.proofPhotoIds, hasLength(1));
    expect(store.evidenceFor('transfer_handover',
      transfer.id, asset.id), hasLength(1));
    final asset2 = store.assets.last;
    final declined = await store.proposeTransfer(
      asset2, 'Gudang Pusat', 'PIC UAT', 'Simulasi ditolak');
    await store.confirmTransfer(declined, false, 'Tidak disetujui');
    expect(declined.state, contains('Ditolak'));
    expect(store.evidenceFor('transfer_handover',
      declined.id, asset2.id), isEmpty);
  });

  testWidgets('RV29 desktop: hovering one asset cell highlights the entire row',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    const tableKey = ValueKey('adaptive-asset-table');
    Table table() => tester.widget<Table>(find.byKey(tableKey));
    expect(table().children.length, greaterThan(1));
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: Offset.zero);
    await pointer.moveTo(tester.getCenter(find.text('Staf Finance').first));
    await tester.pumpAndSettle();
    final firstRow = table().children[1];
    expect((firstRow.decoration as BoxDecoration).color,
      const Color(0xFFEDF5FE));
    await pointer.removePointer();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
