part of 'main.dart';

class AssetRecord {
  String id, code, name, category, subcategory, assetType, brand, serial, location, holder, condition, status;
  String model = '', acquisitionDate = '';
  String categoryId = '', subcategoryId = '', typeId = '';
  String assignedEmployeeId = '';
  String locationSiteId = '', locationAreaId = '', locationSpotId = '';
  String lifecycle = 'Aktif';
  String qrToken = newAssetQrToken();
  bool qrRevoked = false;
  String releaseType = '', releaseDate = '', releaseReference = '',
    releaseReason = '', releaseHandledBy = '';
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
    'model': model, 'acquisitionDate': acquisitionDate, 'acquisitionCost': acquisitionCost,
    'categoryId': categoryId, 'subcategoryId': subcategoryId, 'typeId': typeId,
    'assignedEmployeeId': assignedEmployeeId,
    'qrToken': qrToken, 'qrRevoked': qrRevoked,
    'locationSiteId': locationSiteId,
    'locationAreaId': locationAreaId, 'locationSpotId': locationSpotId,
    'lifecycle': lifecycle,
    'releaseType': releaseType, 'releaseDate': releaseDate,
    'releaseReference': releaseReference,
    'releaseReason': releaseReason, 'releaseHandledBy': releaseHandledBy,
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
    a.assignedEmployeeId = m['assignedEmployeeId']?.toString() ?? '';
    a.qrToken = m['qrToken']?.toString() ?? '';
    a.qrRevoked = m['qrRevoked'] == true;
    a.locationSiteId = m['locationSiteId']?.toString() ?? '';
    a.locationAreaId = m['locationAreaId']?.toString() ?? '';
    a.locationSpotId = m['locationSpotId']?.toString() ?? '';
    a.lifecycle = m['lifecycle']?.toString() ??
      (a.status == 'Dihapuskan' ? 'Dilepas' : 'Aktif');
    a.releaseType = m['releaseType']?.toString() ?? '';
    a.releaseDate = m['releaseDate']?.toString() ?? '';
    a.releaseReference = m['releaseReference']?.toString() ?? '';
    a.releaseReason = m['releaseReason']?.toString() ?? '';
    a.releaseHandledBy = m['releaseHandledBy']?.toString() ?? '';
    return a;
  }
}
class EventRecord {
  final String assetId, type, detail, timestamp;
  final Map<String, dynamic> changes;
  final String reason, actor;
  EventRecord(this.assetId, this.type, this.detail, this.timestamp,
    {Map<String, dynamic>? changes, this.reason = '', this.actor = 'Sistem'})
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

/// Transaction evidence is immutable and separate from catalog photographs.
/// Proof is linked explicitly to the event ID and physical asset ID.
class AssetEvidencePhoto {
  final String id, assetId, transactionId, transactionType;
  final String fileName, recordedAt, mimeType, base64Data;

  const AssetEvidencePhoto({
    required this.id,
    required this.assetId,
    required this.transactionId,
    required this.transactionType,
    required this.fileName,
    required this.recordedAt,
    required this.mimeType,
    required this.base64Data,
  });

  Uint8List get bytes => base64Decode(base64Data);

  Map<String, dynamic> toJson() => {
    'id': id, 'assetId': assetId, 'transactionId': transactionId,
    'transactionType': transactionType, 'fileName': fileName,
    'recordedAt': recordedAt, 'mimeType': mimeType,
    'base64Data': base64Data,
  };

