part of 'main.dart';

extension _AssetEmployeeScreens on _AssetScreenState {
  Widget v5Employees() {
    final queryText = v5EmployeeSearch.trim().toLowerCase();
    final list = store.employees.where((e) {
      return [e.name, e.unit, e.department,
        e.jobTitle, e.workLocation].join(' ').toLowerCase()
          .contains(queryText) &&
        (v5EmployeeFilter == 'Semua' ||
          (v5EmployeeFilter == 'Aktif' ? e.active : !e.active));
    }).toList()..sort((a,b) => a.name.compareTo(b.name));
    final pages = list.isEmpty ? 1 :
      ((list.length - 1) ~/ v5EmployeePerPage) + 1;
    if (v5EmployeePage >= pages) v5EmployeePage = pages - 1;
    final visible = list.skip(v5EmployeePage * v5EmployeePerPage)
      .take(v5EmployeePerPage).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      surface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionHeader('Daftar Karyawan',
            subtitle: store.employees.length.toString() +
              ' karyawan · referensi untuk Assigned Assets'),
          const SizedBox(height: 15),
          LayoutBuilder(builder: (ctx, box) {
            final search = TextField(
              controller: _employeeSearchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari nama, unit, departemen, jabatan...'),
              onChanged: (value) => v4Change(
                () { v5EmployeeSearch = value; v5EmployeePage = 0; }));
            final status = filterDropdown(v5EmployeeFilter,
              ['Semua','Aktif','Tidak Aktif'],
              (value) => v4Change(() {
                v5EmployeeFilter = value; v5EmployeePage = 0;
              }),
              width: 185);
            if (box.maxWidth >= 740) {
              return Row(children: [
                Expanded(child: search),
                const SizedBox(width: 10), status,
              ]);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [search, const SizedBox(height: 10), status]);
          }),
          const SizedBox(height: 14),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 35),
              child: Column(children: [
                const Icon(Icons.person_search_outlined,
                  color: muted, size: 35),
                const SizedBox(height: 10),
                Text(store.employees.isEmpty
                    ? 'Belum ada data karyawan'
                    : 'Karyawan tidak ditemukan',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Tambahkan karyawan atau ubah filter.',
                  style: TextStyle(fontSize: 12, color: muted)),
              ]),
            )
          else LayoutBuilder(builder: (ctx, box) {
            if (box.maxWidth < 850) {
              return Column(children: [
                for (final e in visible) ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline)),
                  title: Text(e.name),
                  subtitle: Text(e.jobTitle + ' · ' + e.unit),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => v4Change(() {
                    selectedEmployee = e;
                    page = 8;
                  }),
                ),
              ]);
            }
            return Table(
              key: const ValueKey('employee-master-table'),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FlexColumnWidth(2.7), 1: FlexColumnWidth(1.8),
                 2: FlexColumnWidth(1.65), 3: FlexColumnWidth(1.25),
                 4: FlexColumnWidth(0.5),
              },
              children: [
                TableRow(decoration: const BoxDecoration(
                  color: Color(0xFFF7F9FC),
                  border: Border(bottom: BorderSide(color: border))),
                  children: [
                    for (final text in [
                      'KARYAWAN','UNIT / DEPARTEMEN','JABATAN',
                      'STATUS','',
                    ]) _v5EmployeeCell(Text(text, style: const TextStyle(
                      fontSize: 10.5, fontWeight: FontWeight.w800,
                      color: muted))),
                  ]),
                for (final employee in visible)
                  TableRow(
                  decoration: BoxDecoration(
                    color: _hoveredTableRow == 'employee:' + employee.id
                      ? _AssetScreenState.lightBlue : Colors.transparent,
                    border: const Border(bottom: BorderSide(color: border))),
                  children: [
                      _v5EmployeeCell(Text(employee.name,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                        employee: employee),
                      _v5EmployeeCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(employee.unit),
                          Text(employee.department,
                            style: const TextStyle(fontSize: 11,
                              color: muted)),
                        ]), employee: employee),
                      _v5EmployeeCell(Text(employee.jobTitle,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                        employee: employee),
                      _v5EmployeeCell(
                        Text(employee.active ? 'Aktif' : 'Tidak Aktif',
                          style: TextStyle(
                            color: employee.active ? _AssetScreenState.green : muted)),
                        employee: employee),
                      _v5EmployeeCell(const Icon(
                        Icons.chevron_right, color: muted),
                        employee: employee),
                    ],
                  ),
              ],
            );
          }),
          if (list.isNotEmpty) ...[
            const SizedBox(height: 14),
            responsiveAssetPager(
              description: 'Menampilkan ' + (v5EmployeePage * v5EmployeePerPage + 1).toString() +
                '–' + (v5EmployeePage * v5EmployeePerPage + visible.length).toString() +
                ' dari ' + list.length.toString() + ' karyawan',
              perPage: v5EmployeePerPage,
              onPerPage: (value) => v4Change(() {
                v5EmployeePerPage = value; v5EmployeePage = 0;
              }),
              onPrevious: v5EmployeePage > 0 ?
                () => v4Change(() => v5EmployeePage--) : null,
              onNext: v5EmployeePage < pages - 1 ?
                () => v4Change(() => v5EmployeePage++) : null,
            ),
          ],
        ],
      )),
    ]);
  }

  Widget _v5EmployeeCell(Widget child, {AssetEmployee? employee}) {
    return MouseRegion(
      onEnter: employee == null ? null :
        (_) => _setTableHover('employee:' + employee.id),
      onExit: employee == null ? null : (_) {
        if (_hoveredTableRow == 'employee:' + employee.id) {
          _setTableHover(null);
        }
      },
      child: InkWell(
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: employee == null ? null : () => v4Change(() {
          selectedEmployee = employee; page = 8;
        }),
        child: Container(
          alignment: Alignment.centerLeft,
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: child,
        ),
      ),
    );
  }

  Widget v5EmployeeDetail(AssetEmployee employee) {
    final batches = store.assignmentsForEmployee(employee.id);
    final activeLines = batches.expand((b) => b.lines)
      .where((l) => l.state == 'Aktif').toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      surface(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.account_circle_outlined,
              color: blue, size: 42),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name, style: const TextStyle(
                  color: ink, fontSize: 21, fontWeight: FontWeight.w800)),
                Text(employee.jobTitle + ' · ' + employee.unit,
                  style: const TextStyle(color: muted, fontSize: 12)),
              ],
            )),
            Text(employee.active ? 'Aktif' : 'Tidak Aktif',
              style: TextStyle(color: employee.active ? _AssetScreenState.green : danger,
                fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 15),
          Wrap(spacing: 9, runSpacing: 8, children: [
            outlineButton('Ubah Data', Icons.edit_outlined,
              () => v5EditEmployee(employee: employee)),
            outlineButton(employee.active ? 'Nonaktifkan' : 'Aktifkan',
              employee.active ? Icons.person_off_outlined :
                Icons.person_add_alt_outlined,
              () => v5ToggleEmployee(employee),
              tone: employee.active
                ? AssetActionTone.warning : AssetActionTone.success),
          ]),
        ],
      )),
      const SizedBox(height: 13),
      LayoutBuilder(builder: (ctx, box) {
        final info = surface(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          sectionHeader('Informasi Karyawan'),
          const SizedBox(height: 12),
          detailValue('Unit', employee.unit),
          detailValue('Departemen', employee.department),
          detailValue('Jabatan', employee.jobTitle),
          detailValue('Lokasi Kerja', employee.workLocation),
          detailValue('Tanggal Bergabung',
            employee.startDate.isEmpty ? 'Belum diisi' : employee.startDate),
        ]));
        final custody = surface(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          sectionHeader('Aset dalam Penguasaan',
            subtitle: activeLines.length.toString() +
              ' aset masih ditugaskan'),
          const SizedBox(height: 10),
          if (activeLines.isEmpty)
            const Text('Belum ada aset aktif pada karyawan ini.',
              style: TextStyle(color: muted))
          else for (final line in activeLines)
            compactCustodyAssetRow(
              name: line.assetName,
              code: line.assetCode,
              condition: line.handoverCondition,
              accessories: line.accessories,
              legacyAccessories: line.hasLegacyAccessories,
              status: line.state,
              photo: store.primaryPhotoFor(line.assetId),
              onTap: () {
                final asset = store.assignmentAsset(line.assetId);
                if (asset == null) return;
                v4Change(() {
                  selectedEmployee = null;
                  selected = asset;
                  page = 1;
                });
              },
            ),
        ]));
        if (box.maxWidth < 850) {
          return Column(children: [
            info, const SizedBox(height: 13), custody]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Expanded(child: info), const SizedBox(width: 13),
          Expanded(child: custody),
        ]);
      }),
      const SizedBox(height: 13),
      surface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionHeader('Riwayat Penugasan',
            subtitle: batches.length.toString() +
              ' proses penugasan tercatat'),
          const SizedBox(height: 12),
          if (batches.isEmpty)
            const Text('Belum ada riwayat.',
              style: TextStyle(color: muted))
          else for (final batch in batches)
            ListTile(
              title: Text(batch.assignmentReference),
              subtitle: Text(batch.kind + ' · ' +
                batch.lines.length.toString() + ' aset · ' + batch.status),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => v4Change(() {
                selectedEmployee = null;
                selectedAssignment = batch;
                page = 7;
              }),
            ),
        ],
      )),
    ]);
  }
}
