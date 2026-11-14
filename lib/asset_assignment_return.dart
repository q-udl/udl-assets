part of 'main.dart';

class V5ReturnForm extends StatefulWidget {
  final AssetStore store;
  final AssetAssignment assignment;
  final void Function(AssetReturnReceipt) onCompleted;
  final VoidCallback? onDirty;
  const V5ReturnForm({
    super.key, required this.store,
    required this.assignment, required this.onCompleted,
    this.onDirty,
  });

  @override
  State<V5ReturnForm> createState() => _V5ReturnFormState();
}

class _V5ReturnFormState extends State<V5ReturnForm> {
  final selected = <String>{};
  final condition = <String,String>{};
  final accessories = <String,String>{};
  final notesByLine = <String,String>{};
  final proofPhotos = <String, SelectedAssetPhoto>{};
  final notes = TextEditingController();
  final receivedBy = TextEditingController();
  late String location;
  String receivingAreaId = '', receivingSpotId = '';
  bool saving = false;
  int stepIndex = 0;
  String? error;

  void moveStep(int next) {
    if (next > stepIndex && stepIndex == 0) {
      if (selected.isEmpty) {
        setState(() => error = 'Pilih aset yang akan dikembalikan.');
        return;
      }
      final missing = widget.assignment.lines.any((line) =>
        selected.contains(line.id) && !proofPhotos.containsKey(line.assetId));
      if (missing) {
        setState(() => error = 'Lengkapi foto bukti setiap aset terpilih.');
        return;
      }
    }
    if (next > stepIndex && stepIndex == 1 &&
        receivedBy.text.trim().isEmpty) {
      setState(() => error = 'Nama Yang Menerima wajib diisi.');
      return;
    }
    setState(() { stepIndex = next; error = null; });
  }
  bool get hasUnsavedChanges =>
    selected.isNotEmpty || condition.isNotEmpty || accessories.isNotEmpty ||
    notesByLine.values.any((v) => v.trim().isNotEmpty) ||
    proofPhotos.isNotEmpty ||
    notes.text.trim().isNotEmpty || receivedBy.text.trim().isNotEmpty ||
    receivingAreaId.isNotEmpty || receivingSpotId.isNotEmpty ||
    (location != (widget.store.activeSites.isEmpty
      ? '' : widget.store.activeSites.first.name));

  @override
  void initState() {
    super.initState();
    notes.addListener(() => widget.onDirty?.call());
    receivedBy.addListener(() => widget.onDirty?.call());
    location = widget.store.activeSites.isEmpty
      ? '' : widget.store.activeSites.first.name;
  }

