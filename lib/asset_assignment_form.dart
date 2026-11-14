part of 'main.dart';

class V5AssignmentForm extends StatefulWidget {
  final AssetStore store;
  final void Function(AssetAssignment) onCreated;
  final VoidCallback onOpenEmployees;
  final VoidCallback? onDirty;
  const V5AssignmentForm({
    super.key, required this.store,
    required this.onCreated, required this.onOpenEmployees,
    this.onDirty,
  });

  @override
  State<V5AssignmentForm> createState() => _V5AssignmentFormState();
}

class _V5AssignmentFormState extends State<V5AssignmentForm> {
  String? employeeId;
  String kind = 'Berkelanjutan';
  String assetSearch = '';
  final due = TextEditingController();
  final notes = TextEditingController();
  final selectedIds = <String>{};
  final accessories = <String, String>{};
  bool saving = false;
  String? error;
  bool get hasUnsavedChanges =>
    employeeId != null || kind != 'Berkelanjutan' ||
    due.text.trim().isNotEmpty || notes.text.trim().isNotEmpty ||
    selectedIds.isNotEmpty || accessories.isNotEmpty;

  @override
  void initState() {
    super.initState();
    due.addListener(() => widget.onDirty?.call());
    notes.addListener(() => widget.onDirty?.call());
  }

  @override
  void dispose() {
    due.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving) return;
    setState(() => error = null);
    if (employeeId == null || selectedIds.isEmpty) {
      setState(() => error = 'Pilih karyawan dan minimal satu aset.');
      return;
    }
    if (kind == 'Sementara' && due.text.trim().isEmpty) {
      setState(() => error = 'Isi tanggal kembali untuk penugasan sementara.');
      return;
    }
    final assignee = widget.store.employeeById(employeeId!);
    final confirmed = await assetConfirmDialog(
      context,
      title: 'Tinjau Penugasan Aset',
      message: 'Penerima: ' + (assignee?.name ?? '-') +
        '\nJumlah aset: ' + selectedIds.length.toString() +
        '\nJenis: ' + kind +
        '\nPastikan identitas penerima dan aset sudah sesuai. '
        'Pembuatan draf belum membuktikan serah terima fisik.',
      confirmLabel: 'Buat Draf Penugasan');
    if (!confirmed || !mounted) return;
    setState(() => saving = true);
    try {
      final batch = await widget.store.createAssignment(
        employeeId: employeeId!,
        kind: kind,
        assetIds: selectedIds.toList(),
        accessories: accessories,
        dueDate: kind == 'Sementara' ? due.text.trim() : '',
        notes: notes.text.trim(),
      );
      if (mounted) widget.onCreated(batch);
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget infoLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(text, style: const TextStyle(
      color: ink, fontWeight: FontWeight.w800, fontSize: 14)));

