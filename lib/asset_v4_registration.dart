part of 'main.dart';

class V4RegistrationPage extends StatefulWidget {
  final AssetStore store;
  final void Function(List<AssetRecord>) onCompleted;
  const V4RegistrationPage({super.key,required this.store,required this.onCompleted});
  @override State<V4RegistrationPage> createState()=>_V4RegistrationPageState();
}

class _V4RegistrationPageState extends State<V4RegistrationPage> {
  final keyForm=GlobalKey<FormState>();
  final name=TextEditingController(),brand=TextEditingController(),
    model=TextEditingController(),serial=TextEditingController(),
    holder=TextEditingController(),cost=TextEditingController(),
    date=TextEditingController(),quantity=TextEditingController(text:'1');
  String? category,sub,kind,location,status,condition;
  String areaId = '', spotId = '';
  Uint8List? pendingPhoto;
  String pendingName='';
  bool costUnknown=false,saving=false;
  @override void dispose(){
    for(final c in [name,brand,model,serial,holder,cost,date,quantity]){c.dispose();}
    super.dispose();
  }

  Widget field(TextEditingController c,String label,{bool required=false,
      TextInputType? keyboard})=>TextFormField(
    controller:c,keyboardType:keyboard,
    decoration:InputDecoration(labelText:label,
      filled:true,fillColor:const Color(0xFFF9FBFD)),
    validator:(v)=>required && (v==null || v.trim().isEmpty)?'Wajib diisi':null);

  Widget choose(String label,String? value,List<String> values,
      void Function(String?) change)=>DropdownButtonFormField<String>(
    key:ValueKey(label+'-'+(value??'')),
    initialValue:value,isExpanded:true,
    decoration:InputDecoration(labelText:label,
      filled:true,fillColor:const Color(0xFFF9FBFD)),
    items:values.map((v)=>DropdownMenuItem(value:v,
      child:Text(v,maxLines:1,overflow:TextOverflow.ellipsis))).toList(),
    validator:(v)=>v==null?'Wajib dipilih':null,onChanged:change);

