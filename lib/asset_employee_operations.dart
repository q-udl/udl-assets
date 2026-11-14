part of 'main.dart';

extension AssetEmployeeOperations on AssetStore {
  AssetEmployee? employeeById(String id) {
    for (final e in employees) {
      if (e.id == id) return e;
    }
    return null;
  }

  AssetRecord? assignmentAsset(String id) {
    for (final a in assets) {
      if (a.id == id) return a;
    }
    return null;
  }

  AssetAssignment? assignmentById(String id) {
    for (final a in assignments) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<AssignedAssetLine> heldLinesFor(String assetId) =>
    assignments.expand((a) => a.lines).where((line) =>
      line.assetId == assetId && (
        line.state == 'Aktif' ||
        line.state == 'Menunggu Penerimaan')).toList();

  List<AssetAssignment> assignmentsForEmployee(String id) =>
    assignments.where((a) => a.employeeId == id).toList();

  List<AssetReturnReceipt> returnsForAssignment(String id) =>
    returnReceipts.where((r) => r.assignmentId == id).toList();

  bool canAssignAsset(AssetRecord a) =>
    a.status == 'Tersedia' && a.lifecycle == 'Aktif' &&
    a.holder.trim().isEmpty &&
    a.assignedEmployeeId.isEmpty &&
    heldLinesFor(a.id).isEmpty &&
    !transfers.any((t) => t.assetId == a.id &&
      t.state == 'Menunggu Penerimaan');

  void verifyAssignmentData(
    List<AssetRecord> records, List<AssetEmployee> staff,
    List<AssetAssignment> batches, List<AssetReturnReceipt> receipts,
  ) {
    final assetIds = records.map((a) => a.id).toSet();
    final staffIds = staff.map((e) => e.id).toSet();
    if (staffIds.length != staff.length ||
        staff.map((e) => e.code.toLowerCase()).toSet().length != staff.length ||
        staff.any((e) => e.id.isEmpty || e.code.trim().isEmpty ||
          e.name.trim().isEmpty)) {
      throw const FormatException('Master karyawan backup tidak valid.');
    }
    final batchIds = batches.map((b) => b.id).toSet();
    if (batchIds.length != batches.length ||
        batches.map((b) => b.draftReference).toSet().length != batches.length) {
      throw const FormatException('Referensi penugasan tidak unik.');
    }
    final activeAssetIds = <String>{};
    for (final batch in batches) {
      if (!staffIds.contains(batch.employeeId) || batch.lines.isEmpty ||
          batch.lines.map((l) => l.assetId).toSet().length != batch.lines.length) {
        throw const FormatException('Penugasan karyawan tidak valid.');
      }
      for (final line in batch.lines) {
        if (!assetIds.contains(line.assetId)) {
          throw const FormatException('Penugasan mengacu aset yang tidak ditemukan.');
        }
        if (line.state == 'Aktif' || line.state == 'Menunggu Penerimaan') {
          if (!activeAssetIds.add(line.assetId)) {
            throw const FormatException('Aset tercatat pada dua penugasan aktif.');
          }
        }
      }
    }
    for (final a in records.where((a) => a.assignedEmployeeId.isNotEmpty)) {
      if (!staffIds.contains(a.assignedEmployeeId) ||
          !batches.any((b) => b.employeeId == a.assignedEmployeeId &&
            b.lines.any((l) => l.assetId == a.id && l.state == 'Aktif'))) {
        throw const FormatException('Relasi penanggung jawab tidak konsisten.');
      }
    }
    if (receipts.map((r) => r.id).toSet().length != receipts.length ||
        receipts.map((r) => r.draftReference).toSet().length != receipts.length) {
      throw const FormatException('Nomor BA pengembalian tidak unik.');
    }
    final returnedLines = <String>{};
    for (final receipt in receipts) {
      final matching = batches.where((a) => a.id == receipt.assignmentId);
      if (matching.length != 1 || receipt.lines.isEmpty) {
        throw const FormatException('BA pengembalian kehilangan penugasan.');
      }
      for (final line in receipt.lines) {
        if (!matching.single.lines.any((l) =>
            l.id == line.assignmentLineId && l.assetId == line.assetId) ||
            !returnedLines.add(line.assignmentLineId)) {
          throw const FormatException('Item BA pengembalian tidak valid.');
        }
      }
    }
  }

  Future<AssetEmployee> addEmployee({
    String code = '', required String name,
    required String unit, required String department,
    required String jobTitle, required String workLocation,
    String startDate = '',
  }) async {
    var employeeCode = code.trim();
    if (employeeCode.isEmpty) {
      do {
        employeeCode = 'KRY-' +
          nextEmployeeNumber.toString().padLeft(6, '0');
        if (employees.any((e) => e.code.toLowerCase() ==
            employeeCode.toLowerCase())) {
          nextEmployeeNumber++;
          continue;
        }
        break;
      } while (true);
    }
    if (employeeCode.length < 3 || name.trim().length < 3 ||
        unit.trim().isEmpty || department.trim().isEmpty ||
        jobTitle.trim().isEmpty || !locations.contains(workLocation) ||
        employees.any((e) => e.code.toLowerCase() ==
          employeeCode.toLowerCase()) ||
        (startDate.isNotEmpty && DateTime.tryParse(startDate) == null)) {
      throw const FormatException('Data karyawan belum lengkap/unik.');
    }
    final now = DateTime.now().toIso8601String();
    final record = AssetEmployee(
      id: uuid.v4(), code: employeeCode,
      name: name.trim(), unit: unit.trim(),
      department: department.trim(), jobTitle: jobTitle.trim(),
      workLocation: workLocation, startDate: startDate,
      createdAt: now, updatedAt: now);
    employees.insert(0, record);
    if (code.trim().isEmpty) {
      nextEmployeeNumber++;
    } else if (employeeCode.startsWith('KRY-')) {
      final serial = int.tryParse(employeeCode.substring(4));
      if (serial != null && serial >= nextEmployeeNumber) {
        nextEmployeeNumber = serial + 1;
      }
    }
    events.insert(0, EventRecord('', 'Master Karyawan',
      'Karyawan ' + record.name + ' (' + record.code + ') ditambahkan', now));
    await persist();
    return record;
  }

  Future<void> updateEmployee(
    AssetEmployee employee, {
    required String name, required String unit,
    required String department, required String jobTitle,
    required String workLocation, required String startDate,
    required String reason,
  }) async {
    if (name.trim().length < 3 || unit.trim().isEmpty ||
        department.trim().isEmpty || jobTitle.trim().isEmpty ||
        !locations.contains(workLocation) || reason.trim().isEmpty ||
        (startDate.isNotEmpty && DateTime.tryParse(startDate) == null)) {
      throw const FormatException('Data karyawan/alasan belum valid.');
    }
    if (employee.name == name.trim() &&
        employee.unit == unit.trim() &&
        employee.department == department.trim() &&
        employee.jobTitle == jobTitle.trim() &&
        employee.workLocation == workLocation &&
        employee.startDate == startDate) {
      throw const FormatException('Tidak ada perubahan.');
    }
    final changes = <String, dynamic>{
      'Nama': {'from': employee.name, 'to': name.trim()},
      'Unit': {'from': employee.unit, 'to': unit.trim()},
      'Departemen': {'from': employee.department, 'to': department.trim()},
      'Jabatan': {'from': employee.jobTitle, 'to': jobTitle.trim()},
      'Lokasi Kerja': {
        'from': employee.workLocation, 'to': workLocation},
    };
    employee.name = name.trim();
    employee.unit = unit.trim();
    employee.department = department.trim();
    employee.jobTitle = jobTitle.trim();
    employee.workLocation = workLocation;
    employee.startDate = startDate;
    employee.updatedAt = DateTime.now().toIso8601String();
    // Historic BAST snapshots intentionally remain unchanged.
    for (final batch in assignments.where((b) => b.employeeId == employee.id)) {
      for (final line in batch.lines.where((l) => l.state == 'Aktif')) {
        final asset = assignmentAsset(line.assetId);
        if (asset != null && asset.assignedEmployeeId == employee.id) {
          asset.holder = employee.name;
        }
      }
    }
    events.insert(0, EventRecord('', 'Master Karyawan',
      'Perubahan data ' + employee.code,
      DateTime.now().toIso8601String(), reason: reason, changes: changes));
    await persist();
  }

  Future<void> setEmployeeActive(
    AssetEmployee employee, bool active, String reason,
  ) async {
    if (employee.active == active || reason.trim().isEmpty) {
      throw const FormatException('Status dan alasan tidak valid.');
    }
    employee.active = active;
    employee.updatedAt = DateTime.now().toIso8601String();
    events.insert(0, EventRecord('', 'Master Karyawan',
      (active ? 'Aktifkan ' : 'Nonaktifkan ') + employee.code,
      DateTime.now().toIso8601String(), reason: reason));
    await persist();
  }
}
