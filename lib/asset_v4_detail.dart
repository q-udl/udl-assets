part of 'main.dart';

extension _AssetV4Detail on _AssetScreenState {
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
          badge(a.lifecycle == 'Aktif' ? a.status : a.lifecycle,compact:true),
          Chip(label:Text('Kondisi: '+a.condition)),
          if(photos.isEmpty)const Chip(label:Text('Foto belum lengkap')),
        ]),
        const SizedBox(height:10),
        Wrap(spacing:8,runSpacing:8,children:[
          if(a.lifecycle=='Aktif' && a.status!='Dihapuskan')...[
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
        if(box.maxWidth<820) { return Column(children:[
          info,const SizedBox(height:14),photo,
        ]); }
        return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(child:info),const SizedBox(width:14),Expanded(child:photo),
        ]);
      }),
      const SizedBox(height:14),
      v5CustodyForAsset(a),
      const SizedBox(height:14),
      v6LifecycleCard(a),
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
    detailValue('Lokasi saat ini',store.locationPath(a)),
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
    if(a.lifecycle=='Aktif' && a.status!='Dihapuskan')outlineButton(
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


  Future<void> v4QrDialog(AssetRecord a) async {
    await v4ShowModal<void>(
      title: 'Identitas QR Aset',
      subtitle: a.name + ' · ' + a.code,
      maxWidth: 480,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 226,
              height: 226,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(12),
              ),
              // QR needs finite dimensions to render and receive pointer events
              // correctly on Flutter Web and Windows Chrome.
              child: SizedBox(
                width: 200,
                height: 200,
                child: RepaintBoundary(
                  child: QrImageView(
                    data: a.code,
                    size: 200,
                    version: QrVersions.auto,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SelectableText(a.code,
            style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text('QR pratinjau lokal hanya memuat kode aset. '
              'Belum terhubung ke sistem online.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: muted)),
        ],
      ),
      actions: (ctx, update) => [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Tutup')),
        FilledButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: a.code));
            Navigator.pop(ctx);
            notify('Kode aset disalin.');
          },
          icon: const Icon(Icons.copy_outlined, size: 17),
          label: const Text('Salin Kode'),
        ),
      ],
    );
  }

  Future<void> v4EditIdentity(AssetRecord a) async {
    final name = TextEditingController(text: a.name);
    final brand = TextEditingController(text: a.brand);
    final model = TextEditingController(text: a.model);
    final serial = TextEditingController(text: a.serial);
    final cost = TextEditingController(text: a.acquisitionCost?.toString() ?? '');
    final reason = TextEditingController();
    var unknown = a.acquisitionCost == null;
    var error = '';
    final ok = await v4ShowModal<bool>(
      title: 'Ubah Informasi Aset',
      subtitle: a.name + ' · ' + a.code,
      maxWidth: 720,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          v4ModalPair(
            TextField(controller: name,
              decoration: v4ModalDecoration('Nama aset *')),
            TextField(controller: brand,
              decoration: v4ModalDecoration('Merek')),
          ),
          const SizedBox(height: 15),
          v4ModalPair(
            TextField(controller: model,
              decoration: v4ModalDecoration('Model / tipe')),
            TextField(controller: serial,
              decoration: v4ModalDecoration('Nomor seri')),
          ),
          const SizedBox(height: 15),
          v4ModalPair(
            TextField(controller: cost, enabled: !unknown,
              keyboardType: TextInputType.number,
              decoration: v4ModalDecoration('Nilai perolehan (Rp)')),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: unknown,
              title: const Text('Nilai belum diketahui',
                style: TextStyle(fontSize: 13)),
              onChanged: (value) => update(() {
                unknown = value ?? false;
                error = '';
              }),
            ),
          ),
          const SizedBox(height: 17),
          TextField(
            controller: reason,
            maxLines: 3,
            decoration: v4ModalDecoration('Alasan koreksi *',
              hint: 'Jelaskan informasi yang dikoreksi'),
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12),
            v4ModalError(error),
          ],
        ],
      ),
      actions: (ctx, update) => [
        OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal')),
        FilledButton(onPressed: () {
          final int? value = unknown ? null : int.tryParse(cost.text.trim());
          if (name.text.trim().isEmpty || reason.text.trim().isEmpty) {
            update(() => error = 'Nama aset dan alasan koreksi wajib diisi.');
          } else if (!unknown && (value == null || value < 0)) {
            update(() => error = 'Nilai perolehan harus angka tidak negatif.');
          } else {
            Navigator.pop(ctx, true);
          }
        }, child: const Text('Simpan Perubahan')),
      ],
    );
    if (ok == true) {
      try {
        final value = unknown ? null : int.tryParse(cost.text.trim());
        await store.editIdentity(a, name.text, brand.text, model.text,
          serial.text, value, reason.text);
        repaint();
        notify('Informasi aset diperbarui.');
      } catch (e) {
        notify(e.toString());
      }
    }
    for (final controller in [name, brand, model, serial, cost, reason]) {
      controller.dispose();
    }
  }

  Future<void> v4Condition(AssetRecord a) async {
    var condition = a.condition;
    final reason = TextEditingController();
    var error = '';
    final ok = await v4ShowModal<bool>(
      title: 'Ubah Kondisi Aset',
      subtitle: a.name + ' · ' + a.code,
      maxWidth: 520,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          v4ModalPair(
            v4ReadonlyField('Kondisi saat ini', a.condition),
            DropdownButtonFormField<String>(
              key: const ValueKey('condition-selector'),
              initialValue: condition,
              isExpanded: true,
              menuMaxHeight: 260,
              dropdownColor: Colors.white,
              decoration: v4ModalDecoration('Kondisi baru *'),
              items: ['Baru', 'Baik', 'Cukup', 'Kurang Baik', 'Rusak']
                .map((value) => DropdownMenuItem(
                  value: value, child: Text(value))).toList(),
              onChanged: (value) => update(() {
                condition = value ?? condition;
                error = '';
              }),
            ),
            breakpoint: 430,
          ),
          const SizedBox(height: 18),
          TextField(controller: reason, maxLines: 3,
            decoration: v4ModalDecoration('Alasan / hasil pemeriksaan *',
              hint: 'Jelaskan kondisi yang ditemukan')),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12),
            v4ModalError(error),
          ],
        ],
      ),
      actions: (ctx, update) => [
        OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal')),
        FilledButton(onPressed: () {
          if (reason.text.trim().isEmpty) {
            update(() => error = 'Alasan atau hasil pemeriksaan wajib diisi.');
          } else if (condition == a.condition) {
            update(() => error = 'Pilih kondisi yang berbeda dari sebelumnya.');
          } else {
            Navigator.pop(ctx, true);
          }
        }, child: const Text('Simpan Perubahan')),
      ],
    );
    if (ok == true) {
      try {
        await store.editCondition(a, condition, reason.text);
        repaint();
        notify('Kondisi aset diperbarui.');
      } catch (e) {
        notify(e.toString());
      }
    }
    reason.dispose();
  }

  Future<void> v4Status(AssetRecord a) async {
    var status = a.status;
    final reason = TextEditingController();
    var error = '';
    final ok = await v4ShowModal<bool>(
      title: 'Ubah Status Aset',
      subtitle: a.name + ' · ' + a.code,
      maxWidth: 520,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          v4ModalPair(
            v4ReadonlyField('Status saat ini', a.status),
            DropdownButtonFormField<String>(
              key: const ValueKey('status-selector'),
              initialValue: status,
              isExpanded: true,
              menuMaxHeight: 260,
              dropdownColor: Colors.white,
              decoration: v4ModalDecoration('Status baru *'),
              // Disposal is a dedicated, guarded action, not a regular status.
              items: ['Tersedia', 'Digunakan', 'Dalam Perbaikan', 'Hilang']
                .map((value) => DropdownMenuItem(
                  value: value, child: Text(value))).toList(),
              onChanged: (value) => update(() {
                status = value ?? status;
                error = '';
              }),
            ),
            breakpoint: 430,
          ),
          const SizedBox(height: 18),
          TextField(controller: reason, maxLines: 3,
            decoration: v4ModalDecoration('Alasan perubahan *',
              hint: 'Jelaskan dasar perubahan status')),
          if (status == 'Hilang') ...[
            const SizedBox(height: 12),
            const Text('Status Hilang memerlukan konfirmasi tambahan.',
              style: TextStyle(color: danger, fontSize: 12)),
          ],
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12),
            v4ModalError(error),
          ],
        ],
      ),
      actions: (ctx, update) => [
        OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal')),
        FilledButton(onPressed: () {
          if (reason.text.trim().isEmpty) {
            update(() => error = 'Alasan perubahan status wajib diisi.');
          } else if (status == a.status) {
            update(() => error = 'Pilih status yang berbeda dari sebelumnya.');
          } else {
            Navigator.pop(ctx, true);
          }
        }, child: const Text('Lanjutkan')),
      ],
    );
    if (ok == true) {
      var confirmed = true;
      if (status == 'Hilang') {
        if (!mounted) {
          reason.dispose();
          return;
        }
        confirmed = await v4ShowModal<bool>(
          title: 'Konfirmasi Status Hilang',
          subtitle: a.name + ' · ' + a.code,
          maxWidth: 520,
          body: (ctx, update) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pastikan kejadian kehilangan telah ditindaklanjuti '
                'sesuai prosedur perusahaan.'),
              const SizedBox(height: 12),
              v4ReadonlyField('Status baru', 'Hilang'),
              const SizedBox(height: 8),
              const Text('Konfirmasi ini hanya simulasi lokal; '
                'belum merupakan persetujuan terverifikasi.',
                style: TextStyle(fontSize: 12, color: muted)),
            ],
          ),
          actions: (ctx, update) => [
            OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Konfirmasi Hilang')),
          ],
        ) ?? false;
      }
      if (confirmed) {
        try {
          await store.editStatus(a, status, reason.text);
          repaint();
          notify('Status aset diperbarui.');
        } catch (e) {
          notify(e.toString());
        }
      }
    }
    reason.dispose();
  }

}
