import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AssetPhotoPicker.debugCameraProbe = null;
    AssetPhotoPicker.debugReadPhoto = null;
  });

  tearDown(() {
    AssetPhotoPicker.debugCameraProbe = null;
    AssetPhotoPicker.debugReadPhoto = null;
  });

  Future<void> mountPhotoAction(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(builder: (anchor) => OutlinedButton(
            onPressed: () => AssetPhotoPicker.choose(
              anchor, anchorContext: anchor),
            child: const Text('Pilih Foto Aktual'),
          )),
        ),
      ),
    ));
  }

  testWidgets('RV27 desktop without webcam opens only file picker',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AssetPhotoPicker.debugCameraProbe = () async => false;
    final sources = <AssetPhotoSource>[];
    AssetPhotoPicker.debugReadPhoto = (source) async {
      sources.add(source);
      return null; // The user dismissed Explorer.
    };
    await mountPhotoAction(tester, const Size(1280, 800));
    await tester.tap(find.text('Pilih Foto Aktual'));
    await tester.pumpAndSettle();
    expect(sources, [AssetPhotoSource.file]);
    expect(find.byKey(const ValueKey('rv27-camera')), findsNothing);
    expect(find.text('Ambil Foto'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RV27 desktop with webcam has only Camera and File',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AssetPhotoPicker.debugCameraProbe = () async => true;
    final sources = <AssetPhotoSource>[];
    AssetPhotoPicker.debugReadPhoto = (source) async {
      sources.add(source);
      return null;
    };
    await mountPhotoAction(tester, const Size(1440, 900));
    await tester.tap(find.text('Pilih Foto Aktual'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rv27-camera')), findsOneWidget);
    expect(find.byKey(const ValueKey('rv27-file')), findsOneWidget);
    expect(find.text('Pilih dari Galeri'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('rv27-camera')));
    await tester.pumpAndSettle();
    expect(sources, [AssetPhotoSource.camera]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RV27 camera detection unknown keeps a manual camera choice',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AssetPhotoPicker.debugCameraProbe = () async => null;
    final sources = <AssetPhotoSource>[];
    AssetPhotoPicker.debugReadPhoto = (source) async {
      sources.add(source);
      return null;
    };
    await mountPhotoAction(tester, const Size(1366, 768));
    await tester.tap(find.text('Pilih Foto Aktual'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rv27-camera')), findsOneWidget);
    expect(find.byKey(const ValueKey('rv27-file')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('rv27-file')));
    await tester.pumpAndSettle();
    expect(sources, [AssetPhotoSource.file]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RV27 mobile keeps camera, gallery and file in bottom sheet',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Even if the desktop device probe says no webcam, mobile provides
    // explicit camera/gallery/file actions because touch browsers differ.
    AssetPhotoPicker.debugCameraProbe = () async => false;
    await mountPhotoAction(tester, const Size(375, 812));
    await tester.tap(find.text('Pilih Foto Aktual'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rv25-camera')), findsOneWidget);
    expect(find.byKey(const ValueKey('rv25-gallery')), findsOneWidget);
    expect(find.byKey(const ValueKey('rv25-file')), findsOneWidget);
    expect(find.text('Tambahkan Foto Aset'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
