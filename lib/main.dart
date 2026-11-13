import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';

part 'asset_ui.dart';

void main() => runApp(const AssetApp());

const navy = Color(0xFF142D4E);
const bg = Color(0xFFF4F7FB);
const uuid = Uuid();

class AssetRecord {
  String id, code, name, category, brand, serial, location, holder, condition, status;
  int cost;
  AssetRecord(this.id, this.code, this.name, this.category, this.brand, this.serial,
      this.location, this.holder, this.condition, this.status, this.cost);
  Map<String, dynamic> toJson() => {
    'id': id, 'code': code, 'name': name, 'category': category, 'brand': brand,
    'serial': serial, 'location': location, 'holder': holder, 'condition': condition,
    'status': status, 'cost': cost
  };
  factory AssetRecord.fromJson(Map<String, dynamic> m) => AssetRecord(
    m['id'] as String, m['code'] as String, m['name'] as String,
    m['category'] as String, m['brand'] as String, m['serial'] as String,
    m['location'] as String, m['holder'] as String, m['condition'] as String,
    m['status'] as String, (m['cost'] as num).toInt());
}
class EventRecord {
  final String assetId, type, detail, timestamp;
  EventRecord(this.assetId, this.type, this.detail, this.timestamp);
  Map<String, dynamic> toJson() => {'assetId': assetId, 'type': type, 'detail': detail, 'timestamp': timestamp};
  factory EventRecord.fromJson(Map<String, dynamic> m) =>
    EventRecord(m['assetId'] as String, m['type'] as String, m['detail'] as String, m['timestamp'] as String);
}
class AssetStore extends ChangeNotifier {
  List<AssetRecord> assets = [];
  List<EventRecord> events = [];
  int nextNumber = 1;
  bool loaded = false;
  static const key = 'udl_asset_local_mvp_v1';
  AssetStore();
  Future<void> initialize() async {
    try {
      final value = (await SharedPreferences.getInstance()).getString(key);
      if (value == null) {
        seed();
        await persist();
      } else {
        restore(value);
      }
    } catch (_) {
      seed();
    }
    loaded = true;
    notifyListeners();
  }
  void seed() {
    assets = [
      AssetRecord(uuid.v4(), 'UDL-AST-000001', 'Laptop Lenovo ThinkPad T14', 'IT', 'Lenovo', 'DEMO-001', 'Kantor Pusat', 'Staf Finance', 'Baik', 'Digunakan', 12500000),
      AssetRecord(uuid.v4(), 'UDL-AST-000002', 'Printer Brother', 'Elektronik', 'Brother', 'DEMO-002', 'Outlet Jepara', '', 'Baik', 'Tersedia', 3400000),
      AssetRecord(uuid.v4(), 'UDL-AST-000003', 'AC Daikin 2 PK', 'Elektronik', 'Daikin', 'DEMO-003', 'Gudang Pusat', '', 'Cukup', 'Dalam Perbaikan', 8500000),
      AssetRecord(uuid.v4(), 'UDL-AST-000004', 'Forklift Toyota', 'Kendaraan', 'Toyota', 'DEMO-004', 'Gudang Pusat', 'Petugas Gudang', 'Baik', 'Digunakan', 180000000),
      AssetRecord(uuid.v4(), 'UDL-AST-000005', 'Meja Kerja Supervisor', 'Furnitur', 'Lokal', 'DEMO-005', 'Outlet Jepara', 'Supervisor Outlet', 'Baik', 'Digunakan', 1700000),
    ];
    events = [for (final a in assets) EventRecord(a.id, 'Registrasi', 'Registrasi data simulasi', DateTime.now().toIso8601String())];
    nextNumber = 6;
    notifyListeners();
  }
  void restore(String raw) {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    final restoredAssets = (m['assets'] as List).map((e) => AssetRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final restoredEvents = (m['events'] as List).map((e) => EventRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final storedNumber = (m['nextNumber'] as num).toInt();
    if (storedNumber < 1 || restoredAssets.map((a) => a.code).toSet().length != restoredAssets.length) {
      throw const FormatException('Kode aset tidak valid atau duplikat');
    }
    assets = restoredAssets;
    events = restoredEvents;
    final biggest = assets.map((a) => int.tryParse(a.code.split('-').last) ?? 0).fold<int>(0, (a,b) => a > b ? a : b);
    nextNumber = storedNumber > biggest ? storedNumber : biggest + 1;
    notifyListeners();
  }
  String backup() => const JsonEncoder.withIndent('  ').convert({
    'version': 1, 'nextNumber': nextNumber,
    'assets': assets.map((x) => x.toJson()).toList(),
    'events': events.map((x) => x.toJson()).toList()
  });
  Future<void> persist() async {
    await (await SharedPreferences.getInstance()).setString(key, backup());
    notifyListeners();
  }
  Future<void> add(String name, String category, String brand, String serial, String location, String holder, int cost) async {
    if (name.trim().isEmpty || location.trim().isEmpty || cost < 0) throw const FormatException('Data wajib belum lengkap');
    if (serial.trim().isNotEmpty && assets.any((a) => a.serial.toLowerCase() == serial.trim().toLowerCase() && a.status != 'Dihapuskan')) {
      throw const FormatException('Nomor seri sudah tercatat');
    }
    final code = 'UDL-AST-' + nextNumber.toString().padLeft(6, '0');
    nextNumber++;
    final a = AssetRecord(uuid.v4(), code, name.trim(), category, brand.trim(), serial.trim(),
      location.trim(), holder.trim(), 'Baik', holder.trim().isEmpty ? 'Tersedia' : 'Digunakan', cost);
    assets.insert(0, a);
    log(a, 'Registrasi', 'Aset didaftarkan di ' + a.location);
    await persist();
  }
  void log(AssetRecord a, String type, String detail) =>
    events.insert(0, EventRecord(a.id, type, detail, DateTime.now().toIso8601String()));
  Future<void> change(AssetRecord a, String location, String holder, String status, String condition, String reason) async {
    if (a.status == 'Dihapuskan') throw const FormatException('Aset sudah dihapuskan');
    if (location.trim().isEmpty || reason.trim().isEmpty) throw const FormatException('Lokasi dan alasan wajib diisi');
    final detail = a.location + ' → ' + location + '; ' + a.holder + ' → ' + holder +
      '; ' + a.status + ' → ' + status + '. Alasan: ' + reason;
    a.location = location.trim();
    a.holder = holder.trim();
    a.status = status;
    a.condition = condition;
    log(a, status == 'Dihapuskan' ? 'Penghapusan' : 'Mutasi', detail);
    await persist();
  }
}
class AssetApp extends StatefulWidget {
  const AssetApp({super.key});
  @override State<AssetApp> createState() => _AssetAppState();
}
class _AssetAppState extends State<AssetApp> {
  final store = AssetStore();
  @override void initState() { super.initState(); store.initialize(); }
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'Manajemen Aset UD. LUTHFI', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1464A4)),
      cardTheme: CardThemeData(elevation: 0, color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E9F0)))),
      inputDecorationTheme: InputDecorationTheme(isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
    home: AnimatedBuilder(animation: store, builder: (context, child) =>
      store.loaded ? AssetScreen(store: store) : const Scaffold(body: Center(child: CircularProgressIndicator()))),
  );
}
class AssetScreen extends StatefulWidget {
  final AssetStore store;
  const AssetScreen({super.key, required this.store});
  @override State<AssetScreen> createState() => _AssetScreenState();
}