  Widget optionalPlace(String label, String value,
      Map<String,String> values, void Function(String?) changed) =>
    DropdownButtonFormField<String>(
      key: ValueKey(label + '-' + value),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label,
        filled: true, fillColor: const Color(0xFFF9FBFD)),
      items: [
        const DropdownMenuItem(value: '',
          child: Text('Belum ditentukan')),
        for (final entry in values.entries)
          DropdownMenuItem(value: entry.key,
            child: Text(entry.value, maxLines: 1,
              overflow: TextOverflow.ellipsis)),
      ],
      onChanged: changed,
    );

  Widget pairs(Widget a,Widget b,bool narrow){
    if(narrow) { return Column(children:[a,const SizedBox(height:12),b]); }
    return Row(children:[Expanded(child:a),const SizedBox(width:12),Expanded(child:b)]);
  }

  Future<void> selectPhoto()async{
    final x=await ImagePicker().pickImage(source:ImageSource.gallery,
      maxWidth:960,maxHeight:960,imageQuality:65);
    if(x==null) { return; }
    final bytes=await x.readAsBytes();
    if(bytes.length>AssetStore.maxPhotoBytes){
      if(mounted) { ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('Foto melebihi 500 KB setelah kompresi.'))); }
      return;
    }
    setState((){pendingPhoto=bytes;pendingName=x.name;});
  }

  Future<void> save()async{
    if(!keyForm.currentState!.validate()) { return; }
    final qty=int.tryParse(quantity.text);
    if(qty==null || qty<1 || qty>100){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('Jumlah harus 1–100 unit.')));return;
    }
    final value=costUnknown?null:int.tryParse(cost.text);
    if(!costUnknown && (value==null || value<0)){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('Nilai perolehan harus angka 0 atau lebih.')));return;
    }
    if(qty>1 && pendingPhoto!=null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('Foto setiap unit ditambahkan terpisah setelah registrasi massal.')));
      return;
    }
    setState(()=>saving=true);
    try{
      final created=await widget.store.registerUnits(
        quantity:qty,name:name.text,category:category!,
        subcategory:sub!,assetType:kind!,brand:brand.text,
        model:model.text,serial:serial.text,location:location!,
        holder:holder.text,status:status!,condition:condition!,
        cost:value,acquisitionDate:date.text,
         placement: AssetPlacement(widget.store.siteByName(location!)?.id ?? '',
           areaId: areaId, spotId: spotId));
      if(pendingPhoto!=null && created.length==1){
        try{
          await widget.store.addPhoto(created.single,pendingPhoto!,pendingName,'Tampak Fisik Aset');
        }catch(_){
          // Registration remains valid, and the missing photo can be uploaded on detail.
        }
      }
      if(mounted) { widget.onCompleted(created); }
    }catch(e){
      if(mounted) { ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Registrasi gagal: '+e.toString()))); }
    }finally{
      if(mounted) { setState(()=>saving=false); }
    }
  }

  @override Widget build(BuildContext context){
    final narrow=MediaQuery.sizeOf(context).width<920;
    final validCategories=widget.store.categories.where((c)=>c.active &&
      c.subcategories.any((s)=>s.active && s.types.any(s.typeIsActive))).toList();
    final cat=category==null?null:widget.store.categoryByName(category!);
    final subs=cat?.subcategories.where((s)=>s.active &&
      s.types.any(s.typeIsActive)).toList()??[];
    final selectedSub=sub==null||category==null?null:
      widget.store.subcategoryByName(category!,sub!);
    final types=selectedSub?.types.where(selectedSub.typeIsActive).toList()??[];
    return Form(key:keyForm,child:Column(
      crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('IDENTITAS ASET',
            style:TextStyle(fontSize:13,fontWeight:FontWeight.bold)),
          const SizedBox(height:13),
          field(name,'Nama aset *',required:true),const SizedBox(height:12),
          pairs(choose('Kategori *',category,validCategories.map((c)=>c.name).toList(),
            (v)=>setState((){category=v;sub=null;kind=null;})),
            choose('Subkategori *',sub,subs.map((s)=>s.name).toList(),
              (v)=>setState((){sub=v;kind=null;})),narrow),
          const SizedBox(height:12),
          pairs(choose('Jenis aset *',kind,types,(v)=>setState(()=>kind=v)),
            field(brand,'Merek'),narrow),
          const SizedBox(height:12),
          pairs(field(model,'Model / Tipe'),field(serial,'Nomor seri (unik)'),narrow),
        ]))),
      const SizedBox(height:12),
      Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('PEROLEHAN ASET',
            style:TextStyle(fontSize:13,fontWeight:FontWeight.bold)),
          const SizedBox(height:13),
          pairs(field(date,'Tanggal perolehan (opsional, YYYY-MM-DD)'),
            field(cost,'Nilai perolehan (Rp)',keyboard:TextInputType.number),narrow),
          CheckboxListTile(value:costUnknown,
            title:const Text('Nilai perolehan belum diketahui'),
            contentPadding:EdgeInsets.zero,
            onChanged:(v)=>setState(()=>costUnknown=v??false)),
        ]))),
      const SizedBox(height:12),
      Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('PENEMPATAN AWAL',
            style:TextStyle(fontSize:13,fontWeight:FontWeight.bold)),
          const SizedBox(height:13),
          pairs(choose('Lokasi Utama *',location,
              widget.store.activeSites.map((site)=>site.name).toList(),
              (v)=>setState(() { location=v; areaId=''; spotId=''; })),
            field(holder,'Penanggung jawab (opsional)'),narrow),
          const SizedBox(height:12),
          pairs(optionalPlace('Area (opsional)', areaId,
              {
                for (final a in (widget.store.siteByName(location??'')
                  ?.areas.where((a)=>a.active) ?? <AssetArea>[])
                  a.id: a.name,
              }, (v)=>setState(() { areaId=v??''; spotId=''; })),
            optionalPlace('Titik Penempatan (opsional)',spotId,
              {
                for (final a in (widget.store.siteByName(location??'')
                  ?.areas ?? <AssetArea>[])
                  if (a.id==areaId)
                    for (final spot in a.spots.where((spot)=>spot.active))
                      spot.id: spot.name,
              },(v)=>setState(()=>spotId=v??'')),narrow),
          const SizedBox(height:12),
          pairs(choose('Status *',status,
              ['Tersedia','Digunakan','Dalam Perbaikan','Hilang'],
              (v)=>setState(()=>status=v)),
            choose('Kondisi fisik *',condition,
              ['Baru','Baik','Cukup','Kurang Baik','Rusak'],
              (v)=>setState(()=>condition=v)),narrow),
          const SizedBox(height:12),
          field(quantity,'Jumlah unit (1–100)',keyboard:TextInputType.number),
          const SizedBox(height:6),
          const Text('Setiap unit memperoleh kode permanen berbeda. Nomor seri dan foto dicatat per unit.',
            style:TextStyle(fontSize:11,color:Color(0xFF718199))),
        ]))),
      const SizedBox(height:12),
      Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('DOKUMENTASI FOTO',
            style:TextStyle(fontSize:13,fontWeight:FontWeight.bold)),
          const SizedBox(height:12),
          const Text('Foto opsional. Untuk registrasi beberapa unit, unggah foto setiap unit setelah disimpan.'),
          const SizedBox(height:12),
          if(pendingPhoto!=null)Image.memory(pendingPhoto!,height:180,fit:BoxFit.contain),
          const SizedBox(height:10),
          OutlinedButton.icon(onPressed:selectPhoto,icon:const Icon(Icons.add_a_photo_outlined),
            label:Text(pendingPhoto==null?'Pilih Foto Aktual':'Ganti Foto')),
        ]))),
      const SizedBox(height:14),
      Row(mainAxisAlignment:MainAxisAlignment.end,children:[
        FilledButton.icon(onPressed:saving?null:save,
          icon:const Icon(Icons.save_outlined),
          label:Text(saving?'Menyimpan...':'Simpan Registrasi')),
      ]),
    ]));
  }
}