  @override
  void dispose() {
    notes.dispose();
    receivedBy.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving) { return; }
    if (receivedBy.text.trim().isEmpty) {
      setState(() => error = 'Nama pihak yang menerima pengembalian wajib diisi.');
      return;
    }
    if (selected.isEmpty) {
      setState(() => error = 'Pilih minimal satu aset yang dikembalikan.');
      return;
    }
    final selectedAssets = widget.assignment.lines
      .where((line) => selected.contains(line.id)).toList();
    if (selectedAssets.any((line) => !proofPhotos.containsKey(line.assetId))) {
      setState(() => error =
        'Setiap aset yang dikembalikan wajib memiliki foto bukti.');
      return;
    }
    setState(() { error = null; saving = true; });
    try {
      final inspections = <String, AssetReturnInput>{
        for (final id in selected)
          id: AssetReturnInput(
            condition: condition[id] ?? 'Baik',
            accessories: accessories[id] ?? '',
            notes: notesByLine[id] ?? ''),
      };
      final receipt = await widget.store.returnAssignedAssets(
        record: widget.assignment,
        inspections: inspections,
        receivingLocation: location,
        receivingPlacement: AssetPlacement(
          widget.store.siteByName(location)?.id ?? '',
          areaId: receivingAreaId, spotId: receivingSpotId),
        receivedByName: receivedBy.text.trim(),
        notes: notes.text,
        proofPhotos: {
          for (final line in selectedAssets)
            line.assetId: proofPhotos[line.assetId]!,
        },
      );
      if (mounted) widget.onCompleted(receipt);
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.assignment.lines
      .where((l) => l.state == 'Aktif').toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF5FC),
          borderRadius: BorderRadius.circular(12)),
        child: Text(
          'Penugasan: ' + widget.assignment.assignmentReference +
          ' · ' + (widget.assignment.employeeSnapshot['name']?.toString() ?? '-') +
          '. Pilih hanya aset yang benar-benar dikembalikan. '
          'Aset lainnya tetap menjadi tanggung jawab karyawan.',
          style: const TextStyle(color: ink, fontSize: 12)),
      ),
      const SizedBox(height: 13),
      Row(children: [
        for (var index = 0; index < 3; index++) ...[
          if (index != 0) const SizedBox(width: 6),
          Expanded(child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: index <= stepIndex ? blue : const Color(0xFFE4EAF1),
              borderRadius: BorderRadius.circular(10)))),
        ],
      ]),
      const SizedBox(height: 11),
      Text('Langkah ' + (stepIndex + 1).toString() + ' dari 3 · ' +
        const ['Pilih Aset', 'Informasi Pengembalian', 'Tinjau & Konfirmasi'][stepIndex],
        style: const TextStyle(color: ink, fontWeight: FontWeight.w700)),
      const SizedBox(height: 13),
      if (stepIndex == 0) Card(child: Padding(padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          const Text('1. Pilih Aset & Periksa Kondisi',
            style: TextStyle(color: ink,
              fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 9),
          Text(selected.length.toString() + ' dari ' +
            active.length.toString() + ' aset dipilih untuk dikembalikan',
            style: const TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 12),
          if (active.isEmpty)
            const Text('Seluruh aset telah dikembalikan.',
              style: TextStyle(color: muted)),
          for (final line in active) ...[
            CheckboxListTile(
              value: selected.contains(line.id),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(line.assetName,
                style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(line.assetCode + ' · kondisi saat penyerahan: ' +
                line.handoverCondition),
              onChanged: (checked) { widget.onDirty?.call(); setState(() {
                if (checked == true) {
                  selected.add(line.id);
                  condition[line.id] = widget.store.assignmentAsset(
                    line.assetId)?.condition ?? line.handoverCondition;
                } else {
                  selected.remove(line.id);
                  proofPhotos.remove(line.assetId);
                }
              }); },
            ),
            if (selected.contains(line.id))
              Padding(
                padding: const EdgeInsets.fromLTRB(36, 0, 4, 15),
                child: LayoutBuilder(builder: (ctx, box) {
                  final selector = DropdownButtonFormField<String>(
                    initialValue: condition[line.id],
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Kondisi saat dikembalikan *'),
                    items: ['Baru','Baik','Cukup','Kurang Baik','Rusak']
                      .map((value) => DropdownMenuItem(
                        value: value, child: Text(value))).toList(),
                    onChanged: (value) { widget.onDirty?.call(); setState(() =>
                      condition[line.id] = value ?? 'Baik'); },
                  );
                  final includedItems = TextFormField(
                    key: ValueKey('return-accessories-' + line.id),
                    initialValue: accessories[line.id] ?? '',
                    decoration: InputDecoration(
                      labelText: line.hasLegacyAccessories
                        ? 'Kelengkapan historis yang kembali (opsional)'
                        : 'Item Penyerta Non-Aset kembali (opsional)',
                      hintText: 'Tuliskan hanya barang tanpa kode aset yang benar-benar kembali',
                      helperText: line.hasLegacyAccessories
                        ? 'Catatan lama belum diverifikasi sebagai non-aset.'
                        : 'Barang dengan kode aset dikembalikan sebagai unit tersendiri.',
                      helperMaxLines: 2),
                    onChanged: (value) { widget.onDirty?.call();
                      accessories[line.id] = value; },
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (line.accessories.trim().isNotEmpty) ...[
                        Text(line.itemRecordLabel + ' saat penyerahan: ' +
                          line.accessories,
                          style: const TextStyle(fontSize: 11.5, color: muted)),
                        const SizedBox(height: 10),
                      ],
                      if (box.maxWidth >= 580)
                        Row(children: [
                          Expanded(child: selector),
                          const SizedBox(width: 12),
                          Expanded(child: includedItems),
                        ])
                      else ...[
                        selector,
                        const SizedBox(height: 10),
                        includedItems,
                      ],
                      const SizedBox(height: 11),
                      TextFormField(
                        key: ValueKey('return-note-' + line.id),
                        initialValue: notesByLine[line.id] ?? '',
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Temuan pemeriksaan / kerusakan',
                          hintText: 'Catat selisih atau kerusakan'),
                        onChanged: (value) { widget.onDirty?.call(); notesByLine[line.id] = value; },
                      ),
                      const SizedBox(height: 12),
                       assetEvidencePicker(
                         context: context,
                         assetCode: line.assetCode,
                         title: 'Foto Bukti Pengembalian',
                         selected: proofPhotos[line.assetId],
                         testKey: 'rv29-return-proof-' + line.id,
                         onSelected: (photo) {
                           widget.onDirty?.call();
                           setState(() {
                             proofPhotos[line.assetId] = photo;
                             error = null;
                           });
                         },
                         onRemove: () {
                           widget.onDirty?.call();
                           setState(() => proofPhotos.remove(line.assetId));
                         },
                       ),
                       const SizedBox(height: 6),
                      if (['Rusak','Kurang Baik'].contains(condition[line.id]))
                        const Padding(
                          padding: EdgeInsets.only(top: 7),
                          child: Text(
                            'Aset ini masuk status Dalam Perbaikan '
                            'setelah pengembalian.',
                            style: TextStyle(fontSize: 12, color: danger)),
                        ),
                    ],
                  );
                }),
              ),
            const Divider(height: 1, color: border),
          ],
        ]),
      )),
      const SizedBox(height: 13),
      if (stepIndex == 1) Card(child: Padding(padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          const Text('2. Informasi Penerimaan Kembali',
            style: TextStyle(color: ink,
              fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 13),
          LayoutBuilder(builder: (ctx, box) {
            final locationSelect = DropdownButtonFormField<String>(
              initialValue: location,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Lokasi aset diterima kembali *'),
              items: widget.store.activeSites.map((site) =>
                DropdownMenuItem(value: site.name, child: Text(site.name))).toList(),
              onChanged: (value) { widget.onDirty?.call(); setState(() {
                location = value ?? location;
                receivingAreaId = '';
                receivingSpotId = '';
              }); },
            );
            final officer = TextField(
              controller: receivedBy,
              decoration: const InputDecoration(
                labelText: 'Yang Menerima (nama petugas) *'));
            if (box.maxWidth < 620) {
              return Column(children: [
                locationSelect, const SizedBox(height: 12), officer]);
            }
            return Row(children: [
              Expanded(child: locationSelect),
              const SizedBox(width: 13),
              Expanded(child: officer),
            ]);
          }),
          const SizedBox(height: 13),
          LayoutBuilder(builder: (ctx, box) {
            final area = DropdownButtonFormField<String>(
              key: ValueKey('return-area-' + location),
              initialValue: receivingAreaId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Area (opsional)'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Belum ditentukan')),
                for (final a in (widget.store.siteByName(location)?.areas
                  .where((a)=>a.active) ?? <AssetArea>[]))
                  DropdownMenuItem(value: a.id, child: Text(a.name)),
              ],
              onChanged: (value) { widget.onDirty?.call(); setState(() {
                receivingAreaId = value ?? '';
                receivingSpotId = '';
              }); },
            );
            final spot = DropdownButtonFormField<String>(
              key: ValueKey('return-spot-' + receivingAreaId),
              initialValue: receivingSpotId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Titik Penempatan (opsional)'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Belum ditentukan')),
                for (final a in (widget.store.siteByName(location)?.areas
                  ?? <AssetArea>[]))
                  if (a.id == receivingAreaId)
                    for (final p in a.spots.where((p)=>p.active))
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (value) { widget.onDirty?.call();
                setState(() => receivingSpotId = value ?? ''); },
            );
            if (box.maxWidth < 620) {
              return Column(children: [
                area, const SizedBox(height: 12), spot]);
            }
            return Row(children: [
              Expanded(child: area), const SizedBox(width: 13),
              Expanded(child: spot)]);
          }),
          const SizedBox(height: 13),
          TextField(
            controller: notes, maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan pengembalian (opsional)')),
        ]),
      )),
      if (stepIndex == 2) Card(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('3. Tinjau & Konfirmasi',
              style: TextStyle(color: ink, fontSize: 14,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text('Yang Mengembalikan: ' +
              (widget.assignment.employeeSnapshot['name']?.toString() ?? '-')),
            const SizedBox(height: 5),
            Text('Yang Menerima: ' + receivedBy.text.trim()),
            const SizedBox(height: 5),
            Text('Lokasi: ' + location),
            const SizedBox(height: 5),
            Text('Jumlah aset: ' + selected.length.toString()),
            const Divider(height: 25),
            for (final line in widget.assignment.lines)
              if (selected.contains(line.id)) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                child: Text('• ' + line.assetName + ' · ' + line.assetCode +
                  ' · ' + (condition[line.id] ?? line.handoverCondition),
                  style: const TextStyle(fontSize: 12))),
              if (selected.contains(line.id) &&
                  (accessories[line.id] ?? '').trim().isNotEmpty)
                Padding(padding: const EdgeInsets.only(left: 14, bottom: 6),
                  child: Text(
                    (line.hasLegacyAccessories ? 'Kelengkapan arsip kembali: '
                      : 'Penyerta non-aset kembali: ') +
                    accessories[line.id]!.trim(),
                    style: const TextStyle(fontSize: 11, color: muted))),
              ],
            const SizedBox(height: 8),
            const Text('Pastikan pemeriksaan dan bukti foto sudah sesuai '
              'sebelum menyimpan pengembalian.',
              style: TextStyle(color: muted, fontSize: 12)),
          ],
        ),
      )),
      const SizedBox(height: 12),
      const Text('Nama para pihak dicatat untuk dokumen BA. '
        'Tanda tangan dan persetujuan tetap dilakukan dan '
        'diverifikasi secara terpisah.',
        style: TextStyle(fontSize: 11.5, color: muted)),
      if (error != null) ...[
        const SizedBox(height: 10),
        Text(error!, style: const TextStyle(color: danger)),
      ],
      const SizedBox(height: 16),
      LayoutBuilder(builder: (ctx, bounds) {
        final previous = OutlinedButton.icon(
          onPressed: saving || stepIndex == 0 ? null :
            () => moveStep(stepIndex - 1),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Sebelumnya'));
        final next = FilledButton.icon(
          key: const ValueKey('return-submit'),
          onPressed: saving ? null : stepIndex < 2
            ? () => moveStep(stepIndex + 1) : save,
          icon: Icon(stepIndex < 2 ? Icons.arrow_forward_rounded :
            Icons.assignment_return_outlined),
          label: Text(stepIndex < 2 ? 'Berikutnya' :
            saving ? 'Mencatat...' : 'Konfirmasi Pengembalian'));
        if (bounds.maxWidth < 530) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 48, child: next),
              if (stepIndex > 0) ...[
                const SizedBox(height: 10),
                SizedBox(height: 48, child: previous),
              ],
            ]);
        }
        return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (stepIndex > 0) ...[
            previous, const SizedBox(width: 10),
          ],
          next,
        ]);
      }),
    ]);
  }
}
