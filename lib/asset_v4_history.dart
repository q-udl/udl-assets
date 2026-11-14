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
      Row(children:[
        Text('Halaman '+(v4HistoryPage+1).toString()+' / '+pages.toString()),
        const Spacer(),
        DropdownButton<int>(value:v4HistoryPerPage,items:[20,40,80].map((n)=>
          DropdownMenuItem(value:n,child:Text(n.toString()))).toList(),
          onChanged:(v)=>v4Change(() {v4HistoryPerPage=v ?? 20;v4HistoryPage=0;})),
        IconButton(onPressed:v4HistoryPage==0?null:
          ()=>v4Change(()=>v4HistoryPage--),icon:const Icon(Icons.chevron_left)),
        IconButton(onPressed:v4HistoryPage>=pages-1?null:
          ()=>v4Change(()=>v4HistoryPage++),icon:const Icon(Icons.chevron_right)),
      ]),
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
    final a=assetFor(e.assetId);
    await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Rincian Aktivitas'),
      content:SizedBox(width:530,child:SingleChildScrollView(child:Column(
        mainAxisSize:MainAxisSize.min,
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(e.type,style:const TextStyle(fontWeight:FontWeight.bold)),
          Text(a==null?'Master Data':a.name+' · '+a.code),
          Text(dateText(e.timestamp),
            style:const TextStyle(fontSize:12,color:muted)),
          const SizedBox(height:12),Text(e.detail),
          if(e.reason.isNotEmpty)...[
            const SizedBox(height:12),Text('Alasan: '+e.reason),
          ],
          if(e.changes.isNotEmpty)...[
            const SizedBox(height:14),
            const Text('Nilai sebelum → sesudah',
              style:TextStyle(fontWeight:FontWeight.bold)),
            for(final change in e.changes.entries)
              Padding(padding:const EdgeInsets.symmetric(vertical:5),
                child:Text(change.key+': '+(change.value is Map
                  ? ((change.value as Map)['from']?.toString() ?? '—')+
                    ' → '+((change.value as Map)['to']?.toString() ?? '—')
                  : change.value.toString()))),
          ],
          const SizedBox(height:12),
          const Text('Pelaku belum terverifikasi (pratinjau tanpa autentikasi)',
            style:TextStyle(fontSize:11,color:muted)),
        ]))),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Tutup')),
        if(a!=null)TextButton(onPressed:(){
          Navigator.pop(ctx);v4Change(() {page=1;selected=a;});
        },child:const Text('Lihat Detail Aset')),
      ]));
  }
}
