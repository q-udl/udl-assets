import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  SelectedAssetPhoto uatProof() {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGMMmHaJgYGBiYGBgYGBAQAUSAG8NMsrTwAAAABJRU5ErkJggg==');
    return SelectedAssetPhoto(bytes, 'bukti-uat.png', bytes.length);
  }



  test('RV18: old flat location data migrates without fictitious areas', () async {
    final store = AssetStore();
    await store.initialize();
    final json = jsonDecode(store.backup()) as Map<String, dynamic>;
    json.remove('locationSites');
    json.remove('nextLocationNumber');
    for (final item in json['assets'] as List) {
      final asset = item as Map<String, dynamic>;
      asset.remove('locationSiteId');
      asset.remove('locationAreaId');
      asset.remove('locationSpotId');
    }
    final imported = AssetStore()..restore(jsonEncode(json));
    expect(imported.locationSites, hasLength(3));
    expect(imported.locationSites.every((s) => s.areas.isEmpty), true);
    expect(imported.assets.every((a) => a.locationSiteId.isNotEmpty), true);
    final stable = AssetStore()..restore(imported.backup());
    expect(stable.assets.first.locationSiteId,
      imported.assets.first.locationSiteId);
    expect(stable.locationSites.first.id, imported.locationSites.first.id);
  });

  test('RV18: nested locations, registration and accepted transfer are auditable',
      () async {
    final store = AssetStore();
    await store.initialize();
    final site = store.siteByName('Gudang Pusat')!;
    final area = await store.addArea(site, 'Gudang Barang');
    final spot = await store.addSpot(site, area, 'Rak A-01');
    final destination = AssetPlacement(site.id,
      areaId: area.id, spotId: spot.id);
    final assets = await store.registerUnits(
      quantity: 1, name: 'Kursi Uji Lokasi',
      category: 'Furnitur', subcategory: 'Kursi',
      assetType: 'Kursi Kerja', brand: 'Lokal', model: '',
      serial: '', location: 'Gudang Pusat', holder: '',
      status: 'Tersedia', condition: 'Baik',
      cost: 100000, acquisitionDate: '', placement: destination);
    final item = assets.single;
    expect(store.locationPath(item),
      'Gudang Pusat / Gudang Barang / Rak A-01');
    await store.renameSpot(site, area, spot, 'Rak A-02');
    expect(store.locationPath(item),
      'Gudang Pusat / Gudang Barang / Rak A-02');
    final outlet = store.siteByName('Outlet Jepara')!;
    final outletArea = await store.addArea(outlet, 'Ruang Kasir');
    final transfer = await store.proposeTransfer(
      item, outlet.name, 'Operator Kasir', 'Pemindahan fasilitas',
      placement: AssetPlacement(outlet.id, areaId: outletArea.id));
    expect(item.location, 'Gudang Pusat');
    await store.confirmTransfer(transfer, true, 'Diterima (simulasi)',
      proofPhoto: uatProof());
    expect(store.locationPath(item), 'Outlet Jepara / Ruang Kasir');
    expect(item.locationAreaId, outletArea.id);
    final restored = AssetStore()..restore(store.backup());
    final same = restored.assets.firstWhere((a) => a.id == item.id);
    expect(restored.locationPath(same), 'Outlet Jepara / Ruang Kasir');
    expect(restored.transfers.single.toAreaId, outletArea.id);
    await store.setAreaActive(outlet, outletArea, false);
    expect(store.validPlacement(AssetPlacement(outlet.id,
      areaId: outletArea.id)), false);
    expect(store.locationPath(item), 'Outlet Jepara / Ruang Kasir');
  });

  test('RV18: rename site does not recreate old site after backup', () async {
    final store = AssetStore();
    await store.initialize();
    final old = store.siteByName('Gudang Pusat')!;
    final id = old.id;
    await store.renameSite(old, 'Gudang Baru');
    final restored = AssetStore()..restore(store.backup());
    expect(restored.siteByName('Gudang Baru')?.id, id);
    expect(restored.siteByName('Gudang Pusat'), isNull);
    expect(restored.assets.any((a) => a.location == 'Gudang Baru'), true);
    expect(restored.assets.any((a) => a.location == 'Gudang Pusat'), false);
  });

  test('RV18: Assigned Assets return saves precise receiving placement', () async {
    final store = AssetStore();
    await store.initialize();
    final employee = await store.addEmployee(
      code: 'KRY-RV18', name: 'Karyawan Pengembalian',
      unit: 'Outlet', department: 'Gudang',
      jobTitle: 'Operator', workLocation: 'Outlet Jepara');
    final asset = store.assets.firstWhere(store.canAssignAsset);
    final batch = await store.createAssignment(
      employeeId: employee.id, kind: 'Berkelanjutan',
      assetIds: [asset.id], accessories: {});
    await store.confirmAssignment(batch, true, '',
      proofPhotos: {asset.id: uatProof()});
    final site = store.siteByName('Gudang Pusat')!;
    final area = await store.addArea(site, 'Ruang Terima Barang');
    final spot = await store.addSpot(site, area, 'Rak Retur 01');
    final placement = AssetPlacement(
      site.id, areaId: area.id, spotId: spot.id);
    final receipt = await store.returnAssignedAssets(
      record: batch,
      inspections: {
        batch.lines.first.id:
          const AssetReturnInput(condition: 'Baik'),
      },
      receivingLocation: site.name,
      receivingPlacement: placement,
      proofPhotos: {asset.id: uatProof()});
    expect(store.locationPath(asset),
      'Gudang Pusat / Ruang Terima Barang / Rak Retur 01');
    expect(receipt.receivingLocationPath, store.locationPath(asset));
    final backup = AssetStore()..restore(store.backup());
    final same = backup.assets.firstWhere((a) => a.id == asset.id);
    expect(backup.locationPath(same), receipt.receivingLocationPath);
    expect(backup.returnReceipts.single.receivingSpotId, spot.id);
  });

  test('RV15: inactive and released assets retain identity and audit trail',
      () async {
    final store = AssetStore();
    await store.initialize();
    final asset = store.assets.firstWhere((a) => a.status == 'Tersedia');
    final originalCode = asset.code;
    await store.setLifecycleActive(asset, false, 'Disimpan sementara');
    expect(asset.lifecycle, 'Tidak Aktif');
    expect(store.canAssignAsset(asset), false);
    await expectLater(
      store.editStatus(asset, 'Digunakan', 'Uji tidak diperbolehkan'),
      throwsFormatException);
    await store.setLifecycleActive(asset, true, 'Dipakai kembali');
    expect(asset.lifecycle, 'Aktif');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await store.releaseAsset(asset, kind: 'Dijual',
      date: today, reference: 'DRAF/BA/001',
      reason: 'Penjualan barang bekas', handledBy: 'Operator demo');
    expect(asset.lifecycle, 'Dilepas');
    expect(asset.code, originalCode);
    expect(store.assets.contains(asset), true);
    expect(store.canAssignAsset(asset), false);
    expect(store.events.where((e) => e.assetId == asset.id &&
      e.type == 'Pelepasan Aset'), hasLength(1));
    await expectLater(
      store.setLifecycleActive(asset, true, 'Uji tidak diperbolehkan'),
      throwsFormatException);
    final restored = AssetStore()..restore(store.backup());
    final same = restored.assets.firstWhere((a) => a.id == asset.id);
    expect(same.lifecycle, 'Dilepas');
    expect(same.releaseReference, 'DRAF/BA/001');
    expect(same.code, originalCode);
  });

  test('RV15: release blocked when assignment has pending acceptance',
      () async {
    final store = AssetStore();
    await store.initialize();
    final employee = await store.addEmployee(
      code: 'TEST-CUSTODY', name: 'Pengguna Uji',
      unit: 'Outlet', department: 'Operasional',
      jobTitle: 'Staf', workLocation: 'Outlet Jepara');
    final asset = store.assets.firstWhere((a) =>
      store.canAssignAsset(a));
    await store.createAssignment(
      employeeId: employee.id, kind: 'Berkelanjutan',
      assetIds: [asset.id], accessories: {});
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await expectLater(store.releaseAsset(asset,
      kind: 'Dijual', date: today, reference: 'DRAF/BA/02',
      reason: 'Uji blokir', handledBy: ''), throwsFormatException);
  });

  testWidgets('RV19: no KPI cards; assign button in title and search first',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assigned Assets').first);
    await tester.pumpAndSettle();
    expect(find.text('Aset ditugaskan aktif'), findsNothing);
    expect(find.text('Menunggu penerimaan'), findsNothing);
    expect(find.text('Penugasan jatuh tempo'), findsNothing);
    expect(find.text('Daftar Penugasan'), findsOneWidget);
    expect(find.text('Tugaskan Aset'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RV20: Back returns to last visited page and preserves filters',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Master Karyawan').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Karyawan Demo A').first);
    await tester.pumpAndSettle();
    expect(find.text('Detail Karyawan'), findsOneWidget);
    await tester.tap(find.text('Assigned Assets').first);
    await tester.pumpAndSettle();
    expect(find.text('Daftar Penugasan'), findsOneWidget);
    await tester.tap(find.byTooltip('Kembali').first);
    await tester.pumpAndSettle();
    expect(find.text('Detail Karyawan'), findsOneWidget);
    await tester.tap(find.byTooltip('Kembali').first);
    await tester.pumpAndSettle();
    expect(find.text('Karyawan Demo A'), findsOneWidget);
    await tester.tap(find.byTooltip('Kembali').first);
    await tester.pumpAndSettle();
    expect(find.text('Daftar Aset'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('RV20: returning to asset list restores search and result count',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Laptop');
    await tester.pumpAndSettle();
    expect(find.text('1 dari 5 aset'), findsOneWidget);
    await tester.tap(find.text('Master Lokasi').first);
    await tester.pumpAndSettle();
    expect(find.text('Lokasi Utama'), findsOneWidget);
    expect(find.text('Area'), findsOneWidget);
    expect(find.text('Titik Penempatan'), findsOneWidget);
    await tester.tap(find.byTooltip('Kembali').first);
    await tester.pumpAndSettle();
    final search = tester.widget<TextField>(find.byType(TextField).first);
    expect(search.controller?.text, 'Laptop');
    expect(find.text('1 dari 5 aset'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RV20: dirty registration warns before leaving',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Aset').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Meja Uji');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assigned Assets').first);
    await tester.pumpAndSettle();
    expect(find.text('Tinggalkan formulir?'), findsOneWidget);
    await tester.tap(find.text('Tetap di Formulir'));
    await tester.pumpAndSettle();
    expect(find.text('Registrasi Aset'), findsOneWidget);
    await tester.tap(find.byTooltip('Kembali').first);
    await tester.pumpAndSettle();
    expect(find.text('Tinggalkan formulir?'), findsOneWidget);
    await tester.tap(find.text('Tinggalkan Tanpa Menyimpan'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar Aset'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

}
