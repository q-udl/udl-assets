part of 'main.dart';

/// Empty means unknown; dates are never inferred from the registration date.
bool validAssetAcquisitionDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return true;
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return false;
  return value == parsed.year.toString().padLeft(4, '0') + '-' +
      parsed.month.toString().padLeft(2, '0') + '-' +
      parsed.day.toString().padLeft(2, '0');
}

// Operational rules for the local v0.4 preview. Actor confirmation is simulation
// only; reliable authorization requires an authenticated server.
extension AssetOperations on AssetStore {
  Future<List<AssetRecord>> registerUnits({
    required int quantity, required String name, required String category,
    required String subcategory, required String assetType, required String brand,
    required String model, required String serial, required String location,
    required String holder, required String status, required String condition,
    required int? cost, required String acquisitionDate,
    AssetPlacement? placement,
  }) async {
    if (quantity < 1 || quantity > 100) throw const FormatException('Jumlah unit harus 1-100.');
    if (quantity > 1 && serial.trim().isNotEmpty) {
      throw const FormatException('Nomor seri unik harus diisi per unit setelah registrasi.');
    }
    final c = categoryByName(category), sub = subcategoryByName(category, subcategory);
    if (c == null || sub == null || !c.active || !sub.active ||
        !sub.types.contains(assetType) || !sub.typeIsActive(assetType) ||
        name.trim().isEmpty || !locations.contains(location) ||
        !['Tersedia', 'Digunakan', 'Dalam Perbaikan', 'Hilang'].contains(status) ||
        !['Baru', 'Baik', 'Cukup', 'Kurang Baik', 'Rusak'].contains(condition) ||
        (cost != null && cost < 0) ||
        !validAssetAcquisitionDate(acquisitionDate)) {
      throw const FormatException('Data registrasi belum lengkap atau tidak valid.');
    }
    if (serial.trim().isNotEmpty && assets.any((a) =>
      a.status != 'Dihapuskan' && a.serial.toLowerCase() == serial.trim().toLowerCase())) {
      throw const FormatException('Nomor seri sudah digunakan.');
    }
    final site = placement == null ?
      siteByName(location) : siteById(placement.siteId);
    final chosen = placement ?? AssetPlacement(site?.id ?? '');
    if (site == null || site.name != location ||
        !validPlacement(chosen)) {
      throw const FormatException('Lokasi/area/titik tidak aktif atau valid.');
    }
    final result = <AssetRecord>[];
    for (var i = 0; i < quantity; i++) {
      final a = AssetRecord(uuid.v4(), 'UDL-AST-' + nextNumber.toString().padLeft(8, '0'),
        name.trim(), category, brand.trim(), serial.trim(), location, holder.trim(),
        condition, status, cost ?? 0, subcategory: subcategory, assetType: assetType);
      a.model = model.trim(); a.acquisitionDate = acquisitionDate.trim();
      a.acquisitionCost = cost;
      applyPlacement(a, chosen);
      a.categoryId = c.code; a.subcategoryId = sub.id; a.typeId = sub.typeId(assetType);
      assets.insert(0, a); nextNumber++; result.add(a);
      log(a, 'Registrasi', 'Registrasi aset pada ' + location);
    }
    await persist();
    return result;
  }

  Future<void> editIdentity(AssetRecord a, String name, String brand,
      String model, String serial, int? cost, String reason,
      {String? acquisitionDate}) async {
    final updatedDate = acquisitionDate?.trim() ?? a.acquisitionDate;
    if (!canOperate(a) || name.trim().isEmpty || reason.trim().isEmpty ||
        (cost != null && cost < 0) || !validAssetAcquisitionDate(updatedDate)) {
      throw const FormatException('Nama dan alasan wajib diisi.');
    }
    if (serial.trim().isNotEmpty && assets.any((v) => v.id != a.id &&
      v.status != 'Dihapuskan' && v.serial.toLowerCase() == serial.trim().toLowerCase())) {
      throw const FormatException('Nomor seri sudah digunakan.');
    }
    final changes = <String, dynamic>{};
    void track(String key, String before, String after) {
      if (before != after) changes[key] = {'from': before, 'to': after};
    }
    track('Nama', a.name, name.trim());
    track('Merek', a.brand, brand.trim());
    track('Model', a.model, model.trim());
    track('Nomor seri', a.serial, serial.trim());
    track('Tanggal perolehan', a.acquisitionDate.isEmpty ? 'Belum diketahui' : a.acquisitionDate,
      updatedDate.isEmpty ? 'Belum diketahui' : updatedDate);
    track('Nilai perolehan', a.acquisitionCost?.toString() ?? 'Belum diketahui',
      cost?.toString() ?? 'Belum diketahui');
    if (changes.isEmpty) throw const FormatException('Tidak ada data berubah.');
    a.name = name.trim(); a.brand = brand.trim(); a.model = model.trim();
    a.serial = serial.trim(); a.acquisitionCost = cost; a.cost = cost ?? 0;
    a.acquisitionDate = updatedDate;
    log(a, 'Koreksi Informasi', 'Informasi aset diperbarui', changes: changes, reason: reason);
    await persist();
  }

