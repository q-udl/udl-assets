import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  SelectedAssetPhoto proof() {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGMMmHaJgYGBiYGBgYGBAQAUSAG8NMsrTwAAAABJRU5ErkJggg==');
    return SelectedAssetPhoto(bytes, 'handover-bukti.png', bytes.length);
  }

  test('BAST unavailable for pending or cancelled assignments', () async {
    final store = AssetStore();
    await store.initialize();
    final person = await store.addEmployee(
      name: 'Uji Penyerahan', unit: 'Distribusi',
      department: 'Operasional', jobTitle: 'Staf Gudang',
      workLocation: 'Gudang Pusat');
    final asset = store.assets.firstWhere(store.canAssignAsset);
    final record = await store.createAssignment(
      employeeId: person.id, kind: 'Berkelanjutan',
      assetIds: [asset.id], accessories: {});
    expect(record.assignmentReference, startsWith('ASG-'));
    expect(record.canPrintBast, isFalse);
    await expectLater(AssetBastPdf.handover(record), throwsFormatException);
    await store.cancelAssignment(record, 'Alokasi dibatalkan');
    expect(record.canPrintBast, isFalse);
    await expectLater(AssetBastPdf.handover(record), throwsFormatException);
  });

  test('Confirmed handover uses real timestamp, location and external BAST number',
      () async {
    final store = AssetStore();
    await store.initialize();
    final employee = await store.addEmployee(
      name: 'Rafi Pratama', unit: 'Distribusi',
      department: 'Operasional', jobTitle: 'Staf Gudang',
      workLocation: 'Gudang Pusat');
    final assets = store.assets.where(store.canAssignAsset).take(2).toList();
    final first = await store.createAssignment(
      employeeId: employee.id, kind: 'Berkelanjutan',
      assetIds: [assets[0].id], accessories: {});
    await expectLater(store.confirmAssignment(first, true, '',
      handedOverByName: 'Rochmad',
      handoverLocation: 'Gudang Pusat',
      proofPhotos: {assets[0].id: proof()}), throwsFormatException);
    expect(first.isPending, isTrue);
    await expectLater(store.confirmAssignment(first, true, '',
      handedOverByName: 'Rochmad',
      bastNumber: 'UDL-BAST-2026.0001',
      proofPhotos: {assets[0].id: proof()}), throwsFormatException);
    expect(first.isPending, isTrue);

    await store.confirmAssignment(first, true, '',
      handedOverByName: 'Rochmad',
      handedOverByJobTitle: 'Staf GA',
      handedOverByUnit: 'GA',
      handoverLocation: 'Gudang Pusat',
      bastNumber: 'UDL-BAST-2026.0001',
      proofPhotos: {assets[0].id: proof()});
    expect(first.isHandoverConfirmed, isTrue);
    expect(first.canPrintBast, isTrue);
    expect(first.acceptedAt, isNotEmpty);
    expect(first.createdAt, isNotEmpty);
    expect(first.bastNumber, 'UDL-BAST-2026.0001');
    expect(first.handoverLocation, 'Gudang Pusat');
    expect(first.handedOverByJobTitle, 'Staf GA');
    expect(first.handedOverByUnit, 'GA');
    final bytes = await AssetBastPdf.handover(first, store: store);
    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');

    final second = await store.createAssignment(
      employeeId: employee.id, kind: 'Berkelanjutan',
      assetIds: [assets[1].id], accessories: {});
    await expectLater(store.confirmAssignment(second, true, '',
      handedOverByName: 'Rochmad',
      handoverLocation: 'Gudang Pusat',
      bastNumber: 'udl-bast-2026.0001',
      proofPhotos: {assets[1].id: proof()}), throwsFormatException);
    expect(second.isPending, isTrue);
    expect(store.evidenceFor(
      'assignment_handover', second.id, assets[1].id), isEmpty);
  });

  test('Confirmed historical handover can complete missing metadata only once',
      () async {
    final store = AssetStore();
    await store.initialize();
    final person = await store.addEmployee(
      name: 'Rafi Pratama', unit: 'Outlet',
      department: 'Penjualan', jobTitle: 'Sales',
      workLocation: 'Outlet Jepara');
    final asset = store.assets.firstWhere(store.canAssignAsset);
    final batch = await store.createAssignment(
      employeeId: person.id, kind: 'Berkelanjutan',
      assetIds: [asset.id], accessories: {});
    await store.confirmAssignment(batch, true, '',
      handedOverByName: 'Rochmad',
      handoverLocation: 'Outlet Jepara',
      bastNumber: 'BAST-ARCHIVE-0001',
      proofPhotos: {asset.id: proof()});

    final json = jsonDecode(store.backup()) as Map<String, dynamic>;
    final saved = (json['assignments'] as List<dynamic>).single
      as Map<String, dynamic>;
    final acceptedAt = saved['acceptedAt'];
    saved.remove('bastNumber');
    saved.remove('handoverLocation');
    final restored = AssetStore()..restore(jsonEncode(json));
    final historic = restored.assignments.single;
    expect(historic.isHandoverConfirmed, isTrue);
    expect(historic.canPrintBast, isFalse);
    await expectLater(AssetBastPdf.handover(historic),
      throwsFormatException);

    await restored.completeBastMetadata(historic,
      bastNumber: 'BAST-ARCHIVE-0001',
      handoverLocation: 'Outlet Jepara',
      handedOverByName: 'Rochmad');
    expect(historic.canPrintBast, isTrue);
    expect(historic.acceptedAt, acceptedAt);
    expect(restored.events.any(
      (event) => event.type == 'Pelengkapan Data BAST'), isTrue);
    final bytes = await AssetBastPdf.handover(historic, store: restored);
    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
    await expectLater(restored.completeBastMetadata(historic,
      bastNumber: 'BAST-ARCHIVE-0002',
      handoverLocation: 'Outlet Jepara',
      handedOverByName: 'Rochmad'), throwsFormatException);
    final rewritten = AssetStore()..restore(restored.backup());
    expect(rewritten.assignments.single.bastNumber, 'BAST-ARCHIVE-0001');
    expect(rewritten.assignments.single.acceptedAt, acceptedAt);
  });

  testWidgets('BAST action is invisible before handover and shown after it',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = AssetStore();
    await store.initialize();
    final person = await store.addEmployee(
      name: 'Rafi Pratama', unit: 'Distribusi',
      department: 'Operasional', jobTitle: 'Staf Gudang',
      workLocation: 'Gudang Pusat');
    final item = store.assets.firstWhere(store.canAssignAsset);
    final batch = await store.createAssignment(
      employeeId: person.id, kind: 'Berkelanjutan',
      assetIds: [item.id], accessories: {});

    Future<void> openDetail() async {
      await tester.tap(find.text('Assigned Assets').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(batch.assignmentReference).first);
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(MaterialApp(home: AssetScreen(store: store)));
    await tester.pumpAndSettle();
    await openDetail();
    expect(find.text('Lihat / Cetak BAST'), findsNothing);
    expect(find.text('Konfirmasi Serah Terima'), findsOneWidget);

    // Rebuild a fresh screen so this test exercises persisted transaction
    // state rather than a mocked button.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await store.confirmAssignment(batch, true, '',
      handedOverByName: 'Rochmad',
      handoverLocation: 'Gudang Pusat',
      bastNumber: 'BAST-WIDGET-0001',
      proofPhotos: {item.id: proof()});
    await tester.pumpWidget(MaterialApp(home: AssetScreen(store: store)));
    await tester.pumpAndSettle();
    await openDetail();
    expect(find.text('Lihat / Cetak BAST'), findsOneWidget);
    expect(find.text('Konfirmasi Serah Terima'), findsNothing);
    expect(find.text('Nomor BAST'), findsOneWidget);
    expect(find.text('BAST-WIDGET-0001'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Legacy penugasan reference is normalized only for display', () async {
    final store = AssetStore();
    await store.initialize();
    final person = await store.addEmployee(
      name: 'Nadia', unit: 'Outlet', department: 'Penjualan',
      jobTitle: 'Sales', workLocation: 'Outlet Jepara');
    final item = store.assets.firstWhere(store.canAssignAsset);
    final batch = await store.createAssignment(
      employeeId: person.id, kind: 'Berkelanjutan',
      assetIds: [item.id], accessories: {});
    final json = jsonDecode(store.backup()) as Map<String, dynamic>;
    final assignment = (json['assignments'] as List<dynamic>).single
      as Map<String, dynamic>;
    assignment['draftReference'] = 'DRAF-BAST-ASG-000001';
    final restored = AssetStore()..restore(jsonEncode(json));
    expect(restored.assignments.single.draftReference,
      'DRAF-BAST-ASG-000001');
    expect(restored.assignments.single.assignmentReference, 'ASG-000001');
  });
}