  factory AssetEvidencePhoto.fromJson(Map<String, dynamic> value) =>
    AssetEvidencePhoto(
      id: value['id']?.toString() ?? '',
      assetId: value['assetId']?.toString() ?? '',
      transactionId: value['transactionId']?.toString() ?? '',
      transactionType: value['transactionType']?.toString() ?? '',
      fileName: value['fileName']?.toString() ?? '',
      recordedAt: value['recordedAt']?.toString() ?? '',
      mimeType: value['mimeType']?.toString() ?? '',
      base64Data: value['base64Data']?.toString() ?? '',
    );
}

class AssetTransfer {
  final String id, assetId, fromLocation, toLocation, fromHolder, toHolder, reason, requestedAt;
  String state, respondedAt, note;
  List<String> proofPhotoIds;
  String fromAreaId, fromSpotId, toAreaId, toSpotId;
  AssetTransfer(this.id, this.assetId, this.fromLocation, this.toLocation,
    this.fromHolder, this.toHolder, this.reason, this.requestedAt,
    {this.state = 'Menunggu Penerimaan', this.respondedAt = '',
    this.note = '', this.proofPhotoIds = const [],
    this.fromAreaId = '', this.fromSpotId = '',
    this.toAreaId = '', this.toSpotId = ''});
  Map<String, dynamic> toJson() => {
    'id': id, 'assetId': assetId, 'fromLocation': fromLocation, 'toLocation': toLocation,
    'fromHolder': fromHolder, 'toHolder': toHolder, 'reason': reason,
    'requestedAt': requestedAt, 'state': state, 'respondedAt': respondedAt,
    'note': note, 'proofPhotoIds': proofPhotoIds,
    'fromAreaId': fromAreaId,
    'fromSpotId': fromSpotId, 'toAreaId': toAreaId, 'toSpotId': toSpotId};
  factory AssetTransfer.fromJson(Map<String, dynamic> x) => AssetTransfer(
    x['id']?.toString() ?? uuid.v4(), x['assetId']?.toString() ?? '',
    x['fromLocation']?.toString() ?? '', x['toLocation']?.toString() ?? '',
    x['fromHolder']?.toString() ?? '', x['toHolder']?.toString() ?? '',
    x['reason']?.toString() ?? '', x['requestedAt']?.toString() ?? '',
    state: x['state']?.toString() ?? 'Menunggu Penerimaan',
    respondedAt: x['respondedAt']?.toString() ?? '',
    note: x['note']?.toString() ?? '',
    proofPhotoIds: (x['proofPhotoIds'] as List<dynamic>? ?? [])
      .map((v) => v.toString()).toList(),
    fromAreaId: x['fromAreaId']?.toString() ?? '',
    fromSpotId: x['fromSpotId']?.toString() ?? '',
    toAreaId: x['toAreaId']?.toString() ?? '',
    toSpotId: x['toSpotId']?.toString() ?? '');
}

class AssetStore extends ChangeNotifier {
  List<AssetRecord> assets = [];
  List<EventRecord> events = [];
  List<AssetCategory> categories = defaultTaxonomy();
  List<AssetPhoto> photos = [];
  List<AssetEvidencePhoto> evidencePhotos = [];
  List<AssetTransfer> transfers = [];
  List<AssetEmployee> employees = [];
  List<AssetAssignment> assignments = [];
  List<AssetReturnReceipt> returnReceipts = [];
  int nextAssignmentNumber = 1;
  int nextReturnNumber = 1;
  List<String> locations = ['Kantor Pusat', 'Gudang Pusat', 'Outlet Jepara'];
  List<AssetSite> locationSites = [];
  int nextLocationNumber = 1;
  int nextNumber = 1;
  bool loaded = false;
  String? loadError;
  static const key = 'udl_asset_local_mvp_v1';
  static const photoKinds = ['Tampak Fisik Aset', 'Dokumentasi Kondisi',
    'Label / Nomor Seri', 'Kerusakan / Perbaikan'];
  static const maxPhotoBytes = 500 * 1024;
  static const maxPhotoCount = 8;
  static const maxAllEncodedBytes = 2900000;
  // Separate from the catalog's eight-photo limit; local-browser quota still applies.
  static const maxEvidenceEncodedBytes = 2000000;
  AssetStore();

  /// The scanner never accepts a plain UDL-AST code as a secure QR.
  AssetRecord? resolveQrPayload(String payload) {
    const prefix = 'UDLQR1:';
    if (!payload.startsWith(prefix)) return null;
    final token = payload.substring(prefix.length);
    if (token.isEmpty) return null;
    for (final asset in assets) {
      if (!asset.qrRevoked && asset.qrToken == token) return asset;
    }
    return null;
  }

  Future<void> revokeQrToken(AssetRecord asset) async {
    if (!assets.any((a) => a.id == asset.id)) {
      throw const FormatException('Aset tidak ditemukan.');
    }
    final before = backup();
    try {
      asset.qrRevoked = true;
      log(asset, 'Pencabutan QR',
        'Token QR dicabut dan tidak bisa digunakan untuk pemindaian.');
      await persist();
    } catch (_) {
      restore(before);
      rethrow;
    }
  }

  Future<void> rotateQrToken(AssetRecord asset) async {
    if (!assets.any((a) => a.id == asset.id)) {
      throw const FormatException('Aset tidak ditemukan.');
    }
    final oldToken = asset.qrToken;
    asset.qrToken = newAssetQrToken();
    asset.qrRevoked = false;
    try {
      log(asset, 'Penerbitan Ulang QR',
        'Identitas QR diganti; QR sebelumnya tidak berlaku.');
      await persist();
    } catch (_) {
      asset.qrToken = oldToken;
      rethrow;
    }
  }

