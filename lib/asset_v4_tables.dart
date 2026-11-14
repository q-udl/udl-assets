part of 'main.dart';

/// Tables consume all available width; narrow viewports switch to compact cards.
extension _AssetV4Tables on _AssetScreenState {
  Widget _v4Head(String label, {String? sort}) => InkWell(
    onTap: sort == null ? null : () => v4Change(() {
      if (v4Sort == sort) {
        v4SortAscending = !v4SortAscending;
      } else {
        v4Sort = sort;
        v4SortAscending = true;
      }
      v4CatalogPage = 0;
    }),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 15),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(child: Text(label,
          overflow: TextOverflow.ellipsis, maxLines: 1,
          style: const TextStyle(color: muted, fontSize: 11,
            fontWeight: FontWeight.w800))),
        if (sort != null && v4Sort == sort) ...[
          const SizedBox(width: 3),
          Icon(v4SortAscending ? Icons.arrow_upward_rounded :
            Icons.arrow_downward_rounded, color: blue, size: 13),
        ],
      ]),
    ),
  );

  Widget _v4Td(Widget child,
      {VoidCallback? tap, String? rowKey}) => MouseRegion(
    onEnter: rowKey == null ? null : (_) => _setTableHover(rowKey),
    onExit: rowKey == null ? null : (_) {
      if (_hoveredTableRow == rowKey) _setTableHover(null);
    },
    child: InkWell(
      onTap: tap,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
        child: child,
      ),
    ),
  );

  Widget _v4AssetTable(Iterable<AssetRecord> assets, double width) {
    final wide = width >= 1180;
    return Table(
      key: const ValueKey('adaptive-asset-table'),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        0: const FlexColumnWidth(3.05),
        1: const FlexColumnWidth(1.60),
        if (wide) 2: const FlexColumnWidth(1.90),
        3 - (wide ? 0 : 1): const FlexColumnWidth(2.35),
        4 - (wide ? 0 : 1): const FlexColumnWidth(1.05),
        5 - (wide ? 0 : 1): const FlexColumnWidth(1.38),
        6 - (wide ? 0 : 1): const FlexColumnWidth(0.66),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F9FC),
            border: Border(bottom: BorderSide(color: border))),
          children: [
            _v4Head('ASET', sort: 'Nama'),
            _v4Head('KODE', sort: 'Kode'),
            if (wide) _v4Head('KATEGORI', sort: 'Kategori'),
            _v4Head('LOKASI / PIC', sort: 'Lokasi'),
            _v4Head('KONDISI', sort: 'Kondisi'),
            _v4Head('STATUS', sort: 'Status'),
            _v4Head('TINDAKAN'),
          ],
        ),
        for (final a in assets)
          TableRow(
            decoration: BoxDecoration(
              color: _hoveredTableRow == 'asset:' + a.id
                ? lightBlue : Colors.transparent,
              border: const Border(bottom: BorderSide(color: border))),
            children: [
              _v4Td(Row(children: [
                assetThumbnail(a, size: 42),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.name, maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: ink, fontSize: 13,
                        fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(wide ? a.assetType : a.category + ' · ' + a.assetType,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 11)),
                  ],
                )),
              ]), tap: () => v4Change(() => selected = a),
                rowKey: 'asset:' + a.id),
              _v4Td(Text(a.code,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: blue,
                  fontWeight: FontWeight.w700)),
                tap: () => v4Change(() => selected = a),
                rowKey: 'asset:' + a.id),
              if (wide)
                _v4Td(Text(a.category, maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ink, fontSize: 12)),
                  tap: () => v4Change(() => selected = a),
                rowKey: 'asset:' + a.id),
              _v4Td(Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.locationPath(a), maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ink, fontSize: 12,
                      fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(a.holder.isEmpty ? 'PIC belum ditetapkan' : a.holder,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11,
                      color: a.holder.isEmpty ? danger : muted)),
                ],
              ), tap: () => v4Change(() => selected = a),
                rowKey: 'asset:' + a.id),
              _v4Td(Text(a.condition,
                style: TextStyle(fontSize: 12, color:
                  ['Rusak', 'Kurang Baik'].contains(a.condition) ?
                    danger : ink)),
                tap: () => v4Change(() => selected = a),
                rowKey: 'asset:' + a.id),
              _v4Td(badge(a.lifecycle == 'Aktif' ? a.status : a.lifecycle, compact: true),
                tap: () => v4Change(() => selected = a),
                rowKey: 'asset:' + a.id),
              _v4Td(PopupMenuButton<String>(
                tooltip: 'Tindakan ' + a.code,
                onSelected: (value) {
                  if (value == 'detail') {
                    v4Change(() => selected = a);
                  } else if (value == 'mutasi') {
                    v4Transfer(a);
                  } else if (value == 'copy') {
                    Clipboard.setData(ClipboardData(text: a.code));
                    notify('Kode aset disalin.');
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'detail', child: Text('Lihat Detail')),
                  PopupMenuItem(value: 'mutasi', child: Text('Mutasi Aset')),
                  PopupMenuItem(value: 'copy', child: Text('Salin Kode')),
                ],
                child: const Icon(Icons.more_horiz, color: blue, size: 21),
              ), rowKey: 'asset:' + a.id),
            ],
          ),
      ],
    );
  }

  Widget _v4HistoryTable(Iterable<EventRecord> events, double width) {
    final wide = width >= 1050;
    return Table(
      key: const ValueKey('adaptive-history-table'),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        0: const FlexColumnWidth(1.55),
        1: const FlexColumnWidth(1.50),
        2: const FlexColumnWidth(2.50),
        if (wide) 3: const FlexColumnWidth(3.45),
        4 - (wide ? 0 : 1): const FlexColumnWidth(0.65),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F9FC),
            border: Border(bottom: BorderSide(color: border))),
          children: [
            _v4Head('TANGGAL & JAM'),
            _v4Head('AKTIVITAS'),
            _v4Head(wide ? 'ASET' : 'ASET / RINGKASAN'),
            if (wide) _v4Head('RINGKASAN'),
            _v4Head('RINCIAN'),
          ],
        ),
        for (final e in events)
          TableRow(
            decoration: BoxDecoration(
              color: _hoveredTableRow == 'event:' + e.hashCode.toString()
                ? lightBlue : Colors.transparent,
              border: const Border(bottom: BorderSide(color: border))),
            children: [
              _v4Td(Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateText(e.timestamp).split(' · ').first,
                    style: const TextStyle(color: ink,
                      fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(dateText(e.timestamp).contains(' · ')
                    ? dateText(e.timestamp).split(' · ').last : '',
                    style: const TextStyle(color: muted, fontSize: 11)),
                ],
              ), tap: () => v4EventDetail(e),
                rowKey: 'event:' + e.hashCode.toString()),
              _v4Td(Row(children: [
                Icon(v4EventIcon(e.type), size: 17, color: blue),
                const SizedBox(width: 7),
                Expanded(child: Text(e.type, maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: ink))),
              ]), tap: () => v4EventDetail(e),
                rowKey: 'event:' + e.hashCode.toString()),
              _v4Td(Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(assetFor(e.assetId)?.name ?? 'Master Data',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ink,
                      fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(assetFor(e.assetId)?.code ?? '',
                    style: const TextStyle(color: muted, fontSize: 11)),
                  if (!wide) ...[
                    const SizedBox(height: 4),
                    Text(e.detail, maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 11)),
                  ],
                ],
              ), tap: () => v4EventDetail(e),
                rowKey: 'event:' + e.hashCode.toString()),
              if (wide)
                _v4Td(Text(e.detail, maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ink, fontSize: 12)),
                  tap: () => v4EventDetail(e),
                rowKey: 'event:' + e.hashCode.toString()),
              _v4Td(IconButton(
                tooltip: 'Lihat Rincian',
                icon: const Icon(Icons.chevron_right_rounded, color: blue),
                onPressed: () => v4EventDetail(e)),
                rowKey: 'event:' + e.hashCode.toString()),
            ],
          ),
      ],
    );
  }
}
