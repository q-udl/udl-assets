part of 'main.dart';

/// Documentation per individual physical asset, not a product-thumbnail catalog.
/// The source stays local in the browser for this review build.
extension _AssetFeaturePanels on _AssetScreenState {
  Widget assetThumbnail(AssetRecord asset, {double size = 42}) {
    final photo = store.primaryPhotoFor(asset.id);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size, height: size,
        child: photo == null
          ? Container(
              color: const Color(0xFFEDF5FE),
              child: const Icon(Icons.photo_camera_back_outlined,
                color: Color(0xFF477AA9), size: 21),
            )
          : Image.memory(photo.bytes, fit: BoxFit.cover, gaplessPlayback: true),
      ),
    );
  }

  Widget photoGallery(AssetRecord a) {
    final photos = store.photosFor(a.id);
    AssetPhoto? current;
    for (final photo in photos) {
      if (photo.id == viewedPhotoId) current = photo;
    }
    current ??= store.primaryPhotoFor(a.id);
    return surface(
      padding: const EdgeInsets.all(19),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        sectionHeader('Dokumentasi foto aset',
          subtitle: 'Foto aktual dari setiap unit fisik, bukan foto produk',
          trailing: primaryButton('Tambah Foto', Icons.add_a_photo_outlined,
            () => uploadAssetPhoto(a))),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Container(
            height: 250, width: double.infinity,
            color: const Color(0xFFF0F5FA),
            child: current == null
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.add_photo_alternate_outlined,
                    size: 47, color: Color(0xFF8FA4BA)),
                  const SizedBox(height: 12),
                  const Text('Belum ada foto aset',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: Color(0xFF526982))),
                  const SizedBox(height: 5),
                  const Text('Unggah foto fisik untuk identifikasi dan pemeriksaan.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF718199))),
                  const SizedBox(height: 13),
                  outlineButton('Unggah foto pertama', Icons.upload_file_outlined,
                    () => uploadAssetPhoto(a)),
                ])
              : Image.memory(current.bytes, fit: BoxFit.contain, gaplessPlayback: true),
          ),
        ),
        const SizedBox(height: 13),
        if (current != null) Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(current.kind, style: const TextStyle(color: Color(0xFF172C47),
              fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 3),
            Text(current.fileName + ' · ' + dateText(current.timestamp),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF718199))),
          ])),
          if (!current.isPrimary)
            TextButton.icon(
              onPressed: () async {
                try {
                  await store.setPrimaryPhoto(a, current!);
                  notify('Foto utama berhasil diperbarui');
                } catch (e) { notify(e.toString()); }
              },
              icon: const Icon(Icons.star_border_rounded, size: 16),
              label: const Text('Jadikan utama'),
            ),
          if (current.isPrimary) const Icon(Icons.star_rounded,
            color: Color(0xFFCA8C23), size: 19),
        ]),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 13),
          SizedBox(height: 82, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final photo = photos[index];
              final selected = current?.id == photo.id;
              return InkWell(
                onTap: () { viewedPhotoId = photo.id; repaint(); },
                child: Container(
                  width: 82, height: 82,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? const Color(0xFF2766A2)
                        : const Color(0xFFE3EAF2),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(7),
                    child: Image.memory(photo.bytes, fit: BoxFit.cover)),
                ),
              );
            },
          )),
        ],
        const SizedBox(height: 12),
        Text('Dokumentasi: ' + photos.length.toString() + '/8 foto · ' +
          'JPEG/PNG/WebP · maksimal 500 KB per foto (preview lokal).',
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF718199))),
      ]),
    );
  }

  Future<void> uploadAssetPhoto(AssetRecord asset) async {
    final selectedKind = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(child: ListView(
        shrinkWrap: true,
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(20, 6, 16, 12),
            child: Text('Jenis dokumentasi foto', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800))),
          for (final item in AssetStore.photoKinds)
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: Text(item),
              onTap: () => Navigator.pop(ctx, item),
            ),
        ],
      )),
    );
    if (selectedKind == null || !mounted) return;
    try {
      final selected = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 960, maxHeight: 960, imageQuality: 65,
      );
      if (selected == null) return;
      await store.addPhoto(asset, await selected.readAsBytes(),
        selected.name, selectedKind);
      viewedPhotoId = store.photosFor(asset.id).last.id;
      repaint();
      notify('Foto aktual aset berhasil dicatat');
    } catch (e) {
      notify('Foto belum tersimpan: ' + e.toString());
    }
  }

  Future<void> _promptMaster(String title, Future<void> Function(String) onSave) async {
    final controller = TextEditingController();
    final key = GlobalKey<FormState>();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title),
        content: SizedBox(width: 430,
          child: Form(key: key, child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nama', hintText: 'Nama klasifikasi'),
            validator: (value) => value == null || value.trim().length < 2
              ? 'Minimal dua karakter' : null))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () {
            if (key.currentState!.validate()) {
              Navigator.pop(ctx, controller.text.trim());
            }
          }, child: const Text('Simpan')),
        ],
      ),
    );
    if (text != null) {
      try { await onSave(text); notify('Master klasifikasi diperbarui'); }
      catch (e) { notify('Tidak dapat menyimpan: ' + e.toString()); }
    }
    controller.dispose();
  }

  // ignore: unused_element
  Widget taxonomyPage() {
    final totalSub = store.categories.fold<int>(
      0, (sum, c) => sum + c.subcategories.length);
    final totalTypes = store.categories.fold<int>(0, (sum, c) =>
      sum + c.subcategories.fold<int>(0, (n, s) => n + s.types.length));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      surface(child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: const Color(0xFFEDF5FE),
            borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.account_tree_outlined, color: Color(0xFF2766A2)),
        ),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Master Klasifikasi Aset',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
              color: Color(0xFF172C47))),
          const SizedBox(height: 4),
          Text(store.categories.length.toString() + ' kategori · ' +
            totalSub.toString() + ' subkategori · ' + totalTypes.toString() + ' jenis',
            style: const TextStyle(fontSize: 12, color: Color(0xFF718199))),
        ])),
        primaryButton('Tambah Kategori', Icons.add_rounded,
          () => _promptMaster('Tambah Kategori Aset', store.addCategory)),
      ])),
      const SizedBox(height: 14),
      surface(child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded, color: Color(0xFF2766A2), size: 19),
        SizedBox(width: 11),
        Expanded(child: Text(
          'Hierarki: Kategori → Subkategori → Jenis Aset. '
          'Tanah, bangunan, serta renovasi struktur tidak dicatat di UDL Assets. '
          'Lokasi dan departemen pengguna dicatat terpisah.',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF526982), height: 1.45))),
      ])),
      const SizedBox(height: 14),
      for (final cat in store.categories) ...[
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3EAF2))),
          child: ExpansionTile(
            key: ValueKey(cat.code),
            initiallyExpanded: cat.code == '03',
            shape: const Border(),
            collapsedShape: const Border(),
            leading: Container(width: 43, height: 43,
              decoration: BoxDecoration(color: const Color(0xFFEDF5FE),
                borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(cat.code,
                style: const TextStyle(fontWeight: FontWeight.w900,
                  color: Color(0xFF2766A2)))),
            ),
            title: Text(cat.name, style: const TextStyle(fontSize: 14,
              fontWeight: FontWeight.w800, color: Color(0xFF172C47))),
            subtitle: Text(cat.subcategories.length.toString() + ' subkategori',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF718199))),
            children: [
              const Divider(height: 1),
              for (final sub in cat.subcategories)
                Padding(padding: const EdgeInsets.fromLTRB(19, 13, 19, 5),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(sub.name,
                        style: const TextStyle(fontWeight: FontWeight.w800,
                          fontSize: 13, color: Color(0xFF172C47)))),
                      TextButton.icon(
                        onPressed: () => _promptMaster('Tambah Jenis Aset · ' + sub.name,
                          (value) => store.addType(cat, sub, value)),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Tambah jenis', style: TextStyle(fontSize: 12)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Wrap(spacing: 7, runSpacing: 7, children: [
                      for (final type in sub.types)
                        Chip(
                          backgroundColor: const Color(0xFFF5F8FC),
                          side: const BorderSide(color: Color(0xFFE3EAF2)),
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          label: Text(type, style: const TextStyle(
                            fontSize: 11.5, color: Color(0xFF50637B))),
                        ),
                      if (sub.types.isEmpty)
                        const Text('Belum ada jenis aset',
                          style: TextStyle(fontSize: 12, color: Color(0xFF718199))),
                    ]),
                    const Divider(height: 22),
                  ]),
                ),
              Padding(padding: const EdgeInsets.fromLTRB(17, 3, 17, 14),
                child: Align(alignment: Alignment.centerLeft,
                  child: outlineButton('Tambah subkategori', Icons.add_rounded,
                    () => _promptMaster('Tambah Subkategori · ' + cat.name,
                      (value) => store.addSubcategory(cat, value))))),
            ],
          ),
        ),
      ],
    ]);
  }

  Future<void> reclassifyAsset(AssetRecord asset) async {
    var category = store.categoryByName(asset.category) == null
      ? store.categories.first.name : asset.category;
    AssetSubcategory initialSub(String cat) {
      final available = store.categoryByName(cat)!.subcategories.where(
        (s) => s.types.isNotEmpty).toList();
      if (available.isEmpty) {
        throw const FormatException('Kategori belum memiliki jenis aset.');
      }
      return available.first;
    }
    var sub = store.subcategoryByName(category, asset.subcategory)?.name ??
      initialSub(category).name;
    var type = asset.assetType;
    final availableTypes = store.subcategoryByName(category, sub)?.types ?? [];
    if (!availableTypes.contains(type)) type = availableTypes.isEmpty ? '' : availableTypes.first;
    final reason = TextEditingController();
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, update) =>
        AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Reklasifikasi Aset'),
          content: SizedBox(width: 490, child: Form(key: key,
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min, children: [
                Text(asset.code + ' · ' + asset.name,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF718199))),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: category,
                  items: store.categories.where((c) => c.subcategories.any(
                    (s) => s.types.isNotEmpty)).map((c) =>
                      DropdownMenuItem(value: c.name, child: Text(c.name,
                        overflow: TextOverflow.ellipsis))).toList(),
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  onChanged: (value) {
                    if (value == null) return;
                    update(() {
                      category = value;
                      sub = initialSub(category).name;
                      type = store.subcategoryByName(category, sub)!.types.first;
                    });
                  },
                ),
                const SizedBox(height: 11),
                DropdownButtonFormField<String>(
                  key: ValueKey(category + sub),
                  isExpanded: true,
                  initialValue: sub,
                  items: store.categoryByName(category)!.subcategories.where(
                    (s) => s.types.isNotEmpty).map((s) =>
                      DropdownMenuItem(value: s.name, child: Text(s.name))).toList(),
                  decoration: const InputDecoration(labelText: 'Subkategori'),
                  onChanged: (value) {
                    if (value == null) return;
                    update(() {
                      sub = value;
                      type = store.subcategoryByName(category, sub)!.types.first;
                    });
                  },
                ),
                const SizedBox(height: 11),
                DropdownButtonFormField<String>(
                  key: ValueKey(category + sub + type),
                  isExpanded: true,
                  initialValue: type,
                  items: (store.subcategoryByName(category, sub)?.types ?? [])
                    .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  decoration: const InputDecoration(labelText: 'Jenis Aset'),
                  onChanged: (value) { if (value != null) update(() => type = value); },
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: reason,
                  decoration: const InputDecoration(labelText: 'Alasan perubahan *'),
                  validator: (value) => value == null || value.trim().isEmpty
                    ? 'Alasan wajib diisi' : null,
                ),
              ]),
            ))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
            FilledButton(onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(ctx, true);
            }, child: const Text('Simpan')),
          ],
        )),
    );
    if (ok == true) {
      try {
        await store.reclassify(asset, category, sub, type, reason.text);
        notify('Klasifikasi aset dan riwayat diperbarui');
      } catch (e) { notify(e.toString()); }
    }
    reason.dispose();
  }
}
