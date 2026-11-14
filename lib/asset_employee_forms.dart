part of 'main.dart';

extension _AssetEmployeeForms on _AssetScreenState {
  Future<void> v5EditEmployee({AssetEmployee? employee}) async {
    final isEdit = employee != null;
    final code = TextEditingController(text: employee?.code ?? '');
    final name = TextEditingController(text: employee?.name ?? '');
    final unit = TextEditingController(text: employee?.unit ?? '');
    final department = TextEditingController(
      text: employee?.department ?? '');
    final jobTitle = TextEditingController(
      text: employee?.jobTitle ?? '');
    final startDate = TextEditingController(
      text: employee?.startDate ?? '');
    final reason = TextEditingController();
    var workLocation = employee?.workLocation ??
      (store.locations.isEmpty ? '' : store.locations.first);
    var error = '';

    Widget editField(TextEditingController controller, String label,
        {bool enabled = true}) => TextField(
      controller: controller, enabled: enabled,
      decoration: v4ModalDecoration(label));

    final accepted = await v4ShowModal<bool>(
      title: isEdit ? 'Ubah Master Karyawan' : 'Tambah Karyawan',
      subtitle: isEdit
        ? 'Kode ' + employee.code + ' tidak dapat diubah'
        : 'Untuk keperluan penguasaan aset, bukan database HRIS',
      maxWidth: 720,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          v4ModalPair(
            editField(name, 'Nama lengkap *'),
            editField(code,
              isEdit ? 'Kode karyawan permanen' :
                'Kode karyawan (kosong = otomatis)',
              enabled: !isEdit),
          ),
          const SizedBox(height: 14),
          v4ModalPair(
            editField(unit, 'Unit *'),
            editField(department, 'Departemen *'),
          ),
          const SizedBox(height: 14),
          v4ModalPair(
            editField(jobTitle, 'Jabatan *'),
            DropdownButtonFormField<String>(
              initialValue: store.locations.contains(workLocation)
                ? workLocation : null,
              isExpanded: true,
              decoration: v4ModalDecoration('Lokasi kerja *'),
              items: store.locations.map((value) => DropdownMenuItem(
                value: value, child: Text(value))).toList(),
              onChanged: (value) => update(
                () => workLocation = value ?? workLocation),
            ),
          ),
          const SizedBox(height: 14),
          editField(startDate, 'Tanggal mulai (opsional; YYYY-MM-DD)'),
          if (isEdit) ...[
            const SizedBox(height: 14),
            editField(reason, 'Alasan perubahan *'),
          ],
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12), v4ModalError(error),
          ],
        ],
      ),
      actions: (ctx, update) => [
        OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal')),
        FilledButton(onPressed: () {
          if (name.text.trim().length < 3 ||
              unit.text.trim().isEmpty ||
              department.text.trim().isEmpty ||
              jobTitle.text.trim().isEmpty ||
              workLocation.isEmpty ||
              (isEdit && reason.text.trim().isEmpty)) {
            update(() => error = 'Lengkapi field wajib dan alasan.');
          } else {
            Navigator.pop(ctx, true);
          }
        }, child: const Text('Simpan Karyawan')),
      ],
    );
    if (accepted == true) {
      try {
        if (employee == null) {
          await store.addEmployee(
            code: code.text, name: name.text,
            unit: unit.text, department: department.text,
            jobTitle: jobTitle.text, workLocation: workLocation,
            startDate: startDate.text.trim());
        } else {
          await store.updateEmployee(employee,
            name: name.text, unit: unit.text,
            department: department.text, jobTitle: jobTitle.text,
            workLocation: workLocation,
            startDate: startDate.text.trim(), reason: reason.text);
        }
        repaint();
        notify('Master karyawan disimpan.');
      } catch (e) {
        notify('Gagal menyimpan karyawan: ' + e.toString());
      }
    }
    for (final ctrl in [code,name,unit,department,jobTitle,
      startDate,reason]) {
      ctrl.dispose();
    }
  }

  Future<void> v5ToggleEmployee(AssetEmployee employee) async {
    final outstanding = store.assignmentsForEmployee(employee.id)
      .expand((a) => a.lines)
      .where((l) => l.state == 'Aktif' ||
        l.state == 'Menunggu Penerimaan').length;
    final reason = TextEditingController();
    var error = '';
    final desired = !employee.active;
    final confirmed = await v4ShowModal<bool>(
      title: desired ? 'Aktifkan Karyawan' : 'Nonaktifkan Karyawan',
      subtitle: employee.name + ' · ' + employee.code,
      maxWidth: 520,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!desired && outstanding > 0) ...[
            v4ModalError(
              outstanding.toString() + ' aset/permintaan masih terkait. '
              'Penonaktifan tidak otomatis mengembalikan aset. '
              'GA wajib menindaklanjuti BAST pengembalian.'),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: reason, maxLines: 3,
            decoration: v4ModalDecoration('Alasan perubahan status *')),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12), v4ModalError(error),
          ],
        ],
      ),
      actions: (ctx, update) => [
        OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal')),
        FilledButton(onPressed: () {
          if (reason.text.trim().isEmpty) {
            update(() => error = 'Alasan wajib diisi.');
          } else {
            Navigator.pop(ctx, true);
          }
        }, child: Text(desired ? 'Aktifkan' : 'Nonaktifkan')),
      ],
    );
    if (confirmed == true) {
      try {
        await store.setEmployeeActive(
          employee, desired, reason.text);
        repaint();
        notify(desired ? 'Karyawan diaktifkan.' :
          'Karyawan dinonaktifkan; tanggung jawab aset tetap dicatat.');
      } catch (e) {
        notify(e.toString());
      }
    }
    reason.dispose();
  }
}
