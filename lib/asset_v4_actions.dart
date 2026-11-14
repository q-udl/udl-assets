part of 'main.dart';

extension AssetV4Actions on _AssetScreenState {
  Future<void> v4Transfer(AssetRecord a) async {
    var destination=store.locations.contains(a.location)?a.location:store.locations.first;
    final receiver=TextEditingController(text:a.holder),reason=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>
      StatefulBuilder(builder:(ctx,update)=>AlertDialog(
        title:const Text('Mutasi Aset'),
        content:SizedBox(width:520,child:SingleChildScrollView(child:Column(
          mainAxisSize:MainAxisSize.min,
          crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(a.name+' · '+a.code),
          const SizedBox(height:13),
          Text('Lokasi asal: '+a.location),
          Text('PIC sebelumnya: '+(a.holder.isEmpty?'Belum ditetapkan':a.holder)),
          const SizedBox(height:12),
          DropdownButtonFormField<String>(
            initialValue:destination,isExpanded:true,
            decoration:const InputDecoration(labelText:'Lokasi tujuan *'),
            items:store.locations.map((v)=>DropdownMenuItem(
              value:v,child:Text(v))).toList(),
            onChanged:(v)=>update(()=>destination=v??destination)),
          const SizedBox(height:12),
          TextField(controller:receiver,
            decoration:const InputDecoration(labelText:'Penanggung jawab baru')),
          const SizedBox(height:12),
          TextField(controller:reason,maxLines:3,
            decoration:const InputDecoration(labelText:'Alasan mutasi *')),
          const SizedBox(height:8),
          const Text('Perubahan lokasi/PIC belum berlaku sebelum serah terima '
            'dikonfirmasi dalam simulasi lokal.',
            style:TextStyle(fontSize:11,color:Color(0xFF718199))),
        ]))),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:const Text('Ajukan Mutasi')),
        ])));
    if(ok==true){
      try{
        await store.proposeTransfer(a,destination,receiver.text,reason.text);
        repaint();notify('Mutasi tercatat menunggu serah terima simulasi.');
      }catch(e){notify('Mutasi gagal: '+e.toString());}
    }
    receiver.dispose();reason.dispose();
  }

  Future<void> v4RespondTransfer(AssetTransfer transfer) async {
    final a=assetFor(transfer.assetId);
    if(a==null)return;
    final note=TextEditingController();
    final response=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Konfirmasi Serah Terima — Simulasi'),
      content:Column(mainAxisSize:MainAxisSize.min,
        crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Aset: '+a.name),
        Text('Asal: '+transfer.fromLocation+' · '+transfer.fromHolder),
        Text('Tujuan: '+transfer.toLocation+' · '+transfer.toHolder),
        const SizedBox(height:10),
        TextField(controller:note,maxLines:2,
          decoration:const InputDecoration(labelText:'Catatan penerimaan / penolakan')),
        const SizedBox(height:8),
        const Text('Tombol ini adalah simulasi operator, bukan tanda tangan '
          'atau persetujuan penerima terverifikasi.',
          style:TextStyle(fontSize:11,color:Color(0xFF718199))),
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),
        TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Tolak')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),
          child:const Text('Terima (Simulasi)')),
      ]));
    if(response!=null){
      try{await store.confirmTransfer(transfer,response,note.text);repaint();}
      catch(e){notify(e.toString());}
    }
    note.dispose();
  }

  Future<void> v4UploadPhoto(AssetRecord a) async {
    var kind=AssetStore.photoKinds.first;
    final note=TextEditingController();
    final confirmed=await showDialog<bool>(context:context,builder:(ctx)=>
      StatefulBuilder(builder:(ctx,update)=>AlertDialog(
        title:const Text('Tambah Dokumentasi Foto'),
        content:Column(mainAxisSize:MainAxisSize.min,children:[
          DropdownButtonFormField<String>(initialValue:kind,isExpanded:true,
            decoration:const InputDecoration(labelText:'Jenis dokumentasi'),
            items:AssetStore.photoKinds.map((v)=>
              DropdownMenuItem(value:v,child:Text(v))).toList(),
            onChanged:(v)=>update(()=>kind=v??kind)),
          const SizedBox(height:10),
          TextField(controller:note,maxLines:2,
            decoration:const InputDecoration(labelText:'Keterangan foto (opsional)')),
        ]),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:const Text('Pilih Foto')),
        ])));
    if(confirmed==true){
      try{
        final picked=await ImagePicker().pickImage(source:ImageSource.gallery,
          maxWidth:960,maxHeight:960,imageQuality:65);
        if(picked!=null){
          final bytes=await picked.readAsBytes();
          if(!mounted)return;
          final preview=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
            title:const Text('Pratinjau Dokumentasi'),
            content:SizedBox(width:480,child:Column(
              mainAxisSize:MainAxisSize.min,children:[
                Image.memory(bytes,height:235,fit:BoxFit.contain),
                const SizedBox(height:8),Text(kind),
                if(note.text.isNotEmpty)Text(note.text),
              ])),
            actions:[
              TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),
              FilledButton(onPressed:()=>Navigator.pop(ctx,true),
                child:const Text('Simpan Foto')),
            ]));
          if(preview==true){
            await store.addPhoto(a,bytes,picked.name,kind,note:note.text);
            repaint();notify('Foto dokumentasi ditambahkan');
          }
        }
      }catch(e){notify('Foto gagal disimpan: '+e.toString());}
    }
    note.dispose();
  }

  Future<void> v4PhotoViewer(AssetRecord a,AssetPhoto photo) async {
    await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(
      title:Text(photo.kind),
      content:SizedBox(width:620,child:SingleChildScrollView(child:Column(
        mainAxisSize:MainAxisSize.min,children:[
          Image.memory(photo.bytes,height:350,fit:BoxFit.contain),
          const SizedBox(height:9),
          Text(photo.fileName+' · '+dateText(photo.timestamp)),
          if(photo.note.isNotEmpty)Text(photo.note),
          if(photo.isPrimary)const Chip(label:Text('Foto Utama')),
        ]))),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx),
          child:const Text('Tutup')),
        if(!photo.isPrimary)TextButton(
          onPressed:(){
            Navigator.pop(ctx);
            store.setPrimaryPhoto(a,photo).then((_)=>repaint())
              .catchError((Object e)=>notify(e.toString()));
          },
          child:const Text('Jadikan Utama')),
        TextButton(onPressed:(){
          Navigator.pop(ctx);v4ArchivePhoto(a,photo);
        },child:const Text('Arsipkan / Koreksi')),
      ]));
  }

  Future<void> v4ArchivePhoto(AssetRecord a,AssetPhoto photo) async {
    final reason=TextEditingController();
    final confirmed=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Arsipkan Dokumentasi'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        const Text('Foto tidak dihapus permanen. Riwayat dan foto lama tetap disimpan.'),
        TextField(controller:reason,maxLines:2,
          decoration:const InputDecoration(labelText:'Alasan pengarsipan *')),
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),
          child:const Text('Arsipkan')),
      ]));
    if(confirmed==true){
      try{await store.archivePhoto(a,photo,reason.text);repaint();}
      catch(e){notify(e.toString());}
    }
    reason.dispose();
  }

  Future<void> v4ArchivedPhotos(AssetRecord a) async {
    await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Dokumentasi Diarsipkan'),
      content:SizedBox(width:500,child:SingleChildScrollView(
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          for(final p in store.archivedPhotosFor(a.id))ListTile(
            leading:Image.memory(p.bytes,width:48,height:48,fit:BoxFit.cover),
            title:Text(p.fileName),
            subtitle:Text(p.archivedReason),
          ),
        ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Tutup'))],
    ));
  }
}
