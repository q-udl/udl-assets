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
              batch.status == 'Aktif' ? green : amber,
            fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 9, runSpacing: 9, children: [
          outlineButton('Cetak / Simpan PDF Draf BAST',
            Icons.picture_as_pdf_outlined, () async {
            try {
              await AssetBastPdf.printHandover(batch);
            } catch (e) {
              notify('PDF gagal dibuat: ' + e.toString());
            }
          }),
          if (batch.isPending) ...[
            primaryButton('Terima (Simulasi)',
              Icons.check_circle_outline, () =>
                v5ConfirmAssignment(batch, true)),
            outlineButton('Tolak (Simulasi)', Icons.cancel_outlined,
              () => v5ConfirmAssignment(batch, false)),
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
          detailValue('Kode', batch.employeeSnapshot['code']?.toString() ?? ''),
          detailValue('Jabatan',
            batch.employeeSnapshot['jobTitle']?.toString() ?? ''),
          detailValue('Unit / Departemen',
            (batch.employeeSnapshot['unit']?.toString() ?? '-') + ' / ' +
            (batch.employeeSnapshot['department']?.toString() ?? '-')),
          detailValue('Lokasi Kerja',
            batch.employeeSnapshot['workLocation']?.toString() ?? ''),
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
          detailValue('Konfirmasi simulasi',
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
                color: line.state == 'Aktif' ? green : muted,
                fontSize: 11, fontWeight: FontWeight.w700)),
              const Icon(Icons.chevron_right_rounded, color: muted),
            ]),
            onTap: () {
              final asset = store.assignmentAsset(line.assetId);
              if (asset != null) v4Change(() {
                selected = asset;
                page = 1;
              });
            },
          ),
      ])),
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
              await AssetBastPdf.printReturn(batch, receipt);
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
    var error = '';
    final approved = await v4ShowModal<bool>(
      title: accepted ? 'Terima Penugasan (Simulasi)' :
        'Tolak Penugasan (Simulasi)',
      subtitle: batch.draftReference,
      maxWidth: 590,
      body: (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Tindakan ini dioperasikan tanpa akun penerima. '
          'Belum menjadi penerimaan yang terautentikasi.'),
        const SizedBox(height: 12),
        v4ReadonlyField('Nama karyawan',
          batch.employeeSnapshot['name']?.toString() ?? ''),
        const SizedBox(height: 10),
        v4ReadonlyField('Jumlah aset',
          batch.lines.length.toString()),
        const SizedBox(height: 15),
        TextField(
          controller: reason, maxLines: 3,
          decoration: v4ModalDecoration(
            accepted ? 'Catatan (opsional)' : 'Alasan penolakan *')),
        if (error.isNotEmpty) ...[
          const SizedBox(height: 10), v4ModalError(error),
        ],
      ]),
      actions: (ctx, update) => [
        OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal')),
        FilledButton(onPressed: () {
          if (!accepted && reason.text.trim().isEmpty) {
            update(() => error = 'Alasan penolakan wajib diisi.');
          } else {
            Navigator.pop(ctx, true);
          }
        }, child: Text(accepted ? 'Konfirmasi Simulasi' : 'Tolak')),
      ],
    );
    if (approved == true) {
      try {
        await store.confirmAssignment(batch, accepted, reason.text);
        repaint();
        notify(accepted
          ? 'Penugasan aktif (simulasi); tanggung jawab tercatat.'
          : 'Pengajuan penugasan ditolak.');
      } catch (e) {
        notify('Gagal memproses: ' + e.toString());
      }
    }
    reason.dispose();
  }
}
