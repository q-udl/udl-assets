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
    expect(find.text('Dokumentasi foto aset'), findsOneWidget);
    expect(find.text('Belum ada foto aset'), findsOneWidget);
  });

  testWidgets('Menampilkan halaman ringkasan aplikasi', (tester) async {
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    expect(find.text('Ringkasan Aset'), findsOneWidget);
    expect(find.text('Total aset aktif'), findsOneWidget);
  });
}
