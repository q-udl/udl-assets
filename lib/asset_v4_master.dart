part of 'main.dart';

extension _AssetV4Master on _AssetScreenState {
  Future<void> v4MasterPrompt(
    String title, String initial,
    Future<void> Function(String) onSave,
  ) async {
    final controller = TextEditingController(text: initial);
    var error = '';
    final value = await v4ShowModal<String>(
      title: title,
      subtitle: 'Master Data UDL Assets',
      maxWidth: 520,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: controller,
            autofocus: true,
            decoration: v4ModalDecoration('Nama *')),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12), v4ModalError(error),
          ],
        ],
      ),
      actions: (ctx, update) => [
        OutlinedButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal')),
        FilledButton(onPressed: () {
          if (controller.text.trim().isEmpty) {
            update(() => error = 'Nama tidak boleh kosong.');
          } else {
            Navigator.pop(ctx, controller.text.trim());
          }
        }, child: const Text('Simpan')),
      ],
    );
    if (value != null && value.isNotEmpty) {
      try {
        await onSave(value);
        repaint();
      } catch (e) {
        notify('Gagal: ' + e.toString());
      }
    }
    controller.dispose();
  }

  Widget v4MasterPanel(String title,String addLabel,VoidCallback? action,List<Widget> items) =>
    surface(padding:const EdgeInsets.all(12),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        Expanded(child:Text(title,style:const TextStyle(fontSize:15,fontWeight:FontWeight.bold))),
        IconButton(tooltip:addLabel,onPressed:action,icon:const Icon(Icons.add_circle_outline)),
      ]),
      const Divider(),
      ConstrainedBox(constraints:const BoxConstraints(maxHeight:465),
        child:ListView(shrinkWrap:true,children:items)),
    ]));

  Widget v4Taxonomy() {
    final matching = store.categories.where((c) {
      final q = v4TaxonomySearch.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
        c.subcategories.any((s) => s.name.toLowerCase().contains(q) ||
          s.types.any((t) => t.toLowerCase().contains(q)));
    }).toList();
    AssetCategory? cat;
    for(final c in matching) {
      if(c.code == v4CategoryCode) cat=c;
    }
    cat ??= matching.isEmpty ? null : matching.first;
    AssetSubcategory? sub;
    if(cat!=null) {
      for(final s in cat.subcategories) {
        if(s.id == v4SubcategoryId) sub=s;
      }
      sub ??= cat.subcategories.isEmpty ? null : cat.subcategories.first;
    }
    final current=cat, chosen=sub;
    final panels=<Widget>[
      v4MasterPanel('Kategori','Tambah Kategori',
        () => v4MasterPrompt('Tambah Kategori','',store.addCategory),
        [for(final c in matching) ListTile(
          selected:current?.code==c.code,dense:true,
          title:Text(c.name,maxLines:2,overflow:TextOverflow.ellipsis),
          subtitle:Text(c.code+' · '+
            store.assets.where((a)=>a.categoryId==c.code || a.category==c.name).length.toString()+
            ' aset'+(c.active ? '' : ' · Nonaktif')),
          onTap:()=>v4Change(() {v4CategoryCode=c.code;v4SubcategoryId='';}),
          trailing:PopupMenuButton<String>(
            onSelected:(action) {
              if(action=='rename') {
                v4MasterPrompt('Ubah Kategori',c.name,(name)=>store.renameCategory(c,name));
              } else {
                store.setClassificationActive(c,null,null,!c.active).then((_)=>repaint())
                  .catchError((Object e)=>notify(e.toString()));
              }
            },
            itemBuilder:(_) => [
              const PopupMenuItem(value:'rename',child:Text('Ubah Nama')),
              PopupMenuItem(value:'toggle',child:Text(c.active ? 'Nonaktifkan' : 'Aktifkan')),
            ]),
        )]),
      v4MasterPanel('Subkategori','Tambah Subkategori',
        current==null ? null : () => v4MasterPrompt('Tambah Subkategori','',
          (name)=>store.addSubcategory(current,name)),
        [if(current!=null) for(final s in current.subcategories) ListTile(
          selected:chosen?.id==s.id,dense:true,
          title:Text(s.name),
          subtitle:Text(store.assets.where((a)=>a.categoryId==current.code &&
            (a.subcategoryId==s.id || a.subcategory==s.name)).length.toString()+
            ' aset'+(s.active ? '' : ' · Nonaktif')),
          onTap:()=>v4Change(()=>v4SubcategoryId=s.id),
          trailing:PopupMenuButton<String>(
            onSelected:(action) {
              if(action=='rename') {
                v4MasterPrompt('Ubah Subkategori',s.name,
                  (name)=>store.renameSubcategory(current,s,name));
              } else {
                store.setClassificationActive(current,s,null,!s.active)
                  .then((_)=>repaint()).catchError((Object e)=>notify(e.toString()));
              }
            },
            itemBuilder:(_) => [
              const PopupMenuItem(value:'rename',child:Text('Ubah Nama')),
              PopupMenuItem(value:'toggle',child:Text(s.active ? 'Nonaktifkan' : 'Aktifkan')),
            ]),
        )]),
      v4MasterPanel('Jenis Aset','Tambah Jenis',
        current==null || chosen==null ? null : () =>
          v4MasterPrompt('Tambah Jenis','',(name)=>store.addType(current,chosen,name)),
        [if(current!=null && chosen!=null) for(final t in chosen.types) ListTile(
          dense:true,
          title:Text(t),
          subtitle:Text(store.assets.where((a)=>a.categoryId==current.code &&
            a.subcategoryId==chosen.id && a.assetType==t).length.toString()+
            ' aset'+(chosen.typeIsActive(t) ? '' : ' · Nonaktif')),
          onTap:()=>openAssetListFromMaster(
            category: current.name, type: t),
          trailing:PopupMenuButton<String>(
            onSelected:(action) {
              if(action=='rename') {
                v4MasterPrompt('Ubah Jenis',t,
                  (name)=>store.renameAssetType(current,chosen,t,name));
              } else {
                store.setClassificationActive(current,chosen,t,!chosen.typeIsActive(t))
                  .then((_)=>repaint()).catchError((Object e)=>notify(e.toString()));
              }
            },
            itemBuilder:(_) => [
              const PopupMenuItem(value:'rename',child:Text('Ubah Nama')),
              PopupMenuItem(value:'toggle',
                child:Text(chosen.typeIsActive(t) ? 'Nonaktifkan' : 'Aktifkan')),
            ]),
        )]),
    ];
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      surface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        sectionHeader('Master Klasifikasi Aset',
          subtitle:'Kelola kategori, subkategori, dan jenis aset operasional'),
        const SizedBox(height:12),
        TextField(decoration:const InputDecoration(
          hintText:'Cari klasifikasi...',prefixIcon:Icon(Icons.search)),
          onChanged:(v)=>v4Change(()=>v4TaxonomySearch=v)),
        const SizedBox(height:8),
        Text(store.categories.length.toString()+
          ' kategori · klasifikasi nonaktif tidak tersedia untuk registrasi baru',
          style:const TextStyle(fontSize:11,color:muted)),
      ])),
      const SizedBox(height:12),
      LayoutBuilder(builder:(context,box) {
        if(box.maxWidth<850) { return Column(children:[
          for(final panel in panels) Padding(
            padding:const EdgeInsets.only(bottom:12),child:panel),
        ]); }
        return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(child:panels[0]),const SizedBox(width:12),
          Expanded(child:panels[1]),const SizedBox(width:12),
          Expanded(child:panels[2]),
        ]);
      }),
    ]);
  }

  Widget v4Locations() => surface(child:Column(
    crossAxisAlignment:CrossAxisAlignment.start,children:[
    sectionHeader('Master Lokasi',
      subtitle:'Lokasi terstandar; data aset lama tetap dipertahankan'),
    const SizedBox(height:12),
    outlineButton('Tambah Lokasi',Icons.add_location_alt_outlined,
      ()=>v4MasterPrompt('Tambah Lokasi','',store.addLocation)),
    const SizedBox(height:14),
    for(final location in store.locations) ListTile(
      leading:const Icon(Icons.place_outlined),
      title:Text(location),
      subtitle:Text(store.assets.where((a)=>a.location==location).length.toString()+' aset'),
      onTap:()=>openAssetListFromMaster(location: location),
      trailing:const Icon(Icons.chevron_right)),
  ]));
}
