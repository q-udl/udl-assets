import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });


  testWidgets('RV21 sidebar menampilkan Manajemen Aset dan UD. LUTHFI',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    expect(find.text('Manajemen Aset'), findsOneWidget);
    expect(find.text('UD. LUTHFI'), findsOneWidget);
    expect(find.text('UDL Assets'), findsNothing);
    final logo = find.byKey(const ValueKey('udl-assets-logo'));
    expect(logo, findsOneWidget);
    final logoImage = tester.widget<Image>(logo).image;
    expect(logoImage, isA<AssetImage>());
    expect(
      (logoImage as AssetImage).assetName,
      'assets/branding/udl_assets_icon.png',
    );

    await tester.tap(find.byTooltip('Minimalkan Sidebar'));
    await tester.pumpAndSettle();
    expect(find.text('Manajemen Aset'), findsNothing);
    expect(find.text('UD. LUTHFI'), findsNothing);
    expect(logo, findsOneWidget);
    expect(find.text('L'), findsNothing);

    await tester.tap(find.byTooltip('Perluas Sidebar'));
    await tester.pumpAndSettle();
    expect(find.text('Manajemen Aset'), findsOneWidget);
    expect(find.text('UD. LUTHFI'), findsOneWidget);
    expect(logo, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RV23 Compact Sidebar preserves labels, logo and toggle',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();

    const panel = ValueKey('udl-sidebar-panel');
    const first = ValueKey('udl-sidebar-menu-1');
    const second = ValueKey('udl-sidebar-menu-7');
    expect(tester.getSize(find.byKey(panel)).width, 196);
    expect(tester.getSize(find.byKey(first)).height, 38);
    expect(tester.getTopLeft(find.byKey(second)).dy -
      tester.getTopLeft(find.byKey(first)).dy, 42);
    expect(find.text('Manajemen Aset'), findsOneWidget);
    expect(find.text('Master Klasifikasi'), findsOneWidget);
    expect(find.byKey(const ValueKey('udl-assets-logo')), findsOneWidget);

    await tester.tap(find.byTooltip('Minimalkan Sidebar'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(panel)).width, 72);
    expect(find.text('Manajemen Aset'), findsNothing);
    expect(find.byTooltip('Master Klasifikasi'), findsOneWidget);
    expect(tester.getSize(find.byKey(first)).height, 38);

    await tester.tap(find.byTooltip('Perluas Sidebar'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(panel)).width, 196);
    await tester.tap(find.text('Master Klasifikasi').first);
    await tester.pumpAndSettle();
    expect(find.text('Master Klasifikasi Aset'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(find.text('QR memuat token acak, bukan kode aset. '
      'Pencocokan lokal bukan verifikasi keamanan server.'), findsOneWidget);
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
    final originalWidth = tester.getSize(tableAsset).width;
    expect(originalWidth, greaterThan(1200));
    await tester.tap(find.byTooltip('Minimalkan Sidebar'));
    await tester.pumpAndSettle();
    expect(tester.getSize(tableAsset).width,
      greaterThan(originalWidth + 100));
    await tester.tap(find.byTooltip('Perluas Sidebar'));
    await tester.pumpAndSettle();
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

  testWidgets('RV16 dan RV17 membuka menu, detail karyawan, dan formulir',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Master Karyawan').first);
    await tester.pumpAndSettle();
    expect(find.text('Anisa Putri'), findsOneWidget);
    expect(find.text('Rafi Pratama'), findsOneWidget);
    await tester.tap(find.text('Anisa Putri').first);
    await tester.pumpAndSettle();
    expect(find.text('Aset dalam Penguasaan'), findsOneWidget);
    await tester.tap(find.text('Assigned Assets').first);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada penugasan aset'), findsOneWidget);
    await tester.tap(find.text('Tugaskan Aset').first);
    await tester.pumpAndSettle();
    expect(find.text('1. Karyawan Penerima'), findsOneWidget);
    expect(find.text('2. Pilih Aset'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Assigned Assets tampil responsif pada layar mobile',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Buka Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assigned Assets').first);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada penugasan aset'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Halaman awal adalah Daftar Aset', (tester) async {
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    expect(find.text('Daftar Aset'), findsWidgets);
    expect(find.text('Ringkasan Aset'), findsNothing);
  });
}
