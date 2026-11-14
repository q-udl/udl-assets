part of 'main.dart';

class AssetRecord {
  String id, code, name, category, subcategory, assetType, brand, serial, location, holder, condition, status;
  String model = '', acquisitionDate = '';
  String categoryId = '', subcategoryId = '', typeId = '';
  int? acquisitionCost;
  int cost;
  AssetRecord(this.id, this.code, this.name, this.category, this.brand, this.serial,
      this.location, this.holder, this.condition, this.status, this.cost,
      {this.subcategory = '', this.assetType = ''});
  Map<String, dynamic> toJson() => {
    'id': id, 'code': code, 'name': name, 'category': category,
    'subcategory': subcategory, 'assetType': assetType,
    'brand': brand, 'serial': serial, 'location': location, 'holder': holder,
    'condition': condition, 'status': status, 'cost': cost,
    'model': model, 'acquisitionDate': acquisitionDate, 'acquisitionCost': acquisitionCost ?? cost,
    'categoryId': categoryId, 'subcategoryId': subcategoryId, 'typeId': typeId,
  };
  factory AssetRecord.fromJson(Map<String, dynamic> m) {
    final old = m['category']?.toString() ?? '';
    final name = m['name']?.toString() ?? '';
    final sub = m['subcategory']?.toString() ?? '';
    final typ = m['assetType']?.toString() ?? '';
    final cl = sub.isEmpty || typ.isEmpty
      ? classifyLegacyAsset(old, name) : AssetClassification(old, sub, typ);
    final a = AssetRecord(m['id']?.toString() ?? uuid.v4(), m['code']?.toString() ?? '',
      name, cl.category, m['brand']?.toString() ?? '', m['serial']?.toString() ?? '',
      m['location']?.toString() ?? '', m['holder']?.toString() ?? '',
      m['condition']?.toString() ?? 'Baik', m['status']?.toString() ?? 'Tersedia',
      (m['cost'] as num?)?.toInt() ?? 0,
      subcategory: cl.subcategory, assetType: cl.type);
    a.model = m['model']?.toString() ?? '';
    a.acquisitionDate = m['acquisitionDate']?.toString() ?? '';
    a.acquisitionCost = m.containsKey('acquisitionCost')
      ? (m['acquisitionCost'] as num?)?.toInt() : a.cost;
    a.categoryId = m['categoryId']?.toString() ?? '';
    a.subcategoryId = m['subcategoryId']?.toString() ?? '';
    a.typeId = m['typeId']?.toString() ?? '';
    return a;
  }
}
class EventRecord {
  final String assetId, type, detail, timestamp;
  final Map<String, dynamic> changes;
  final String reason, actor;
  EventRecord(this.assetId, this.type, this.detail, this.timestamp,
    {Map<String, dynamic>? changes, this.reason = '', this.actor = 'Simulasi Lokal'})
      : changes = changes ?? {};
  Map<String, dynamic> toJson() => {
    'assetId': assetId, 'type': type, 'detail': detail, 'timestamp': timestamp,
    'changes': changes, 'reason': reason, 'actor': actor
  };
  factory EventRecord.fromJson(Map<String, dynamic> m) => EventRecord(
    m['assetId']?.toString() ?? '', m['type']?.toString() ?? '',
    m['detail']?.toString() ?? '', m['timestamp']?.toString() ?? '',
    changes: m['changes'] is Map ? Map<String, dynamic>.from(m['changes'] as Map) : {},
    reason: m['reason']?.toString() ?? '',
    actor: m['actor']?.toString() ?? 'Tidak terverifikasi');
}
class AssetPhoto {
  final String id, assetId, kind, fileName, timestamp, mimeType, base64Data;
  bool isPrimary;
  String note = '', relatedEvent = '', archivedReason = '';
  bool archived = false;
  AssetPhoto(this.id, this.assetId, this.kind, this.fileName, this.timestamp,
      this.mimeType, this.base64Data, this.isPrimary);
  Map<String, dynamic> toJson() => {
    'id': id, 'assetId': assetId, 'kind': kind, 'fileName': fileName,
    'timestamp': timestamp, 'mimeType': mimeType,
    'base64Data': base64Data, 'isPrimary': isPrimary,
    'note': note, 'relatedEvent': relatedEvent,
    'archived': archived, 'archivedReason': archivedReason,
  };
  factory AssetPhoto.fromJson(Map<String, dynamic> x) => AssetPhoto(
    x['id']?.toString() ?? uuid.v4(), x['assetId']?.toString() ?? '',
    x['kind']?.toString() ?? 'Dokumentasi Kondisi',
    x['fileName']?.toString() ?? 'Foto', x['timestamp']?.toString() ?? '',
    x['mimeType']?.toString() ?? 'image/jpeg',
    x['base64Data']?.toString() ?? '', x['isPrimary'] == true)
    ..note = x['note']?.toString() ?? ''
    ..relatedEvent = x['relatedEvent']?.toString() ?? ''
    ..archived = x['archived'] == true
    ..archivedReason = x['archivedReason']?.toString() ?? '';
  Uint8List get bytes => base64Decode(base64Data);
}
class AssetTransfer {
  final String id, assetId, fromLocation, toLocation, fromHolder, toHolder, reason, requestedAt;
  String state, respondedAt, note;
  AssetTransfer(this.id, this.assetId, this.fromLocation, this.toLocation,
    this.fromHolder, this.toHolder, this.reason, this.requestedAt,
    {this.state = 'Menunggu Penerimaan', this.respondedAt = '', this.note = ''});
  Map<String, dynamic> toJson() => {
    'id': id, 'assetId': assetId, 'fromLocation': fromLocation, 'toLocation': toLocation,
    'fromHolder': fromHolder, 'toHolder': toHolder, 'reason': reason,
    'requestedAt': requestedAt, 'state': state, 'respondedAt': respondedAt, 'note': note};
  factory AssetTransfer.fromJson(Map<String, dynamic> x) => AssetTransfer(
    x['id']?.toString() ?? uuid.v4(), x['assetId']?.toString() ?? '',
    x['fromLocation']?.toString() ?? '', x['toLocation']?.toString() ?? '',
    x['fromHolder']?.toString() ?? '', x['toHolder']?.toString() ?? '',
    x['reason']?.toString() ?? '', x['requestedAt']?.toString() ?? '',
    state: x['state']?.toString() ?? 'Menunggu Penerimaan',
    respondedAt: x['respondedAt']?.toString() ?? '',
    note: x['note']?.toString() ?? '');
}

