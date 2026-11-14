part of 'main.dart';

/// Strip retired employee codes from imported historical snapshots without
/// changing employee UUIDs, names, positions or transaction identities.
Map<String, dynamic> employeeSnapshotWithoutCode(dynamic source) {
  final values = source is Map
    ? Map<String, dynamic>.from(source) : <String, dynamic>{};
  values.remove('code');
  return values;
}

/// Employee records contain only the fields needed for physical asset custody.
/// This is a local prototype, not an HR employee system.
class AssetEmployee {
  final String id, createdAt;
  String name, unit, department, jobTitle, workLocation, startDate, updatedAt;
  bool active;

  AssetEmployee({
    required this.id,
    required this.name,
    required this.unit,
    required this.department,
    required this.jobTitle,
    required this.workLocation,
    this.startDate = '',
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> snapshot() => {
    'name': name, 'unit': unit,
    'department': department, 'jobTitle': jobTitle,
    'workLocation': workLocation,
  };

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'unit': unit,
    'department': department, 'jobTitle': jobTitle,
    'workLocation': workLocation, 'startDate': startDate,
    'active': active, 'createdAt': createdAt, 'updatedAt': updatedAt,
  };

  factory AssetEmployee.fromJson(Map<String, dynamic> x) => AssetEmployee(
    id: x['id']?.toString() ?? '',
    name: x['name']?.toString() ?? '',
    unit: x['unit']?.toString() ?? '',
    department: x['department']?.toString() ?? '',
    jobTitle: x['jobTitle']?.toString() ?? '',
    workLocation: x['workLocation']?.toString() ?? '',
    startDate: x['startDate']?.toString() ?? '',
    active: x['active'] != false,
    createdAt: x['createdAt']?.toString() ?? '',
    updatedAt: x['updatedAt']?.toString() ?? '',
  );
}

/// Assignment statuses are distinct from transfer statuses. Older backups
/// used receiver-oriented terminology; map it only within custody records.
String normalizeAssignmentStatus(String value) => switch (value) {
  'Menunggu Penerimaan' => 'Menunggu Serah Terima',
  'Ditolak' => 'Dibatalkan',
  _ => value,
};

/// Older backups may have a free-text 'Kelengkapan' value without a
/// classification marker. Preserve only nonempty historical notes as
/// unclassified; an empty historical field contains nothing to reclassify.
String accessoryClassificationFromJson(
    Map<String, dynamic> record, String legacyTextKey) {
  final declared = record['accessoriesClassification']?.toString();
  if (declared == 'non_asset' || declared == 'legacy_unclassified') {
    return declared!;
  }
  return (record[legacyTextKey]?.toString() ?? '').trim().isEmpty
    ? 'non_asset' : 'legacy_unclassified';
}

class AssignedAssetLine {
  final String id, assetId, assetCode, assetName, serial, handoverCondition;
  String accessories, accessoriesClassification, state, returnReceiptId, returnedAt;

  /// Persist the original free-text entry without silently treating older
  /// 'Kelengkapan' records as verified non-asset items.
  bool get hasLegacyAccessories => accessories.trim().isNotEmpty &&
    accessoriesClassification != 'non_asset';
  String get itemRecordLabel => hasLegacyAccessories
    ? 'Kelengkapan historis (klasifikasi belum diverifikasi)'
    : 'Item Penyerta Non-Aset';
  final List<String> photoIds;
  List<String> handoverProofPhotoIds;

  AssignedAssetLine({
    required this.id,
    required this.assetId,
    required this.assetCode,
    required this.assetName,
    required this.serial,
    required this.handoverCondition,
    this.accessories = '',
    this.accessoriesClassification = 'non_asset',
    this.state = 'Menunggu Serah Terima',
    this.returnReceiptId = '',
    this.returnedAt = '',
    this.photoIds = const [],
    this.handoverProofPhotoIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'assetId': assetId, 'assetCode': assetCode,
    'assetName': assetName, 'serial': serial,
    'handoverCondition': handoverCondition,
    'accessories': accessories,
    'accessoriesClassification': accessoriesClassification,
    'state': state,
    'returnReceiptId': returnReceiptId, 'returnedAt': returnedAt,
    'photoIds': photoIds,
    'handoverProofPhotoIds': handoverProofPhotoIds,
  };

  factory AssignedAssetLine.fromJson(Map<String, dynamic> x) => AssignedAssetLine(
    id: x['id']?.toString() ?? '',
    assetId: x['assetId']?.toString() ?? '',
    assetCode: x['assetCode']?.toString() ?? '',
    assetName: x['assetName']?.toString() ?? '',
    serial: x['serial']?.toString() ?? '',
    handoverCondition: x['handoverCondition']?.toString() ?? '',
    accessories: x['accessories']?.toString() ?? '',
    accessoriesClassification:
      accessoryClassificationFromJson(x, 'accessories'),
    state: normalizeAssignmentStatus(
      x['state']?.toString() ?? 'Menunggu Serah Terima'),
    returnReceiptId: x['returnReceiptId']?.toString() ?? '',
    returnedAt: x['returnedAt']?.toString() ?? '',
    photoIds: (x['photoIds'] as List<dynamic>? ?? [])
      .map((v) => v.toString()).toList(),
    handoverProofPhotoIds:
      (x['handoverProofPhotoIds'] as List<dynamic>? ?? [])
        .map((v) => v.toString()).toList(),
  );
}

class AssetAssignment {
  final String id, draftReference, employeeId, kind, createdAt;
  final Map<String, dynamic> employeeSnapshot;
  final List<AssignedAssetLine> lines;
  String dueDate, notes, status, acceptedAt, cancellationReason, cancelledAt;
  String handedOverByName, handedOverByJobTitle, handedOverByUnit;
  String handoverLocation, bastNumber;

