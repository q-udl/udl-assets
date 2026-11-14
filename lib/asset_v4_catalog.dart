part of 'main.dart';

extension _AssetV4Catalog on _AssetScreenState {
  List<AssetRecord> v4FilteredAssets() {
    final q = query.trim().toLowerCase();
    final items = store.assets.where((a) {
      final searchable = [a.name, a.code, a.serial, a.category, a.subcategory,
        a.assetType, a.brand, a.location, a.holder].join(' ').toLowerCase();
      return searchable.contains(q) &&
        (statusFilter == 'Semua status' ||
          (statusFilter == 'Tidak Aktif' || statusFilter == 'Dilepas'
            ? a.lifecycle == statusFilter
            : a.lifecycle == 'Aktif' && a.status == statusFilter)) &&
        (categoryFilter == 'Semua kategori' || a.category == categoryFilter) &&
        (v4LocationFilter == 'Semua lokasi' || a.location == v4LocationFilter) &&
        (v4LocationAreaFilter.isEmpty || a.locationAreaId == v4LocationAreaFilter) &&
        (v4LocationSpotFilter.isEmpty || a.locationSpotId == v4LocationSpotFilter) &&
        (v4ConditionFilter == 'Semua kondisi' || a.condition == v4ConditionFilter) &&
        (!v4NoPic || a.holder.trim().isEmpty) &&
        (!v4NoPhoto || store.photosFor(a.id).isEmpty) &&
        (!v4Attention || needsAttention(a)) &&
        (!v4NeedsClassification || a.category == 'Perlu Klasifikasi Ulang' ||
          a.subcategory.isEmpty || a.assetType.isEmpty);
    }).toList();
    int compare(AssetRecord a, AssetRecord b) {
      switch (v4Sort) {
        case 'Nama': return a.name.compareTo(b.name);
        case 'Kategori': return a.category.compareTo(b.category);
        case 'Lokasi': return a.location.compareTo(b.location);
        case 'Status': return a.status.compareTo(b.status);
        case 'Kondisi': return a.condition.compareTo(b.condition);
        default: return a.code.compareTo(b.code);
      }
    }
    items.sort((a,b) => v4SortAscending ? compare(a,b) : compare(b,a));
    return items;
  }


