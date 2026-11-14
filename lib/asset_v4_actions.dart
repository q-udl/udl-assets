part of 'main.dart';

extension _AssetV4Actions on _AssetScreenState {
  Future<void> v4Transfer(AssetRecord a) async {
    var destination = store.activeSites.any((s) => s.name == a.location)
      ? a.location : (store.activeSites.isEmpty
        ? a.location : store.activeSites.first.name);
    var destinationArea = destination == a.location ? a.locationAreaId : '';
    var destinationSpot = destination == a.location ? a.locationSpotId : '';
    final receiver = TextEditingController(text: a.holder);
    final reason = TextEditingController();
    var error = '';
    final ok = await v4ShowModal<bool>(
      title: 'Mutasi Aset',
      subtitle: a.name + ' · ' + a.code,
      maxWidth: 760,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          v4ModalPair(
            Column(crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              const Text('Penempatan Saat Ini', style: TextStyle(
                fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 12),
              v4ReadonlyField('Lokasi asal', store.locationPath(a)),
              const SizedBox(height: 12),
              v4ReadonlyField('Penanggung jawab sebelumnya', a.holder),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              const Text('Penempatan Tujuan', style: TextStyle(
                fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: destination,
                menuMaxHeight: 260,
                isExpanded: true,
                dropdownColor: Colors.white,
                decoration: v4ModalDecoration('Lokasi tujuan *'),
                items: store.activeSites.map((site) => DropdownMenuItem(
                  value: site.name, child: Text(site.name))).toList(),
                onChanged: (value) => update(() {
                  destination = value ?? destination;
                  destinationArea = '';
                  destinationSpot = '';
                  error = '';
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('transfer-area-' + destination),
                initialValue: destinationArea,
                isExpanded: true,
                decoration: v4ModalDecoration('Area (opsional)'),
                items: [
                  const DropdownMenuItem(value: '',
                    child: Text('Belum ditentukan')),
                  for (final area in (store.siteByName(destination)
                    ?.areas.where((a) => a.active) ?? <AssetArea>[]))
                    DropdownMenuItem(value: area.id,
                      child: Text(area.name)),
                ],
                onChanged: (value) => update(() {
                  destinationArea = value ?? '';
                  destinationSpot = '';
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('transfer-spot-' + destinationArea),
                initialValue: destinationSpot,
                isExpanded: true,
                decoration: v4ModalDecoration('Titik Penempatan (opsional)'),
                items: [
                  const DropdownMenuItem(value: '',
                    child: Text('Belum ditentukan')),
                  for (final area in (store.siteByName(destination)
                    ?.areas ?? <AssetArea>[]))
                    if (area.id == destinationArea)
                      for (final spot in area.spots.where((p) => p.active))
                        DropdownMenuItem(value: spot.id,
                          child: Text(spot.name)),
                ],
                onChanged: (value) =>
                  update(() => destinationSpot = value ?? ''),
              ),
              const SizedBox(height: 12),
              TextField(controller: receiver,
                decoration: v4ModalDecoration('Penanggung jawab baru')),
            ]),
            breakpoint: 550,
          ),
          const SizedBox(height: 18),
          TextField(controller: reason, maxLines: 3,
            decoration: v4ModalDecoration('Alasan mutasi *',
              hint: 'Jelaskan tujuan perpindahan aset')),
          const SizedBox(height: 12),
          const Text('Mutasi belum berlaku sampai serah terima '
            'dikonfirmasi melalui simulasi lokal.',
            style: TextStyle(color: muted, fontSize: 12)),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12), v4ModalError(error),
          ],
        ],
      ),
      actions: (ctx, update) => [
        OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal')),
        FilledButton.icon(
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          onPressed: () {
            if (reason.text.trim().isEmpty) {
              update(() => error = 'Alasan mutasi wajib diisi.');
            } else if (destination == a.location &&
                destinationArea == a.locationAreaId &&
                destinationSpot == a.locationSpotId &&
                receiver.text.trim() == a.holder) {
              update(() => error =
                'Pilih lokasi atau penanggung jawab yang berbeda.');
            } else {
              Navigator.pop(ctx, true);
            }
          },
          label: const Text('Ajukan Mutasi'),
        ),
      ],
    );
    if (ok == true) {
      try {
        await store.proposeTransfer(
          a, destination, receiver.text, reason.text,
          placement: AssetPlacement(
            store.siteByName(destination)?.id ?? '',
            areaId: destinationArea, spotId: destinationSpot));
        repaint();
        notify('Mutasi tercatat menunggu serah terima simulasi.');
      } catch (e) {
        notify('Mutasi gagal: ' + e.toString());
      }
    }
    receiver.dispose();
    reason.dispose();
  }

  Future<void> v4RespondTransfer(AssetTransfer transfer) async {
    final a = assetFor(transfer.assetId);
    if (a == null) return;
    final note = TextEditingController();
    final response = await v4ShowModal<bool>(
      title: 'Konfirmasi Serah Terima',
      subtitle: a.name + ' · ' + a.code,
      maxWidth: 690,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          v4ModalPair(
            Column(crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              v4ReadonlyField('Lokasi asal', transfer.fromLocation),
              const SizedBox(height: 12),
              v4ReadonlyField('Penyerah/PIC lama', transfer.fromHolder),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              v4ReadonlyField('Lokasi tujuan', transfer.toLocation),
              const SizedBox(height: 12),
              v4ReadonlyField('Penerima/PIC baru', transfer.toHolder),
            ]),
            breakpoint: 540,
          ),
          const SizedBox(height: 18),
          TextField(controller: note, maxLines: 3,
            decoration: v4ModalDecoration(
              'Catatan penerimaan atau penolakan')),
          const SizedBox(height: 12),
          const Text('Konfirmasi ini dilakukan oleh operator dalam '
            'pratinjau lokal. Belum merupakan tanda tangan atau '
            'persetujuan penerima yang terverifikasi.',
            style: TextStyle(color: muted, fontSize: 12)),
        ],
      ),
      actions: (ctx, update) => [
        OutlinedButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal')),
        TextButton(onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Tolak')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Terima (Simulasi)')),
      ],
    );
    if (response != null) {
      try {
        await store.confirmTransfer(transfer, response, note.text);
        repaint();
        notify(response ? 'Serah terima simulasi diterima.' :
          'Serah terima simulasi ditolak.');
      } catch (e) {
        notify(e.toString());
      }
    }
    note.dispose();
  }

  Future<void> v4UploadPhoto(AssetRecord a, {BuildContext? anchorContext}) async {
    var kind = AssetStore.photoKinds.first;
    final note = TextEditingController();
    final confirmed = await v4ShowModal<bool>(
      title: 'Tambah Dokumentasi Foto',
      subtitle: a.name + ' · ' + a.code,
      maxWidth: 550,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: kind, isExpanded: true, menuMaxHeight: 260,
            decoration: v4ModalDecoration('Jenis dokumentasi'),
            items: AssetStore.photoKinds.map((value) =>
              DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: (value) => update(() => kind = value ?? kind),
          ),
          const SizedBox(height: 16),
          TextField(controller: note, maxLines: 3,
            decoration: v4ModalDecoration('Keterangan (opsional)')),
        ],
      ),
      actions: (ctx, update) => [
        OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Lanjut ke Foto')),
      ],
    );
    if (confirmed == true && mounted) {
      try {
        final selected = await AssetPhotoPicker.choose(context,
          anchorContext: anchorContext);
        if (selected != null && mounted) {
          await store.addPhoto(a, selected.bytes, selected.fileName, kind,
            note: note.text);
          repaint();
          notify('Foto dokumentasi berhasil ditambahkan.');
        }
      } catch (e) {
        if (mounted) notify('Foto gagal disimpan: ' + e.toString());
      }
    }
    note.dispose();
  }

  Future<void> v4PhotoViewer(AssetRecord a, AssetPhoto photo) async {
    await v4ShowModal<void>(
      title: photo.kind,
      subtitle: a.name + ' · ' + a.code,
      maxWidth: 760,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: Image.memory(photo.bytes,
            height: 370, fit: BoxFit.contain)),
          const SizedBox(height: 12),
          Text(photo.fileName + ' · ' + dateText(photo.timestamp),
            style: const TextStyle(color: muted, fontSize: 12)),
          if (photo.note.isNotEmpty) ...[
            const SizedBox(height: 8), Text(photo.note),
          ],
          if (photo.isPrimary)
            const Chip(label: Text('Foto Utama')),
        ],
      ),
      actions: (ctx, update) => [
        OutlinedButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Tutup')),
        if (!photo.isPrimary)
          TextButton(onPressed: () {
            Navigator.pop(ctx);
            store.setPrimaryPhoto(a, photo).then((_) => repaint())
              .catchError((Object e) => notify(e.toString()));
          }, child: const Text('Jadikan Utama')),
        TextButton(onPressed: () {
          Navigator.pop(ctx);
          v4ArchivePhoto(a, photo);
        }, child: const Text('Arsipkan / Koreksi')),
      ],
    );
  }

  Future<void> v4ArchivePhoto(AssetRecord a, AssetPhoto photo) async {
    final reason = TextEditingController();
    var error = '';
    final approved = await v4ShowModal<bool>(
      title: 'Arsipkan Dokumentasi',
      subtitle: a.name + ' · ' + photo.fileName,
      maxWidth: 500,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Foto tidak dihapus permanen. '
            'Dokumentasi dan alasannya tetap tercatat.'),
          const SizedBox(height: 15),
          TextField(controller: reason, maxLines: 3,
            decoration: v4ModalDecoration('Alasan pengarsipan *')),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12), v4ModalError(error),
          ],
        ],
      ),
      actions: (ctx, update) => [
        OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal')),
        FilledButton(onPressed: () {
          if (reason.text.trim().isEmpty) {
            update(() => error = 'Alasan pengarsipan wajib diisi.');
          } else {
            Navigator.pop(ctx, true);
          }
        }, child: const Text('Arsipkan')),
      ],
    );
    if (approved == true) {
      try {
        await store.archivePhoto(a, photo, reason.text);
        repaint();
        notify('Foto telah diarsipkan.');
      } catch (e) {
        notify(e.toString());
      }
    }
    reason.dispose();
  }

  Future<void> v4ArchivedPhotos(AssetRecord a) async {
    await v4ShowModal<void>(
      title: 'Dokumentasi Diarsipkan',
      subtitle: a.name + ' · ' + a.code,
      maxWidth: 650,
      body: (ctx, update) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final photo in store.archivedPhotosFor(a.id))
            ListTile(
              leading: Image.memory(photo.bytes,
                width: 48, height: 48, fit: BoxFit.cover),
              title: Text(photo.fileName),
              subtitle: Text(photo.archivedReason),
            ),
        ],
      ),
      actions: (ctx, update) => [
        OutlinedButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Tutup')),
      ],
    );
  }
}
