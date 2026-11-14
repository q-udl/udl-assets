part of 'main.dart';

extension AssetV4History on _AssetScreenState {
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
    if(v4HistoryPage>=pages)v4HistoryPage=pages-1;
    final rows=items.skip(v4HistoryPage*v4HistoryPerPage).take(v4HistoryPerPage);
    return surface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      sectionHeader('Riwayat Aktivitas',
        subtitle:items.length.toString()+' peristiwa · pelaku belum terverifikasi (lokal)'),
      const SizedBox(height:12),
      TextField(decoration:const InputDecoration(
        prefixIcon:Icon(Icons.search),
        hintText:'Cari nama, kode aset, atau aktivitas...'),
        onChanged:(v)=>setState(() {v4HistoryQuery=v;v4HistoryPage=0;})),
      const SizedBox(height:10),
      Wrap(spacing:10,runSpacing:10,children:[
        filterDropdown(v4HistoryType,['Semua aktivitas',...types],
          (v)=>setState(() {v4HistoryType=v;v4HistoryPage=0;}),width:210),
        filterDropdown(v4HistoryPeriod,['Semua periode','7 hari','30 hari'],
          (v)=>setState(() {v4HistoryPeriod=v;v4HistoryPage=0;}),width:165),
      ]),
      const SizedBox(height:14),
      LayoutBuilder(builder:(ctx,box) {
        if(box.maxWidth<750)return Column(children:[
          for(final e in rows) ListTile(
            onTap:()=>v4EventDetail(e),
            leading:Icon(v4EventIcon(e.type)),
            title:Text(e.type+' · '+(assetFor(e.assetId)?.name ?? 'Master Data')),
            subtitle:Text(e.detail,maxLines:2,overflow:TextOverflow.ellipsis),
            trailing:const Icon(Icons.chevron_right)),
        ]);
        return SingleChildScrollView(scrollDirection:Axis.horizontal,
          child:DataTable(columnSpacing:18,
            columns:const [
              DataColumn(label:Text('TANGGAL & JAM')),
              DataColumn(label:Text('AKTIVITAS')),
              DataColumn(label:Text('ASET')),
              DataColumn(label:Text('RINGKASAN')),
              DataColumn(label:Text('RINCIAN')),
            ],
            rows:[for(final e in rows) DataRow(cells:[
              DataCell(Text(dateText(e.timestamp))),
              DataCell(Row(children:[
                Icon(v4EventIcon(e.type),size:17,color:blue),
                const SizedBox(width:6),Text(e.type)])),
              DataCell(SizedBox(width:185,child:Column(
                mainAxisAlignment:MainAxisAlignment.center,
                crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(assetFor(e.assetId)?.name ?? 'Master Data',
                    maxLines:1,overflow:TextOverflow.ellipsis),
                  Text(assetFor(e.assetId)?.code ?? '',
                    style:const TextStyle(fontSize:11,color:muted)),
              ]))),
              DataCell(SizedBox(width:250,child:Text(e.detail,
                maxLines:2,overflow:TextOverflow.ellipsis))),
              DataCell(IconButton(tooltip:'Lihat rincian',icon:const Icon(Icons.open_in_new),
                onPressed:()=>v4EventDetail(e))),
            ])]));
      }),
      const Divider(height:22),
      Row(children:[
        Text('Halaman '+(v4HistoryPage+1).toString()+' / '+pages.toString()),
        const Spacer(),
        DropdownButton<int>(value:v4HistoryPerPage,items:[20,40,80].map((n)=>
          DropdownMenuItem(value:n,child:Text(n.toString()))).toList(),
          onChanged:(v)=>setState(() {v4HistoryPerPage=v ?? 20;v4HistoryPage=0;})),
        IconButton(onPressed:v4HistoryPage==0?null:
          ()=>setState(()=>v4HistoryPage--),icon:const Icon(Icons.chevron_left)),
        IconButton(onPressed:v4HistoryPage>=pages-1?null:
          ()=>setState(()=>v4HistoryPage++),icon:const Icon(Icons.chevron_right)),
      ]),
    ]));
  }

  IconData v4EventIcon(String type) {
    if(type=='Registrasi')return Icons.add_circle_outline;
    if(type.contains('Foto'))return Icons.photo_camera_outlined;
    if(type.contains('Mutasi'))return Icons.swap_horiz_rounded;
    if(type.contains('Kondisi'))return Icons.build_outlined;
    if(type.contains('Status')||type=='Penghapusan')return Icons.flag_outlined;
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
          Navigator.pop(ctx);setState(() {page=1;selected=a;});
        },child:const Text('Lihat Detail Aset')),
      ]));
  }
}