  @override
  Widget build(BuildContext context) {
    final activeEmployees = widget.store.employees
      .where((e) => e.active).toList()
      ..sort((a,b) => a.name.compareTo(b.name));
    final available = widget.store.assets
      .where(widget.store.canAssignAsset).toList()
      ..sort((a,b) => a.code.compareTo(b.code));
    final filtered = available.where((a) =>
      [a.code, a.name, a.category, a.location].join(' ')
        .toLowerCase().contains(assetSearch.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF5FC),
            borderRadius: BorderRadius.circular(12)),
          child: const Text(
            'Satu penugasan dapat memuat beberapa aset. Dokumen BAST '
            'hanya tersedia setelah serah terima dikonfirmasi. '
            'Aset belum berpindah penguasaan selama menunggu serah terima.',
            style: TextStyle(color: ink, fontSize: 12)),
        ),
        const SizedBox(height: 13),
        Card(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              infoLabel('1. Karyawan Penerima'),
              if (activeEmployees.isEmpty) ...[
                const Text('Belum ada karyawan aktif. '
                  'Tambahkan melalui Master Karyawan.',
                  style: TextStyle(color: muted)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: widget.onOpenEmployees,
                  icon: const Icon(Icons.person_add_alt_outlined),
                  label: const Text('Buka Master Karyawan')),
              ] else DropdownButtonFormField<String>(
                key: const ValueKey('assignment-employee'),
                initialValue: employeeId,
                decoration: const InputDecoration(
                  labelText: 'Pilih karyawan *'),
                isExpanded: true,
                items: [
                  for (final e in activeEmployees)
                    DropdownMenuItem(
                      value: e.id,
                      child: Text(e.name + ' · ' + e.jobTitle + ' · ' + e.unit,
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (value) { widget.onDirty?.call();
                  setState(() => employeeId = value); },
              ),
              const SizedBox(height: 14),
              LayoutBuilder(builder: (ctx, box) {
                final type = DropdownButtonFormField<String>(
                  key: const ValueKey('assignment-kind'),
                  initialValue: kind,
                  decoration: const InputDecoration(
                    labelText: 'Jenis penugasan *'),
                  items: ['Berkelanjutan','Sementara'].map((value) =>
                    DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (value) { widget.onDirty?.call(); setState(() {
                    kind = value ?? kind;
                  }); });
                final date = TextField(
                  controller: due,
                  enabled: kind == 'Sementara',
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Estimasi kembali (YYYY-MM-DD)',
                    hintText: '2026-12-31'),
                );
                if (box.maxWidth < 570) {
                  return Column(children: [
                    type, const SizedBox(height: 13), date]);
                }
                return Row(children: [
                  Expanded(child: type), const SizedBox(width: 13),
                  Expanded(child: date),
                ]);
              }),
              const SizedBox(height: 14),
              TextField(controller: notes, maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Keperluan / catatan (opsional)')),
            ],
          ),
        )),
        const SizedBox(height: 13),
        Card(child: Padding(padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            infoLabel('2. Pilih Aset'),
            Text(
              selectedIds.length.toString() + ' aset dipilih · ' +
              available.length.toString() + ' aset siap ditugaskan',
              style: const TextStyle(color: muted, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari nama atau kode aset tersedia...'),
              onChanged: (value) => setState(() => assetSearch = value),
            ),
            const SizedBox(height: 10),
            if (available.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 25),
                child: Text('Tidak ada aset yang dapat ditugaskan. '
                  'Aset harus berstatus Tersedia, belum memiliki PIC, '
                  'dan tidak berada pada mutasi/penugasan lain.',
                  style: TextStyle(color: muted))),
            if (available.isNotEmpty && filtered.isEmpty)
              const Text('Aset tidak ditemukan.',
                style: TextStyle(color: muted)),
            for (final a in filtered) ...[
              CheckboxListTile(
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                value: selectedIds.contains(a.id),
                title: Text(a.name, maxLines: 2,
                  overflow: TextOverflow.ellipsis),
                secondary: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(width: 52, height: 52,
                    child: widget.store.primaryPhotoFor(a.id) == null
                      ? const ColoredBox(color: Color(0xFFF1F5FA),
                          child: Icon(Icons.inventory_2_outlined,
                            color: blue, size: 23))
                      : Image.memory(widget.store.primaryPhotoFor(a.id)!.bytes,
                          fit: BoxFit.cover))),
                subtitle: Text(a.code + ' · ' + a.condition +
                  ' · ' + a.location),
                onChanged: (value) { widget.onDirty?.call(); setState(() {
                  if (value == true) {
                    selectedIds.add(a.id);
                  } else {
                    selectedIds.remove(a.id);
                    accessories.remove(a.id);
                  }
                }); },
              ),
              if (selectedIds.contains(a.id))
                Padding(
                  padding: const EdgeInsets.only(
                    left: 38, right: 3, bottom: 12),
                  child: TextFormField(
                    key: ValueKey('accessories-' + a.id),
                    initialValue: accessories[a.id] ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Kelengkapan yang diserahkan',
                      hintText: 'Contoh: charger, tas, kabel'),
                    onChanged: (value) { widget.onDirty?.call();
                      accessories[a.id] = value; },
                  ),
                ),
              const Divider(height: 1, color: border),
            ],
          ]),
        )),
        const SizedBox(height: 13),
        if (error != null) Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2F0),
            borderRadius: BorderRadius.circular(10)),
          child: Text(error!, style: const TextStyle(color: danger)),
        ),
        const SizedBox(height: 15),
        LayoutBuilder(builder:(ctx,box)=>Align(
          alignment:Alignment.centerRight,
          child:SizedBox(
            width:box.maxWidth<530?box.maxWidth:null,
            child:FilledButton.icon(
              key:const ValueKey('assignment-save'),
              onPressed:saving?null:save,
              icon:const Icon(Icons.assignment_ind_outlined),
              label:Text(saving?'Menyimpan...':'Buat Penugasan',
                textAlign:TextAlign.center),
            ),
          ),
        )),
      ],
    );
  }
}
