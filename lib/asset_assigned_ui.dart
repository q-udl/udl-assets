part of 'main.dart';

extension _AssignedAssetsScreens on _AssetScreenState {
  Widget v5AssignedAssets() {
    final queryText = v5AssignmentSearch.trim().toLowerCase();
    final matching = store.assignments.where((a) {
      final snapshot = a.employeeSnapshot;
      final haystack = [
        a.assignmentReference, snapshot['name']?.toString() ?? '',
        snapshot['jobTitle']?.toString() ?? '',
        snapshot['unit']?.toString() ?? '',
        ...a.lines.map((l) => l.assetCode + ' ' + l.assetName),
      ].join(' ').toLowerCase();
      return haystack.contains(queryText) &&
        (v5AssignmentFilter == 'Semua' ||
          a.status == v5AssignmentFilter);
    }).toList()..sort((a,b) => b.createdAt.compareTo(a.createdAt));
    final pages = matching.isEmpty ? 1 :
      ((matching.length - 1) ~/ v5AssignmentPerPage) + 1;
    if (v5AssignmentPage >= pages) v5AssignmentPage = pages - 1;
    final visible = matching.skip(
      v5AssignmentPage * v5AssignmentPerPage)
      .take(v5AssignmentPerPage).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      surface(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(builder: (ctx, box) {
            final search = TextField(
              controller: _assignmentSearchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari karyawan, referensi BA, kode aset...',
              ),
              onChanged: (text) => v4Change(() {
                v5AssignmentSearch = text;
                v5AssignmentPage = 0;
              }));
            final status = filterDropdown(v5AssignmentFilter,
              ['Semua', 'Menunggu Serah Terima', 'Aktif', 'Selesai', 'Dibatalkan'],
              (value) => v4Change(() {
                v5AssignmentFilter = value;
                v5AssignmentPage = 0;
              }), width: 200);
            if (box.maxWidth >= 780) {
              return Row(children: [
                Expanded(child: search),
                const SizedBox(width: 10), status,
              ]);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [search, const SizedBox(height: 10), status]);
          }),
          const SizedBox(height: 10),
          const Text('Pencatatan serah terima belum terhubung ke autentikasi '
            'atau verifikasi tanda tangan digital.',
            style: TextStyle(fontSize: 11, color: muted)),
        ],
      )),
      const SizedBox(height: 12),
      surface(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionHeader('Daftar Penugasan',
            subtitle: matching.length.toString() + ' penugasan sesuai filter'),
          const SizedBox(height: 12),
          if (matching.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(children: [
                const Icon(Icons.assignment_ind_outlined,
                  size: 39, color: muted),
                const SizedBox(height: 12),
                Text(store.assignments.isEmpty
                  ? 'Belum ada penugasan aset'
                  : 'Penugasan tidak ditemukan',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Pilih karyawan aktif dan aset yang tersedia.',
                  style: TextStyle(fontSize: 12, color: muted)),
              ]),
            )
          else LayoutBuilder(builder: (ctx, box) {
            if (box.maxWidth < 850) {
              return Column(children: [
                for (final a in visible)
                  ListTile(
                    title: Text(a.employeeSnapshot['name']?.toString() ?? '-'),
                    subtitle: Text(a.assignmentReference + ' · ' +
                      a.lines.length.toString() + ' aset · ' + a.status),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => v4Change(() {
                      page = 7; selectedAssignment = a;
                    }),
                  ),
              ]);
            }
            return Table(
              key: const ValueKey('assigned-assets-table'),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FlexColumnWidth(2.2), 1: FlexColumnWidth(2.1),
                2: FlexColumnWidth(1.2), 3: FlexColumnWidth(1.6),
                4: FlexColumnWidth(1.3), 5: FlexColumnWidth(0.4),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F9FC),
                    border: Border(bottom: BorderSide(color: border))),
                  children: [
                    for (final h in ['REFERENSI PENUGASAN','PENERIMA',
                      'JUMLAH ASET','JENIS / BATAS','STATUS',''])
                      _v5AssignedCell(Text(h, style: const TextStyle(
                        fontSize: 10.5, fontWeight: FontWeight.w800,
                        color: muted))),
                  ],
                ),
                for (final batch in visible)
                  TableRow(decoration: BoxDecoration(
                    color: _hoveredTableRow == 'assignment:' + batch.id
                      ? _AssetScreenState.lightBlue : Colors.transparent,
                    border: const Border(bottom: BorderSide(color: border))),
                    children: [
                      _v5AssignedCell(Text(batch.assignmentReference,
                        style: const TextStyle(color: blue,
                          fontWeight: FontWeight.w700)),
                        batch: batch),
                      _v5AssignedCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(batch.employeeSnapshot['name']?.toString() ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text((batch.employeeSnapshot['jobTitle']?.toString() ?? '') +
                             ' · ' + (batch.employeeSnapshot['unit']?.toString() ?? ''),
                            style: const TextStyle(fontSize: 11, color: muted)),
                        ]), batch: batch),
                      _v5AssignedCell(Text(batch.activeCount.toString() +
                        ' aktif / ' + batch.lines.length.toString() + ' total'),
                        batch: batch),
                      _v5AssignedCell(Text(batch.kind +
                        (batch.dueDate.isEmpty ? '' : ' · ' + batch.dueDate)),
                        batch: batch),
                      _v5AssignedCell(badge(batch.status,
                        compact: true, toneColor: batch.isOverdue ? danger : null),
                        batch: batch),
                      _v5AssignedCell(const Icon(
                        Icons.chevron_right_rounded, color: muted),
                        batch: batch),
                    ],
                  ),
              ],
            );
          }),
          if (matching.isNotEmpty) ...[
            const Divider(height: 23, color: border),
            responsiveAssetPager(
              description:matching.length.toString() + ' penugasan sesuai filter',
              perPage:v5AssignmentPerPage,
              onPerPage:(value)=>v4Change(() {
                v5AssignmentPerPage=value;v5AssignmentPage=0;
              }),
              onPrevious:v5AssignmentPage==0?null:
                ()=>v4Change(()=>v5AssignmentPage--),
              onNext:v5AssignmentPage>=pages-1?null:
                ()=>v4Change(()=>v5AssignmentPage++),
            ),
          ],
        ],
      )),
    ]);
  }

  Widget _v5AssignedCell(Widget child, {AssetAssignment? batch}) =>
    MouseRegion(
      onEnter: batch == null ? null :
        (_) => _setTableHover('assignment:' + batch.id),
      onExit: batch == null ? null : (_) {
        if (_hoveredTableRow == 'assignment:' + batch.id) {
          _setTableHover(null);
        }
      },
      child: InkWell(
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: batch == null ? null : () => v4Change(() {
          selectedAssignment = batch;
          page = 7;
        }),
        child: Container(
          constraints: const BoxConstraints(minHeight: 66),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: child),
      ),
    );
}
