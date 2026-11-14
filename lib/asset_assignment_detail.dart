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
            Text(batch.assignmentReference, style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 4),
            const Text('Referensi penugasan',
              style: TextStyle(fontSize: 11.5, color: muted)),
          ])),
          badge(batch.status, compact: true,
            toneColor: batch.isOverdue ? danger : null),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 9, runSpacing: 9, children: [
          if (batch.isPending) ...[
            primaryButton('Konfirmasi Serah Terima',
              Icons.check_circle_outline, () =>
                v5ConfirmAssignment(batch, true),
              tone: AssetActionTone.success),
            outlineButton('Batalkan Penugasan', Icons.cancel_outlined,
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
          if (batch.canPrintBast)
          outlineButton('Lihat / Cetak BAST',
            Icons.picture_as_pdf_outlined, () async {
            try {
              await AssetBastPdf.printHandover(batch, store: store);
            } catch (error) {
              notify('PDF gagal dibuat: ' + error.toString());
            }
          }),
          if (batch.isHandoverConfirmed && !batch.canPrintBast)
            outlineButton('Lengkapi Data BAST', Icons.edit_document,
              () => v5CompleteBastMetadata(batch)),
        ]),
        const SizedBox(height: 12),
        Text(
          batch.status == 'Dibatalkan'
            ? 'Penugasan dibatalkan sebelum serah terima. '
              'Aset kembali tersedia; alasan tersimpan di riwayat.'
            : 'Serah terima dicatat oleh petugas. '
              'Pencatatan ini bukan tanda tangan atau persetujuan '
              'karyawan yang terverifikasi.',
          style: const TextStyle(fontSize: 12, color: muted)),
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
            detailValue('Penyerah', batch.handedOverByName),
          if (batch.handedOverByJobTitle.isNotEmpty)
            detailValue('Jabatan Penyerah', batch.handedOverByJobTitle),
          if (batch.handedOverByUnit.isNotEmpty)
            detailValue('Unit Penyerah', batch.handedOverByUnit),
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
          detailValue('Konfirmasi serah terima',
            batch.acceptedAt.isEmpty ? 'Belum ada' :
              dateText(batch.acceptedAt)),
          if (batch.handoverLocation.isNotEmpty)
            detailValue('Lokasi Serah Terima', batch.handoverLocation),
          if (batch.bastNumber.isNotEmpty)
            detailValue('Nomor BAST', batch.bastNumber),
          if (batch.cancelledAt.isNotEmpty)
            detailValue('Dibatalkan pada', dateText(batch.cancelledAt)),
          detailValue('Aset masih dikuasai',
            batch.activeCount.toString() + ' dari ' +
            batch.lines.length.toString()),
          detailValue('Catatan', batch.notes.isEmpty ? '-' : batch.notes),
          if (batch.cancellationReason.isNotEmpty)
            detailValue('Alasan pembatalan', batch.cancellationReason),
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
          compactCustodyAssetRow(
            name: line.assetName,
            code: line.assetCode,
            condition: line.handoverCondition,
            accessories: line.accessories,
            status: line.state,
            photo: store.primaryPhotoFor(line.assetId),
            onTap: () {
              final asset = store.assignmentAsset(line.assetId);
              if (asset == null) return;
              v4Change(() { selected = asset; page = 1; });
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
                    InkWell(
                      onTap: () => v5ShowProof(photo, line.assetCode),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.memory(photo.bytes,
                          height: 115, width: 205, fit: BoxFit.cover))),
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
        else for (final receipt in receipts) Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            const Icon(Icons.description_outlined, color: blue, size: 22),
            const SizedBox(width: 11),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(receipt.draftReference, maxLines: 2,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(receipt.lines.length.toString() +
                  ' aset · ' + dateText(receipt.createdAt),
                  style: const TextStyle(color: muted, fontSize: 11)),
              ],
            )),
            TextButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
              label: const Text('Lihat / Cetak PDF'),
              onPressed: () async {
                try {
                  await AssetBastPdf.printReturn(batch, receipt, store: store);
                } catch (error) {
                  notify('PDF gagal dibuat: ' + error.toString());
                }
              },
            ),
          ]),
        ),
      ])),
    ]);
  }

  Future<void> v5ShowProof(
      AssetEvidencePhoto photo, String code) async {
    await v4ShowModal<void>(
      title: 'Foto Bukti Transaksi',
      subtitle: code + ' · ' + dateText(photo.recordedAt),
      maxWidth: 780,
      body: (context, update) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .55,
        child: InteractiveViewer(
          minScale: 0.8, maxScale: 5,
          child: Center(child: Image.memory(photo.bytes,
            fit: BoxFit.contain, filterQuality: FilterQuality.high)),
        ),
      ),
      actions: (context, update) => [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup')),
      ],
    );
  }

  Future<void> v5ConfirmAssignment(
      AssetAssignment batch, bool accepted) async {
    final reason = TextEditingController();
    final handedBy = TextEditingController();
    final handedByJob = TextEditingController();
    final handedByUnit = TextEditingController();
    final handoverAt = TextEditingController();
    final bastNumber = TextEditingController();
    final proofPhotos = <String, SelectedAssetPhoto>{};
    var error = '';
    Future<dynamic>? modalFullyClosed;
    bool hasChanges() => reason.text.isNotEmpty ||
      handedBy.text.isNotEmpty || handedByJob.text.isNotEmpty ||
      handedByUnit.text.isNotEmpty || handoverAt.text.isNotEmpty ||
      bastNumber.text.isNotEmpty || proofPhotos.isNotEmpty;
    final approved = await v4ShowModal<bool>(
      title: accepted ? 'Konfirmasi Serah Terima' :
        'Batalkan Penugasan',
      subtitle: batch.assignmentReference,
      maxWidth: 650,
      isDirty: hasChanges,
      body: (ctx, update) {
        // The showDialog Future resolves before its reverse animation ends.
        // Keep controllers alive until the overlay is fully removed.
        modalFullyClosed ??= ModalRoute.of(ctx)?.completed;
        return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(accepted
          ? 'Konfirmasi ini mencatat serah terima oleh petugas, '
            'bukan persetujuan karyawan yang terautentikasi.'
          : 'Batalkan draf sebelum serah terima fisik. '
            'Reservasi aset akan dilepas, dan alasan pembatalan '
            'dicatat dalam riwayat.'),
        const SizedBox(height: 12),
        v4ReadonlyField('Nama karyawan',
          batch.employeeSnapshot['name']?.toString() ?? ''),
        if (accepted) ...[
          const SizedBox(height: 12),
          TextField(controller: handedBy,
            decoration: v4ModalDecoration('Penyerah (nama petugas) *')),
          const SizedBox(height: 10),
          v4ModalPair(
            TextField(controller: handedByJob,
              decoration: v4ModalDecoration('Jabatan Penyerah (opsional)')),
            TextField(controller: handedByUnit,
              decoration: v4ModalDecoration('Unit Penyerah (opsional)')),
          ),
          const SizedBox(height: 10),
          TextField(controller: handoverAt,
            decoration: v4ModalDecoration('Lokasi serah terima aktual *')),
          const SizedBox(height: 10),
          TextField(controller: bastNumber,
            decoration: v4ModalDecoration('Nomor BAST (sesuai DMS) *')),
          const SizedBox(height: 5),
          const Text('Nomor resmi diisi dari DMS perusahaan, '
            'belum diterbitkan otomatis oleh UDL Assets.',
            style: TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 10),
        ],
        v4ReadonlyField('Jumlah aset', batch.lines.length.toString()),
        const SizedBox(height: 15),
        TextField(
          controller: reason, maxLines: 3,
          decoration: v4ModalDecoration(
            accepted ? 'Catatan (opsional)' : 'Alasan pembatalan *')),
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
      ]);
      },
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
              update(() => error = 'Alasan pembatalan wajib diisi.');
            } else if (accepted && handedBy.text.trim().isEmpty) {
              update(() => error = 'Nama pihak yang menyerahkan wajib diisi.');
            } else if (accepted && handoverAt.text.trim().isEmpty) {
              update(() => error = 'Lokasi serah terima wajib diisi.');
            } else if (accepted && bastNumber.text.trim().isEmpty) {
              update(() => error = 'Nomor BAST dari DMS wajib diisi.');
            } else if (accepted &&
                batch.lines.any((l) => !proofPhotos.containsKey(l.assetId))) {
              update(() => error =
                'Lengkapi foto bukti setiap aset sebelum konfirmasi serah terima.');
            } else {
              Navigator.pop(ctx, true);
            }
          },
          child: Text(accepted
            ? 'Konfirmasi Serah Terima' : 'Batalkan Penugasan')),
      ],
    );
    if (approved == true) {
      try {
        if (accepted) {
          await store.confirmAssignment(batch, true, reason.text,
            proofPhotos: proofPhotos,
            handedOverByName: handedBy.text,
            handedOverByJobTitle: handedByJob.text,
            handedOverByUnit: handedByUnit.text,
            handoverLocation: handoverAt.text,
            bastNumber: bastNumber.text);
        } else {
          await store.cancelAssignment(batch, reason.text);
        }
        repaint();
        notify(accepted
          ? 'Penugasan aktif; foto bukti tercatat pada BAST.'
          : 'Penugasan dibatalkan. Aset kembali tersedia.');
      } catch (e) {
        notify('Gagal memproses penugasan: ' + e.toString());
      }
    }
    if (modalFullyClosed != null) await modalFullyClosed;
    reason.dispose();
    handedBy.dispose();
    handedByJob.dispose();
    handedByUnit.dispose();
    handoverAt.dispose();
    bastNumber.dispose();
  }

  Future<void> v5CompleteBastMetadata(AssetAssignment batch) async {
    if (!batch.isHandoverConfirmed || batch.canPrintBast) return;
    final number = TextEditingController(text: batch.bastNumber);
    final location = TextEditingController(text: batch.handoverLocation);
    final penyerah = TextEditingController(text: batch.handedOverByName);
    Future<dynamic>? fullyClosed;
    var error = '';
    final approved = await v4ShowModal<bool>(
      title: 'Lengkapi Data BAST Historis',
      subtitle: batch.assignmentReference,
      maxWidth: 590,
      isDirty: () => number.text != batch.bastNumber ||
        location.text != batch.handoverLocation ||
        penyerah.text != batch.handedOverByName,
      body: (ctx, update) {
        fullyClosed ??= ModalRoute.of(ctx)?.completed;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Isi hanya berdasarkan dokumen serah terima yang dapat '
              'dipertanggungjawabkan. Tanggal konfirmasi historis '
              'tidak akan diubah.',
              style: TextStyle(color: muted, fontSize: 12)),
            const SizedBox(height: 12),
            v4ReadonlyField('Waktu Serah Terima',
              dateText(batch.acceptedAt)),
            const SizedBox(height: 12),
            TextField(
              controller: number,
              readOnly: batch.bastNumber.isNotEmpty,
              decoration: v4ModalDecoration('Nomor BAST dari DMS *')),
            const SizedBox(height: 12),
            TextField(
              controller: location,
              readOnly: batch.handoverLocation.isNotEmpty,
              decoration: v4ModalDecoration('Lokasi serah terima aktual *')),
            const SizedBox(height: 12),
            TextField(
              controller: penyerah,
              readOnly: batch.handedOverByName.isNotEmpty,
              decoration: v4ModalDecoration('Penyerah (nama petugas) *')),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 10),
              v4ModalError(error),
            ],
          ],
        );
      },
      actions: (ctx, update) => [
        OutlinedButton(
          onPressed: () => assetRequestModalClose(ctx,
            isDirty: () => number.text != batch.bastNumber ||
              location.text != batch.handoverLocation ||
              penyerah.text != batch.handedOverByName),
          child: const Text('Batal')),
        FilledButton.icon(
          icon: const Icon(Icons.save_outlined, size: 17),
          label: const Text('Simpan Data BAST'),
          onPressed: () {
            if (number.text.trim().isEmpty ||
                location.text.trim().isEmpty ||
                penyerah.text.trim().isEmpty) {
              update(() => error = 'Lengkapi nomor, lokasi dan Penyerah.');
              return;
            }
            Navigator.pop(ctx, true);
          }),
      ],
    );
    if (approved == true) {
      try {
        await store.completeBastMetadata(batch,
          bastNumber: number.text,
          handoverLocation: location.text,
          handedOverByName: penyerah.text);
        repaint();
        notify('Data BAST lengkap; dokumen dapat dilihat dan dicetak.');
      } catch (e) {
        notify('Data BAST gagal disimpan: ' + e.toString());
      }
    }
    if (fullyClosed != null) await fullyClosed;
    number.dispose();
    location.dispose();
    penyerah.dispose();
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
          title: Text(batch.assignmentReference),
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
