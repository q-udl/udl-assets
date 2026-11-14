import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> setSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> showConfirmation(WidgetTester tester, {
    bool destructive = true, double scale = 1.0,
  }) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale)),
        child: child!),
      home: Scaffold(
        body: Builder(builder: (ctx) => Center(
          child: FilledButton(
            onPressed: () => assetConfirmDialog(
              ctx,
              title: 'Tinggalkan formulir?',
              message: 'Perubahan yang belum disimpan akan hilang '
                'jika Anda meninggalkan formulir ini.',
              confirmLabel: 'Tinggalkan Tanpa Menyimpan',
              cancelLabel: 'Tetap di Formulir',
              destructive: destructive),
            child: const Text('Buka Konfirmasi')))),
      ),
    ));
    await tester.tap(find.text('Buka Konfirmasi'));
    await tester.pumpAndSettle();
  }

  for (final size in <Size>[
    const Size(320, 568),
    const Size(375, 812),
    const Size(400, 858),
    const Size(430, 932),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    testWidgets('RV28 confirmation fits ' +
      size.width.toInt().toString() + 'x' + size.height.toInt().toString(),
        (tester) async {
      await setSize(tester, size);
      await showConfirmation(tester);
      expect(find.byKey(const ValueKey('rv28-confirm-dialog')), findsOneWidget);
      expect(find.text('Tetap di Formulir'), findsOneWidget);
      expect(find.text('Tinggalkan Tanpa Menyimpan'), findsOneWidget);
      final bounds = tester.getRect(
        find.byKey(const ValueKey('rv28-confirm-dialog')));
      expect(bounds.width, lessThanOrEqualTo(size.width));
      expect(bounds.height, lessThanOrEqualTo(size.height));
      final safe = tester.getRect(find.byKey(const ValueKey('rv28-dialog-safe')));
      final risky = tester.getRect(
        find.byKey(const ValueKey('rv28-dialog-destructive')));
      if (size.width < 650) {
        expect(safe.top, lessThan(risky.top));
        expect(safe.width, greaterThan(size.width * .70));
        expect(risky.width, greaterThan(size.width * .70));
        expect(safe.height, greaterThanOrEqualTo(44));
      }
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('rv28-dialog-safe')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('rv28-confirm-dialog')), findsNothing);
    });
  }

  testWidgets('RV28 dialog remains readable with text scale 150%',
      (tester) async {
    await setSize(tester, const Size(320, 568));
    await showConfirmation(tester, scale: 1.5);
    expect(find.text('Tinggalkan formulir?'), findsOneWidget);
    expect(find.byKey(const ValueKey('rv28-dialog-safe')), findsOneWidget);
    expect(find.byKey(const ValueKey('rv28-dialog-destructive')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RV28 employee edit cannot be discarded using modal X',
      (tester) async {
    await setSize(tester, const Size(400, 858));
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Buka Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Master Karyawan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Karyawan').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rv28-adaptive-modal')), findsOneWidget);
    final employeeNameField = find.byWidgetPredicate((w) =>
      w is TextField && w.decoration?.labelText == 'Nama lengkap *');
    expect(employeeNameField, findsOneWidget);
    await tester.enterText(employeeNameField, 'Karyawan Uji');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rv28-modal-close')));
    await tester.pumpAndSettle();
    expect(find.text('Tinggalkan formulir?'), findsOneWidget);
    await tester.tap(find.text('Tetap di Formulir'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rv28-adaptive-modal')), findsOneWidget);
    expect(find.byKey(const ValueKey('rv28-modal-mobile-actions')),
      findsOneWidget);
    await tester.tap(find.text('Batal').last);
    await tester.pumpAndSettle();
    expect(find.text('Tinggalkan formulir?'), findsOneWidget);
    await tester.tap(find.text('Tinggalkan Tanpa Menyimpan'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rv28-adaptive-modal')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RV28 mobile import uses guarded, stacked action area',
      (tester) async {
    await setSize(tester, const Size(375, 812));
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Impor Data Aset').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rv28-import-dialog')), findsOneWidget);
    expect(find.text('Unduh Template'), findsOneWidget);
    expect(find.text('Upload Template'), findsOneWidget);
    expect(find.byKey(const ValueKey('rv28-import-confirm')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Batal').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rv28-import-dialog')), findsNothing);
  });


  testWidgets('RV28 keyboard inset keeps employee modal actions reachable',
      (tester) async {
    await setSize(tester, const Size(320, 568));
    tester.view.viewInsets = const FakeViewPadding(bottom: 230);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Buka Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Master Karyawan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Karyawan').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rv28-adaptive-modal')), findsOneWidget);
    expect(find.byKey(const ValueKey('rv28-modal-scroll')), findsOneWidget);
    expect(find.byKey(const ValueKey('rv28-modal-mobile-actions')),
      findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RV28 mobile system back requests confirmation on dirty form',
      (tester) async {
    await setSize(tester, const Size(375, 812));
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Buka Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Master Karyawan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Karyawan').last);
    await tester.pumpAndSettle();
    final field = find.byWidgetPredicate((w) =>
      w is TextField && w.decoration?.labelText == 'Nama lengkap *');
    await tester.enterText(field, 'Petugas Uji');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Tinggalkan formulir?'), findsOneWidget);
    await tester.tap(find.text('Tetap di Formulir'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rv28-adaptive-modal')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
