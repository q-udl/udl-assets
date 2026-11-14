part of 'main.dart';

extension AssetLifecycleOperations on AssetStore {
  bool hasOpenCustody(AssetRecord asset) =>
    asset.holder.trim().isNotEmpty ||
    asset.assignedEmployeeId.isNotEmpty ||
    heldLinesFor(asset.id).isNotEmpty ||
    transfers.any((t) => t.assetId == asset.id &&
      t.state == 'Menunggu Penerimaan');

  bool canOperate(AssetRecord asset) =>
    asset.lifecycle == 'Aktif' && asset.status != 'Dihapuskan';

  Future<void> setLifecycleActive(
      AssetRecord asset, bool active, String reason) async {
    if (reason.trim().isEmpty || asset.lifecycle == 'Dilepas' ||
        asset.lifecycle == (active ? 'Aktif' : 'Tidak Aktif')) {
      throw const FormatException('Perubahan siklus hidup tidak valid.');
    }
    if (!active && hasOpenCustody(asset)) {
      throw const FormatException('Tuntaskan penugasan/mutasi dahulu.');
    }
    final before = asset.lifecycle;
    asset.lifecycle = active ? 'Aktif' : 'Tidak Aktif';
    log(asset, active ? 'Pengaktifan Aset' : 'Penonaktifan Aset',
      before + ' → ' + asset.lifecycle, reason: reason.trim(),
      changes: {'Siklus Hidup': {
        'from': before, 'to': asset.lifecycle}});
    await persist();
  }

  Future<void> releaseAsset(
    AssetRecord asset, {
    required String kind,
    required String date,
    required String reference,
    required String reason,
    required String handledBy,
  }) async {
    const kinds = ['Dijual','Dihibahkan','Dimusnahkan','Lainnya'];
    final parsed = DateTime.tryParse(date);
    if (!kinds.contains(kind) || parsed == null ||
        date.length != 10 ||
        parsed.isAfter(DateTime.now()) ||
        reference.trim().isEmpty || reason.trim().isEmpty ||
        asset.lifecycle == 'Dilepas' || asset.status == 'Hilang') {
      throw const FormatException('Data pelepasan belum lengkap/valid.');
    }
    if (hasOpenCustody(asset)) {
      throw const FormatException(
        'Aset masih ditugaskan atau memiliki serah terima tertunda.');
    }
    final before = asset.lifecycle;
    asset.lifecycle = 'Dilepas';
    asset.releaseType = kind;
    asset.releaseDate = date;
    asset.releaseReference = reference.trim();
    asset.releaseReason = reason.trim();
    asset.releaseHandledBy = handledBy.trim();
    log(asset, 'Pelepasan Aset',
      kind + ' · ' + date + ' · Ref. ' + reference.trim(),
      reason: reason.trim(), changes: {
        'Siklus Hidup': {'from': before, 'to': 'Dilepas'},
        'Dokumen Referensi': {'from': '', 'to': reference.trim()},
      });
    await persist();
  }
}
