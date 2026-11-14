part of 'main.dart';

class V4RegistrationPage extends StatefulWidget {
  final AssetStore store;
  final void Function(List<AssetRecord>) onCompleted;
  final VoidCallback? onDirty;
  const V4RegistrationPage({super.key,required this.store,required this.onCompleted,this.onDirty});
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
  bool costUnknown=true,dateUnknown=true,saving=false;
  int mobileStep=0;
  @override void dispose(){
    for(final c in [name,brand,model,serial,holder,cost,date,quantity]){c.dispose();}
    super.dispose();
  }

  Widget field(TextEditingController c,String label,{bool required=false,
      TextInputType? keyboard, bool enabled=true})=>TextFormField(
    controller:c,keyboardType:keyboard,enabled:enabled,
    onChanged: (_) => widget.onDirty?.call(),
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
    validator:(v)=>v==null?'Wajib dipilih':null,
    onChanged:(v) { widget.onDirty?.call(); change(v); });

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
      onChanged: (v) { widget.onDirty?.call(); changed(v); },
    );

  Widget pairs(Widget a,Widget b,bool narrow){
    if(narrow) { return Column(children:[a,const SizedBox(height:12),b]); }
    return Row(children:[Expanded(child:a),const SizedBox(width:12),Expanded(child:b)]);
  }

  Future<void> selectPhoto([BuildContext? anchor]) async {
    final selected = await AssetPhotoPicker.choose(context,
      anchorContext: anchor);
    if (selected == null || !mounted) return;
    widget.onDirty?.call();
    setState(() { pendingPhoto = selected.bytes; pendingName = selected.fileName; });
  }

  String? stepError(int step) {
    if (step == 0) {
      if (name.text.trim().isEmpty || category == null || sub == null || kind == null) {
        return 'Lengkapi nama, kategori, subkategori, dan jenis aset.';
      }
    } else if (step == 1) {
      if (!dateUnknown && (date.text.trim().isEmpty ||
          !validAssetAcquisitionDate(date.text))) {
        return 'Isi tanggal YYYY-MM-DD valid atau centang belum diketahui.';
      }
      if (!costUnknown && (int.tryParse(cost.text.trim()) == null ||
          int.parse(cost.text.trim()) < 0)) {
        return 'Isi nilai perolehan angka tidak negatif atau centang belum diketahui.';
      }
    } else if (step == 2) {
      final count = int.tryParse(quantity.text.trim());
      if (location == null || status == null || condition == null ||
          count == null || count < 1 || count > 100) {
        return 'Pilih lokasi, status, kondisi, dan jumlah unit 1–100.';
      }
    } else if (step == 3) {
      if ((int.tryParse(quantity.text.trim()) ?? 1) > 1 && pendingPhoto != null) {
        return 'Foto dicatat per unit. Hapus foto pilihan atau ubah jumlah menjadi 1.';
      }
    }
    return null;
  }

  void mobileNext() {
    final message = stepError(mobileStep);
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      keyForm.currentState?.validate();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => mobileStep++);
  }

  Future<void> save()async{
    if (saving) return;
    for (var step = 0; step < 4; step++) {
      final message = stepError(step);
      if (message != null) {
        if (MediaQuery.sizeOf(context).width < 650) {
          setState(() => mobileStep = step);
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        return;
      }
    }
    if (MediaQuery.sizeOf(context).width >= 650 &&
        !keyForm.currentState!.validate()) { return; }
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
        cost:value,acquisitionDate:dateUnknown ? '' : date.text.trim(),
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
    final mobile=MediaQuery.sizeOf(context).width<650;
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
      if (mobile) ...[
        Text('Langkah ' + (mobileStep + 1).toString() + ' dari 4 · ' +
          ['Identitas Aset','Perolehan Aset','Penempatan Awal','Dokumentasi Foto'][mobileStep],
          style:const TextStyle(color:ink,fontWeight:FontWeight.w700)),
        const SizedBox(height:10),
        LinearProgressIndicator(value:(mobileStep + 1)/4,
          minHeight:6,borderRadius:BorderRadius.circular(8)),
        const SizedBox(height:14),
      ],
      if (!mobile || mobileStep == 0)
      Card(child:Padding(padding:EdgeInsets.all(mobile ? 14 : 20),child:Column(
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
      if (!mobile || mobileStep == 1)
      Card(child:Padding(padding:EdgeInsets.all(mobile ? 14 : 20),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('PEROLEHAN ASET',
            style:TextStyle(fontSize:13,fontWeight:FontWeight.bold)),
          const SizedBox(height:13),
          pairs(
            Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              field(date,'Tanggal Perolehan (YYYY-MM-DD)',
                keyboard:TextInputType.datetime,enabled:!dateUnknown),
              CheckboxListTile(
                key:const ValueKey('rv24-date-unknown'),
                value:dateUnknown,dense:true,
                contentPadding:EdgeInsets.zero,
                controlAffinity:ListTileControlAffinity.leading,
                title:const Text('Tanggal perolehan belum diketahui',
                  style:TextStyle(fontSize:13)),
                onChanged:(v) {
                  widget.onDirty?.call();
                  setState(()=>dateUnknown=v??false);
                }),
            ]),
            Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              field(cost,'Nilai Perolehan (Rp)',
                keyboard:TextInputType.number,enabled:!costUnknown),
              CheckboxListTile(
                key:const ValueKey('rv24-value-unknown'),
                value:costUnknown,dense:true,
                contentPadding:EdgeInsets.zero,
                controlAffinity:ListTileControlAffinity.leading,
                title:const Text('Nilai perolehan belum diketahui',
                  style:TextStyle(fontSize:13)),
                onChanged:(v) {
                  widget.onDirty?.call();
                  setState(()=>costUnknown=v??false);
                }),
            ]),narrow),
        ]))),
      const SizedBox(height:12),
      if (!mobile || mobileStep == 2)
      Card(child:Padding(padding:EdgeInsets.all(mobile ? 14 : 20),child:Column(
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
                  ?.areas.where((a)=>a.active) ?? <AssetArea>[]))
                  a.id: a.name,
              }, (v)=>setState(() { areaId=v??''; spotId=''; })),
            optionalPlace('Titik Penempatan (opsional)',spotId,
              {
                for (final a in (widget.store.siteByName(location??'')
                  ?.areas ?? <AssetArea>[]))
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
      if (!mobile || mobileStep == 3)
      Card(child:Padding(padding:EdgeInsets.all(mobile ? 14 : 20),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('DOKUMENTASI FOTO',
            style:TextStyle(fontSize:13,fontWeight:FontWeight.bold)),
          const SizedBox(height:12),
          const Text('Foto opsional. Untuk registrasi beberapa unit, unggah foto setiap unit setelah disimpan.'),
          const SizedBox(height:12),
          if(pendingPhoto!=null)Image.memory(pendingPhoto!,height:180,fit:BoxFit.contain),
          if (pendingPhoto != null) TextButton.icon(
            onPressed: () { widget.onDirty?.call(); setState(() {
              pendingPhoto=null; pendingName='';
            }); },
            icon:const Icon(Icons.delete_outline),
            label:const Text('Hapus Foto Pilihan')),
          const SizedBox(height:10),
          Builder(builder:(photoAnchor)=>OutlinedButton.icon(
             onPressed:()=>selectPhoto(photoAnchor),
             icon:const Icon(Icons.add_a_photo_outlined),
             label:Text(pendingPhoto==null?'Pilih Foto Aktual':'Ganti Foto'))),
        ]))),
      const SizedBox(height:14),
      if (mobile)
        Row(children: [
          if (mobileStep > 0) ...[
            OutlinedButton.icon(
              key:const ValueKey('rv26-prev-step'),
              onPressed:saving?null:()=>setState(()=>mobileStep--),
              icon:const Icon(Icons.arrow_back,size:18),
              label:const Text('Kembali')),
            const SizedBox(width:8),
          ],
          Expanded(child:FilledButton.icon(
            key:const ValueKey('rv26-next-step'),
            onPressed:saving?null:(mobileStep == 3 ? save : mobileNext),
            icon:Icon(mobileStep==3 ? Icons.save_outlined : Icons.arrow_forward),
            label:Text(saving?'Menyimpan...':
              mobileStep==3?'Simpan Registrasi':'Berikutnya'))),
        ])
      else
        Row(mainAxisAlignment:MainAxisAlignment.end,children:[
          FilledButton.icon(onPressed:saving?null:save,
            icon:const Icon(Icons.save_outlined),
            label:Text(saving?'Menyimpan...':'Simpan Registrasi')),
        ]),
    ]));
  }
}
