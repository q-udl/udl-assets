part of 'main.dart';

extension _AssetV4Catalog on _AssetScreenState {
  List<AssetRecord> v4FilteredAssets() {
    final q = query.trim().toLowerCase();
    final items = store.assets.where((a) {
      final searchable = [a.name, a.code, a.serial, a.category, a.subcategory,
        a.assetType, a.brand, a.location, a.holder].join(' ').toLowerCase();
      return searchable.contains(q) &&
        (statusFilter == 'Semua status' || a.status == statusFilter) &&
        (categoryFilter == 'Semua kategori' || a.category == categoryFilter) &&
        (v4LocationFilter == 'Semua lokasi' || a.location == v4LocationFilter) &&
        (v4ConditionFilter == 'Semua kondisi' || a.condition == v4ConditionFilter) &&
        (!v4NoPic || a.holder.trim().isEmpty) &&
        (!v4NoPhoto || store.photosFor(a.id).isEmpty) &&
        (!v4Attention || needsAttention(a)) &&
        (!v4NeedsClassification || a.category == 'Perlu Klasifikasi Ulang' ||
          a.subcategory.isEmpty || a.assetType.isEmpty);
    }).toList();
    int compare(AssetRecord a, AssetRecord b) {
      switch (v4Sort) {
        case 'Nama': return a.name.compareTo(b.name);
        case 'Kategori': return a.category.compareTo(b.category);
        case 'Lokasi': return a.location.compareTo(b.location);
        case 'Status': return a.status.compareTo(b.status);
        case 'Kondisi': return a.condition.compareTo(b.condition);
        default: return a.code.compareTo(b.code);
      }
    }
    items.sort((a,b) => v4SortAscending ? compare(a,b) : compare(b,a));
    return items;
  }