  Future<void> v26ShowMobileFilters(List<String> categories) async {
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true,
      showDragHandle: true, useSafeArea: true,
      builder: (sheet) => StatefulBuilder(
        builder: (ctx, update) {
          final available = MediaQuery.sizeOf(ctx);
          final width = available.width - 40;
          void apply(VoidCallback change) {
            v4Change(() { change(); v4CatalogPage = 0; });
            update(() {});
          }
          Widget choice(String label, String value, List<String> options,
              ValueChanged<String> changed) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(label, style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: ink)),
                const SizedBox(height: 6),
                filterDropdown(value, options, changed, width: width),
              ]),
          );
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: available.height * 0.88),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Filter Daftar Aset',
                    style: TextStyle(color: ink, fontSize: 19,
                      fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  choice('Status', statusFilter,
                    const ['Semua status','Tersedia','Digunakan',
                      'Dalam Perbaikan','Hilang','Tidak Aktif','Dilepas'],
                    (value) => apply(() => statusFilter = value)),
                  choice('Kategori', categoryFilter,
                    ['Semua kategori', ...categories],
                    (value) => apply(() => categoryFilter = value)),
                  choice('Lokasi', v4LocationFilter,
                    ['Semua lokasi', ...store.locations],
                    (value) => apply(() => v4LocationFilter = value)),
                  choice('Kondisi', v4ConditionFilter,
                    const ['Semua kondisi','Baru','Baik','Cukup',
                      'Kurang Baik','Rusak'],
                    (value) => apply(() => v4ConditionFilter = value)),
                  const Text('Filter cepat',
                    style: TextStyle(color: ink, fontSize: 12,
                      fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 5, children: [
                    FilterChip(label: const Text('Belum ada PIC'),
                      selected: v4NoPic,
                      onSelected: (v) => apply(() => v4NoPic = v)),
                    FilterChip(label: const Text('Belum ada foto'),
                      selected: v4NoPhoto,
                      onSelected: (v) => apply(() => v4NoPhoto = v)),
                    FilterChip(label: const Text('Perlu perhatian'),
                      selected: v4Attention,
                      onSelected: (v) => apply(() => v4Attention = v)),
                    FilterChip(label: const Text('Perlu klasifikasi'),
                      selected: v4NeedsClassification,
                      onSelected: (v) => apply(() => v4NeedsClassification = v)),
                  ]),
                  const SizedBox(height: 18),
                  Wrap(spacing: 8, runSpacing: 8,
                    alignment: WrapAlignment.end, children: [
                      if (hasAssetFilters) OutlinedButton.icon(
                        onPressed: () { resetAssetFilters(); update(() {}); },
                        icon: const Icon(Icons.filter_alt_off_outlined),
                        label: const Text('Reset Filter')),
                      FilledButton(
                        key: const ValueKey('rv26-apply-filters'),
                        onPressed: () => Navigator.pop(sheet),
                        child: const Text('Selesai')),
                    ]),
                ]),
            ),
          );
        },
      ),
    );
  }

  Widget v4Catalog() {
    final items = v4FilteredAssets();
    final total = store.assets.length;
    final pages = items.isEmpty ? 1 :
      ((items.length - 1) ~/ v4PerPage) + 1;
    if (v4CatalogPage >= pages) { v4CatalogPage = pages - 1; }
    final slice = items.skip(v4CatalogPage * v4PerPage)
      .take(v4PerPage).toList();
    final categories = {
      ...store.categories.map((c) => c.name),
      ...store.assets.map((a) => a.category),
    }.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        surface(child: LayoutBuilder(builder: (ctx, box) {
          final filters = <Widget>[
            filterDropdown(statusFilter,
              const ['Semua status', 'Tersedia', 'Digunakan',
                'Dalam Perbaikan', 'Hilang', 'Tidak Aktif', 'Dilepas'],
              (value) => v4Change(() {
                statusFilter = value; v4CatalogPage = 0;
              }), width: 168),
            filterDropdown(categoryFilter,
              ['Semua kategori', ...categories],
              (value) => v4Change(() {
                categoryFilter = value; v4CatalogPage = 0;
              }), width: 208),
            filterDropdown(v4LocationFilter,
              ['Semua lokasi', ...store.locations],
              (value) => v4Change(() {
                v4LocationFilter = value; v4CatalogPage = 0;
              }), width: 185),
            filterDropdown(v4ConditionFilter,
              const ['Semua kondisi', 'Baru', 'Baik', 'Cukup',
                'Kurang Baik', 'Rusak'],
              (value) => v4Change(() {
                v4ConditionFilter = value; v4CatalogPage = 0;
              }), width: 165),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (box.maxWidth < 650) ...[
                searchBox(),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    key: const ValueKey('rv26-open-filters'),
                    onPressed: () => v26ShowMobileFilters(categories),
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(hasAssetFilters
                      ? 'Filter Aset · Aktif' : 'Filter Aset'))),
                  if (hasAssetFilters) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Reset Filter',
                      onPressed: resetAssetFilters,
                      icon: const Icon(Icons.filter_alt_off_outlined)),
                  ],
                ]),
              ] else if (box.maxWidth >= 1180)
                Row(children: [
                  Expanded(child: searchBox()),
                  const SizedBox(width: 8),
                  for (var i = 0; i < filters.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    filters[i],
                  ],
                ])
              else ...[
                searchBox(),
                const SizedBox(height: 10),
                Wrap(spacing: 9, runSpacing: 9, children: filters),
              ],
              if (box.maxWidth >= 650) ...[
              const SizedBox(height: 9),
              Wrap(
                spacing: 8, runSpacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (v4LocationAreaFilter.isNotEmpty ||
                      v4LocationSpotFilter.isNotEmpty)
                    InputChip(
                      label: Text('Penempatan terpilih: ' +
                        (v4LocationSpotFilter.isNotEmpty
                          ? 'Titik Penempatan' : 'Area')),
                      onDeleted: () => v4Change(() {
                        v4LocationAreaFilter = '';
                        v4LocationSpotFilter = '';
                        v4CatalogPage = 0;
                      })),
                  FilterChip(
                    label: const Text('Belum ada PIC'),
                    selected: v4NoPic,
                    onSelected: (value) => v4Change(() {
                      v4NoPic = value; v4CatalogPage = 0;
                    }),
                  ),
                  FilterChip(
                    label: const Text('Belum ada foto'),
                    selected: v4NoPhoto,
                    onSelected: (value) => v4Change(() {
                      v4NoPhoto = value; v4CatalogPage = 0;
                    }),
                  ),
                  FilterChip(
                    label: const Text('Perlu perhatian'),
                    selected: v4Attention,
                    onSelected: (value) => v4Change(() {
                      v4Attention = value; v4CatalogPage = 0;
                    }),
                  ),
                  FilterChip(
                    label: const Text('Perlu klasifikasi'),
                    selected: v4NeedsClassification,
                    onSelected: (value) => v4Change(() {
                      v4NeedsClassification = value; v4CatalogPage = 0;
                    }),
                  ),
                  if (hasAssetFilters)
                    TextButton.icon(
                      key: const ValueKey('asset-reset-filters'),
                      onPressed: resetAssetFilters,
                      icon: const Icon(Icons.filter_alt_off_outlined,
                        size: 18),
                      label: const Text('Reset Filter'),
                    ),
                ],
              ),
              ],
            ],
          );
        })),
        const SizedBox(height: 12),
        surface(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sectionHeader('Daftar Aset',
              subtitle: items.length.toString() + ' dari ' +
                total.toString() + ' aset'),
            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 48, horizontal: 24),
                child: Column(children: [
                  Icon(hasAssetFilters ? Icons.search_off_rounded :
                    Icons.inventory_2_outlined, size: 43, color: muted),
                  const SizedBox(height: 12),
                  Text(hasAssetFilters
                      ? 'Tidak ada aset yang sesuai'
                      : 'Belum ada aset terdaftar',
                    style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w800, color: ink)),
                  const SizedBox(height: 7),
                  Text(hasAssetFilters
                      ? 'Tidak ditemukan aset dengan kombinasi '
                        'pencarian dan filter saat ini.'
                      : 'Mulai dengan meregistrasikan aset perusahaan.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted, fontSize: 12.5)),
                  const SizedBox(height: 17),
                  if (hasAssetFilters)
                    OutlinedButton.icon(
                      key: const ValueKey('empty-asset-reset'),
                      onPressed: resetAssetFilters,
                      icon: const Icon(Icons.filter_alt_off_rounded),
                      label: const Text('Reset Filter'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => v4Change(() => page = 6),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tambah Aset'),
                    ),
                ]),
              )
            else ...[
              const SizedBox(height: 12),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6, children: [
                  const Text('Urutkan:', style: TextStyle(
                    fontSize: 12, color: muted)),
                  DropdownButton<String>(
                    value: v4Sort,
                    items: ['Kode', 'Nama', 'Kategori',
                      'Lokasi', 'Kondisi', 'Status']
                      .map((value) => DropdownMenuItem(
                        value: value, child: Text(value))).toList(),
                    onChanged: (value) => v4Change(() {
                      v4Sort = value ?? 'Kode'; v4CatalogPage = 0;
                    }),
                  ),
                  IconButton(
                    tooltip: 'Balik urutan',
                    onPressed: () => v4Change(() =>
                      v4SortAscending = !v4SortAscending),
                    icon: Icon(v4SortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              LayoutBuilder(builder: (ctx, box) {
                if (box.maxWidth < 800) {
                  return Column(children: [
                    for (final a in slice)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: assetMiniCard(a),
                      ),
                  ]);
                }
                return _v4AssetTable(slice, box.maxWidth);
              }),
              const SizedBox(height: 12),
              const Divider(height: 1, color: border),
              const SizedBox(height: 7),
              responsiveAssetPager(
                description: 'Menampilkan ' +
                  (v4CatalogPage * v4PerPage + 1).toString() +
                  '–' +
                  (v4CatalogPage * v4PerPage + slice.length).toString() +
                  ' dari ' + items.length.toString() + ' aset',
                perPage: v4PerPage,
                onPerPage: (v) => v4Change(() {
                  v4PerPage = v; v4CatalogPage = 0;
                }),
                onPrevious: v4CatalogPage == 0 ? null :
                  () => v4Change(() => v4CatalogPage--),
                onNext: v4CatalogPage >= pages - 1 ? null :
                  () => v4Change(() => v4CatalogPage++),
              ),
            ],
          ],
        )),
      ],
    );
  }
}