  AssetAssignment({
    required this.id,
    required this.draftReference,
    required this.employeeId,
    required this.employeeSnapshot,
    required this.kind,
    required this.createdAt,
    required this.lines,
    this.dueDate = '',
    this.notes = '',
    this.status = 'Menunggu Serah Terima',
    this.acceptedAt = '',
    this.cancellationReason = '',
    this.cancelledAt = '',
    this.handedOverByName = '',
    this.handedOverByJobTitle = '',
    this.handedOverByUnit = '',
    this.handoverLocation = '',
    this.bastNumber = '',
  });

  int get activeCount => lines.where((l) => l.state == 'Aktif').length;
  int get returnedCount => lines.where((l) => l.state == 'Dikembalikan').length;
  bool get isPending => status == 'Menunggu Serah Terima';
  /// Old internal draft IDs remain byte-for-byte intact in backups, while
  /// documents and UI use a neutral penugasan reference.
  String get assignmentReference =>
    draftReference.startsWith('DRAF-BAST-')
      ? draftReference.substring('DRAF-BAST-'.length)
      : draftReference;
  bool get isHandoverConfirmed =>
    (status == 'Aktif' || status == 'Selesai') &&
    acceptedAt.trim().isNotEmpty;
  /// Publishing requires confirmed custody and all verified-by-operator
  /// document fields. It does NOT imply electronic signature verification.
  bool get canPrintBast => isHandoverConfirmed &&
    handedOverByName.trim().isNotEmpty &&
    handoverLocation.trim().isNotEmpty &&
    bastNumber.trim().isNotEmpty;
  bool get isOverdue {
    if (dueDate.isEmpty || activeCount == 0) return false;
    final due = DateTime.tryParse(dueDate);
    if (due == null) return false;
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day).isAfter(
      DateTime(due.year, due.month, due.day));
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'draftReference': draftReference,
    'employeeId': employeeId,
    'employeeSnapshot': employeeSnapshotWithoutCode(employeeSnapshot), 'kind': kind,
    'createdAt': createdAt, 'dueDate': dueDate, 'notes': notes,
    'status': status, 'acceptedAt': acceptedAt,
    'cancellationReason': cancellationReason,
    'cancelledAt': cancelledAt,
    'handedOverByName': handedOverByName,
    'handedOverByJobTitle': handedOverByJobTitle,
    'handedOverByUnit': handedOverByUnit,
    'handoverLocation': handoverLocation,
    'bastNumber': bastNumber,
    'lines': lines.map((l) => l.toJson()).toList(),
  };

  factory AssetAssignment.fromJson(Map<String, dynamic> x) => AssetAssignment(
    id: x['id']?.toString() ?? '',
    draftReference: x['draftReference']?.toString() ?? '',
    employeeId: x['employeeId']?.toString() ?? '',
    employeeSnapshot: employeeSnapshotWithoutCode(x['employeeSnapshot']),
    kind: x['kind']?.toString() ?? 'Berkelanjutan',
    createdAt: x['createdAt']?.toString() ?? '',
    lines: (x['lines'] as List<dynamic>? ?? [])
      .map((v) => AssignedAssetLine.fromJson(
        Map<String, dynamic>.from(v as Map))).toList(),
    dueDate: x['dueDate']?.toString() ?? '',
    notes: x['notes']?.toString() ?? '',
    status: normalizeAssignmentStatus(
      x['status']?.toString() ?? 'Menunggu Serah Terima'),
    acceptedAt: x['acceptedAt']?.toString() ?? '',
    cancellationReason: x['cancellationReason']?.toString() ??
      x['rejectionReason']?.toString() ?? '',
    cancelledAt: x['cancelledAt']?.toString() ?? '',
    handedOverByName: x['handedOverByName']?.toString() ?? '',
    handedOverByJobTitle: x['handedOverByJobTitle']?.toString() ?? '',
    handedOverByUnit: x['handedOverByUnit']?.toString() ?? '',
    handoverLocation: x['handoverLocation']?.toString() ?? '',
    bastNumber: x['bastNumber']?.toString() ?? '',
  );
}

class AssetReturnLine {
  final String assignmentLineId, assetId, assetCode, assetName;
  final String handoverCondition, returnCondition, accessoriesReturned, notes;
  final String accessoriesClassification;