  Widget v4Catalog() {
    final items = v4FilteredAssets();
    final pages = items.isEmpty ? 1 : ((items.length - 1) ~/ v4PerPage) + 1;
    if (v4CatalogPage >= pages) v4CatalogPage = pages - 1;
    final slice = items.skip(v4CatalogPage * v4PerPage).take(v4PerPage);
    final cats = {...store.categories.map((c) => c.name),
      ...store.assets.map((a) => a.category)}.toList()..sort();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        searchBox(), const SizedBox(height: 10),
        Wrap(spacing: 9, runSpacing: 9, children: [
          filterDropdown(statusFilter, const ['Semua status','Tersedia','Digunakan',
            'Dalam Perbaikan','Hilang','Dihapuskan'],
            (v) => v4Change(() {statusFilter=v; v4CatalogPage=0;}), width: 175),
          filterDropdown(categoryFilter, ['Semua kategori', ...cats],
            (v) => v4Change(() {categoryFilter=v; v4CatalogPage=0;}), width: 225),
          filterDropdown(v4LocationFilter, ['Semua lokasi', ...store.locations],
            (v) => v4Change(() {v4LocationFilter=v; v4CatalogPage=0;}), width: 195),
          filterDropdown(v4ConditionFilter, const ['Semua kondisi','Baru','Baik',
            'Cukup','Kurang Baik','Rusak'],
            (v) => v4Change(() {v4ConditionFilter=v; v4CatalogPage=0;}), width: 170),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 7, runSpacing: 3, children: [
          FilterChip(label: const Text('Belum ada PIC'), selected: v4NoPic,
            onSelected: (v) => v4Change(() {v4NoPic=v; v4CatalogPage=0;})),
          FilterChip(label: const Text('Belum ada foto'), selected: v4NoPhoto,
            onSelected: (v) => v4Change(() {v4NoPhoto=v; v4CatalogPage=0;})),
          FilterChip(label: const Text('Perlu perhatian'), selected: v4Attention,
            onSelected: (v) => v4Change(() {v4Attention=v; v4CatalogPage=0;})),
          FilterChip(label: const Text('Perlu klasifikasi'), selected: v4NeedsClassification,
            onSelected: (v) => v4Change(() {v4NeedsClassification=v; v4CatalogPage=0;})),
        ]),
      ])),
      const SizedBox(height: 12),
      surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        sectionHeader('Daftar Aset', subtitle: items.length.toString() + ' aset'),
        Row(children: [
          const Text('Urutkan: ', style: TextStyle(fontSize: 12)),
          DropdownButton<String>(value: v4Sort, items: ['Kode','Nama','Kategori',
            'Lokasi','Kondisi','Status'].map((v) =>
            DropdownMenuItem(value:v,child:Text(v))).toList(),
            onChanged: (v) => v4Change(() {v4Sort=v ?? 'Kode';v4CatalogPage=0;})),
          IconButton(tooltip:'Balik urutan', onPressed: () =>
            v4Change(() => v4SortAscending = !v4SortAscending),
            icon: Icon(v4SortAscending ? Icons.arrow_upward : Icons.arrow_downward)),
        ]),
        LayoutBuilder(builder: (context, box) {
          if (box.maxWidth < 800) return Column(children: [
            for (final a in slice) Padding(padding: const EdgeInsets.only(bottom: 10),
              child: assetMiniCard(a)),
          ]);
          return SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 19, dataRowMinHeight: 65, dataRowMaxHeight: 73,
              columns: const [
                DataColumn(label:Text('ASET')), DataColumn(label:Text('KODE')),
                DataColumn(label:Text('KATEGORI')), DataColumn(label:Text('LOKASI / PIC')),
                DataColumn(label:Text('KONDISI')), DataColumn(label:Text('STATUS')),
                DataColumn(label:Text('TINDAKAN')),
              ],
              rows: [for (final a in slice) DataRow(cells: [
                DataCell(SizedBox(width: 225, child: Row(children: [
                  assetThumbnail(a,size:42), const SizedBox(width:9),
                  Expanded(child: Column(mainAxisAlignment:MainAxisAlignment.center,
                    crossAxisAlignment:CrossAxisAlignment.start,children: [
                    Text(a.name,maxLines:1,overflow:TextOverflow.ellipsis,
                      style:const TextStyle(fontWeight:FontWeight.bold)),
                    Text(a.assetType,maxLines:1,overflow:TextOverflow.ellipsis),
                  ])),
                ])),onTap:() => v4Change(() => selected=a)),
                DataCell(SelectableText(a.code)),
                DataCell(SizedBox(width:180,child:Text(a.category,maxLines:2))),
                DataCell(SizedBox(width:175,child:Column(
                  mainAxisAlignment:MainAxisAlignment.center,
                  crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text(a.location,maxLines:1,overflow:TextOverflow.ellipsis),
                    Text(a.holder.isEmpty ? 'PIC belum ditetapkan' : a.holder,
                      maxLines:1,overflow:TextOverflow.ellipsis,
                      style:TextStyle(fontSize:11,color:a.holder.isEmpty ? danger : muted)),
                  ]))),
                DataCell(Text(a.condition)),
                DataCell(badge(a.status,compact:true)),
                DataCell(PopupMenuButton<String>(
                  onSelected:(v) {
                    if(v=='detail') v4Change(() => selected=a);
                    if(v=='mutasi') v4Transfer(a);
                    if(v=='copy') Clipboard.setData(ClipboardData(text:a.code));
                  },
                  itemBuilder:(_) => const [
                    PopupMenuItem(value:'detail',child:Text('Lihat Detail')),
                    PopupMenuItem(value:'mutasi',child:Text('Mutasi Aset')),
                    PopupMenuItem(value:'copy',child:Text('Salin Kode')),
                  ],child:const Icon(Icons.more_horiz))),
              ])],
            ));
        }),
        const Divider(height:20),
        Row(children: [
          Text('Halaman ' + (v4CatalogPage+1).toString() + ' / ' + pages.toString()),
          const Spacer(),
          DropdownButton<int>(value:v4PerPage,items:[20,40,80].map((n) =>
            DropdownMenuItem(value:n,child:Text(n.toString()+' / halaman'))).toList(),
            onChanged:(v) => v4Change(() {v4PerPage=v ?? 20;v4CatalogPage=0;})),
          IconButton(onPressed:v4CatalogPage==0 ? null :
            () => v4Change(() => v4CatalogPage--),
            icon:const Icon(Icons.chevron_left)),
          IconButton(onPressed:v4CatalogPage>=pages-1 ? null :
            () => v4Change(() => v4CatalogPage++),
            icon:const Icon(Icons.chevron_right)),
        ]),
      ])),
    ]);
  }
}
