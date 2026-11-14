import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AssetAssignment> draftFor(AssetStore store) async {
    final employee = await store.addEmployee(
      name: 'Nadia Pramesti', unit: 'Distribusi',
      department: 'Operasional', jobTitle: 'Staf Gudang',
      workLocation: 'Gudang Pusat');
    final asset = store.assets.firstWhere(store.canAssignAsset);
    return store.createAssignment(employeeId: employee.id,
      kind: 'Berkelanjutan', assetIds: [asset.id], accessories: {});
  }

  test('RV030: cancellation requires a reason and releases asset reservation',
      () async {
    final store = AssetStore();
    await store.initialize();
    final batch = await draftFor(store);
    final asset = store.assignmentAsset(batch.lines.single.assetId)!;
    final originalLocation = asset.location;
    final originalCode = asset.code;
    expect(batch.status, 'Menunggu Serah Terima');
    expect(batch.lines.single.state, 'Menunggu Serah Terima');
    expect(store.canAssignAsset(asset), false);

    await expectLater(store.cancelAssignment(batch, '  '),
      throwsFormatException);
    expect(batch.isPending, true);
    expect(store.canAssignAsset(asset), false);

    await store.cancelAssignment(batch, 'Penugasan tidak diperlukan');
    expect(batch.status, 'Dibatalkan');
    expect(batch.lines.single.state, 'Dibatalkan');
    expect(batch.cancellationReason, 'Penugasan tidak diperlukan');
    expect(batch.cancelledAt, isNotEmpty);
    expect(batch.acceptedAt, isEmpty);
    expect(batch.handedOverByName, isEmpty);
    expect(store.canAssignAsset(asset), true);
    expect(asset.status, 'Tersedia');
    expect(asset.location, originalLocation);
    expect(asset.code, originalCode);
    expect(asset.assignedEmployeeId, isEmpty);
    expect(store.evidenceFor('assignment_handover', batch.id, asset.id), isEmpty);
    expect(store.events.any((e) => e.type == 'Pembatalan Penugasan' &&
      e.reason == 'Penugasan tidak diperlukan'), true);

    await expectLater(store.cancelAssignment(batch, 'Ulangi'),
      throwsFormatException);
    final second = await store.createAssignment(
      employeeId: batch.employeeId,
      kind: 'Berkelanjutan',
      assetIds: [asset.id], accessories: {});
    expect(second.isPending, true);
    expect(second.id, isNot(batch.id));
  });

  test('RV030: legacy pending backup maps status and line without losing IDs',
      () async {
    final store = AssetStore();
    await store.initialize();
    final batch = await draftFor(store);
    final raw = jsonDecode(store.backup()) as Map<String, dynamic>;
    final original = (raw['assignments'] as List<dynamic>).single
      as Map<String, dynamic>;
    original['status'] = 'Menunggu Penerimaan';
    ((original['lines'] as List<dynamic>).single as Map<String, dynamic>)
      ['state'] = 'Menunggu Penerimaan';
    final restored = AssetStore()..restore(jsonEncode(raw));
    final pending = restored.assignments.single;
    expect(pending.id, batch.id);
    expect(pending.status, 'Menunggu Serah Terima');
    expect(pending.lines.single.state, 'Menunggu Serah Terima');
    final asset = restored.assignmentAsset(pending.lines.single.assetId)!;
    expect(restored.canAssignAsset(asset), false);
    await restored.cancelAssignment(pending, 'Draf lama dibatalkan');
    expect(restored.canAssignAsset(asset), true);
  });

  test('RV030: legacy rejection reason remains accessible as cancellation',
      () async {
    final store = AssetStore();
    await store.initialize();
    final batch = await draftFor(store);
    final raw = jsonDecode(store.backup()) as Map<String, dynamic>;
    final original = (raw['assignments'] as List<dynamic>).single
      as Map<String, dynamic>;
    original['status'] = 'Ditolak';
    original['rejectionReason'] = 'Draf historis tidak dijalankan';
    original.remove('cancellationReason');
    original.remove('cancelledAt');
    ((original['lines'] as List<dynamic>).single as Map<String, dynamic>)
      ['state'] = 'Ditolak';
    final restored = AssetStore()..restore(jsonEncode(raw));
    final cancelled = restored.assignments.single;
    expect(cancelled.id, batch.id);
    expect(cancelled.status, 'Dibatalkan');
    expect(cancelled.lines.single.state, 'Dibatalkan');
    expect(cancelled.cancellationReason, 'Draf historis tidak dijalankan');
    expect(cancelled.cancelledAt, isEmpty);
    expect(restored.canAssignAsset(
      restored.assignmentAsset(cancelled.lines.single.assetId)!), true);
    expect(restored.backup(), isNot(contains('"rejectionReason"')));
  });

  testWidgets('RV030: Detail Penugasan uses handover/cancel actions',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = AssetStore();
    await store.initialize();
    final batch = await draftFor(store);

    await tester.pumpWidget(MaterialApp(home: AssetScreen(store: store)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assigned Assets').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(batch.draftReference).first);
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi Serah Terima'), findsOneWidget);
    expect(find.text('Batalkan Penugasan'), findsOneWidget);
    expect(find.text('Terima Penugasan'), findsNothing);
    expect(find.text('Tolak Penugasan'), findsNothing);
    expect(find.text('Menunggu Serah Terima'), findsWidgets);

    await tester.tap(find.text('Batalkan Penugasan').first);
    await tester.pumpAndSettle();
    expect(find.text('Alasan pembatalan *'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last,
      'Alokasi aset ditunda');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batalkan Penugasan').last);
    await tester.pumpAndSettle();
    expect(batch.status, 'Dibatalkan');
    expect(find.text('Alasan pembatalan'), findsOneWidget);
    expect(find.text('Alokasi aset ditunda'), findsOneWidget);
    expect(find.text('Lihat / Cetak BAST'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
