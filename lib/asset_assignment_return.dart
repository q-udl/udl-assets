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
  final notes = TextEditingController();
  final receivedBy = TextEditingController();
  late String location;
  String receivingAreaId = '', receivingSpotId = '';
  bool saving = false;
  String? error;

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

  Future<void> uploadReturnPhoto(AssignedAssetLine line) async {
    final asset = widget.store.assignmentAsset(line.assetId);
    if (asset == null) return;
    try {
      final chosen = await AssetPhotoPicker.choose(context);
      if (chosen == null || !mounted) return;
      await widget.store.addPhoto(
        asset, chosen.bytes, chosen.fileName, 'Dokumentasi Kondisi',
        note: 'Dokumentasi saat pengembalian: ' +
          widget.assignment.draftReference);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Foto kondisi ditambahkan ke dokumentasi aset.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
          error = 'Gagal menambah foto kondisi: ' + e.toString());
      }
    }
  }

  Future<void> save() async {
    if (saving) { return; }
    if (selected.isEmpty) {
      setState(() => error = 'Pilih minimal satu aset yang dikembalikan.');
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
        receivedByName: receivedBy.text,
        notes: notes.text,
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
          'Penugasan: ' + widget.assignment.draftReference +
          ' · ' + (widget.assignment.employeeSnapshot['name']?.toString() ?? '-') +
          '. Pilih hanya aset yang benar-benar dikembalikan. '
          'Aset lainnya tetap menjadi tanggung jawab karyawan.',
          style: const TextStyle(color: ink, fontSize: 12)),
      ),
      const SizedBox(height: 13),
      Card(child: Padding(padding: const EdgeInsets.all(20),
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
                  final accessory = TextFormField(
                    key: ValueKey('return-accessories-' + line.id),
                    initialValue: accessories[line.id] ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Kelengkapan yang kembali',
                      hintText: 'Contoh: adaptor, kabel, tas'),
                    onChanged: (value) { widget.onDirty?.call();
                      accessories[line.id] = value; },
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (box.maxWidth >= 580)
                        Row(children: [
                          Expanded(child: selector),
                          const SizedBox(width: 12),
                          Expanded(child: accessory),
                        ])
                      else ...[
                        selector,
                        const SizedBox(height: 10),
                        accessory,
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
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => uploadReturnPhoto(line),
                        icon: const Icon(Icons.add_a_photo_outlined, size: 17),
                        label: const Text('Tambah Foto Kondisi Kembali'),
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
      Card(child: Padding(padding: const EdgeInsets.all(20),
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
                labelText: 'Nama penerima di GA (isian simulasi)'));
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
      const SizedBox(height: 12),
      const Text('Pencatatan di aplikasi bersifat simulasi lokal. '
        'Tanda tangan dan pengesahan dilakukan terpisah '
        'pada dokumen BA perusahaan.',
        style: TextStyle(fontSize: 11.5, color: muted)),
      if (error != null) ...[
        const SizedBox(height: 10),
        Text(error!, style: const TextStyle(color: danger)),
      ],
      const SizedBox(height: 16),
      LayoutBuilder(builder:(ctx,box)=>Align(
        alignment:Alignment.centerRight,
        child:SizedBox(
          width:box.maxWidth<530?box.maxWidth:null,
          child:FilledButton.icon(
            key:const ValueKey('return-submit'),
            onPressed:saving?null:save,
            icon:const Icon(Icons.assignment_return_outlined),
            label:Text(saving?'Mencatat...':'Catat Pengembalian & Draf BA',
              textAlign:TextAlign.center),
          ),
        ),
      )),
    ]);
  }
}
