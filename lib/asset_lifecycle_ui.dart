part of 'main.dart';

extension _AssetLifecycleUI on _AssetScreenState {
  Widget v6LifecycleCard(AssetRecord asset) => surface(
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
      sectionHeader('Administrasi & Siklus Hidup Aset',
        subtitle: 'Tindakan administratif terpisah dari operasional'),
      const SizedBox(height: 14),
      v4ReadonlyField('Siklus hidup aset', asset.lifecycle),
      const SizedBox(height: 10),
      if (asset.lifecycle == 'Dilepas') ...[
        v4ReadonlyField('Jenis pelepasan',
          asset.releaseType.isEmpty ? 'Pelepasan data lama' : asset.releaseType),
        const SizedBox(height: 8),
        v4ReadonlyField('Tanggal pelepasan',
          asset.releaseDate.isEmpty ? 'Tidak tercatat' : asset.releaseDate),
        const SizedBox(height: 8),
        v4ReadonlyField('Dokumen referensi',
          asset.releaseReference.isEmpty ?
            'Tidak tercatat (data lama)' : asset.releaseReference),
        const SizedBox(height: 8),
        v4ReadonlyField('Alasan',
          asset.releaseReason.isEmpty ? 'Tidak tercatat' : asset.releaseReason),
        const SizedBox(height: 8),
        const Text('Kode aset, dokumentasi foto dan riwayat '
          'tetap tersimpan; tidak dapat ditugaskan kembali.',
          style: TextStyle(fontSize: 12, color: muted)),
      ] else ...[
        const Text('Menonaktifkan aset tidak menghapus identitasnya. '
          'Pelepasan untuk penjualan, hibah atau pemusnahan harus '
          'memiliki dokumen referensi dan alasan yang jelas.',
          style: TextStyle(fontSize: 12, color: muted)),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 8, children: [
          outlineButton(
            asset.lifecycle == 'Aktif' ? 'Nonaktifkan Aset' : 'Aktifkan Kembali',
            asset.lifecycle == 'Aktif'
              ? Icons.pause_circle_outline
              : Icons.play_circle_outline,
            () => v6ChangeLifecycle(asset),
             tone: asset.lifecycle == 'Aktif'
               ? AssetActionTone.warning : AssetActionTone.success),
          outlineButton('Catat Pelepasan', Icons.outbox_outlined,
            () => v6ReleaseDialog(asset),
             tone: AssetActionTone.danger),
        ]),
      ],
    ]),
  );

  Future<void> v6ChangeLifecycle(AssetRecord asset) async {
    final newActive = asset.lifecycle == 'Tidak Aktif';
    final reason = TextEditingController();
    var error = '';
    bool hasChanges() => reason.text.isNotEmpty;
    final okay = await v4ShowModal<bool>(
      title: newActive ? 'Aktifkan Kembali Aset' : 'Nonaktifkan Aset',
      subtitle: asset.name + ' · ' + asset.code,
      maxWidth: 540,
      isDirty: hasChanges,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          v4ReadonlyField('Siklus hidup saat ini', asset.lifecycle),
          const SizedBox(height: 13),
          const Text('Perubahan ini dicatat pada Riwayat Aset. '
            'Tidak menghapus kode atau dokumentasi foto.',
            style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 15),
          TextField(controller: reason, maxLines: 3,
            decoration: v4ModalDecoration('Alasan *')),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 10), v4ModalError(error),
          ],
        ],
      ),
      actions: (ctx, update) => [
        OutlinedButton(style: assetOutlinedStyle(AssetActionTone.secondary),
          onPressed: () => assetRequestModalClose(
          ctx, isDirty: hasChanges), child: const Text('Batal')),
        FilledButton(
          style: assetFilledStyle(newActive
            ? AssetActionTone.success : AssetActionTone.warning),
          onPressed: () {
          if (reason.text.trim().isEmpty) {
            update(() => error = 'Alasan wajib diisi.');
          } else {
            Navigator.pop(ctx, true);
          }
        }, child: Text(newActive ? 'Aktifkan' : 'Nonaktifkan')),
      ],
    );
    if (okay == true) {
      try {
        await store.setLifecycleActive(asset, newActive, reason.text);
        repaint();
        notify(newActive ? 'Aset kembali aktif.' : 'Aset dinonaktifkan.');
      } catch (e) {
        notify(e.toString());
      }
    }
    reason.dispose();
  }

  Future<void> v6ReleaseDialog(AssetRecord asset) async {
    final reference = TextEditingController();
    final reason = TextEditingController();
    final date = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10));
    final handledBy = TextEditingController();
    final confirmation = TextEditingController();
    var kind = 'Dijual';
    var error = '';
    final originalDate = date.text;
    bool hasChanges() => reference.text.isNotEmpty ||
      reason.text.isNotEmpty || date.text != originalDate ||
      handledBy.text.isNotEmpty || confirmation.text.isNotEmpty ||
      kind != 'Dijual';
    final result = await v4ShowModal<bool>(
      title: 'Pelepasan Aset (Simulasi)',
      subtitle: asset.name + ' · ' + asset.code,
      maxWidth: 700,
      isDirty: hasChanges,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          v4ModalError('Aset yang sudah dilepas tidak dapat '
            'ditugaskan lagi. Data, foto, kode dan riwayat tidak dihapus.'),
          const SizedBox(height: 14),
          v4ModalPair(
            DropdownButtonFormField<String>(
              initialValue: kind, isExpanded: true,
              decoration: v4ModalDecoration('Jenis pelepasan *'),
              items: ['Dijual','Dihibahkan','Dimusnahkan','Lainnya']
                .map((type) => DropdownMenuItem(
                  value: type, child: Text(type))).toList(),
              onChanged: (value) => update(() => kind = value ?? kind)),
            TextField(controller: date,
              decoration: v4ModalDecoration(
                'Tanggal efektif * (YYYY-MM-DD)')),
          ),
          const SizedBox(height: 13),
          TextField(controller: reference,
            decoration: v4ModalDecoration('Referensi dokumen/BA *')),
          const SizedBox(height: 13),
          TextField(controller: reason, maxLines: 3,
            decoration: v4ModalDecoration('Alasan pelepasan *')),
          const SizedBox(height: 13),
          TextField(controller: handledBy,
            decoration: v4ModalDecoration(
              'Petugas pencatat (opsional, belum terverifikasi)')),
          const SizedBox(height: 13),
          TextField(controller: confirmation,
            decoration: v4ModalDecoration(
              'Ketik kode aset untuk konfirmasi *', hint: asset.code)),
          const SizedBox(height: 11),
          const Text('Pratinjau lokal belum memiliki autentikasi '
            'atau persetujuan resmi. Jangan menganggap pencatatan ini '
            'sebagai persetujuan pelepasan perusahaan.',
            style: TextStyle(fontSize: 12, color: muted)),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 10), v4ModalError(error),
          ],
        ],
      ),
      actions: (ctx, update) => [
        OutlinedButton(style: assetOutlinedStyle(AssetActionTone.secondary),
          onPressed: () => assetRequestModalClose(
          ctx, isDirty: hasChanges), child: const Text('Batal')),
        FilledButton(
          style: assetFilledStyle(AssetActionTone.danger),
          onPressed: () {
            if (reference.text.trim().isEmpty ||
                reason.text.trim().isEmpty ||
                DateTime.tryParse(date.text.trim()) == null) {
              update(() => error = 'Isi tanggal, dokumen, dan alasan.');
            } else if (confirmation.text.trim() != asset.code) {
              update(() => error = 'Kode konfirmasi tidak sesuai.');
            } else {
              Navigator.pop(ctx, true);
            }
          },
          child: const Text('Catat Pelepasan (Simulasi)')),
      ],
    );
    if (result == true) {
      try {
        await store.releaseAsset(asset, kind: kind,
          date: date.text.trim(), reference: reference.text.trim(),
          reason: reason.text.trim(), handledBy: handledBy.text.trim());
        repaint();
        notify('Pelepasan tercatat sebagai simulasi; riwayat tetap ada.');
      } catch (e) {
        notify(e.toString());
      }
    }
    for (final controller in [
      reference,reason,date,handledBy,confirmation]) {
      controller.dispose();
    }
  }
}
