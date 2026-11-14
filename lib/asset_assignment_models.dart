part of 'main.dart';

/// Employee records contain only the fields needed for physical asset custody.
/// This is a local prototype, not an HR employee system.
class AssetEmployee {
  final String id, code, createdAt;
  String name, unit, department, jobTitle, workLocation, startDate, updatedAt;
  bool active;

  AssetEmployee({
    required this.id,
    required this.code,
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
    'code': code, 'name': name, 'unit': unit,
    'department': department, 'jobTitle': jobTitle,
    'workLocation': workLocation,
  };

  Map<String, dynamic> toJson() => {
    'id': id, 'code': code, 'name': name, 'unit': unit,
    'department': department, 'jobTitle': jobTitle,
    'workLocation': workLocation, 'startDate': startDate,
    'active': active, 'createdAt': createdAt, 'updatedAt': updatedAt,
  };

  factory AssetEmployee.fromJson(Map<String, dynamic> x) => AssetEmployee(
    id: x['id']?.toString() ?? '',
    code: x['code']?.toString() ?? '',
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

class AssignedAssetLine {
  final String id, assetId, assetCode, assetName, serial, handoverCondition;
  String accessories, state, returnReceiptId, returnedAt;
  final List<String> photoIds;

  AssignedAssetLine({
    required this.id,
    required this.assetId,
    required this.assetCode,
    required this.assetName,
    required this.serial,
    required this.handoverCondition,
    this.accessories = '',
    this.state = 'Menunggu Penerimaan',
    this.returnReceiptId = '',
    this.returnedAt = '',
    this.photoIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'assetId': assetId, 'assetCode': assetCode,
    'assetName': assetName, 'serial': serial,
    'handoverCondition': handoverCondition,
    'accessories': accessories, 'state': state,
    'returnReceiptId': returnReceiptId, 'returnedAt': returnedAt,
    'photoIds': photoIds,
  };

  factory AssignedAssetLine.fromJson(Map<String, dynamic> x) => AssignedAssetLine(
    id: x['id']?.toString() ?? '',
    assetId: x['assetId']?.toString() ?? '',
    assetCode: x['assetCode']?.toString() ?? '',
    assetName: x['assetName']?.toString() ?? '',
    serial: x['serial']?.toString() ?? '',
    handoverCondition: x['handoverCondition']?.toString() ?? '',
    accessories: x['accessories']?.toString() ?? '',
    state: x['state']?.toString() ?? 'Menunggu Penerimaan',
    returnReceiptId: x['returnReceiptId']?.toString() ?? '',
    returnedAt: x['returnedAt']?.toString() ?? '',
    photoIds: (x['photoIds'] as List<dynamic>? ?? [])
      .map((v) => v.toString()).toList(),
  );
}

class AssetAssignment {
  final String id, draftReference, employeeId, kind, createdAt;
  final Map<String, dynamic> employeeSnapshot;
  final List<AssignedAssetLine> lines;
  String dueDate, notes, status, acceptedAt, rejectionReason;

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
    this.status = 'Menunggu Penerimaan',
    this.acceptedAt = '',
    this.rejectionReason = '',
  });

  int get activeCount => lines.where((l) => l.state == 'Aktif').length;
  int get returnedCount => lines.where((l) => l.state == 'Dikembalikan').length;
  bool get isPending => status == 'Menunggu Penerimaan';
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
    'employeeSnapshot': employeeSnapshot, 'kind': kind,
    'createdAt': createdAt, 'dueDate': dueDate, 'notes': notes,
    'status': status, 'acceptedAt': acceptedAt,
    'rejectionReason': rejectionReason,
    'lines': lines.map((l) => l.toJson()).toList(),
  };

  factory AssetAssignment.fromJson(Map<String, dynamic> x) => AssetAssignment(
    id: x['id']?.toString() ?? '',
    draftReference: x['draftReference']?.toString() ?? '',
    employeeId: x['employeeId']?.toString() ?? '',
    employeeSnapshot: x['employeeSnapshot'] is Map
      ? Map<String, dynamic>.from(x['employeeSnapshot'] as Map)
      : {},
    kind: x['kind']?.toString() ?? 'Berkelanjutan',
    createdAt: x['createdAt']?.toString() ?? '',
    lines: (x['lines'] as List<dynamic>? ?? [])
      .map((v) => AssignedAssetLine.fromJson(
        Map<String, dynamic>.from(v as Map))).toList(),
    dueDate: x['dueDate']?.toString() ?? '',
    notes: x['notes']?.toString() ?? '',
    status: x['status']?.toString() ?? 'Menunggu Penerimaan',
    acceptedAt: x['acceptedAt']?.toString() ?? '',
    rejectionReason: x['rejectionReason']?.toString() ?? '',
  );
}

class AssetReturnLine {
  final String assignmentLineId, assetId, assetCode, assetName;
  final String handoverCondition, returnCondition, accessoriesReturned, notes;
  final List<String> photoIds;
  AssetReturnLine({
    required this.assignmentLineId,
    required this.assetId,
    required this.assetCode,
    required this.assetName,
    required this.handoverCondition,
    required this.returnCondition,
    required this.accessoriesReturned,
    required this.notes,
    this.photoIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'assignmentLineId': assignmentLineId,
    'assetId': assetId, 'assetCode': assetCode, 'assetName': assetName,
    'handoverCondition': handoverCondition,
    'returnCondition': returnCondition,
    'accessoriesReturned': accessoriesReturned, 'notes': notes,
    'photoIds': photoIds,
  };
  factory AssetReturnLine.fromJson(Map<String, dynamic> x) => AssetReturnLine(
    assignmentLineId: x['assignmentLineId']?.toString() ?? '',
    assetId: x['assetId']?.toString() ?? '',
    assetCode: x['assetCode']?.toString() ?? '',
    assetName: x['assetName']?.toString() ?? '',
    handoverCondition: x['handoverCondition']?.toString() ?? '',
    returnCondition: x['returnCondition']?.toString() ?? '',
    accessoriesReturned: x['accessoriesReturned']?.toString() ?? '',
    notes: x['notes']?.toString() ?? '',
    photoIds: (x['photoIds'] as List<dynamic>? ?? [])
      .map((v) => v.toString()).toList(),
  );
}

class AssetReturnReceipt {
  final String id, draftReference, assignmentId, createdAt;
  final Map<String, dynamic> employeeSnapshot;
  final List<AssetReturnLine> lines;
  final String notes, receivingLocation, receivedByName;
  AssetReturnReceipt({
    required this.id, required this.draftReference,
    required this.assignmentId, required this.employeeSnapshot,
    required this.createdAt, required this.lines, this.notes = '',
    required this.receivingLocation, this.receivedByName = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'draftReference': draftReference,
    'assignmentId': assignmentId,
    'employeeSnapshot': employeeSnapshot,
    'createdAt': createdAt, 'notes': notes,
    'receivingLocation': receivingLocation, 'receivedByName': receivedByName,
    'lines': lines.map((l) => l.toJson()).toList(),
  };

  factory AssetReturnReceipt.fromJson(Map<String, dynamic> x) =>
    AssetReturnReceipt(
      id: x['id']?.toString() ?? '',
      draftReference: x['draftReference']?.toString() ?? '',
      assignmentId: x['assignmentId']?.toString() ?? '',
      employeeSnapshot: x['employeeSnapshot'] is Map
        ? Map<String, dynamic>.from(x['employeeSnapshot'] as Map)
        : {},
      createdAt: x['createdAt']?.toString() ?? '',
      lines: (x['lines'] as List<dynamic>? ?? [])
        .map((v) => AssetReturnLine.fromJson(
          Map<String, dynamic>.from(v as Map))).toList(),
      notes: x['notes']?.toString() ?? '',
      receivingLocation: x['receivingLocation']?.toString() ?? '',
      receivedByName: x['receivedByName']?.toString() ?? '',
    );
}
