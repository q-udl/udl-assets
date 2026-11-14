import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  SelectedAssetPhoto uatProof() {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGMMmHaJgYGBiYGBgYGBAQAUSAG8NMsrTwAAAABJRU5ErkJggg==');
    return SelectedAssetPhoto(bytes, 'bukti-uat.png', bytes.length);
  }

  test('Registrasi massal memberi nomor unik berurutan', () async {
    final store=AssetStore();
    await store.initialize();
    final created=await store.registerUnits(
      quantity:3,name:'Kursi Simulasi',category:'Furnitur',
      subcategory:'Kursi',assetType:'Kursi Kerja',
      brand:'',model:'',serial:'',location:'Kantor Pusat',
      holder:'',status:'Tersedia',condition:'Baru',
      cost:null,acquisitionDate:'');
    expect(created.length,3);
    expect(created.map((a)=>a.code).toSet().length,3);
    expect(created.map((a)=>a.code).toList(),
      ['UDL-AST-00000006','UDL-AST-00000007','UDL-AST-00000008']);
    expect(created.first.acquisitionCost,isNull);
    final backup=store.backup();
    final copy=AssetStore()..restore(backup);
    expect(copy.assets.first.code,'UDL-AST-00000008');
    expect(copy.assets.first.acquisitionCost,isNull);
    expect(copy.nextNumber,9);
  });

  test('Mutasi tidak mengganti penguasaan sampai serah terima diterima', () async {
    final store=AssetStore();
    await store.initialize();
    final asset=store.assets.first;
    final previous=asset.location;
    final transfer=await store.proposeTransfer(asset,'Outlet Jepara','PIC Baru',
      'Kebutuhan unit');
    expect(asset.location,previous);
    expect(transfer.state,'Menunggu Penerimaan');
    await store.confirmTransfer(transfer,true,'Diterima secara simulasi',
      proofPhoto: uatProof());
    expect(asset.location,'Outlet Jepara');
    expect(asset.holder,'PIC Baru');
    expect(store.events.first.changes['Lokasi']['from'],previous);
  });

  test('Mutasi yang ditolak tidak mengubah lokasi dan PIC', () async {
    final store=AssetStore();
    await store.initialize();
    final asset=store.assets.first;
    final original=asset.location;
    final transfer=await store.proposeTransfer(asset,'Outlet Jepara','PIC Baru','Uji');
    await store.confirmTransfer(transfer,false,'Barang belum tiba');
    expect(asset.location,original);
    expect(transfer.state,contains('Ditolak'));
  });

  test('Koreksi kondisi menyimpan nilai awal, akhir, alasan', () async {
    final store=AssetStore();
    await store.initialize();
    final asset=store.assets.first;
    await store.editCondition(asset,'Rusak','Pemeriksaan fisik');
    final event=store.events.first;
    expect(event.type,'Perubahan Kondisi');
    expect(event.changes['Kondisi']['from'],'Baik');
    expect(event.changes['Kondisi']['to'],'Rusak');
    expect(event.reason,'Pemeriksaan fisik');
  });

  test('Mengubah nama kategori mempertahankan referensi aset', () async {
    final store=AssetStore();
    await store.initialize();
    final cat=store.categoryByName('Furnitur')!;
    final code=cat.code;
    await store.renameCategory(cat,'Furnitur Kerja');
    expect(cat.code,code);
    expect(store.assets.last.category,'Furnitur Kerja');
    final copy=AssetStore()..restore(store.backup());
    expect(copy.assets.last.categoryId,code);
  });

  test('Foto diarsipkan tetap ada di backup tetapi tidak menjadi utama', () async {
    final store=AssetStore();
    await store.initialize();
    const png='iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO2/TnYAAAAASUVORK5CYII=';
    final asset=store.assets.first;
    await store.addPhoto(asset,Uint8List.fromList(base64Decode(png)),'unit.png',
      'Tampak Fisik Aset',note:'Kondisi awal');
    final photo=store.photosFor(asset.id).single;
    expect(photo.note,'Kondisi awal');
    await store.archivePhoto(asset,photo,'Foto tidak akurat');
    expect(store.photosFor(asset.id),isEmpty);
    expect(store.archivedPhotosFor(asset.id),hasLength(1));
    final copy=AssetStore()..restore(store.backup());
    expect(copy.archivedPhotosFor(asset.id).single.archivedReason,'Foto tidak akurat');
  });

  test('Data legacy tanpa field v0.4 tetap dapat dibaca', () {
    final store=AssetStore();
    final input=jsonEncode({'nextNumber':2,'assets':[{
      'id':'a-1','code':'UDL-AST-000001','name':'Laptop Legacy',
      'category':'IT','location':'Kantor Pusat','cost':1200000,
    }],'events':[]});
    store.restore(input);
    expect(store.assets.single.code,'UDL-AST-000001');
    expect(store.assets.single.acquisitionCost,1200000);
    expect(store.assets.single.categoryId,'03');
  });
}