  Future<void> editCondition(AssetRecord a, String condition, String reason) async {
    if (!canOperate(a) || condition == a.condition ||
      reason.trim().isEmpty ||
      !['Baru', 'Baik', 'Cukup', 'Kurang Baik', 'Rusak'].contains(condition)) {
      throw const FormatException('Perubahan kondisi tidak valid.');
    }
    final previous = a.condition; a.condition = condition;
    log(a, 'Perubahan Kondisi', previous + ' → ' + condition, reason: reason,
      changes: {'Kondisi': {'from': previous, 'to': condition}});
    await persist();
  }

  Future<void> editStatus(AssetRecord a, String status, String reason) async {
    if (a.assignedEmployeeId.isNotEmpty) {
      throw const FormatException(
        'Aset masih ditugaskan. Selesaikan pengembalian sebelum ubah status.');
    }
    if (!canOperate(a) || status == a.status ||
      reason.trim().isEmpty ||
      !['Tersedia', 'Digunakan', 'Dalam Perbaikan', 'Hilang'].contains(status)) {
      throw const FormatException('Perubahan status tidak valid.');
    }
    if (transfers.any((t) => t.assetId == a.id && t.state == 'Menunggu Penerimaan')) {
      throw const FormatException('Selesaikan serah terima tertunda terlebih dahulu.');
    }
    final previous = a.status; a.status = status;
    log(a, status == 'Dihapuskan' ? 'Penghapusan' : 'Perubahan Status',
      previous + ' → ' + status, reason: reason,
      changes: {'Status': {'from': previous, 'to': status}});
    await persist();
  }

  Future<AssetTransfer> proposeTransfer(AssetRecord a, String destination,
      String receiver, String reason, {AssetPlacement? placement}) async {
    if (a.lifecycle != 'Aktif' || a.assignedEmployeeId.isNotEmpty || heldLinesFor(a.id).isNotEmpty) {
      throw const FormatException(
        'Aset sedang dalam proses penugasan; selesaikan dahulu.');
    }
    final site = siteByName(destination);
    final chosen = placement ?? AssetPlacement(site?.id ?? '');
    if (a.lifecycle != 'Aktif' || site == null ||
        !validPlacement(chosen) || chosen.siteId != site.id) {
      throw const FormatException('Lokasi tujuan tidak aktif atau valid.');
    }
    final samePlacement = chosen.siteId == a.locationSiteId &&
      chosen.areaId == a.locationAreaId &&
      chosen.spotId == a.locationSpotId;
    if (a.status == 'Dihapuskan' || !locations.contains(destination) ||
      reason.trim().isEmpty || (samePlacement && receiver.trim() == a.holder) ||
      transfers.any((t) => t.assetId == a.id && t.state == 'Menunggu Penerimaan')) {
      throw const FormatException('Mutasi tidak valid atau masih tertunda.');
    }
    final t = AssetTransfer(uuid.v4(), a.id, a.location, destination,
      a.holder, receiver.trim(), reason.trim(), DateTime.now().toIso8601String(),
      fromAreaId: a.locationAreaId, fromSpotId: a.locationSpotId,
      toAreaId: chosen.areaId, toSpotId: chosen.spotId);
    transfers.insert(0, t);
    log(a, 'Permintaan Mutasi', locationPath(a) + ' → ' + placementPath(chosen),
      reason: reason, changes: {
        'Lokasi': {'from': a.location, 'to': destination},
        'PIC': {'from': a.holder, 'to': receiver.trim()}});
    await persist();
    return t;
  }