class AssetStore extends ChangeNotifier {
  List<AssetRecord> assets = [];
  List<EventRecord> events = [];
  List<AssetCategory> categories = defaultTaxonomy();
  List<AssetPhoto> photos = [];
  List<AssetTransfer> transfers = [];
  List<String> locations = ['Kantor Pusat', 'Gudang Pusat', 'Outlet Jepara'];
  int nextNumber = 1;
  bool loaded = false;
  String? loadError;
  static const key = 'udl_asset_local_mvp_v1';
  static const photoKinds = ['Tampak Fisik Aset', 'Dokumentasi Kondisi',
    'Label / Nomor Seri', 'Kerusakan / Perbaikan'];
  static const maxPhotoBytes = 500 * 1024;
  static const maxPhotoCount = 8;
  static const maxAllEncodedBytes = 2900000;
  AssetStore();

  Future<void> initialize() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      if (raw == null) { seed(); await persist(); }
      else { restore(raw); }
    } catch (e) {
      loadError = 'Data browser tidak dapat dibaca. Data lama tidak ditimpa: ' + e.toString();
    }
    loaded = true;
    notifyListeners();
  }
  void seed() {
    categories = defaultTaxonomy();
    assets = [
      AssetRecord(uuid.v4(), 'UDL-AST-000001', 'Laptop Lenovo ThinkPad T14',
        'Teknologi Informasi & Komunikasi', 'Lenovo', 'DEMO-001', 'Kantor Pusat',
        'Staf Finance', 'Baik', 'Digunakan', 12500000,
        subcategory: 'Komputer', assetType: 'Laptop'),
      AssetRecord(uuid.v4(), 'UDL-AST-000002', 'Printer Brother',
        'Teknologi Informasi & Komunikasi', 'Brother', 'DEMO-002',
        'Outlet Jepara', '', 'Baik', 'Tersedia', 3400000,
        subcategory: 'Periferal Komputer', assetType: 'Printer Dokumen'),
      AssetRecord(uuid.v4(), 'UDL-AST-000003', 'AC Daikin 2 PK',
        'Peralatan Fasilitas & Utilitas', 'Daikin', 'DEMO-003', 'Gudang Pusat',
        '', 'Cukup', 'Dalam Perbaikan', 8500000,
        subcategory: 'Pendingin Ruangan', assetType: 'AC'),
      AssetRecord(uuid.v4(), 'UDL-AST-000004', 'Forklift Toyota',
        'Peralatan Gudang & Logistik', 'Toyota', 'DEMO-004', 'Gudang Pusat',
        'Petugas Gudang', 'Baik', 'Digunakan', 180000000,
        subcategory: 'Penanganan Material', assetType: 'Forklift'),
      AssetRecord(uuid.v4(), 'UDL-AST-000005', 'Meja Kerja Supervisor',
        'Furnitur', 'Lokal', 'DEMO-005', 'Outlet Jepara', 'Supervisor Outlet',
        'Baik', 'Digunakan', 1700000,
        subcategory: 'Meja', assetType: 'Meja Kerja'),
    ];
    events = [for (final a in assets)
      EventRecord(a.id, 'Registrasi', 'Registrasi data simulasi',
        DateTime.now().toIso8601String())];
    photos = []; transfers = []; nextNumber = 6; loadError = null; notifyListeners();
  }
  AssetCategory? categoryByName(String name) {
    for (final c in categories) { if (c.name == name) return c; }
    return null;
  }
  AssetSubcategory? subcategoryByName(String category, String name) {
    final cat = categoryByName(category);
    if (cat == null) return null;
    for (final sub in cat.subcategories) { if (sub.name == name) return sub; }
    return null;
  }
  List<AssetPhoto> photosFor(String id) =>
    photos.where((p) => p.assetId == id && !p.archived).toList();
  List<AssetPhoto> archivedPhotosFor(String id) =>
    photos.where((p) => p.assetId == id && p.archived).toList();
  AssetPhoto? primaryPhotoFor(String id) {
    final list = photosFor(id);
    for (final photo in list) { if (photo.isPrimary) return photo; }
    return list.isEmpty ? null : list.first;
  }
  void restore(String raw) {
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic>) throw const FormatException('JSON bukan objek.');
    final a = value['assets'], e = value['events'], next = value['nextNumber'];
    if (a is! List || e is! List || next is! num) throw const FormatException('Backup tidak sesuai.');
    final restoredAssets = a.map((v) =>
      AssetRecord.fromJson(Map<String, dynamic>.from(v as Map))).toList();
    final restoredEvents = e.map((v) =>
      EventRecord.fromJson(Map<String, dynamic>.from(v as Map))).toList();
    final restoredPhotos = (value['photos'] as List<dynamic>? ?? []).map((v) =>
      AssetPhoto.fromJson(Map<String, dynamic>.from(v as Map))).toList();
    final restoredCategories = value['categories'] is List
      ? (value['categories'] as List<dynamic>).map((v) =>
          AssetCategory.fromJson(Map<String, dynamic>.from(v as Map))).toList()
      : defaultTaxonomy();
    final codes = restoredAssets.map((v) => v.code).toList();
    final ids = restoredAssets.map((v) => v.id).toSet();
    if (next.toInt() < 1 || codes.toSet().length != codes.length ||
        codes.any((v) => !RegExp(r'^UDL-AST-\d{6,}$').hasMatch(v))) {
      throw const FormatException('Kode aset atau nomor urut tidak valid.');
    }
    if (restoredCategories.isEmpty ||
        restoredCategories.map((v) => v.name.toLowerCase()).toSet().length !=
          restoredCategories.length ||
        restoredCategories.any((v) => ['tanah', 'bangunan', 'properti & bangunan']
          .contains(v.name.toLowerCase()))) {
      throw const FormatException('Master kategori tidak valid.');
    }
    if (restoredPhotos.any((v) => !ids.contains(v.assetId)) ||
        restoredPhotos.map((v) => v.id).toSet().length != restoredPhotos.length ||
        restoredPhotos.fold<int>(0, (sum, v) => sum + v.base64Data.length) >
          maxAllEncodedBytes) {
      throw const FormatException('Referensi/ukuran foto backup tidak valid.');
    }
    assets = restoredAssets; events = restoredEvents;
    photos = restoredPhotos; categories = restoredCategories;
    transfers = (value['transfers'] as List<dynamic>? ?? [])
      .map((v) => AssetTransfer.fromJson(Map<String, dynamic>.from(v as Map))).toList();
    locations = (value['locations'] as List<dynamic>? ?? [])
      .map((v) => v.toString()).toList();
    locations = {...locations, 'Kantor Pusat', 'Gudang Pusat', 'Outlet Jepara',
      ...assets.map((a) => a.location)}.toList();
    for (final a in assets) {
      final c = categoryByName(a.category);
      if (c == null) continue;
      a.categoryId = c.code;
      final sub = subcategoryByName(c.name, a.subcategory);
      if (sub == null) continue;
      a.subcategoryId = sub.id; a.typeId = sub.typeId(a.assetType);
    }
    final biggest = assets.map((v) => int.tryParse(v.code.split('-').last) ?? 0)
      .fold<int>(0, (x, y) => x > y ? x : y);
    nextNumber = next.toInt() > biggest ? next.toInt() : biggest + 1;
    loadError = null; notifyListeners();
  }
  String backup() => const JsonEncoder.withIndent('  ').convert({
    'version': 3, 'nextNumber': nextNumber,
    'locations': locations, 'transfers': transfers.map((v) => v.toJson()).toList(),
    'assets': assets.map((v) => v.toJson()).toList(),
    'events': events.map((v) => v.toJson()).toList(),
    'categories': categories.map((v) => v.toJson()).toList(),
    'photos': photos.map((v) => v.toJson()).toList(),
  });
  Future<void> persist() async {
    final ok = await (await SharedPreferences.getInstance()).setString(key, backup());
    if (!ok) throw StateError('Browser menolak penyimpanan lokal.');
    notifyListeners();
  }
  Future<void> add(String name, String category, String brand, String serial,
      String location, String holder, int cost, {String? subcategory, String? assetType}) async {
    if (name.trim().isEmpty || location.trim().isEmpty || cost < 0) {
      throw const FormatException('Nama, lokasi, dan harga harus valid.');
    }
    if (serial.trim().isNotEmpty && assets.any((a) =>
      a.serial.toLowerCase() == serial.trim().toLowerCase() && a.status != 'Dihapuskan')) {
      throw const FormatException('Nomor seri sudah tercatat.');
    }
    final mapped = category == 'IT' ? 'Teknologi Informasi & Komunikasi' : category;
    final c = categoryByName(mapped);
    if (c == null) throw const FormatException('Kategori harus dipilih dari master.');
    final s = subcategory == null
      ? (c.subcategories.isEmpty ? null : c.subcategories.first)
      : subcategoryByName(c.name, subcategory);
    if (s == null) throw const FormatException('Subkategori tidak valid.');
    final t = assetType ?? (s.types.isEmpty ? '' : s.types.first);
    if (!s.types.contains(t) || !c.active || !s.active || !s.typeIsActive(t)) {
      throw const FormatException('Jenis aset tidak tersedia/aktif.');
    }
    final code = 'UDL-AST-' + nextNumber.toString().padLeft(6, '0');
    final a = AssetRecord(uuid.v4(), code, name.trim(), c.name, brand.trim(), serial.trim(),
      location.trim(), holder.trim(), 'Baik',
      holder.trim().isEmpty ? 'Tersedia' : 'Digunakan', cost,
      subcategory: s.name, assetType: t);
    a.categoryId = c.code; a.subcategoryId = s.id; a.typeId = s.typeId(t);
    assets.insert(0, a); nextNumber++;
    log(a, 'Registrasi', 'Aset didaftarkan di ' + a.location);
    await persist();
  }
  void log(AssetRecord a, String type, String detail,
      {Map<String, dynamic>? changes, String reason = ''}) =>
    events.insert(0, EventRecord(a.id, type, detail, DateTime.now().toIso8601String(),
      changes: changes, reason: reason));
  Future<void> change(AssetRecord a, String location, String holder, String status,
      String condition, String reason) async {
    if (a.status == 'Dihapuskan') throw const FormatException('Aset sudah dihapuskan.');
    if (location.trim().isEmpty || reason.trim().isEmpty) {
      throw const FormatException('Lokasi dan alasan wajib diisi.');
    }
    final detail = a.location + ' → ' + location + '; ' + a.holder + ' → ' + holder +
      '; ' + a.status + ' → ' + status + '. Alasan: ' + reason;
    final before = {'Lokasi': a.location, 'PIC': a.holder,
      'Status': a.status, 'Kondisi': a.condition};
    a.location = location.trim(); a.holder = holder.trim();
    a.status = status; a.condition = condition;
    log(a, status == 'Dihapuskan' ? 'Penghapusan' : 'Mutasi', detail,
      reason: reason, changes: {
        'Lokasi': {'from': before['Lokasi'], 'to': a.location},
        'PIC': {'from': before['PIC'], 'to': a.holder},
        'Status': {'from': before['Status'], 'to': a.status},
        'Kondisi': {'from': before['Kondisi'], 'to': a.condition}});
    await persist();
  }
  Future<void> reclassify(AssetRecord a, String category, String subcategory,
      String assetType, String reason) async {
    final s = subcategoryByName(category, subcategory);
    if (s == null || !s.types.contains(assetType) || reason.trim().isEmpty) {
      throw const FormatException('Klasifikasi atau alasan belum valid.');
    }
    final previous = a.category + ' / ' + a.subcategory + ' / ' + a.assetType;
    a.category = category; a.subcategory = subcategory; a.assetType = assetType;
    a.categoryId = categoryByName(category)?.code ?? '';
    a.subcategoryId = s.id; a.typeId = s.typeId(assetType);
    log(a, 'Reklasifikasi', previous + ' → ' + category + ' / ' + subcategory +
      ' / ' + assetType + '. Alasan: ' + reason);
    await persist();
  }
  Future<void> addCategory(String name) async {
    final clean = name.trim();
    if (clean.length < 3 || categories.any((v) =>
        v.name.toLowerCase() == clean.toLowerCase()) ||
        ['tanah', 'bangunan', 'properti & bangunan'].contains(clean.toLowerCase())) {
      throw const FormatException('Kategori tidak valid atau dikecualikan.');
    }
    var largest = 0;
    for (final cat in categories) {
      final v = int.tryParse(cat.code) ?? 0; if (v > largest) largest = v;
    }
    categories.add(AssetCategory((largest + 1).toString().padLeft(2, '0'), clean, []));
    await persist();
  }
  Future<void> addSubcategory(AssetCategory cat, String name) async {
    final clean = name.trim();
    if (clean.length < 2 || cat.subcategories.any((v) =>
        v.name.toLowerCase() == clean.toLowerCase())) {
      throw const FormatException('Subkategori tidak valid atau duplikat.');
    }
    cat.subcategories.add(AssetSubcategory(clean, [], id: 'sub-' + uuid.v4())); await persist();
  }
  Future<void> addType(AssetCategory cat, AssetSubcategory sub, String name) async {
    final clean = name.trim();
    if (clean.length < 2 || sub.types.any((v) =>
        v.toLowerCase() == clean.toLowerCase())) {
      throw const FormatException('Jenis aset tidak valid atau duplikat.');
    }
    sub.types.add(clean); sub.typeIds[clean] = 'type-' + uuid.v4(); await persist();
  }
  Future<void> addPhoto(AssetRecord a, Uint8List bytes, String fileName, String kind,
      {String note = '', String relatedEvent = ''}) async {
    if (!assets.any((v) => v.id == a.id)) throw const FormatException('Aset tidak ada.');
    if (!photoKinds.contains(kind)) throw const FormatException('Kategori foto tidak dikenal.');
    if (photosFor(a.id).length >= maxPhotoCount) throw const FormatException('Maksimum 8 foto per aset.');
    if (bytes.isEmpty || bytes.length > maxPhotoBytes) {
      throw const FormatException('Foto maksimal 500 KB setelah kompresi.');
    }
    final mime = _mime(bytes);
    if (mime == null) throw const FormatException('Foto harus JPEG, PNG, atau WebP.');
    final encoded = base64Encode(bytes);
    final total = photos.fold<int>(0, (n, p) => n + p.base64Data.length);
    if (total + encoded.length > maxAllEncodedBytes) {
      throw const FormatException('Kuota foto prototipe lokal hampir penuh.');
    }
    final photo = AssetPhoto(uuid.v4(), a.id, kind, fileName,
      DateTime.now().toIso8601String(), mime, encoded, photosFor(a.id).isEmpty)
      ..note = note ..relatedEvent = relatedEvent;
    photos.add(photo);
    log(a, 'Dokumentasi Foto', 'Ditambahkan: ' + kind + ' (' + fileName + ')');
    try { await persist(); }
    catch (_) {
      photos.removeWhere((p) => p.id == photo.id);
      if (events.isNotEmpty && events.first.assetId == a.id &&
          events.first.type == 'Dokumentasi Foto') {
        events.removeAt(0);
      }
      rethrow;
    }
  }
  Future<void> setPrimaryPhoto(AssetRecord a, AssetPhoto selected) async {
    if (selected.assetId != a.id || selected.archived) throw const FormatException('Foto tidak aktif/milik aset.');
    for (final p in photos) {
      if (p.assetId == a.id) p.isPrimary = p.id == selected.id;
    }
    log(a, 'Foto Utama', 'Foto utama diganti ke ' + selected.fileName);
    await persist();
  }
  String? _mime(Uint8List bytes) {
    if (bytes.length > 3 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255) {
      return 'image/jpeg';
    }
    if (bytes.length > 8 && bytes[0] == 137 && bytes[1] == 80 && bytes[2] == 78) {
      return 'image/png';
    }
    if (bytes.length > 12 && String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }
}