  Future<void> initialize() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      if (raw == null) { seed(); await persist(); }
      else {
        restore(raw);
        // Upgrade legacy backups without changing any visible asset code.
        if (assets.any((a) => a.qrToken.isEmpty)) {
          for (final asset in assets) {
            if (asset.qrToken.isEmpty) asset.qrToken = newAssetQrToken();
          }
          await persist();
        }
      }
    } catch (e) {
      loadError = 'Data browser tidak dapat dibaca. Data lama tidak ditimpa: ' + e.toString();
    }
    loaded = true;
    notifyListeners();
  }
  void seed() {
    categories = defaultTaxonomy();
    assets = [
      AssetRecord(uuid.v4(), 'UDL-AST-00000001', 'Laptop Lenovo ThinkPad T14',
        'Teknologi Informasi & Komunikasi', 'Lenovo', 'SN-LT-240418', 'Kantor Pusat',
        'Staf Finance', 'Baik', 'Digunakan', 12500000,
        subcategory: 'Komputer', assetType: 'Laptop'),
      AssetRecord(uuid.v4(), 'UDL-AST-00000002', 'Printer Brother',
        'Teknologi Informasi & Komunikasi', 'Brother', 'SN-PR-240122',
        'Outlet Jepara', '', 'Baik', 'Tersedia', 3400000,
        subcategory: 'Periferal Komputer', assetType: 'Printer Dokumen'),
      AssetRecord(uuid.v4(), 'UDL-AST-00000003', 'AC Daikin 2 PK',
        'Peralatan Fasilitas & Utilitas', 'Daikin', 'SN-AC-230915', 'Gudang Pusat',
        '', 'Cukup', 'Dalam Perbaikan', 8500000,
        subcategory: 'Pendingin Ruangan', assetType: 'AC'),
      AssetRecord(uuid.v4(), 'UDL-AST-00000004', 'Forklift Toyota',
        'Peralatan Gudang & Logistik', 'Toyota', 'SN-FK-231109', 'Gudang Pusat',
        'Petugas Gudang', 'Baik', 'Digunakan', 180000000,
        subcategory: 'Penanganan Material', assetType: 'Forklift'),
      AssetRecord(uuid.v4(), 'UDL-AST-00000005', 'Meja Kerja Supervisor',
        'Furnitur', 'Lokal', 'SN-FN-250108', 'Outlet Jepara', 'Supervisor Outlet',
        'Baik', 'Digunakan', 1700000,
        subcategory: 'Meja', assetType: 'Meja Kerja'),
    ];
    for (final a in assets) {
      a.acquisitionCost = a.cost;
      final c = categoryByName(a.category);
      if (c == null) continue;
      a.categoryId = c.code;
      final sub = subcategoryByName(c.name, a.subcategory);
      if (sub == null) continue;
      a.subcategoryId = sub.id;
      a.typeId = sub.typeId(a.assetType);
    }
    events = [for (final a in assets)
      EventRecord(a.id, 'Registrasi', 'Registrasi awal inventaris',
        DateTime.now().toIso8601String())];
    photos = []; evidencePhotos = [];
    transfers = []; nextNumber = 6;
    final now = DateTime.now().toIso8601String();
    employees = [
      AssetEmployee(id: uuid.v4(),
        name: 'Anisa Putri', unit: 'Outlet',
        department: 'Penjualan', jobTitle: 'Supervisor Outlet',
        workLocation: 'Outlet Jepara',
        createdAt: now, updatedAt: now),
      AssetEmployee(id: uuid.v4(),
        name: 'Rafi Pratama', unit: 'Distribusi',
        department: 'Operasional', jobTitle: 'Staf Gudang',
        workLocation: 'Gudang Pusat',
        createdAt: now, updatedAt: now),
    ];
    assignments = []; returnReceipts = [];
    nextAssignmentNumber = 1; nextReturnNumber = 1;
    migrateLocationMaster(const {});
    loadError = null; notifyListeners();
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

  List<AssetEvidencePhoto> evidenceFor(
      String transactionType, String transactionId, String assetId) =>
    evidencePhotos.where((p) => p.transactionType == transactionType &&
      p.transactionId == transactionId && p.assetId == assetId).toList();

  /// All selected images must exist before the transaction changes state.
  /// No image is persisted while a modal or return form is still being edited.
  List<AssetEvidencePhoto> prepareEvidence({
    required String transactionType,
    required String transactionId,
    required Set<String> requiredAssetIds,
    required Map<String, SelectedAssetPhoto> selectedPhotos,
  }) {
    const types = {
      'assignment_handover', 'assignment_return', 'transfer_handover'};
    if (!types.contains(transactionType) || transactionId.trim().isEmpty ||
        requiredAssetIds.isEmpty ||
        selectedPhotos.length != requiredAssetIds.length ||
        !selectedPhotos.keys.toSet().containsAll(requiredAssetIds)) {
      throw const FormatException(
        'Foto bukti wajib diunggah untuk setiap unit aset.');
    }
    final now = DateTime.now().toIso8601String();
    final prepared = <AssetEvidencePhoto>[];
    var total = evidencePhotos.fold<int>(
      0, (sum, p) => sum + p.base64Data.length);
    for (final assetId in requiredAssetIds) {
      if (!assets.any((a) => a.id == assetId)) {
        throw const FormatException('Referensi aset bukti tidak valid.');
      }
      final photo = selectedPhotos[assetId]!;
      final mime = _mime(photo.bytes);
      if (photo.bytes.isEmpty || photo.bytes.length > maxPhotoBytes ||
          mime == null) {
        throw const FormatException(
          'Foto bukti harus JPEG, PNG, atau WebP maksimal 500 KB.');
      }
      final encoded = base64Encode(photo.bytes);
      total += encoded.length;
      if (total > maxEvidenceEncodedBytes) {
        throw const FormatException(
          'Kuota bukti foto pratinjau lokal hampir penuh. '
          'Gunakan data UAT terpisah, jangan hapus bukti transaksi.');
      }
      prepared.add(AssetEvidencePhoto(
        id: uuid.v4(), assetId: assetId,
        transactionId: transactionId, transactionType: transactionType,
        fileName: photo.fileName, recordedAt: now,
        mimeType: mime, base64Data: encoded));
    }
    return prepared;
  }
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
    final restoredEvidence = (value['evidencePhotos'] as List<dynamic>? ?? [])
      .map((v) => AssetEvidencePhoto.fromJson(
        Map<String, dynamic>.from(v as Map))).toList();
    final restoredCategories = value['categories'] is List
      ? (value['categories'] as List<dynamic>).map((v) =>
          AssetCategory.fromJson(Map<String, dynamic>.from(v as Map))).toList()
      : defaultTaxonomy();
    final restoredEmployees = (value['employees'] as List<dynamic>? ?? [])
      .map((v) => AssetEmployee.fromJson(
        Map<String, dynamic>.from(v as Map))).toList();
    final restoredAssignments = (value['assignments'] as List<dynamic>? ?? [])
      .map((v) => AssetAssignment.fromJson(
        Map<String, dynamic>.from(v as Map))).toList();
    final restoredReturns = (value['returnReceipts'] as List<dynamic>? ?? [])
      .map((v) => AssetReturnReceipt.fromJson(
        Map<String, dynamic>.from(v as Map))).toList();
    verifyAssignmentData(restoredAssets, restoredEmployees,
      restoredAssignments, restoredReturns);
    final codes = restoredAssets.map((v) => v.code).toList();
    final ids = restoredAssets.map((v) => v.id).toSet();
    if (next.toInt() < 1 || ids.length != restoredAssets.length ||
        codes.toSet().length != codes.length ||
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
    if (restoredEvidence.any((v) =>
        !ids.contains(v.assetId) || v.id.isEmpty ||
        v.transactionId.isEmpty || v.fileName.isEmpty ||
        !{'image/jpeg', 'image/png', 'image/webp'}.contains(v.mimeType)) ||
        restoredEvidence.map((v) => v.id).toSet().length !=
          restoredEvidence.length ||
        restoredEvidence.fold<int>(
          0, (sum, p) => sum + p.base64Data.length) >
          maxEvidenceEncodedBytes) {
      throw const FormatException('Foto bukti transaksi backup tidak valid.');
    }
    if (restoredPhotos.any((v) => !ids.contains(v.assetId)) ||
        restoredPhotos.map((v) => v.id).toSet().length != restoredPhotos.length ||
        restoredPhotos.fold<int>(0, (sum, v) => sum + v.base64Data.length) >
          maxAllEncodedBytes) {
      throw const FormatException('Referensi/ukuran foto backup tidak valid.');
    }
    // Old backups did not carry QR identities. Issue new random tokens
    // without altering their permanent, human-readable asset codes.
    final qrTokens = <String>{};
    for (final asset in restoredAssets) {
      if (asset.qrToken.isEmpty) asset.qrToken = newAssetQrToken();
      if (!qrTokens.add(asset.qrToken)) {
        throw const FormatException('Token QR aset pada backup tidak unik.');
      }
    }
    assets = restoredAssets; events = restoredEvents;
    photos = restoredPhotos;
    evidencePhotos = restoredEvidence; categories = restoredCategories;
    employees = restoredEmployees;
    assignments = restoredAssignments;
    returnReceipts = restoredReturns;
    nextAssignmentNumber = _safeNextCounter(value['nextAssignmentNumber'],
      assignments.map((e) => int.tryParse(
        e.draftReference.split('-').last) ?? 0));
    nextReturnNumber = _safeNextCounter(value['nextReturnNumber'],
      returnReceipts.map((e) => int.tryParse(
        e.draftReference.split('-').last) ?? 0));
    transfers = (value['transfers'] as List<dynamic>? ?? [])
      .map((v) => AssetTransfer.fromJson(Map<String, dynamic>.from(v as Map))).toList();
    final legacyLocations = (value['locations'] as List<dynamic>? ?? [])
      .map((v) => v.toString()).toList();
    locations = {
      ...legacyLocations,
      if (legacyLocations.isEmpty && value['locationSites'] is! List)
        ...['Kantor Pusat', 'Gudang Pusat', 'Outlet Jepara'],
      ...assets.map((a) => a.location),
    }.toList();
    migrateLocationMaster(value);
    if (assets.any((v) => !['Aktif','Tidak Aktif','Dilepas']
        .contains(v.lifecycle))) {
      throw const FormatException('Status siklus hidup aset tidak valid.');
    }
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
  int _safeNextCounter(dynamic raw, Iterable<int> previous) {
    final highest = previous.fold<int>(
      0, (current, number) => number > current ? number : current);
    final proposed = raw is num ? raw.toInt() : 1;
    return proposed > highest ? proposed : highest + 1;
  }

  String backup() => const JsonEncoder.withIndent('  ').convert({
    'version': 5, 'nextNumber': nextNumber,
    'locationSites': locationSites.map((s) => s.toJson()).toList(),
    'nextLocationNumber': nextLocationNumber,
    'nextAssignmentNumber': nextAssignmentNumber,
    'nextReturnNumber': nextReturnNumber,
    'employees': employees.map((e) => e.toJson()).toList(),
    'assignments': assignments.map((e) => e.toJson()).toList(),
    'returnReceipts': returnReceipts.map((e) => e.toJson()).toList(),
    'locations': locations, 'transfers': transfers.map((v) => v.toJson()).toList(),
    'assets': assets.map((v) => v.toJson()).toList(),
    'events': events.map((v) => v.toJson()).toList(),
    'categories': categories.map((v) => v.toJson()).toList(),
    'photos': photos.map((v) => v.toJson()).toList(),
    'evidencePhotos': evidencePhotos.map((v) => v.toJson()).toList(),
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
    final code = 'UDL-AST-' + nextNumber.toString().padLeft(8, '0');
    final a = AssetRecord(uuid.v4(), code, name.trim(), c.name, brand.trim(), serial.trim(),
      location.trim(), holder.trim(), 'Baik',
      holder.trim().isEmpty ? 'Tersedia' : 'Digunakan', cost,
      subcategory: s.name, assetType: t);
    a.categoryId = c.code; a.subcategoryId = s.id; a.typeId = s.typeId(t);
    final site = siteByName(location.trim());
    if (site == null || !site.active) {
      throw const FormatException('Lokasi tidak ada/aktif.');
    }
    applyPlacement(a, AssetPlacement(site.id));
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
    if (!canOperate(a)) throw const FormatException('Aset tidak aktif/dilepas.');
    if (status == 'Dihapuskan') {
      throw const FormatException('Gunakan prosedur Pelepasan Aset.');
    }
    if (a.assignedEmployeeId.isNotEmpty) {
      throw const FormatException(
        'Aset masih ditugaskan kepada karyawan; selesaikan pengembalian lebih dulu.');
    }
    if (location.trim().isEmpty || reason.trim().isEmpty) {
      throw const FormatException('Lokasi dan alasan wajib diisi.');
    }
    final detail = a.location + ' → ' + location + '; ' + a.holder + ' → ' + holder +
      '; ' + a.status + ' → ' + status + '. Alasan: ' + reason;
    final before = {'Lokasi': a.location, 'PIC': a.holder,
      'Status': a.status, 'Kondisi': a.condition};
    final site = siteByName(location.trim());
    if (site == null || !site.active) {
      throw const FormatException('Lokasi baru tidak valid.');
    }
    if (location.trim() != a.location) {
      applyPlacement(a, AssetPlacement(site.id));
    }
    a.holder = holder.trim();
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
      throw const FormatException('Kuota foto penyimpanan browser hampir penuh.');
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