  Future<void> confirmTransfer(AssetTransfer transfer, bool accepted,
      String note, {SelectedAssetPhoto? proofPhoto}) async {
    if (transfer.state != 'Menunggu Penerimaan') {
      throw const FormatException('Serah terima sudah diproses.');
    }
    final a = assets.firstWhere((a) => a.id == transfer.assetId);
    final proof = accepted ? prepareEvidence(
      transactionType: 'transfer_handover',
      transactionId: transfer.id,
      requiredAssetIds: {a.id},
      selectedPhotos: {
        if (proofPhoto != null) a.id: proofPhoto,
      },
    ) : <AssetEvidencePhoto>[];
    final previousBackup = backup();
    try {
    if (accepted) {
      final site = siteByName(transfer.toLocation);
      if (site == null) throw const FormatException('Lokasi tujuan hilang.');
      final dest = AssetPlacement(site.id,
        areaId: transfer.toAreaId, spotId: transfer.toSpotId);
      if (!validPlacement(dest, allowInactive: true)) {
        throw const FormatException('Area/titik tujuan tidak ditemukan.');
      }
      applyPlacement(a, dest);
      a.holder = transfer.toHolder;
    }
    transfer.state = accepted ? 'Diterima (Simulasi)' : 'Ditolak (Simulasi)';
    if (accepted) transfer.proofPhotoIds = proof.map((p) => p.id).toList();
    transfer.note = note.trim();
    transfer.respondedAt = DateTime.now().toIso8601String();
    log(a, accepted ? 'Penerimaan Mutasi' : 'Penolakan Mutasi',
      transfer.fromLocation + ' → ' + transfer.toLocation + ': ' + transfer.state,
      reason: note, changes: {
        'Lokasi': {'from': transfer.fromLocation,
          'to': accepted ? transfer.toLocation : transfer.fromLocation},
        'PIC': {'from': transfer.fromHolder,
          'to': accepted ? transfer.toHolder : transfer.fromHolder}});
    evidencePhotos.addAll(proof);
    await persist();
    } catch (_) {
      restore(previousBackup);
      rethrow;
    }
  }

  Future<void> addLocation(String name) async {
    await addSite(name);
  }

  Future<void> renameCategory(AssetCategory c, String name) async {
    final value = name.trim();
    if (value.length < 3 || categories.any((x) => x != c &&
        x.name.toLowerCase() == value.toLowerCase())) {
      throw const FormatException('Kategori tidak valid atau duplikat.');
    }
    final old = c.name; c.name = value;
    for (final a in assets.where((a) => a.categoryId == c.code || a.category == old)) {
      a.category = value;
    }
    events.insert(0, EventRecord('', 'Master Klasifikasi',
      'Kategori: ' + old + ' → ' + value, DateTime.now().toIso8601String()));
    await persist();
  }

  Future<void> renameSubcategory(AssetCategory c, AssetSubcategory sub, String name) async {
    final value = name.trim();
    if (value.length < 2 || c.subcategories.any((x) => x != sub &&
      x.name.toLowerCase() == value.toLowerCase())) {
      throw const FormatException('Subkategori tidak valid atau duplikat.');
    }
    final old = sub.name; sub.name = value;
    for (final a in assets.where((a) => a.categoryId == c.code &&
      (a.subcategoryId == sub.id || a.subcategory == old))) {
      a.subcategory = value;
    }
    events.insert(0, EventRecord('', 'Master Klasifikasi',
      'Subkategori: ' + old + ' → ' + value, DateTime.now().toIso8601String()));
    await persist();
  }

  Future<void> renameAssetType(AssetCategory c, AssetSubcategory sub,
      String old, String name) async {
    final value = name.trim();
    if (value.length < 2 || sub.types.any((x) => x != old &&
      x.toLowerCase() == value.toLowerCase())) {
      throw const FormatException('Jenis tidak valid atau duplikat.');
    }
    final index = sub.types.indexOf(old);
    if (index == -1) throw const FormatException('Jenis aset tidak ditemukan.');
    final id = sub.typeId(old);
    sub.types[index] = value;
    sub.typeIds.remove(old); sub.typeIds[value] = id;
    if (sub.inactiveTypes.remove(old)) sub.inactiveTypes.add(value);
    for (final a in assets.where((a) => a.categoryId == c.code &&
      a.subcategoryId == sub.id && a.assetType == old)) {
      a.assetType = value;
    }
    events.insert(0, EventRecord('', 'Master Klasifikasi',
      'Jenis: ' + old + ' → ' + value, DateTime.now().toIso8601String()));
    await persist();
  }

  Future<void> setClassificationActive(AssetCategory c,
      AssetSubcategory? sub, String? type, bool active) async {
    if (type != null && sub != null) {
      if (active) { sub.inactiveTypes.remove(type); }
      else { sub.inactiveTypes.add(type); }
    } else if (sub != null) {
      sub.active = active;
    } else {
      c.active = active;
    }
    events.insert(0, EventRecord('', 'Master Klasifikasi',
      (active ? 'Aktif: ' : 'Nonaktif: ') + (type ?? sub?.name ?? c.name),
      DateTime.now().toIso8601String()));
    await persist();
  }

  Future<void> archivePhoto(AssetRecord a, AssetPhoto photo, String reason) async {
    if (reason.trim().isEmpty || photo.assetId != a.id || photo.archived) {
      throw const FormatException('Foto dan alasan wajib valid.');
    }
    photo.archived = true; photo.archivedReason = reason.trim();
    if (photo.isPrimary) {
      photo.isPrimary = false;
      final remaining = photosFor(a.id);
      if (remaining.isNotEmpty) remaining.first.isPrimary = true;
    }
    log(a, 'Arsip Foto', photo.fileName + ' diarsipkan', reason: reason);
    await persist();
  }
}
