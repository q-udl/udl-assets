import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });


  testWidgets('Master klasifikasi dapat dibuka dari sidebar', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Master Klasifikasi').first);
    await tester.pumpAndSettle();
    expect(find.text('Master Klasifikasi Aset'), findsOneWidget);
  });

  testWidgets('Halaman detail menyiapkan dokumentasi foto aktual', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daftar Aset').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laptop Lenovo ThinkPad T14').first);
    await tester.pumpAndSettle();
    expect(find.text('Dokumentasi Foto'), findsOneWidget);
    expect(find.text('Belum ada foto aktual'), findsOneWidget);
  });

  testWidgets('Modal QR memiliki dimensi terukur tanpa exception',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laptop Lenovo ThinkPad T14').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat QR').first);
    await tester.pumpAndSettle();
    expect(find.text('Identitas QR Aset'), findsOneWidget);
    expect(find.text('QR pratinjau lokal hanya memuat kode aset. '
      'Belum terhubung ke sistem online.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sidebar compact memakai toggle tepi dan tetap berfungsi',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    expect(find.byTooltip('Minimalkan Sidebar'), findsOneWidget);
    await tester.tap(find.byTooltip('Minimalkan Sidebar'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Perluas Sidebar'), findsOneWidget);
    expect(find.byTooltip('Master Klasifikasi'), findsOneWidget);
    await tester.tap(find.byTooltip('Perluas Sidebar'));
    await tester.pumpAndSettle();
    expect(find.text('Master Klasifikasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tabel asset dan riwayat melebar pada desktop wide',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    final tableAsset = find.byKey(const ValueKey('adaptive-asset-table'));
    expect(tableAsset, findsOneWidget);
    expect(tester.getSize(tableAsset).width, greaterThan(1200));
    await tester.tap(find.text('Riwayat').first);
    await tester.pumpAndSettle();
    final tableHistory = find.byKey(const ValueKey('adaptive-history-table'));
    expect(tableHistory, findsOneWidget);
    expect(tester.getSize(tableHistory).width, greaterThan(1200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Filter tanpa hasil menampilkan empty state dan Reset Filter',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'ASET-TIDAK-ADA-123');
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada aset yang sesuai'), findsOneWidget);
    expect(find.text('0 dari 5 aset'), findsOneWidget);
    expect(find.byKey(const ValueKey('adaptive-asset-table')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('asset-reset-filters')));
    await tester.pumpAndSettle();
    expect(find.text('5 dari 5 aset'), findsOneWidget);
    final input = tester.widget<TextField>(find.byType(TextField).first);
    expect(input.controller?.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Halaman awal adalah Daftar Aset', (tester) async {
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    expect(find.text('Daftar Aset'), findsWidgets);
    expect(find.text('Ringkasan Aset'), findsNothing);
  });
}
