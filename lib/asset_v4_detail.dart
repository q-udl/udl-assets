part of 'main.dart';

extension AssetV4Detail on _AssetScreenState {
  Widget v4Detail(AssetRecord a) {
    final photos=store.photosFor(a.id);
    final primary=store.primaryPhotoFor(a.id);
    final pending=store.transfers.where((t)=>t.assetId==a.id &&
      t.state=='Menunggu Penerimaan').toList();
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      surface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(a.name,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
        const SizedBox(height:5),
        SelectableText(a.code,style:const TextStyle(color:blue,fontWeight:FontWeight.bold)),
        const SizedBox(height:9),
        Wrap(spacing:8,runSpacing:8,children:[
          badge(a.status,compact:true),
          Chip(label:Text('Kondisi: '+a.condition)),
          if(photos.isEmpty)const Chip(label:Text('Foto belum lengkap')),
        ]),
        const SizedBox(height:10),
        Wrap(spacing:8,runSpacing:8,children:[
          if(a.status!='Dihapuskan')...[
            primaryButton('Mutasi Aset',Icons.swap_horiz_rounded,()=>v4Transfer(a)),
            outlineButton('Ubah Informasi',Icons.edit_outlined,()=>v4EditIdentity(a)),
            outlineButton('Ubah Kondisi',Icons.build_outlined,()=>v4Condition(a)),
            outlineButton('Ubah Status',Icons.flag_outlined,()=>v4Status(a)),
          ],
          outlineButton('Lihat QR',Icons.qr_code_2,()=>v4QrDialog(a)),
        ]),
        if(pending.isNotEmpty)...[
          const Divider(height:28),
          Text('Serah terima menunggu penerimaan (simulasi lokal)',
            style:const TextStyle(fontWeight:FontWeight.bold,color:amber)),
          Text('Tujuan: '+pending.first.toLocation+' · Penerima: '+
            pending.first.toHolder),
          const SizedBox(height:8),
          outlineButton('Proses Serah Terima',Icons.fact_check_outlined,
            ()=>v4RespondTransfer(pending.first)),
        ],
      ])),
      const SizedBox(height:14),
      LayoutBuilder(builder:(ctx,box) {
        final photo=v4PhotoCard(a,primary,photos);
        final info=v4InfoCard(a);
        if(box.maxWidth<820)return Column(children:[
          info,const SizedBox(height:14),photo,
        ]);
        return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(child:info),const SizedBox(width:14),Expanded(child:photo),
        ]);
      }),
      const SizedBox(height:14),
      surface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        sectionHeader('Riwayat Aset',subtitle:'Peristiwa terkait '+a.code),
        const SizedBox(height:8),
        for(final e in store.events.where((e)=>e.assetId==a.id))
          ListTile(leading:Icon(v4EventIcon(e.type)),
            title:Text(e.type),subtitle:Text(e.detail,maxLines:1,
              overflow:TextOverflow.ellipsis),
            trailing:Text(dateText(e.timestamp),
              style:const TextStyle(fontSize:11,color:muted)),
            onTap:()=>v4EventDetail(e)),
      ])),
    ]);
  }

  Widget v4InfoCard(AssetRecord a) => surface(child:Column(
    crossAxisAlignment:CrossAxisAlignment.start,children:[
    sectionHeader('Identitas & Penempatan'),
    const SizedBox(height:12),
    detailValue('Lokasi saat ini',a.location),
    detailValue('Penanggung jawab',a.holder.isEmpty?'Belum ditetapkan':a.holder),
    detailValue('Kategori',a.category),
    detailValue('Subkategori',a.subcategory),
    detailValue('Jenis aset',a.assetType),
    detailValue('Merek',a.brand),
    detailValue('Model / tipe',a.model),
    detailValue('Nomor seri',a.serial),
    detailValue('Tanggal perolehan',a.acquisitionDate),
    detailValue('Nilai perolehan',
      a.acquisitionCost==null?'Belum diketahui':rupiah(a.acquisitionCost!)),
    const SizedBox(height:12),
    if(a.status!='Dihapuskan')outlineButton(
      'Ubah Klasifikasi',Icons.account_tree_outlined,()=>reclassifyAsset(a)),
  ]));

  Widget v4PhotoCard(AssetRecord a,AssetPhoto? primary,List<AssetPhoto> photos) =>
    surface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    sectionHeader('Dokumentasi Foto',
      subtitle:photos.length.toString()+' / 8 foto aktif · dokumentasi fisik per unit'),
    const SizedBox(height:12),
    InkWell(onTap:primary==null?null:()=>v4PhotoViewer(a,primary),
      child:Container(height:primary==null?155:230,width:double.infinity,
        decoration:BoxDecoration(color:const Color(0xFFF1F5FA),
          borderRadius:BorderRadius.circular(12)),
        child:primary==null?const Column(mainAxisAlignment:MainAxisAlignment.center,
          children:[
          Icon(Icons.image_outlined,size:35,color:muted),
          Text('Belum ada foto aktual',style:TextStyle(color:muted)),
        ]):ClipRRect(borderRadius:BorderRadius.circular(12),
          child:Image.memory(primary.bytes,fit:BoxFit.contain)))),
    const SizedBox(height:10),
    Wrap(spacing:8,runSpacing:8,children:[
      for(final p in photos) InkWell(onTap:()=>v4PhotoViewer(a,p),
        child:Container(width:65,height:65,
          decoration:BoxDecoration(border:Border.all(
            color:p.isPrimary?blue:border,width:p.isPrimary?2:1),
            borderRadius:BorderRadius.circular(8)),
          child:ClipRRect(borderRadius:BorderRadius.circular(7),
            child:Image.memory(p.bytes,fit:BoxFit.cover)))),
    ]),
    const SizedBox(height:10),
    outlineButton('Tambah Foto',Icons.add_a_photo_outlined,()=>v4UploadPhoto(a)),
    if(store.archivedPhotosFor(a.id).isNotEmpty)TextButton(
      onPressed:()=>v4ArchivedPhotos(a),
      child:Text('Lihat Foto Diarsipkan ('+
        store.archivedPhotosFor(a.id).length.toString()+')')),
  ]));

  Future<void> v4QrDialog(AssetRecord a) => showDialog<void>(
    context:context,builder:(ctx)=>AlertDialog(
    title:const Text('Identitas QR Aset'),
    content:Column(mainAxisSize:MainAxisSize.min,children:[
      QrImageView(data:a.code,size:190),
      SelectableText(a.code),
      const SizedBox(height:8),
      const Text('QR lokal berisi kode aset, belum URL yang diautentikasi.',
        style:TextStyle(fontSize:11)),
    ]),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Tutup')),
      TextButton(onPressed:(){
        Clipboard.setData(ClipboardData(text:a.code));Navigator.pop(ctx);
      },child:const Text('Salin Kode')),
    ]));

  Future<void> v4EditIdentity(AssetRecord a) async {
    final name=TextEditingController(text:a.name),brand=TextEditingController(text:a.brand),
      model=TextEditingController(text:a.model),serial=TextEditingController(text:a.serial),
      cost=TextEditingController(text:a.acquisitionCost?.toString()??''),
      reason=TextEditingController();
    var unknown=a.acquisitionCost==null;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>
      StatefulBuilder(builder:(ctx,update)=>AlertDialog(
        title:const Text('Ubah Informasi Aset'),
        content:SizedBox(width:520,child:SingleChildScrollView(child:Column(
          mainAxisSize:MainAxisSize.min,children:[
          TextField(controller:name,decoration:const InputDecoration(labelText:'Nama aset *')),
          const SizedBox(height:9),
          TextField(controller:brand,decoration:const InputDecoration(labelText:'Merek')),
          const SizedBox(height:9),
          TextField(controller:model,decoration:const InputDecoration(labelText:'Model')),
          const SizedBox(height:9),
          TextField(controller:serial,decoration:const InputDecoration(labelText:'Nomor seri')),
          const SizedBox(height:9),
          TextField(controller:cost,keyboardType:TextInputType.number,
            decoration:const InputDecoration(labelText:'Nilai perolehan')),
          CheckboxListTile(value:unknown,title:const Text('Nilai belum diketahui'),
            onChanged:(v)=>update(()=>unknown=v??false)),
          TextField(controller:reason,maxLines:2,
            decoration:const InputDecoration(labelText:'Alasan koreksi *')),
        ]))),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Simpan')),
        ])));
    if(ok==true){
      try{
        final value=unknown?null:int.tryParse(cost.text);
        if(!unknown&&value==null)throw const FormatException('Nilai tidak valid.');
        await store.editIdentity(a,name.text,brand.text,model.text,serial.text,
          value,reason.text);
        repaint();notify('Informasi aset diperbarui');
      }catch(e){notify(e.toString());}
    }
    for(final c in [name,brand,model,serial,cost,reason]){c.dispose();}
  }

  Future<void> v4Condition(AssetRecord a) async {
    var condition=a.condition;
    final reason=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>
      StatefulBuilder(builder:(ctx,update)=>AlertDialog(
        title:const Text('Ubah Kondisi Aset'),
        content:Column(mainAxisSize:MainAxisSize.min,children:[
          Text('Sebelumnya: '+a.condition),
          DropdownButton<String>(value:condition,isExpanded:true,
            items:['Baru','Baik','Cukup','Kurang Baik','Rusak'].map((v)=>
              DropdownMenuItem(value:v,child:Text(v))).toList(),
            onChanged:(v)=>update(()=>condition=v??condition)),
          TextField(controller:reason,maxLines:3,
            decoration:const InputDecoration(labelText:'Alasan / hasil pemeriksaan *')),
        ]),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Simpan')),
        ])));
    if(ok==true){
      try{await store.editCondition(a,condition,reason.text);repaint();}
      catch(e){notify(e.toString());}
    }
    reason.dispose();
  }

  Future<void> v4Status(AssetRecord a) async {
    var status=a.status;
    final reason=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>
      StatefulBuilder(builder:(ctx,update)=>AlertDialog(
        title:const Text('Ubah Status Aset'),
        content:Column(mainAxisSize:MainAxisSize.min,children:[
          Text('Status saat ini: '+a.status),
          DropdownButton<String>(value:status,isExpanded:true,
            items:['Tersedia','Digunakan','Dalam Perbaikan','Hilang','Dihapuskan']
              .map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
            onChanged:(v)=>update(()=>status=v??status)),
          if(status=='Dihapuskan'||status=='Hilang')const Padding(
            padding:EdgeInsets.all(10),child:Text(
              'Perubahan penting: konfirmasi tambahan diperlukan.',
              style:TextStyle(color:danger))),
          TextField(controller:reason,maxLines:3,
            decoration:const InputDecoration(labelText:'Alasan perubahan *')),
        ]),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Lanjutkan')),
        ])));
    if(ok==true){
      var confirmed=true;
      if(status=='Dihapuskan'||status=='Hilang'){
        confirmed=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
          title:const Text('Konfirmasi Perubahan Penting'),
          content:Text('Pastikan perubahan status '+status+
            ' sudah didukung prosedur perusahaan. Prototipe lokal belum mempunyai persetujuan otorisasi.'),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),
            FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Konfirmasi')),
          ]))??false;
      }
      if(confirmed){
        try{await store.editStatus(a,status,reason.text);repaint();}
        catch(e){notify(e.toString());}
      }
    }
    reason.dispose();
  }
}
