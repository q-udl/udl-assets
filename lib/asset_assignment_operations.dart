part of 'main.dart';

class AssetReturnInput {
  final String condition, accessories, notes;
  const AssetReturnInput({
    required this.condition,
    this.accessories = '',
    this.notes = '',
  });
}

extension AssetAssignmentOperations on AssetStore {
  Future<AssetAssignment> createAssignment({
    required String employeeId,
    required String kind,
    required List<String> assetIds,
    required Map<String, String> accessories,
    String dueDate = '',
    String notes = '',
  }) async {
    final employee = employeeById(employeeId);
    if (employee == null || !employee.active ||
        !['Berkelanjutan', 'Sementara'].contains(kind)) {
      throw const FormatException('Pilih karyawan aktif dan jenis penugasan.');
    }
    if (assetIds.isEmpty || assetIds.length != assetIds.toSet().length) {
      throw const FormatException('Pilih satu atau beberapa aset unik.');
    }
    if (kind == 'Sementara' &&
      (dueDate.isEmpty || DateTime.tryParse(dueDate) == null ||
      DateTime.parse(dueDate).isBefore(DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day)))) {
      throw const FormatException(
        'Peminjaman sementara wajib memiliki tanggal kembali yang valid.');
    }
    final selected = <AssetRecord>[];
    for (final id in assetIds) {
      final asset = assignmentAsset(id);
      if (asset == null || !canAssignAsset(asset)) {
        throw FormatException(
          'Aset tidak tersedia untuk diserahkan (ID: ' + id + ').');
      }
      selected.add(asset);
    }
    final now = DateTime.now().toIso8601String();
    final number = nextAssignmentNumber.toString().padLeft(6, '0');
    final record = AssetAssignment(
      id: uuid.v4(), draftReference: 'ASG-' + number,
      employeeId: employee.id,
      employeeSnapshot: employee.snapshot(),
      kind: kind, createdAt: now, dueDate: dueDate,
      notes: notes.trim(),
      lines: [
        for (final asset in selected)
          AssignedAssetLine(
            id: uuid.v4(), assetId: asset.id,
            assetCode: asset.code, assetName: asset.name,
            serial: asset.serial, handoverCondition: asset.condition,
            accessories: accessories[asset.id]?.trim() ?? '',
            photoIds: photosFor(asset.id).take(2)
              .map((photo) => photo.id).toList()),
      ],
    );
    assignments.insert(0, record);
    nextAssignmentNumber++;
    for (final asset in selected) {
      log(asset, 'Pengajuan Penugasan',
        record.assignmentReference + ' kepada ' + employee.name +
        '; menunggu serah terima',
        reason: notes.trim());
    }
    await persist();
    return record;
  }

  Future<void> confirmAssignment(
    AssetAssignment record, bool accepted, String reason, {
    Map<String, SelectedAssetPhoto> proofPhotos = const {},
    String handedOverByName = '',
    String handedOverByJobTitle = '',
    String handedOverByUnit = '',
    String handoverLocation = '',
    String bastNumber = '',
  }) async {
    if (!record.isPending) {
      throw const FormatException('Penugasan sudah dikonfirmasi atau dibatalkan.');
    }
    if (accepted && handedOverByName.trim().isEmpty) {
      throw const FormatException('Nama pihak yang menyerahkan wajib diisi.');
    }
    if (accepted) {
      if (handoverLocation.trim().isEmpty) {
        throw const FormatException('Lokasi serah terima aktual wajib diisi.');
      }
      if (bastNumber.trim().isNotEmpty) {
        _validateBastNumber(bastNumber, record.id);
      }
    }
    if (!accepted && reason.trim().isEmpty) {
      throw const FormatException('Alasan pembatalan penugasan wajib diisi.');
    }
    final employee = employeeById(record.employeeId);
    if (accepted && (employee == null || !employee.active)) {
      throw const FormatException('Penerima sudah tidak aktif.');
    }
    // Validate every asset BEFORE applying any change.
    if (accepted) {
      for (final line in record.lines) {
        final asset = assignmentAsset(line.assetId);
        if (asset == null || asset.status != 'Tersedia' ||
            asset.assignedEmployeeId.isNotEmpty || asset.holder.isNotEmpty ||
            transfers.any((t) => t.assetId == asset.id &&
              t.state == 'Menunggu Penerimaan')) {
          throw const FormatException(
            'Ada aset yang berubah kondisinya; tinjau sebelum konfirmasi serah terima.');
        }
      }
    }
    final preparedProof = accepted ? prepareEvidence(
      transactionType: 'assignment_handover',
      transactionId: record.id,
      requiredAssetIds: record.lines.map((l) => l.assetId).toSet(),
      selectedPhotos: proofPhotos,
    ) : <AssetEvidencePhoto>[];
    final previousBackup = backup();
    try {
    final now = DateTime.now().toIso8601String();
    record.status = accepted ? 'Aktif' : 'Dibatalkan';
    record.acceptedAt = accepted ? now : '';
    record.cancelledAt = accepted ? '' : now;
    record.cancellationReason = accepted ? '' : reason.trim();
    record.handedOverByName = accepted ? handedOverByName.trim() : '';
    record.handedOverByJobTitle = accepted ? handedOverByJobTitle.trim() : '';
    record.handedOverByUnit = accepted ? handedOverByUnit.trim() : '';
    record.handoverLocation = accepted ? handoverLocation.trim() : '';
    record.bastNumber = accepted ? bastNumber.trim() : '';
    for (final line in record.lines) {
      line.state = accepted ? 'Aktif' : 'Dibatalkan';
      if (accepted) {
        line.handoverProofPhotoIds = [
          for (final p in preparedProof)
            if (p.assetId == line.assetId) p.id,
        ];
      }
      final asset = assignmentAsset(line.assetId)!;
      if (accepted) {
        final previous = asset.status;
        asset.status = 'Digunakan';
        asset.holder = employee!.name;
        asset.assignedEmployeeId = employee.id;
        log(asset, 'Konfirmasi Serah Terima',
          record.assignmentReference + ' diserahterimakan kepada ' +
          employee.name + (record.bastNumber.isNotEmpty
            ? ' · BAST ' + record.bastNumber : ' · Nomor BAST belum dicatat'),
          changes: {
            'Status': {'from': previous, 'to': asset.status},
            'PIC': {'from': '', 'to': employee.name},
          });
      } else {
        log(asset, 'Pembatalan Penugasan',
          record.assignmentReference + ' dibatalkan sebelum serah terima',
          reason: reason.trim());
      }
    }
    evidencePhotos.addAll(preparedProof);
    await persist();
    } catch (_) {
      restore(previousBackup);
      rethrow;
    }
  }

  void _validateBastNumber(String number, String assignmentId) {
    final value = number.trim();
    if (value.isEmpty || value.length > 100 ||
        value.contains('\n') || value.contains('\r')) {
      throw const FormatException(
        'Isi Nomor BAST sesuai DMS (maksimal 100 karakter).');
    }
    if (assignments.any((b) => b.id != assignmentId &&
        b.bastNumber.toLowerCase() == value.toLowerCase())) {
      throw const FormatException('Nomor BAST sudah digunakan.');
    }
  }

  /// Complete missing data on an already-confirmed historical handover.
  /// Never rewrite its confirmation timestamp or invent a signature.
  Future<void> completeBastMetadata(
    AssetAssignment record, {
    required String bastNumber,
    required String handoverLocation,
    required String handedOverByName,
    String handedOverByJobTitle = '',
    String handedOverByUnit = '',
  }) async {
    if (!assignments.any((b) => b.id == record.id) ||
        !record.isHandoverConfirmed) {
      throw const FormatException(
        'Data BAST hanya dapat dilengkapi setelah serah terima terkonfirmasi.');
    }
    if (record.canPrintBast) {
      throw const FormatException('BAST sudah lengkap; tidak dapat ditimpa.');
    }
    if (handedOverByName.trim().isEmpty ||
        handoverLocation.trim().isEmpty) {
      throw const FormatException('Identitas Penyerah dan lokasi wajib diisi.');
    }
    _validateBastNumber(bastNumber, record.id);
    if ((record.handedOverByName.isNotEmpty &&
          record.handedOverByName != handedOverByName.trim()) ||
        (record.handoverLocation.isNotEmpty &&
          record.handoverLocation != handoverLocation.trim()) ||
        (record.bastNumber.isNotEmpty &&
          record.bastNumber != bastNumber.trim()) ||
        (handedOverByJobTitle.trim().isNotEmpty &&
          record.handedOverByJobTitle.isNotEmpty &&
          record.handedOverByJobTitle != handedOverByJobTitle.trim()) ||
        (handedOverByUnit.trim().isNotEmpty &&
          record.handedOverByUnit.isNotEmpty &&
          record.handedOverByUnit != handedOverByUnit.trim())) {
      throw const FormatException(
        'Informasi serah terima yang sudah tercatat tidak boleh diubah.');
    }
    final before = backup();
    try {
      record.handedOverByName = handedOverByName.trim();
      if (handedOverByJobTitle.trim().isNotEmpty) {
        record.handedOverByJobTitle = handedOverByJobTitle.trim();
      }
      if (handedOverByUnit.trim().isNotEmpty) {
        record.handedOverByUnit = handedOverByUnit.trim();
      }
      record.handoverLocation = handoverLocation.trim();
      record.bastNumber = bastNumber.trim();
      for (final line in record.lines) {
        final asset = assignmentAsset(line.assetId);
        if (asset != null) {
          log(asset, 'Pelengkapan Data BAST',
            record.assignmentReference + ' · Nomor BAST ' +
              record.bastNumber + ' dicatat dari dokumen perusahaan',
            reason: 'Pelengkapan arsip; waktu serah terima tidak diubah');
        }
      }
      await persist();
    } catch (_) {
      restore(before);
      rethrow;
    }
  }

  /// Explicit cancellation releases reservation while keeping the asset's
  /// physical location, custody data, and historical code unchanged.
  Future<void> cancelAssignment(
      AssetAssignment record, String reason) =>
    confirmAssignment(record, false, reason);

  Future<AssetReturnReceipt> returnAssignedAssets({
    required AssetAssignment record,
    required Map<String, AssetReturnInput> inspections,
    required String receivingLocation,
    AssetPlacement? receivingPlacement,
    String receivedByName = '',
    String notes = '',
    Map<String, SelectedAssetPhoto> proofPhotos = const {},
  }) async {
    if (record.status != 'Aktif' || receivedByName.trim().isEmpty ||
      inspections.isEmpty || !locations.contains(receivingLocation)) {
      throw const FormatException('Penugasan atau lokasi penerimaan tidak valid.');
    }
    final receivingSite = siteByName(receivingLocation);
    final destination = receivingPlacement ??
      AssetPlacement(receivingSite?.id ?? '');
    if (receivingSite == null || !validPlacement(destination) ||
        destination.siteId != receivingSite.id) {
      throw const FormatException('Penempatan pengembalian tidak valid.');
    }
    final validConditions = {'Baru', 'Baik', 'Cukup', 'Kurang Baik', 'Rusak'};
    final selected = <AssignedAssetLine>[];
    for (final entry in inspections.entries) {
      final lines = record.lines.where((l) => l.id == entry.key);
      if (lines.length != 1 || lines.single.state != 'Aktif' ||
          !validConditions.contains(entry.value.condition)) {
        throw const FormatException('Pemeriksaan pengembalian belum valid.');
      }
      final asset = assignmentAsset(lines.single.assetId);
      if (asset == null || asset.assignedEmployeeId != record.employeeId) {
        throw const FormatException('Penguasaan aset tidak konsisten.');
      }
      selected.add(lines.single);
    }
    final receiptId = uuid.v4();
    final preparedProof = prepareEvidence(
      transactionType: 'assignment_return',
      transactionId: receiptId,
      requiredAssetIds: selected.map((l) => l.assetId).toSet(),
      selectedPhotos: proofPhotos,
    );
    final previousBackup = backup();
    try {
    final now = DateTime.now().toIso8601String();
    final number = nextReturnNumber.toString().padLeft(6, '0');
    final receipt = AssetReturnReceipt(
      id: receiptId,
      draftReference: 'DRAF-BAP-ASG-' + number,
      assignmentId: record.id,
      employeeSnapshot: Map<String, dynamic>.from(record.employeeSnapshot),
      createdAt: now,
      receivingLocation: receivingLocation,
      receivingLocationPath: placementPath(destination),
      receivingAreaId: destination.areaId,
      receivingSpotId: destination.spotId,
      receivedByName: receivedByName.trim(),
      notes: notes.trim(),
      lines: [
        for (final line in selected)
          AssetReturnLine(
            assignmentLineId: line.id,
            assetId: line.assetId, assetCode: line.assetCode,
            assetName: line.assetName,
            handoverCondition: line.handoverCondition,
            returnCondition: inspections[line.id]!.condition,
            accessoriesReturned: inspections[line.id]!.accessories.trim(),
            accessoriesClassification: line.accessoriesClassification,
            notes: inspections[line.id]!.notes.trim(),
            proofPhotoIds: [
              for (final p in preparedProof)
                if (p.assetId == line.assetId) p.id,
            ],
          ),
      ],
    );
    returnReceipts.insert(0, receipt);
    nextReturnNumber++;
    for (final line in selected) {
      final inspection = inspections[line.id]!;
      final asset = assignmentAsset(line.assetId)!;
      final oldStatus = asset.status;
      final oldLocation = asset.location;
      final oldCondition = asset.condition;
      line.state = 'Dikembalikan';
      line.returnReceiptId = receipt.id;
      line.returnedAt = now;
      asset.assignedEmployeeId = '';
      asset.holder = '';
      applyPlacement(asset, destination);
      asset.condition = inspection.condition;
      asset.status = ['Rusak','Kurang Baik'].contains(inspection.condition)
        ? 'Dalam Perbaikan' : 'Tersedia';
      log(asset, 'Pengembalian Aset',
        receipt.draftReference + ' · ' + record.assignmentReference,
        reason: inspection.notes, changes: {
          'Kondisi': {'from': oldCondition, 'to': inspection.condition},
          'Status': {'from': oldStatus, 'to': asset.status},
          'Lokasi': {'from': oldLocation, 'to': placementPath(destination)},
          'PIC': {
            'from': record.employeeSnapshot['name']?.toString() ?? '',
            'to': '',
          },
        });
    }
    if (record.activeCount == 0) record.status = 'Selesai';
    evidencePhotos.addAll(preparedProof);
    await persist();
    return receipt;
    } catch (_) {
      restore(previousBackup);
      rethrow;
    }
  }
}
