import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('RV24 distinguishes unknown acquisition from zero and tracks corrections',
      () async {
    expect(validAssetAcquisitionDate(''), isTrue);
    expect(validAssetAcquisitionDate('2024-02-29'), isTrue);
    expect(validAssetAcquisitionDate('2024-02-30'), isFalse);
    expect(validAssetAcquisitionDate('2024-2-3'), isFalse);
    expect(validAssetAcquisitionDate('2024-13-01'), isFalse);
    final store = AssetStore();
    await store.initialize();
    final assets = await store.registerUnits(
      quantity: 1, name: 'Aset Lama Belum Didata',
      category: 'Furnitur', subcategory: 'Kursi',
      assetType: 'Kursi Kerja', brand: '', model: '', serial: '',
      location: 'Kantor Pusat', holder: '',
      status: 'Tersedia', condition: 'Baik',
      cost: null, acquisitionDate: '');
    final a = assets.single;
    expect(a.acquisitionCost, isNull);
    expect(a.acquisitionDate, '');
    await store.editIdentity(a, a.name, a.brand, a.model, a.serial,
      0, 'Ditemukan bukti nilai nol', acquisitionDate: '2024-02-29');
    expect(a.acquisitionCost, 0);
    expect(a.acquisitionDate, '2024-02-29');
    expect(store.events.first.changes['Tanggal perolehan']['from'],
      'Belum diketahui');
    expect(store.events.first.changes['Tanggal perolehan']['to'],
      '2024-02-29');
    await store.editIdentity(a, a.name, a.brand, a.model, a.serial,
      null, 'Koreksi berkas perolehan', acquisitionDate: '');
    expect(a.acquisitionCost, isNull);
    expect(a.acquisitionDate, '');
    final reloaded = AssetStore()..restore(store.backup());
    final restored = reloaded.assets.firstWhere((v) => v.id == a.id);
    expect(restored.acquisitionDate, isEmpty);
    expect(restored.acquisitionCost, isNull);
  });

  test('RV24 refuses invalid or fictitious dates', () async {
    final store = AssetStore();
    await store.initialize();
    await expectLater(
      store.registerUnits(
        quantity:1,name:'Tanggal Tidak Benar',category:'Furnitur',
        subcategory:'Kursi',assetType:'Kursi Kerja',brand:'',
        model:'',serial:'',location:'Kantor Pusat',holder:'',
        status:'Tersedia',condition:'Baik',cost:null,
        acquisitionDate:'2026-02-30'),
      throwsFormatException);
    final a = store.assets.first;
    final old = a.acquisitionDate;
    await expectLater(
      store.editIdentity(a,a.name,a.brand,a.model,a.serial,
        a.acquisitionCost,'Uji tanggal',acquisitionDate:'2026-02-30'),
      throwsFormatException);
    expect(a.acquisitionDate, old);
  });

  test('RV25 accepts JPEG/PNG/WebP signatures and rejects unrelated data', () {
    final png = Uint8List.fromList(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO2/TnYAAAAASUVORK5CYII='));
    final selected = AssetPhotoProcessing.normalize(png, 'aset.png');
    expect(selected.bytes, orderedEquals(png));
    expect(selected.fileName, 'aset.png');
    expect(() => AssetPhotoProcessing.normalize(
      Uint8List.fromList([1,2,3,4]),'salah.exe'), throwsFormatException);
    expect(() => AssetPhotoProcessing.normalize(
      Uint8List(AssetPhotoProcessing.maxInputBytes + 1),'besar.png'),
      throwsFormatException);
  });

  test('RV25 recompresses camera-sized photos to under storage limit', () {
    final image = img.Image(width: 720, height: 720);
    var seed = 123456789;
    for (var y=0; y<720; y++) {
      for (var x=0; x<720; x++) {
        seed = (seed * 1664525 + 1013904223) & 0x7fffffff;
        image.setPixelRgb(x,y,
          seed & 255, (seed >> 8) & 255, (seed >> 16) & 255);
      }
    }
    final original = Uint8List.fromList(img.encodeJpg(image, quality:100));
    expect(original.length, greaterThan(AssetStore.maxPhotoBytes));
    final out = AssetPhotoProcessing.normalize(original,'uji-fisik.jpg');
    expect(out.bytes.length, lessThanOrEqualTo(AssetStore.maxPhotoBytes));
    expect(out.bytes[0], 255);
    expect(out.fileName, 'uji-fisik.jpg');
  });

  testWidgets('RV25 chooser shows Camera, Gallery and File on small screens',
      (tester) async {
    tester.view.physicalSize = const Size(390,844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Builder(builder: (ctx) => TextButton(
        onPressed: () { AssetPhotoPicker.choose(ctx); },
        child: const Text('Buka Pilihan Foto'))))));
    await tester.tap(find.text('Buka Pilihan Foto'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Sumber Foto'), findsOneWidget);
    for (final id in ['rv25-camera','rv25-gallery','rv25-file']) {
      expect(find.byKey(ValueKey(id)), findsOneWidget);
    }
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('RV26 phone asset catalog opens compact filters', (tester) async {
    tester.view.physicalSize = const Size(390,844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rv26-open-filters')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('rv26-open-filters')));
    await tester.pumpAndSettle();
    expect(find.text('Filter Daftar Aset'), findsOneWidget);
    expect(find.text('Belum ada foto'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('rv26-apply-filters')));
    await tester.tap(find.byKey(const ValueKey('rv26-apply-filters')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('RV26 registration is four steps on a phone, not desktop',
      (tester) async {
    tester.view.physicalSize = const Size(375,812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Aset').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Langkah 1 dari 4'), findsOneWidget);
    expect(find.text('IDENTITAS ASET'), findsOneWidget);
    expect(find.text('PEROLEHAN ASET'), findsNothing);
    expect(find.byKey(const ValueKey('rv26-next-step')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('rv26-next-step')));
    await tester.pump();
    expect(find.text('IDENTITAS ASET'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RV26 narrow 320px viewport keeps app navigation functional',
      (tester) async {
    tester.view.physicalSize = const Size(320,568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Buka Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Master Karyawan').first);
    await tester.pumpAndSettle();
    expect(find.text('Master Karyawan'), findsWidgets);
    expect(find.byTooltip('Buka Menu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
