part of 'main.dart';

extension _AssignedAssetsDetail on _AssetScreenState {
  Widget v5AssignmentDetail(AssetAssignment batch) {
    final receipts = store.returnsForAssignment(batch.id);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
      surface(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.assignment_ind_outlined,
            color: blue, size: 31),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(batch.draftReference, style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 4),
            const Text('Referensi draf lokal · Bukan nomor BA resmi',
              style: TextStyle(fontSize: 11.5, color: muted)),
          ])),
          Text(batch.status, style: TextStyle(
            color: batch.isOverdue ? danger :
              batch.status == 'Aktif' ? _AssetScreenState.green : amber,
            fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 9, runSpacing: 9, children: [
          outlineButton('Cetak / Simpan PDF Draf BAST',
            Icons.picture_as_pdf_outlined, () async {
            try {
              await AssetBastPdf.printHandover(batch, store: store);
            } catch (e) {
              notify('PDF gagal dibuat: ' + e.toString());
            }
          }),
          if (batch.isPending) ...[
            primaryButton('Terima Penugasan',
              Icons.check_circle_outline, () =>
                v5ConfirmAssignment(batch, true),
              tone: AssetActionTone.success),
            outlineButton('Tolak Penugasan', Icons.cancel_outlined,
              () => v5ConfirmAssignment(batch, false),
              tone: AssetActionTone.danger),
          ],
          if (batch.activeCount > 0)
            primaryButton('Pengembalian Aset',
              Icons.assignment_return_outlined,
              () => v4Change(() {
                selectedAssignment = batch;
                page = 10;
              })),
        ]),
        const SizedBox(height: 12),
        const Text(
          'Penyerahan di aplikasi ini adalah pencatatan simulasi '
          'oleh operator, bukan tanda tangan atau persetujuan karyawan '
          'yang terverifikasi.',
          style: TextStyle(fontSize: 12, color: muted)),
      ])),
      const SizedBox(height: 13),
      LayoutBuilder(builder: (ctx, box) {
        final employee = surface(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          sectionHeader('Penerima Aset'),
          const SizedBox(height: 12),
          detailValue('Nama', batch.employeeSnapshot['name']?.toString() ?? ''),
          detailValue('Jabatan',
            batch.employeeSnapshot['jobTitle']?.toString() ?? ''),
          detailValue('Unit / Departemen',
            (batch.employeeSnapshot['unit']?.toString() ?? '-') + ' / ' +
            (batch.employeeSnapshot['department']?.toString() ?? '-')),
          detailValue('Lokasi Kerja',
            batch.employeeSnapshot['workLocation']?.toString() ?? ''),
          if (batch.handedOverByName.isNotEmpty)
            detailValue('Yang Menyerahkan', batch.handedOverByName),
          TextButton.icon(
            onPressed: () {
              final record = store.employeeById(batch.employeeId);
              if (record != null) {
                v4Change(() {
                  selectedEmployee = record;
                  selectedAssignment = null;
                  page = 8;
                });
              }
            },
            icon: const Icon(Icons.person_outline),
            label: const Text('Buka Master Karyawan')),
        ]));
        final terms = surface(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          sectionHeader('Ketentuan Penugasan'),
          const SizedBox(height: 12),
          detailValue('Jenis', batch.kind),
          detailValue('Pengajuan', dateText(batch.createdAt)),
          detailValue('Batas pengembalian',
            batch.dueDate.isEmpty ? 'Tidak ditentukan' : batch.dueDate),
          detailValue('Konfirmasi',
            batch.acceptedAt.isEmpty ? 'Belum ada' :
              dateText(batch.acceptedAt)),
          detailValue('Aset masih dikuasai',
            batch.activeCount.toString() + ' dari ' +
            batch.lines.length.toString()),
          detailValue('Catatan', batch.notes.isEmpty ? '-' : batch.notes),
          if (batch.rejectionReason.isNotEmpty)
            detailValue('Alasan ditolak', batch.rejectionReason),
        ]));
        if (box.maxWidth < 820) {
          return Column(children: [
            employee, const SizedBox(height: 13), terms,
          ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Expanded(child: employee), const SizedBox(width: 13),
          Expanded(child: terms),
        ]);
      }),
      const SizedBox(height: 13),
      surface(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        sectionHeader('Daftar Aset Penugasan',
          subtitle: batch.lines.length.toString() +
            ' unit memiliki kode dan riwayat terpisah'),
        const SizedBox(height: 12),
        for (final line in batch.lines)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            leading: const Icon(Icons.inventory_2_outlined,
              color: blue, size: 24),
            title: Text(line.assetName,
              style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(line.assetCode + ' · ' +
              line.handoverCondition + ' · ' +
              (line.accessories.isEmpty
                ? 'Kelengkapan tidak dicatat'
                : line.accessories)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, children: [
              Text(line.state, style: TextStyle(
                color: line.state == 'Aktif' ? _AssetScreenState.green : muted,
                fontSize: 11, fontWeight: FontWeight.w700)),
              const Icon(Icons.chevron_right_rounded, color: muted),
            ]),
            onTap: () {
              final asset = store.assignmentAsset(line.assetId);
              if (asset != null) {
                v4Change(() {
                  selected = asset;
                  page = 1;
                });
              }
            },
          ),
      ])),
      if (batch.lines.any((line) =>
          line.handoverProofPhotoIds.isNotEmpty)) ...[
        const SizedBox(height: 13),
        surface(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          sectionHeader('Foto Bukti Serah Terima',
            subtitle: 'Foto bukti per unit, terlampir dalam BAST'),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final line in batch.lines)
              for (final photo in store.evidenceFor(
                  'assignment_handover', batch.id, line.assetId))
                SizedBox(width: 205, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(9),
                      child: Image.memory(photo.bytes,
                        height: 115, width: 205, fit: BoxFit.contain)),
                    const SizedBox(height: 5),
                    Text(line.assetCode + ' · ' + photo.fileName,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 11)),
                  ],
                )),
          ]),
        ])),
      ],
      const SizedBox(height: 13),
      surface(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        sectionHeader('Berita Acara Pengembalian',
          subtitle: receipts.length.toString() +
            ' dokumen pengembalian, termasuk pengembalian parsial'),
        const SizedBox(height: 12),
        if (receipts.isEmpty)
          const Text('Belum ada pengembalian yang tercatat.',
            style: TextStyle(color: muted))
        else for (final receipt in receipts) ListTile(
          leading: const Icon(Icons.description_outlined, color: blue),
          title: Text(receipt.draftReference),
          subtitle: Text(receipt.lines.length.toString() +
            ' aset dikembalikan · ' + dateText(receipt.createdAt)),
          trailing: const Icon(Icons.picture_as_pdf_outlined, color: blue),
          onTap: () async {
            try {
              await AssetBastPdf.printReturn(batch, receipt, store: store);
            } catch (e) {
              notify('PDF gagal dibuat: ' + e.toString());
            }
          },
        ),
      ])),
    ]);
  }

  Future<void> v5ConfirmAssignment(
      AssetAssignment batch, bool accepted) async {
    final reason = TextEditingController();
    final handedBy = TextEditingController();
    final proofPhotos = <String, SelectedAssetPhoto>{};
    var error = '';
    bool hasChanges() => reason.text.isNotEmpty ||
      handedBy.text.isNotEmpty || proofPhotos.isNotEmpty;
    final approved = await v4ShowModal<bool>(
      title: accepted ? 'Konfirmasi Serah Terima' :
        'Tolak Penugasan',
      subtitle: batch.draftReference,
      maxWidth: 650,
      isDirty: hasChanges,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Tindakan ini dioperasikan tanpa akun penerima. '
          'Belum menjadi penerimaan yang terautentikasi.'),
        const SizedBox(height: 12),
        v4ReadonlyField('Nama karyawan',
          batch.employeeSnapshot['name']?.toString() ?? ''),
        if (accepted) ...[
          const SizedBox(height: 12),
          TextField(controller: handedBy,
            decoration: v4ModalDecoration('Yang Menyerahkan (nama petugas) *')),
          const SizedBox(height: 10),
        ],
        v4ReadonlyField('Jumlah aset', batch.lines.length.toString()),
        const SizedBox(height: 15),
        TextField(
          controller: reason, maxLines: 3,
          decoration: v4ModalDecoration(
            accepted ? 'Catatan (opsional)' : 'Alasan penolakan *')),
        if (accepted) ...[
          const SizedBox(height: 17),
          const Text('FOTO BUKTI SERAH TERIMA (WAJIB)',
            style: TextStyle(fontWeight: FontWeight.w800,
              color: ink, fontSize: 13)),
          const SizedBox(height: 6),
          const Text('Setiap unit aset memerlukan satu foto bukti aktual. '
            'Foto akan menjadi lampiran BAST setelah dikonfirmasi.',
            style: TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 12),
          for (final line in batch.lines) ...[
            assetEvidencePicker(
              context: ctx,
              assetCode: line.assetCode,
              title: line.assetName,
              selected: proofPhotos[line.assetId],
              testKey: 'rv29-handover-proof-' + line.id,
              onSelected: (photo) => update(() {
                proofPhotos[line.assetId] = photo;
                error = '';
              }),
              onRemove: () => update(() {
                proofPhotos.remove(line.assetId);
              }),
            ),
            const SizedBox(height: 10),
          ],
        ],
        if (error.isNotEmpty) ...[
          const SizedBox(height: 10), v4ModalError(error),
        ],
      ]),
      actions: (ctx, update) => [
        OutlinedButton(
          style: assetOutlinedStyle(AssetActionTone.secondary),
          onPressed: () => assetRequestModalClose(
            ctx, isDirty: hasChanges),
          child: const Text('Batal')),
        FilledButton(
          key: const ValueKey('rv29-confirm-assignment'),
          style: assetFilledStyle(accepted
            ? AssetActionTone.success : AssetActionTone.danger),
          onPressed: () {
            if (!accepted && reason.text.trim().isEmpty) {
              update(() => error = 'Alasan penolakan wajib diisi.');
            } else if (accepted && handedBy.text.trim().isEmpty) {
              update(() => error = 'Nama pihak yang menyerahkan wajib diisi.');
            } else if (accepted &&
                batch.lines.any((l) => !proofPhotos.containsKey(l.assetId))) {
              update(() => error =
                'Lengkapi foto bukti pada setiap aset sebelum menerima.');
            } else {
              Navigator.pop(ctx, true);
            }
          },
          child: Text(accepted
            ? 'Konfirmasi Serah Terima' : 'Tolak Penugasan')),
      ],
    );
    if (approved == true) {
      try {
        await store.confirmAssignment(batch, accepted, reason.text,
          proofPhotos: proofPhotos,
          handedOverByName: handedBy.text);
        repaint();
        notify(accepted
          ? 'Penugasan aktif; foto bukti tercatat pada BAST.'
          : 'Pengajuan penugasan ditolak.');
      } catch (e) {
        notify('Gagal memproses penugasan: ' + e.toString());
      }
    }
    reason.dispose();
    handedBy.dispose();
  }

  Widget v5CustodyForAsset(AssetRecord asset) {
    final history = store.assignments.where((a) =>
      a.lines.any((l) => l.assetId == asset.id)).toList();
    return surface(child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      sectionHeader('Assigned Assets',
        subtitle: 'Riwayat penugasan dan penguasaan unit ' + asset.code),
      const SizedBox(height: 11),
      if (asset.assignedEmployeeId.isNotEmpty) ...[
        v4ReadonlyField('Penerima aktif',
          store.employeeById(asset.assignedEmployeeId)?.name ??
            'Karyawan tidak ditemukan'),
        const SizedBox(height: 10),
      ] else if (asset.holder.trim().isNotEmpty) ...[
        const Text('PIC ini berasal dari data lama berbasis teks. '
          'Belum terhubung otomatis ke Master Karyawan.',
          style: TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 10),
      ],
      if (history.isEmpty)
        const Text('Belum ada penugasan terstruktur pada aset ini.',
          style: TextStyle(color: muted))
      else for (final batch in history)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(batch.draftReference),
          subtitle: Text(
            (batch.employeeSnapshot['name']?.toString() ?? '-') +
            ' · ' + batch.status),
          trailing: const Icon(Icons.chevron_right, color: muted),
          onTap: () => v4Change(() {
            selected = null;
            selectedAssignment = batch;
            page = 7;
          }),
        ),
    ]));
  }
}