  bool get hasLegacyAccessories => accessoriesClassification != 'non_asset';
  final List<String> photoIds;
  final List<String> proofPhotoIds;
  AssetReturnLine({
    required this.assignmentLineId,
    required this.assetId,
    required this.assetCode,
    required this.assetName,
    required this.handoverCondition,
    required this.returnCondition,
    required this.accessoriesReturned,
    this.accessoriesClassification = 'non_asset',
    required this.notes,
    this.photoIds = const [],
    this.proofPhotoIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'assignmentLineId': assignmentLineId,
    'assetId': assetId, 'assetCode': assetCode, 'assetName': assetName,
    'handoverCondition': handoverCondition,
    'returnCondition': returnCondition,
    'accessoriesReturned': accessoriesReturned,
    'accessoriesClassification': accessoriesClassification,
    'notes': notes,
    'photoIds': photoIds,
    'proofPhotoIds': proofPhotoIds,
  };
  factory AssetReturnLine.fromJson(Map<String, dynamic> x) => AssetReturnLine(
    assignmentLineId: x['assignmentLineId']?.toString() ?? '',
    assetId: x['assetId']?.toString() ?? '',
    assetCode: x['assetCode']?.toString() ?? '',
    assetName: x['assetName']?.toString() ?? '',
    handoverCondition: x['handoverCondition']?.toString() ?? '',
    returnCondition: x['returnCondition']?.toString() ?? '',
    accessoriesReturned: x['accessoriesReturned']?.toString() ?? '',
    accessoriesClassification:
      accessoryClassificationFromJson(x, 'accessoriesReturned'),
    notes: x['notes']?.toString() ?? '',
    photoIds: (x['photoIds'] as List<dynamic>? ?? [])
      .map((v) => v.toString()).toList(),
    proofPhotoIds: (x['proofPhotoIds'] as List<dynamic>? ?? [])
      .map((v) => v.toString()).toList(),
  );
}

class AssetReturnReceipt {
  final String id, draftReference, assignmentId, createdAt;
  final Map<String, dynamic> employeeSnapshot;
  final List<AssetReturnLine> lines;
  final String notes, receivingLocation, receivingLocationPath, receivedByName;
  final String receivingAreaId, receivingSpotId;
  AssetReturnReceipt({
    required this.id, required this.draftReference,
    required this.assignmentId, required this.employeeSnapshot,
    required this.createdAt, required this.lines, this.notes = '',
    required this.receivingLocation, this.receivedByName = '',
    this.receivingLocationPath = '',
    this.receivingAreaId = '', this.receivingSpotId = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'draftReference': draftReference,
    'assignmentId': assignmentId,
    'employeeSnapshot': employeeSnapshotWithoutCode(employeeSnapshot),
    'createdAt': createdAt, 'notes': notes,
    'receivingLocation': receivingLocation, 'receivedByName': receivedByName,
    'receivingLocationPath': receivingLocationPath,
    'receivingAreaId': receivingAreaId, 'receivingSpotId': receivingSpotId,
    'lines': lines.map((l) => l.toJson()).toList(),
  };

  factory AssetReturnReceipt.fromJson(Map<String, dynamic> x) =>
    AssetReturnReceipt(
      id: x['id']?.toString() ?? '',
      draftReference: x['draftReference']?.toString() ?? '',
      assignmentId: x['assignmentId']?.toString() ?? '',
      employeeSnapshot: employeeSnapshotWithoutCode(x['employeeSnapshot']),
      createdAt: x['createdAt']?.toString() ?? '',
      lines: (x['lines'] as List<dynamic>? ?? [])
        .map((v) => AssetReturnLine.fromJson(
          Map<String, dynamic>.from(v as Map))).toList(),
      notes: x['notes']?.toString() ?? '',
      receivingLocation: x['receivingLocation']?.toString() ?? '',
      receivingLocationPath: x['receivingLocationPath']?.toString() ?? '',
      receivingAreaId: x['receivingAreaId']?.toString() ?? '',
      receivingSpotId: x['receivingSpotId']?.toString() ?? '',
      receivedByName: x['receivedByName']?.toString() ?? '',
    );
}
