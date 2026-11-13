import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Sembilan kategori dasar tidak memuat tanah dan bangunan', () async {
    final store = AssetStore();
    await store.initialize();
    expect(store.categories.length, 9);
    expect(store.categoryByName('Tanah'), isNull);
    expect(store.categoryByName('Bangunan'), isNull);
    final tik = store.categoryByName('Teknologi Informasi & Komunikasi');
    expect(tik, isNotNull);
    final peripheral = store.subcategoryByName(tik!.name, 'Periferal Komputer');
    expect(peripheral!.types, containsAll(['Monitor', 'Printer Dokumen']));
  });

  test('Registrasi mempertahankan kode dan hierarki valid', () async {
    final store = AssetStore();
    await store.initialize();
    await store.add('Monitor Dell 24 inci', 'Teknologi Informasi & Komunikasi',
      'Dell', 'SERIAL-0024', 'Kantor Pusat', '', 2400000,
      subcategory: 'Periferal Komputer', assetType: 'Monitor');
    expect(store.assets.first.code, 'UDL-AST-000006');
    expect(store.assets.first.subcategory, 'Periferal Komputer');
    expect(store.assets.first.assetType, 'Monitor');
  });

  test('Backup lama dimigrasikan tanpa mengubah kode identitas', () {
    final store = AssetStore();
    final old = jsonEncode({
      'nextNumber': 8,
      'assets': [{
        'id': 'old-1',
        'code': 'UDL-AST-000007',
        'name': 'Printer Brother',
        'category': 'Elektronik',
        'brand': 'Brother',
        'serial': 'SN-OLD',
        'location': 'Outlet Jepara',
        'holder': '',
        'condition': 'Baik',
        'status': 'Tersedia',
        'cost': 2000000,
      }],
      'events': [],
    });
    store.restore(old);
    expect(store.assets.first.code, 'UDL-AST-000007');
    expect(store.assets.first.category, 'Teknologi Informasi & Komunikasi');
    expect(store.assets.first.assetType, 'Printer Dokumen');
    expect(store.nextNumber, 8);
  });

  test('Aset lama yang tergolong bangunan tidak dihapus otomatis', () {
    final store = AssetStore();
    store.restore(jsonEncode({
      'nextNumber': 10,
      'assets': [{
        'id': 'legacy-bangunan', 'code': 'UDL-AST-000009',
        'name': 'Bangunan Gudang', 'category': 'Bangunan',
        'brand': '', 'serial': '', 'location': 'Gudang Pusat',
        'holder': '', 'condition': 'Baik', 'status': 'Tersedia', 'cost': 0,
      }],
      'events': [],
    }));
    expect(store.assets.first.category, 'Perlu Klasifikasi Ulang');
    expect(store.assets.first.code, 'UDL-AST-000009');
    expect(store.categoryByName('Bangunan'), isNull);
  });

  test('Foto asset dipisah per unit dan masuk backup bersama audit', () async {
    final store = AssetStore();
    await store.initialize();
    const onePixel = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO2/TnYAAAAASUVORK5CYII=';
    final bytes = Uint8List.fromList(base64Decode(onePixel));
    final asset = store.assets.first;
    await store.addPhoto(asset, bytes, 'foto-unit.png', 'Dokumentasi Kondisi');
    expect(store.photosFor(asset.id), hasLength(1));
    expect(store.primaryPhotoFor(asset.id)!.isPrimary, isTrue);
    expect(store.events.first.type, 'Dokumentasi Foto');
    final copy = AssetStore();
    copy.restore(store.backup());
    expect(copy.photosFor(asset.id).single.base64Data, base64Encode(bytes));
  });

  test('Foto yang terlalu besar tidak disimpan', () async {
    final store = AssetStore();
    await store.initialize();
    final invalid = Uint8List(AssetStore.maxPhotoBytes + 1);
    expect(
      () => store.addPhoto(store.assets.first, invalid, 'besar.png', 'Foto Utama'),
      throwsA(isA<FormatException>()),
    );
    expect(store.photos, isEmpty);
  });

  test('Master dapat ditambah tanpa mengizinkan tanah/bangunan', () async {
    final store = AssetStore();
    await store.initialize();
    await store.addCategory('Peralatan Khusus');
    final c = store.categoryByName('Peralatan Khusus')!;
    await store.addSubcategory(c, 'Perlengkapan Uji');
    await store.addType(c, c.subcategories.first, 'Perangkat Uji Terkendali');
    expect(c.code, '10');
    expect(c.subcategories.first.types, contains('Perangkat Uji Terkendali'));
    expect(() => store.addCategory('Tanah'), throwsA(isA<FormatException>()));
  });
}
