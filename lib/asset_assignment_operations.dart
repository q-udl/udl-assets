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
      id: uuid.v4(), draftReference: 'DRAF-BAST-ASG-' + number,
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
        record.draftReference + ' kepada ' + employee.name +
        '; menunggu penerimaan',
        reason: notes.trim());
    }
    await persist();
    return record;
  }

  Future<void> confirmAssignment(
    AssetAssignment record, bool accepted, String reason,
  ) async {
    if (!record.isPending) {
      throw const FormatException('Penugasan telah diproses.');
    }
    if (!accepted && reason.trim().isEmpty) {
      throw const FormatException('Alasan penolakan wajib diisi.');
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
            'Ada aset yang berubah kondisinya; tinjau sebelum menerima.');
        }
      }
    }
    final now = DateTime.now().toIso8601String();
    record.status = accepted ? 'Aktif' : 'Ditolak';
    record.acceptedAt = accepted ? now : '';
    record.rejectionReason = accepted ? '' : reason.trim();
    for (final line in record.lines) {
      line.state = accepted ? 'Aktif' : 'Ditolak';
      final asset = assignmentAsset(line.assetId)!;
      if (accepted) {
        final previous = asset.status;
        asset.status = 'Digunakan';
        asset.holder = employee!.name;
        asset.assignedEmployeeId = employee.id;
        log(asset, 'Penerimaan Penugasan',
          record.draftReference + ' diterima (simulasi) oleh ' + employee.name,
          changes: {
            'Status': {'from': previous, 'to': asset.status},
            'PIC': {'from': '', 'to': employee.name},
          });
      } else {
        log(asset, 'Penolakan Penugasan',
          record.draftReference + ' ditolak (simulasi)', reason: reason);
      }
    }
    await persist();
  }

  Future<AssetReturnReceipt> returnAssignedAssets({
    required AssetAssignment record,
    required Map<String, AssetReturnInput> inspections,
    required String receivingLocation,
    String receivedByName = '',
    String notes = '',
  }) async {
    if (record.status != 'Aktif' ||
      inspections.isEmpty || !locations.contains(receivingLocation)) {
      throw const FormatException('Penugasan atau lokasi penerimaan tidak valid.');
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
    final now = DateTime.now().toIso8601String();
    final number = nextReturnNumber.toString().padLeft(6, '0');
    final receipt = AssetReturnReceipt(
      id: uuid.v4(),
      draftReference: 'DRAF-BAP-ASG-' + number,
      assignmentId: record.id,
      employeeSnapshot: Map<String, dynamic>.from(record.employeeSnapshot),
      createdAt: now,
      receivingLocation: receivingLocation,
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
            notes: inspections[line.id]!.notes.trim(),
            photoIds: photosFor(line.assetId).where((p) {
              final photoTime = DateTime.tryParse(p.timestamp);
              final acceptedTime = DateTime.tryParse(record.acceptedAt);
              return photoTime != null && acceptedTime != null &&
                photoTime.isAfter(acceptedTime);
            }).take(2).map((p) => p.id).toList(),
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
      asset.location = receivingLocation;
      asset.condition = inspection.condition;
      asset.status = ['Rusak','Kurang Baik'].contains(inspection.condition)
        ? 'Dalam Perbaikan' : 'Tersedia';
      log(asset, 'Pengembalian Aset',
        receipt.draftReference + ' · ' + record.draftReference,
        reason: inspection.notes, changes: {
          'Kondisi': {'from': oldCondition, 'to': inspection.condition},
          'Status': {'from': oldStatus, 'to': asset.status},
          'Lokasi': {'from': oldLocation, 'to': receivingLocation},
          'PIC': {
            'from': record.employeeSnapshot['name']?.toString() ?? '',
            'to': '',
          },
        });
    }
    if (record.activeCount == 0) record.status = 'Selesai';
    await persist();
    return receipt;
  }
}
