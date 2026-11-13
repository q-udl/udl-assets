import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('data simulasi menggunakan kode urut unik', () async {
    final store = AssetStore();
    await store.initialize();
    expect(store.assets.length, 5);
    expect(store.assets.map((a) => a.code).toSet().length, 5);
    expect(store.nextNumber, 6);
  });

  test('registrasi menaikkan nomor dan menulis audit', () async {
    final store = AssetStore();
    await store.initialize();
    await store.add('Monitor 24 inci', 'IT', 'Dell', 'SERIAL-UNIK', 'Kantor Pusat', '', 2400000);
    expect(store.assets.first.code, 'UDL-AST-000006');
    expect(store.nextNumber, 7);
    expect(store.events.first.type, 'Registrasi');
  });

  test('mutasi tidak mengubah kode aset', () async {
    final store = AssetStore();
    await store.initialize();
    final asset = store.assets.first;
    final code = asset.code;
    await store.change(asset, 'Outlet Jepara', 'Petugas Baru', 'Digunakan', 'Baik', 'Mutasi operasional');
    expect(asset.code, code);
    expect(asset.location, 'Outlet Jepara');
    expect(store.events.first.type, 'Mutasi');
  });

  test('backup dan restore menjaga urutan kode', () async {
    final store = AssetStore();
    await store.initialize();
    final copy = AssetStore();
    copy.restore(store.backup());
    expect(copy.assets.length, store.assets.length);
    expect(copy.nextNumber, store.nextNumber);
  });
}
