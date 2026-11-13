import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
  AssetStore() { initialize(); }
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
class _AssetScreenState extends State<AssetScreen> {
  int page = 0;
  String query = '', filter = 'Semua';
  AssetRecord? selected;
  final labels = ['Ringkasan', 'Katalog Aset', 'Riwayat', 'Pengaturan'];
  final icons = [Icons.dashboard_outlined, Icons.inventory_2_outlined, Icons.history, Icons.settings_outlined];
  AssetStore get store => widget.store;
  void info(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
  String rupiah(int n) => 'Rp' + n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  Future<void> register() async {
    final name = TextEditingController(), brand = TextEditingController(), serial = TextEditingController();
    final location = TextEditingController(), holder = TextEditingController(), cost = TextEditingController(text: '0');
    String category = 'IT';
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, update) =>
      AlertDialog(title: const Text('Registrasi Aset'), content: SizedBox(width: 460,
        child: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Kode permanen diterbitkan secara otomatis.'), const SizedBox(height: 16),
          field(name, 'Nama aset *', required: true),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: category, decoration: const InputDecoration(labelText: 'Kategori'),
            items: ['IT', 'Elektronik', 'Furnitur', 'Kendaraan', 'Mesin', 'Bangunan', 'Lainnya'].map((x) =>
              DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (x) => update(() => category = x ?? category)),
          const SizedBox(height: 10), field(brand, 'Merek'), const SizedBox(height: 10),
          field(serial, 'Nomor seri'), const SizedBox(height: 10),
          field(location, 'Lokasi *', required: true), const SizedBox(height: 10),
          field(holder, 'Penanggung jawab'), const SizedBox(height: 10),
          TextFormField(controller: cost, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Harga perolehan (Rp)'),
            validator: (v) => (int.tryParse(v ?? '') == null || int.parse(v!) < 0) ? 'Masukkan angka tidak negatif' : null),
        ])))), actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(ctx, true); },
            child: const Text('Simpan')),
        ])));
    if (ok == true) {
      try {
        await store.add(name.text, category, brand.text, serial.text, location.text, holder.text, int.parse(cost.text));
        setState(() => page = 1);
        info('Aset berhasil disimpan');
      } catch (e) { info(e.toString()); }
    }
    for (final c in [name, brand, serial, location, holder, cost]) { c.dispose(); }
  }
  Widget field(TextEditingController c, String label, {bool required = false}) => TextFormField(
    controller: c, decoration: InputDecoration(labelText: label),
    validator: required ? (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null : null);
  Future<void> mutate(AssetRecord a) async {
    final location = TextEditingController(text: a.location), holder = TextEditingController(text: a.holder);
    final reason = TextEditingController();
    var status = a.status, condition = a.condition;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, update) =>
      AlertDialog(title: Text('Mutasi · ' + a.code), content: SizedBox(width: 460,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          field(location, 'Lokasi *', required: true), const SizedBox(height: 10),
          field(holder, 'Penanggung jawab'), const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: status, decoration: const InputDecoration(labelText: 'Status'),
            items: ['Tersedia', 'Digunakan', 'Dalam Perbaikan', 'Hilang', 'Dihapuskan'].map((x) =>
              DropdownMenuItem(value: x, child: Text(x))).toList(),
            onChanged: (x) => update(() => status = x ?? status)), const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: condition, decoration: const InputDecoration(labelText: 'Kondisi'),
            items: ['Baru', 'Baik', 'Cukup', 'Kurang Baik', 'Rusak'].map((x) =>
              DropdownMenuItem(value: x, child: Text(x))).toList(),
            onChanged: (x) => update(() => condition = x ?? condition)), const SizedBox(height: 10),
          field(reason, 'Alasan perubahan *'),
        ])), actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan Perubahan')),
        ])));
    if (ok == true) {
      try { await store.change(a, location.text, holder.text, status, condition, reason.text);
        info('Mutasi dan riwayat dicatat'); }
      catch (e) { info(e.toString()); }
    }
    location.dispose(); holder.dispose(); reason.dispose();
  }
  Widget panel(Widget child) => Card(child: Padding(padding: const EdgeInsets.all(18), child: child));
  Widget badge(String status) {
    final c = status == 'Digunakan' ? Colors.green : status == 'Tersedia' ? Colors.blue :
      status == 'Dalam Perbaikan' ? Colors.orange : Colors.red;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: c.withValues(alpha: .09)),
      child: Text(status, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)));
  }
  Widget metric(String label, String value, IconData icon) => SizedBox(width: 225, child: panel(
    Row(children: [Icon(icon, color: const Color(0xFF1464A4)), const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
        const SizedBox(height: 5), Text(value, style: const TextStyle(color: navy, fontSize: 22, fontWeight: FontWeight.bold))
      ]))])));
  Widget dashboard() {
    final active = store.assets.where((a) => a.status != 'Dihapuskan').toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 12, runSpacing: 12, children: [
        metric('Total Aset', active.length.toString(), Icons.inventory_2_outlined),
        metric('Digunakan', active.where((x) => x.status == 'Digunakan').length.toString(), Icons.person_pin_outlined),
        metric('Perlu Perhatian', active.where((x) => x.status == 'Dalam Perbaikan' || x.status == 'Hilang' ||
          x.condition == 'Rusak').length.toString(), Icons.warning_amber_outlined),
        metric('Nilai Perolehan', rupiah(active.fold<int>(0, (s, a) => s + a.cost)), Icons.payments_outlined),
      ]), const SizedBox(height: 18),
      panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Aktivitas Terbaru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const Divider(height: 24),
        for (final e in store.events.take(8)) eventTile(e),
      ])),
    ]);
  }
  Widget eventTile(EventRecord e) {
    final matches = store.assets.where((a) => a.id == e.assetId);
    final assetCode = matches.isEmpty ? 'Aset' : matches.first.code;
    return ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.history),
      title: Text(e.type + ' · ' + assetCode), subtitle: Text(e.detail),
      trailing: Text(e.timestamp.substring(0, 10), style: const TextStyle(fontSize: 11)));
  }
  Widget catalog() {
    final matches = store.assets.where((a) =>
      (filter == 'Semua' || a.status == filter) &&
      (a.code + a.name + a.location + a.holder + a.serial).toLowerCase().contains(query.toLowerCase())).toList();
    return Column(children: [
      panel(Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(width: 310, child: TextField(onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari kode, nama, lokasi, PIC'))),
        SizedBox(width: 190, child: DropdownButtonFormField<String>(initialValue: filter,
          decoration: const InputDecoration(labelText: 'Status'),
          items: ['Semua', 'Tersedia', 'Digunakan', 'Dalam Perbaikan', 'Hilang', 'Dihapuskan']
            .map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
          onChanged: (x) => setState(() => filter = x ?? 'Semua'))),
        Text(matches.length.toString() + ' aset'),
      ])), const SizedBox(height: 12),
      panel(Column(children: [
        for (final a in matches) ...[
          ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.qr_code)),
            title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(a.code + '  ·  ' + a.category + '  ·  ' + a.location),
            trailing: badge(a.status), onTap: () => setState(() => selected = a)),
          const Divider(height: 1),
        ],
        if (matches.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Tidak ada aset yang cocok.')),
      ]))
    ]);
  }
  Widget datum(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [SizedBox(width: 160, child: Text(label, style: const TextStyle(color: Colors.blueGrey))),
      Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontWeight: FontWeight.w600)))]));
  Widget detail(AssetRecord a) => Wrap(spacing: 16, runSpacing: 16, children: [
    SizedBox(width: 600, child: panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(a.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        badge(a.status)]), const Divider(height: 25),
      datum('Kode', a.code), datum('Kategori', a.category), datum('Merek', a.brand),
      datum('Nomor Seri', a.serial), datum('Lokasi', a.location), datum('Penanggung Jawab', a.holder),
      datum('Kondisi', a.condition), datum('Nilai Perolehan', rupiah(a.cost)),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: a.status == 'Dihapuskan' ? null : () => mutate(a),
        icon: const Icon(Icons.swap_horiz), label: const Text('Mutasi / Ubah Status')),
      const Divider(height: 30),
      const Text('Riwayat Aset', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      for (final e in store.events.where((e) => e.assetId == a.id)) eventTile(e),
    ]))),
    SizedBox(width: 260, child: panel(Column(children: [
      const Text('Label QR Aset', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12), QrImageView(data: a.code, size: 180),
      SelectableText(a.code), const SizedBox(height: 10),
      const Text('QR hanya berisi kode aset, belum URL produksi.', textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
      OutlinedButton.icon(onPressed: () async {
        await Clipboard.setData(ClipboardData(text: a.code)); info('Kode aset disalin');
      }, icon: const Icon(Icons.copy), label: const Text('Salin kode'))
    ]))),
  ]);
  Widget settings() => panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Penyimpanan Lokal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12), const Text('Data hanya disimpan di browser saat ini. Tidak ada login, server, atau sinkronisasi. Jangan gunakan data operasional nyata.'),
    const SizedBox(height: 18),
    Wrap(spacing: 12, children: [
      OutlinedButton.icon(onPressed: () async {
        await Clipboard.setData(ClipboardData(text: store.backup())); info('Backup JSON disalin');
      }, icon: const Icon(Icons.copy), label: const Text('Salin Backup JSON')),
      OutlinedButton.icon(onPressed: () async {
        final input = TextEditingController();
        final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Impor Backup JSON'),
          content: SizedBox(width: 500, child: TextField(controller: input, minLines: 5, maxLines: 10,
            decoration: const InputDecoration(hintText: 'Tempel JSON backup'))),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Impor'))]));
        if (ok == true) {
          try { store.restore(input.text); await store.persist(); info('Data dipulihkan'); }
          catch (_) { info('Backup tidak valid'); }
        }
        input.dispose();
      }, icon: const Icon(Icons.upload_file), label: const Text('Impor JSON')),
      OutlinedButton.icon(onPressed: () async {
        final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Reset data simulasi?'), content: const Text('Data pada browser akan diganti.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset'))]));
        if (confirm == true) { store.seed(); await store.persist(); info('Data demo direset'); }
      }, icon: const Icon(Icons.refresh), label: const Text('Reset Demo')),
    ]),
    const SizedBox(height: 16),
    Text('Nomor berikutnya: UDL-AST-' + store.nextNumber.toString().padLeft(6, '0')),
  ]));
  Widget menu(bool isDrawer) => Column(children: [
    const Padding(padding: EdgeInsets.fromLTRB(18, 25, 18, 16),
      child: Align(alignment: Alignment.centerLeft, child: Text('WORKSPACE',
        style: TextStyle(fontSize: 11, color: Colors.blueGrey, letterSpacing: 1.5)))),
    for (var i = 0; i < labels.length; i++) Padding(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      child: ListTile(dense: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: page == i && selected == null, selectedTileColor: const Color(0xFFE7F2FB),
        leading: Icon(icons[i], size: 20), title: Text(labels[i]),
        onTap: () { setState(() { page = i; selected = null; }); if (isDrawer) Navigator.pop(context); })),
    const Spacer(), const Padding(padding: EdgeInsets.all(15), child: Text('UDL Assets v0.1 · Local UAT',
      style: TextStyle(fontSize: 11, color: Colors.blueGrey)))
  ]);
  @override Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 850;
    return Scaffold(
      appBar: AppBar(backgroundColor: navy, foregroundColor: Colors.white,
        title: const Text('UD. LUTHFI  /  Manajemen Aset', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: const [Center(child: Padding(padding: EdgeInsets.only(right: 20),
          child: Text('PROTOTIPE LOKAL', style: TextStyle(fontSize: 11))))]),
      drawer: narrow ? Drawer(child: SafeArea(child: menu(true))) : null,
      body: Row(children: [
        if (!narrow) Container(width: 225, color: Colors.white, child: menu(false)),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(selected == null ? labels[page] : 'Detail Aset',
                    style: const TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 26)),
                  const SizedBox(height: 5),
                  Text(selected == null ? 'Pengendalian aset operasional · data simulasi' : selected!.code,
                    style: const TextStyle(color: Colors.blueGrey)),
                ])),
                if (selected != null) OutlinedButton.icon(onPressed: () => setState(() => selected = null),
                  icon: const Icon(Icons.arrow_back), label: const Text('Kembali')),
                if (selected == null && page == 1) FilledButton.icon(onPressed: register,
                  icon: const Icon(Icons.add), label: const Text('Tambah Aset')),
              ]),
              const SizedBox(height: 22),
              if (selected != null) detail(selected!)
              else if (page == 0) dashboard()
              else if (page == 1) catalog()
              else if (page == 2) panel(Column(children: [for (final e in store.events) eventTile(e)]))
              else settings()
            ]))))),
      ])
    );
  }
}
