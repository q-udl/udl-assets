part of 'main.dart';

extension _AssetV4History on _AssetScreenState {
  Widget v4History() {
    final types = store.events.map((e)=>e.type).toSet().toList()..sort();
    final queryText = v4HistoryQuery.trim().toLowerCase();
    final items = store.events.where((e) {
      final a=assetFor(e.assetId);
      final text=[e.type,e.detail,a?.code ?? '',a?.name ?? ''].join(' ').toLowerCase();
      final at=DateTime.tryParse(e.timestamp);
      final periodOk=v4HistoryPeriod=='Semua periode' ||
        (at!=null && ((v4HistoryPeriod=='7 hari' &&
          at.isAfter(DateTime.now().subtract(const Duration(days:7)))) ||
          (v4HistoryPeriod=='30 hari' &&
          at.isAfter(DateTime.now().subtract(const Duration(days:30))))));
      return text.contains(queryText) && periodOk &&
        (v4HistoryType=='Semua aktivitas'||v4HistoryType==e.type);
    }).toList()..sort((a,b)=>b.timestamp.compareTo(a.timestamp));
    final pages=items.isEmpty?1:((items.length-1)~/v4HistoryPerPage)+1;
    if(v4HistoryPage>=pages) { v4HistoryPage=pages-1; }
    final rows=items.skip(v4HistoryPage*v4HistoryPerPage).take(v4HistoryPerPage);
    return surface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      sectionHeader('Riwayat Aktivitas',
        subtitle:items.length.toString()+' peristiwa · pelaku belum terverifikasi (lokal)'),
      const SizedBox(height:12),
      LayoutBuilder(builder: (ctx, available) {
        final search = TextField(
          controller: _historySearchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Cari nama, kode aset, atau aktivitas...',
          ),
          onChanged: (value) => v4Change(() {
            v4HistoryQuery = value; v4HistoryPage = 0;
          }),
        );
        final activity = filterDropdown(
          v4HistoryType, ['Semua aktivitas', ...types],
          (value) => v4Change(() {
            v4HistoryType = value; v4HistoryPage = 0;
          }), width: 210);
        final period = filterDropdown(
          v4HistoryPeriod, ['Semua periode', '7 hari', '30 hari'],
          (value) => v4Change(() {
            v4HistoryPeriod = value; v4HistoryPage = 0;
          }), width: 165);
        if (available.maxWidth >= 1050) {
          return Row(children: [
            Expanded(child: search),
            const SizedBox(width: 10),
            activity,
            const SizedBox(width: 10),
            period,
          ]);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            search,
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10,
              children: [activity, period]),
          ],
        );
      }),
      const SizedBox(height:14),
      LayoutBuilder(builder:(ctx,box) {
        if(box.maxWidth<750) { return Column(children:[
          for(final e in rows) ListTile(
            onTap:()=>v4EventDetail(e),
            leading:Icon(v4EventIcon(e.type)),
            title:Text(e.type+' · '+(assetFor(e.assetId)?.name ?? 'Master Data')),
            subtitle:Text(e.detail,maxLines:2,overflow:TextOverflow.ellipsis),
            trailing:const Icon(Icons.chevron_right)),
        ]); }
        return _v4HistoryTable(rows, box.maxWidth);
      }),
      const Divider(height:22),
      responsiveAssetPager(
        description:'Halaman '+(v4HistoryPage+1).toString()+' / '+pages.toString(),
        perPage:v4HistoryPerPage,
        onPerPage:(v)=>v4Change(() {v4HistoryPerPage=v;v4HistoryPage=0;}),
        onPrevious:v4HistoryPage==0?null:
          ()=>v4Change(()=>v4HistoryPage--),
        onNext:v4HistoryPage>=pages-1?null:
          ()=>v4Change(()=>v4HistoryPage++),
      ),
    ]));
  }

  IconData v4EventIcon(String type) {
    if(type=='Registrasi') { return Icons.add_circle_outline; }
    if(type.contains('Foto')) { return Icons.photo_camera_outlined; }
    if(type.contains('Mutasi')) { return Icons.swap_horiz_rounded; }
    if(type.contains('Kondisi')) { return Icons.build_outlined; }
    if(type.contains('Status')||type=='Penghapusan') { return Icons.flag_outlined; }
    return Icons.history_rounded;
  }

  Future<void> v4EventDetail(EventRecord e) async {
    final a = assetFor(e.assetId);
    await v4ShowModal<void>(
      title: 'Rincian Aktivitas',
      subtitle: a == null ? 'Master Data' : a.name + ' · ' + a.code,
      maxWidth: 650,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(v4EventIcon(e.type), size: 20, color: blue),
            const SizedBox(width: 9),
            Expanded(child: Text(e.type,
              style: const TextStyle(fontSize: 15, color: ink,
                fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 6),
          Text(dateText(e.timestamp),
            style: const TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 14),
          Text(e.detail, style: const TextStyle(fontSize: 13)),
          if (e.reason.isNotEmpty) ...[
            const SizedBox(height: 14),
            v4ReadonlyField('Alasan perubahan', e.reason),
          ],
          if (e.changes.isNotEmpty) ...[
            const SizedBox(height: 17),
            const Text('Nilai Sebelum dan Sesudah',
              style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final change in e.changes.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: v4ModalPair(
                  v4ReadonlyField(change.key + ' · Sebelum',
                    change.value is Map
                      ? ((change.value as Map)['from']?.toString() ?? '—')
                      : '—'),
                  v4ReadonlyField(change.key + ' · Sesudah',
                    change.value is Map
                      ? ((change.value as Map)['to']?.toString() ?? '—')
                      : change.value.toString()),
                  breakpoint: 460,
                ),
              ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Pelaku belum terverifikasi (prototipe tanpa autentikasi).',
            style: TextStyle(fontSize: 12, color: muted)),
        ],
      ),
      actions: (ctx, update) => [
        OutlinedButton(style: assetOutlinedStyle(AssetActionTone.secondary),
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Tutup')),
        if (a != null)
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              v4Change(() {
                page = 1; selected = a;
              });
            },
            child: const Text('Lihat Detail Aset'),
          ),
      ],
    );
  }
}
