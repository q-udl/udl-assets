import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('RV030-06: new physical units receive permanent 8-digit global codes',
      () async {
    final store = AssetStore();
    await store.initialize();
    final assets = await store.registerUnits(
      quantity: 5, name: 'Mouse Logitech M170',
      category: 'Teknologi Informasi & Komunikasi',
      subcategory: 'Periferal Komputer', assetType: 'Mouse',
      brand: 'Logitech', model: 'M170', serial: '',
      location: 'Gudang Pusat', holder: '', status: 'Tersedia',
      condition: 'Baik', cost: null, acquisitionDate: '');
    expect(assets.map((a) => a.code).toSet().length, 5);
    expect(assets.first.code, 'UDL-AST-00000006');
    expect(assets.last.code, 'UDL-AST-00000010');
    final firstCode = assets.first.code;
    expect(store.assets.where((a) => a.id == assets.first.id), hasLength(1));
    expect(assets.first.code, firstCode);
  });

  test('RV030-06: legacy 6-digit asset remains unchanged after restore',
      () async {
    final store = AssetStore();
    await store.initialize();
    final json = jsonDecode(store.backup()) as Map<String, dynamic>;
    final assets = json['assets'] as List<dynamic>;
    final first = assets.first as Map<String, dynamic>;
    first['code'] = 'UDL-AST-000001';
    first.remove('qrToken');
    first.remove('qrRevoked');
    final restored = AssetStore()..restore(jsonEncode(json));
    expect(restored.assets.first.code, 'UDL-AST-000001');
    expect(restored.assets.first.qrToken, isNotEmpty);
    await restored.add('Meja Baru', 'Furnitur', 'Lokal', '',
      'Gudang Pusat', '', 0,
      subcategory: 'Meja', assetType: 'Meja Kerja');
    expect(restored.assets.first.code, 'UDL-AST-00000006');
    expect(restored.assets.any((a) => a.code == 'UDL-AST-000001'), isTrue);
  });

  test('RV030-07: non-predictable QR maps to UUID and can be rotated or revoked',
      () async {
    final store = AssetStore();
    await store.initialize();
    final asset = store.assets.first;
    expect(asset.qrToken, isNotEmpty);
    expect(asset.qrToken, isNot(contains(asset.code)));
    expect(store.resolveQrPayload(asset.code), isNull);
    final old = 'UDLQR1:' + asset.qrToken;
    expect(store.resolveQrPayload(old)?.id, asset.id);
    final originalCode = asset.code;
    await store.rotateQrToken(asset);
    expect(store.resolveQrPayload(old), isNull);
    expect(store.resolveQrPayload('UDLQR1:' + asset.qrToken)?.id, asset.id);
    expect(asset.code, originalCode);
    await store.revokeQrToken(asset);
    expect(asset.qrRevoked, isTrue);
    expect(store.resolveQrPayload('UDLQR1:' + asset.qrToken), isNull);
  });

  test('RV030-03: old employee codes are ignored in new snapshots and backup',
      () async {
    final store = AssetStore();
    await store.initialize();
    final person = await store.addEmployee(
      name: 'Karyawan Arsip', unit: 'Outlet', department: 'Penjualan',
      jobTitle: 'Supervisor', workLocation: 'Outlet Jepara');
    final asset = store.assets.firstWhere(store.canAssignAsset);
    await store.createAssignment(
      employeeId: person.id, kind: 'Berkelanjutan',
      assetIds: [asset.id], accessories: {});
    final legacy = jsonDecode(store.backup()) as Map<String, dynamic>;
    final employee = (legacy['employees'] as List<dynamic>)
      .firstWhere((x) => (x as Map)['id'] == person.id) as Map<String, dynamic>;
    employee['code'] = 'KRY-ARCHIVE-1';
    final batch = (legacy['assignments'] as List<dynamic>).first as Map<String, dynamic>;
    (batch['employeeSnapshot'] as Map<String, dynamic>)['code'] = 'KRY-ARCHIVE-1';
    final restored = AssetStore()..restore(jsonEncode(legacy));
    expect(restored.employeeById(person.id)?.id, person.id);
    expect(restored.assignments.single.employeeSnapshot.containsKey('code'), false);
    final rewritten = restored.backup();
    expect(rewritten, isNot(contains('KRY-ARCHIVE-1')));
    expect(restored.assignments.single.employeeId, person.id);
  });

  test('RV030-07: QR scan action is catalog-only and camera-gated', () {
    expect(assetQrScanVisible(cameraAvailable: false,
      page: 1, showingAssetDetail: false), isFalse);
    expect(assetQrScanVisible(cameraAvailable: true,
      page: 1, showingAssetDetail: false), isTrue);
    expect(assetQrScanVisible(cameraAvailable: true,
      page: 1, showingAssetDetail: true), isFalse);
    for (final page in [0, 2, 3, 4, 5, 6, 7, 8, 9, 10]) {
      expect(assetQrScanVisible(cameraAvailable: true,
        page: page, showingAssetDetail: false), isFalse,
        reason: 'Scan QR must not appear on page $page');
    }
  });

  testWidgets('RV030-07: scan action absent without confirmed camera',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    expect(find.byTooltip('Scan QR Code'), findsNothing);
    expect(find.text('Scan QR Code'), findsNothing);
  });
}
