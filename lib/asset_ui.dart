part of 'main.dart';

// UDL Assets local preview — UI layer. Data model and persistence remain in main.dart.
class _AssetScreenState extends State<AssetScreen> {
  int page = 0;
  String query = '';
  String statusFilter = 'Semua status';
  String categoryFilter = 'Semua kategori';
  AssetRecord? selected;

  AssetStore get store => widget.store;

  static const ink = Color(0xFF172C47);
  static const muted = Color(0xFF718199);
  static const border = Color(0xFFE3EAF2);
  static const blue = Color(0xFF2766A2);
  static const lightBlue = Color(0xFFEDF5FE);
  static const green = Color(0xFF168366);
  static const amber = Color(0xFFB97813);
  static const danger = Color(0xFFC04D53);

  final labels = const ['Ringkasan', 'Katalog Aset', 'Riwayat', 'Pengaturan'];
  final icons = const [
    Icons.space_dashboard_outlined,
    Icons.inventory_2_outlined,
    Icons.history_rounded,
    Icons.tune_rounded
  ];

  void notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  String rupiah(int amount) {
    final s = amount.toString();
    return 'Rp' + s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  }

  String compactMoney(int amount) {
    if (amount >= 1000000000) {
      return 'Rp' + (amount / 1000000000).toStringAsFixed(1).replaceAll('.', ',') + ' M';
    }
    if (amount >= 1000000) {
      return 'Rp' + (amount / 1000000).toStringAsFixed(1).replaceAll('.', ',') + ' jt';
    }
    return rupiah(amount);
  }

  String dateText(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return d + '/' + m + '/' + local.year.toString() + ' · ' + h + ':' + min;
  }

  AssetRecord? assetFor(String id) {
    for (final a in store.assets) {
      if (a.id == id) return a;
    }
    return null;
  }

  bool needsAttention(AssetRecord a) =>
      a.status == 'Dalam Perbaikan' || a.status == 'Hilang' ||
      a.condition == 'Rusak' || a.condition == 'Kurang Baik';

  void navigate(int index) {
    setState(() {
      page = index;
      selected = null;
    });
  }

  Widget surface({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(20)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget sectionHeader(String title, {String? subtitle, Widget? trailing}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, color: ink, fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: muted)),
        ]
      ])),
      if (trailing != null) trailing,
    ]);
  }

  Widget badge(String value, {bool compact = false}) {
    final Color tint;
    switch (value) {
      case 'Digunakan':
        tint = green;
        break;
      case 'Tersedia':
        tint = blue;
        break;
      case 'Dalam Perbaikan':
        tint = amber;
        break;
      case 'Hilang':
      case 'Dihapuskan':
        tint = danger;
        break;
      default:
        tint = muted;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 11, vertical: compact ? 5 : 7),
      decoration: BoxDecoration(color: tint.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(24)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: tint, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(value, style: TextStyle(color: tint, fontSize: compact ? 11 : 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget primaryButton(String label, IconData icon, VoidCallback action) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 43),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: action,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget outlineButton(String label, IconData icon, VoidCallback action) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: blue,
        minimumSize: const Size(0, 41),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: action,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _sideItem(int index) {
    final active = page == index && selected == null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: active ? lightBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => navigate(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: active ? Border.all(color: const Color(0xFFDCEAF9)) : null,
            ),
            child: Row(children: [
              Icon(icons[index], size: 19, color: active ? blue : const Color(0xFF697B91)),
              const SizedBox(width: 13),
              Expanded(child: Text(labels[index], style: TextStyle(
                fontSize: 13.5, fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? blue : const Color(0xFF54667A)))),
              if (index == 1) Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: active ? Colors.white : const Color(0xFFF0F3F8),
                  borderRadius: BorderRadius.circular(6)),
                child: Text(store.assets.length.toString(), style: const TextStyle(fontSize: 11, color: muted)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget sidebar({bool inDrawer = false}) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 22, right: 16, bottom: 12),
            child: Text('MENU UTAMA', style: TextStyle(
              fontSize: 10, letterSpacing: 1.7, color: Color(0xFF9AA8B9), fontWeight: FontWeight.w800)),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(children: [_sideItem(0), _sideItem(1), _sideItem(2)])),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.only(left: 22, right: 16, bottom: 12),
            child: Text('SISTEM', style: TextStyle(
              fontSize: 10, letterSpacing: 1.7, color: Color(0xFF9AA8B9), fontWeight: FontWeight.w800)),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _sideItem(3)),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F9FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(children: [
                Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: green, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Pratinjau Lokal', style: TextStyle(fontSize: 12, color: ink, fontWeight: FontWeight.w700)),
                  SizedBox(height: 3),
                  Text('UDL Assets · v0.2.0', style: TextStyle(fontSize: 11, color: muted)),
                ])),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget appHeader() {
    return Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: const Color(0xFF2A547F), borderRadius: BorderRadius.circular(9)),
        child: const Center(child: Text('L', style: TextStyle(
          color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900))),
      ),
      const SizedBox(width: 12),
      const Flexible(child: Text('UD. LUTHFI', overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
      const SizedBox(width: 12),
      Container(width: 1, height: 22, color: Colors.white24),
      const SizedBox(width: 12),
      const Flexible(child: Text('Manajemen Aset', overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Color(0xFFD8E4F1), fontSize: 14, fontWeight: FontWeight.w600))),
    ]);
  }

  Widget titleArea() {
    final title = selected != null ? 'Detail Aset' :
      page == 0 ? 'Ringkasan Aset' : labels[page];
    final description = selected != null ? 'Informasi, posisi, dan jejak aktivitas aset' :
      page == 0 ? 'Pantau kondisi dan distribusi aset perusahaan dari satu tempat.' :
      page == 1 ? 'Temukan, registrasikan, dan kelola seluruh inventaris perusahaan.' :
      page == 2 ? 'Lacak aktivitas dan perubahan sepanjang siklus hidup aset.' :
      'Kelola data simulasi dan standar identitas aset.';
    final isMobile = MediaQuery.sizeOf(context).width < 650;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.home_outlined, size: 14, color: muted),
        const SizedBox(width: 7),
        const Text('ASET PERUSAHAAN', style: TextStyle(fontSize: 10.5,
          color: muted, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.chevron_right, size: 14, color: muted)),
        Flexible(child: Text(title.toUpperCase(), overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.5, color: blue,
            fontWeight: FontWeight.w800, letterSpacing: 1.0))),
      ]),
      const SizedBox(height: 15),
      if (isMobile) ...[
        Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: ink)),
        const SizedBox(height: 5),
        Text(description, style: const TextStyle(fontSize: 13, color: muted)),
        const SizedBox(height: 12),
        if (selected != null)
          outlineButton('Kembali ke katalog', Icons.arrow_back_rounded, () => setState(() => selected = null)),
        if (selected == null && page == 1)
          primaryButton('Tambah Aset', Icons.add_rounded, register),
      ] else
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800,
              letterSpacing: -0.5, color: ink)),
            const SizedBox(height: 5),
            Text(description, style: const TextStyle(fontSize: 13, color: muted)),
          ])),
          const SizedBox(width: 14),
          if (selected != null)
            outlineButton('Kembali', Icons.arrow_back_rounded, () => setState(() => selected = null)),
          if (selected == null && page == 1)
            primaryButton('Tambah Aset', Icons.add_rounded, register),
        ]),
    ]);
  }

  Widget metricCard(String label, String value, String note, IconData icon,
      Color accent, double width) {
    return SizedBox(
      width: width,
      child: surface(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: const TextStyle(
              fontSize: 12.5, color: muted, fontWeight: FontWeight.w600))),
            Container(
              width: 37, height: 37,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: accent, size: 20),
            ),
          ]),
          const SizedBox(height: 10),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child:
            Text(value, maxLines: 1, style: const TextStyle(
              fontSize: 27, fontWeight: FontWeight.w900, color: ink, letterSpacing: -0.5))),
          const SizedBox(height: 6),
          Text(note, style: const TextStyle(fontSize: 11.5, color: muted)),
        ],
      )),
    );
  }

  Widget metrics() {
    final active = store.assets.where((a) => a.status != 'Dihapuskan').toList();
    final inUse = active.where((a) => a.status == 'Digunakan').length;
    final concern = active.where(needsAttention).length;
    final cost = active.fold<int>(0, (sum, a) => sum + a.cost);
    return LayoutBuilder(builder: (context, box) {
      final n = box.maxWidth >= 1060 ? 4 : box.maxWidth >= 510 ? 2 : 1;
      final width = (box.maxWidth - (n - 1) * 14) / n;
      return Wrap(spacing: 14, runSpacing: 14, children: [
        metricCard('Total aset aktif', active.length.toString(), 'Tercatat di seluruh lokasi',
          Icons.inventory_2_outlined, blue, width),
        metricCard('Sedang digunakan', inUse.toString(), 'Aset dalam penguasaan unit',
          Icons.assignment_ind_outlined, green, width),
        metricCard('Perlu perhatian', concern.toString(), 'Hilang, rusak, atau diperbaiki',
          Icons.report_problem_outlined, amber, width),
        metricCard('Nilai perolehan', compactMoney(cost), rupiah(cost) + ' · sebelum penyusutan',
          Icons.account_balance_wallet_outlined, const Color(0xFF6F66B5), width),
      ]);
    });
  }

  Widget distributionCard() {
    final active = store.assets.where((a) => a.status != 'Dihapuskan').toList();
    final total = active.length;
    final groups = [
      ('Digunakan', green, active.where((a) => a.status == 'Digunakan').length),
      ('Tersedia', blue, active.where((a) => a.status == 'Tersedia').length),
      ('Lainnya', amber, active.where((a) => a.status != 'Tersedia' && a.status != 'Digunakan').length),
    ];
    return surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      sectionHeader('Distribusi status', subtitle: 'Gambaran penggunaan aset yang masih aktif'),
      const SizedBox(height: 20),
      ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(
        height: 12,
        child: Row(children: [
          for (final g in groups)
            if (g.$3 > 0)
              Expanded(flex: g.$3, child: Container(color: g.$2)),
          if (total == 0) Expanded(child: Container(color: const Color(0xFFE8EDF5))),
        ]),
      )),
      const SizedBox(height: 15),
      Wrap(spacing: 22, runSpacing: 10, children: [
        for (final g in groups)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: g.$2,
              borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Text(g.$1, style: const TextStyle(fontSize: 12, color: muted)),
            const SizedBox(width: 5),
            Text(g.$3.toString(), style: const TextStyle(fontSize: 12, color: ink, fontWeight: FontWeight.w800)),
          ]),
      ])
    ]));
  }

  Widget attentionCard() {
    final attention = store.assets.where((a) => a.status != 'Dihapuskan' && needsAttention(a)).toList();
    return surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      sectionHeader('Perlu perhatian',
        subtitle: 'Aset yang perlu tindak lanjut'),
      const SizedBox(height: 14),
      if (attention.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(vertical: 20),
          child: Row(children: [
            Icon(Icons.check_circle_outline, color: green),
            SizedBox(width: 10),
            Expanded(child: Text('Belum ada aset dengan kondisi kritis.',
              style: TextStyle(color: muted, fontSize: 13))),
          ])),
      for (final a in attention.take(4)) ...[
        const Divider(height: 1, color: border),
        InkWell(onTap: () => setState(() => selected = a),
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              Container(width: 37, height: 37,
                decoration: BoxDecoration(color: const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.build_circle_outlined, color: amber, size: 20)),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
                const SizedBox(height: 3),
                Text(a.code + '  ·  ' + a.location, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: muted)),
              ])),
              const SizedBox(width: 7),
              const Icon(Icons.chevron_right_rounded, size: 18, color: muted),
            ]))),
      ],
      if (attention.length > 4)
        Text('+' + (attention.length - 4).toString() + ' aset lainnya',
          style: const TextStyle(color: muted, fontSize: 11)),
    ]));
  }

  Widget activityCard() {
    return surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      sectionHeader('Aktivitas terbaru', subtitle: 'Jejak perubahan data aset',
        trailing: TextButton(onPressed: () => navigate(2), child: const Text('Lihat semua'))),
      const SizedBox(height: 10),
      for (final e in store.events.take(5)) activityLine(e),
      if (store.events.isEmpty)
        const Padding(padding: EdgeInsets.all(20), child: Text('Belum ada aktivitas.',
          style: TextStyle(color: muted))),
    ]));
  }

  Widget activityLine(EventRecord e) {
    final a = assetFor(e.assetId);
    return Column(children: [
      const Divider(height: 1, color: border),
      InkWell(onTap: a == null ? null : () => setState(() => selected = a),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(children: [
            Container(width: 34, height: 34,
              decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.history_rounded, size: 18, color: blue)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.type + ' · ' + (a?.code ?? 'Aset'), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: ink, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(e.detail, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: muted)),
            ])),
            const SizedBox(width: 8),
            Text(dateText(e.timestamp), style: const TextStyle(fontSize: 10.5, color: muted)),
          ]))),
    ]);
  }

  Widget dashboard() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      metrics(),
      const SizedBox(height: 18),
      distributionCard(),
      const SizedBox(height: 18),
      LayoutBuilder(builder: (context, box) {
        final wide = box.maxWidth >= 900;
        if (!wide) return Column(children: [
          attentionCard(), const SizedBox(height: 16), activityCard(),
        ]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 4, child: attentionCard()),
          const SizedBox(width: 16),
          Expanded(flex: 6, child: activityCard()),
        ]);
      }),
    ]);
  }

  Widget searchBox() {
    return SizedBox(height: 44, child: TextField(
      decoration: InputDecoration(
        hintText: 'Cari nama, kode, lokasi, nomor seri...',
        hintStyle: const TextStyle(fontSize: 12.5, color: muted),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: muted),
        filled: true, fillColor: const Color(0xFFF9FBFD),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border)),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onChanged: (value) => setState(() => query = value),
    ));
  }

  Widget filterDropdown(String current, List<String> options,
      void Function(String) onChange, {double width = 170}) {
    return SizedBox(width: width, child: DropdownButtonFormField<String>(
      key: ValueKey('filter-' + current),
      initialValue: current,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: muted),
      decoration: InputDecoration(
        filled: true, fillColor: const Color(0xFFF9FBFD),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 12.5, color: ink),
      items: options.map((v) => DropdownMenuItem(value: v, child: Text(v,
        maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (x) { if (x != null) onChange(x); },
    ));
  }

  List<AssetRecord> filteredAssets() => store.assets.where((a) {
    final q = query.trim().toLowerCase();
    final searchable = [
      a.name, a.code, a.location, a.holder, a.serial, a.category, a.brand,
    ].join(' ').toLowerCase();
    return searchable.contains(q) &&
        (statusFilter == 'Semua status' || a.status == statusFilter) &&
        (categoryFilter == 'Semua kategori' || a.category == categoryFilter);
  }).toList();

  Widget catalogTools() {
    final categories = store.assets.map((a) => a.category).toSet().toList()..sort();
    return surface(padding: const EdgeInsets.all(15),
      child: LayoutBuilder(builder: (context, box) {
        if (box.maxWidth >= 720) {
          return Row(children: [
            Expanded(child: searchBox()),
            const SizedBox(width: 12),
            filterDropdown(statusFilter, const [
              'Semua status', 'Tersedia', 'Digunakan', 'Dalam Perbaikan', 'Hilang', 'Dihapuskan',
            ], (v) => setState(() => statusFilter = v), width: 170),
            const SizedBox(width: 12),
            filterDropdown(categoryFilter, ['Semua kategori', ...categories],
              (v) => setState(() => categoryFilter = v), width: 170),
          ]);
        }
        return Column(children: [
          searchBox(),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: filterDropdown(statusFilter, const [
              'Semua status', 'Tersedia', 'Digunakan', 'Dalam Perbaikan', 'Hilang', 'Dihapuskan',
            ], (v) => setState(() => statusFilter = v), width: double.infinity)),
            const SizedBox(width: 10),
            Expanded(child: filterDropdown(categoryFilter, ['Semua kategori', ...categories],
              (v) => setState(() => categoryFilter = v), width: double.infinity)),
          ]),
        ]);
      }));
  }

  Widget tableHeaderCell(String label, int flex) => Expanded(
    flex: flex, child: Text(label.toUpperCase(), style: const TextStyle(
      fontSize: 10.5, fontWeight: FontWeight.w800, color: muted, letterSpacing: 0.7)));

  Widget assetTable(List<AssetRecord> items) {
    return surface(padding: EdgeInsets.zero, child: Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: Color(0xFFF9FBFE),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Row(children: [
          tableHeaderCell('Aset', 4),
          tableHeaderCell('Kode aset', 2),
          tableHeaderCell('Kategori', 2),
          tableHeaderCell('Lokasi / Penanggung Jawab', 3),
          tableHeaderCell('Status', 2),
          const SizedBox(width: 20),
        ])),
      for (final a in items) ...[
        const Divider(height: 1, color: border),
        Material(color: Colors.transparent, child: InkWell(
          onTap: () => setState(() => selected = a),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(children: [
              Expanded(flex: 4, child: Row(children: [
                Container(width: 42, height: 42,
                  decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.inventory_2_outlined, size: 21, color: blue)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(a.brand.isEmpty ? 'Tanpa merek' : a.brand,
                    style: const TextStyle(fontSize: 11.5, color: muted)),
                ])),
              ])),
              Expanded(flex: 2, child: SelectableText(a.code,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: blue))),
              Expanded(flex: 2, child: Text(a.category, style: const TextStyle(fontSize: 12.5, color: ink))),
              Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.location, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ink, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(a.holder.isEmpty ? 'Belum ditetapkan' : a.holder,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: muted)),
              ])),
              Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: badge(a.status, compact: true))),
              const SizedBox(width: 20, child: Icon(Icons.chevron_right_rounded, size: 18, color: muted)),
            ])),
          ),
        )),
      ],
      if (items.isEmpty) const Padding(padding: EdgeInsets.all(35),
        child: Column(children: [
          Icon(Icons.search_off_rounded, size: 34, color: muted),
          SizedBox(height: 8),
          Text('Tidak ada aset sesuai filter.', style: TextStyle(color: muted)),
        ]))
    ]));
  }

  Widget assetMiniCard(AssetRecord a) {
    return Material(color: Colors.white, borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => selected = a),
        child: Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 38, height: 38,
                decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.inventory_2_outlined, color: blue, size: 20)),
              const Spacer(),
              badge(a.status, compact: true),
            ]),
            const SizedBox(height: 12),
            Text(a.name, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 5),
            Text(a.code + ' · ' + a.category,
              style: const TextStyle(fontSize: 11.5, color: blue, fontWeight: FontWeight.w600)),
            const Divider(height: 22, color: border),
            Row(children: [
              const Icon(Icons.place_outlined, color: muted, size: 16), const SizedBox(width: 6),
              Expanded(child: Text(a.location, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: muted))),
              const Icon(Icons.chevron_right_rounded, color: muted, size: 18),
            ])
          ])),
      ));
  }

  Widget catalog() {
    final items = filteredAssets();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      catalogTools(),
      const SizedBox(height: 15),
      Row(children: [
        const Text('Daftar Aset', style: TextStyle(fontSize: 16, color: ink, fontWeight: FontWeight.w800)),
        const SizedBox(width: 9),
        Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(7)),
          child: Text(items.length.toString(), style: const TextStyle(
            color: blue, fontSize: 12, fontWeight: FontWeight.w800))),
        const Spacer(),
        const Icon(Icons.info_outline_rounded, size: 15, color: muted),
        const SizedBox(width: 5),
        const Flexible(child: Text('Kode tetap saat aset dimutasi',
          textAlign: TextAlign.end, style: TextStyle(fontSize: 11.5, color: muted))),
      ]),
      const SizedBox(height: 11),
      LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 900) return assetTable(items);
        final width = constraints.maxWidth;
        final cols = width >= 550 ? 2 : 1;
        final tileWidth = (width - 12 * (cols - 1)) / cols;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (final a in items) SizedBox(width: tileWidth, child: assetMiniCard(a)),
          if (items.isEmpty) surface(child: const Text('Tidak ada aset sesuai filter.',
            style: TextStyle(color: muted))),
        ]);
      }),
      const SizedBox(height: 12),
      Text('Menampilkan ' + items.length.toString() + ' dari ' + store.assets.length.toString() + ' aset',
        style: const TextStyle(color: muted, fontSize: 11.5)),
    ]);
  }

  Widget dialogField(TextEditingController c, String label, {bool mandatory = false,
      TextInputType? keyboard, String? hint}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, hintText: hint, filled: true,
        fillColor: const Color(0xFFF9FBFD)),
      validator: (value) {
        if (mandatory && (value == null || value.trim().isEmpty)) return 'Wajib diisi';
        return null;
      },
    );
  }

  Widget twoFields(Widget left, Widget right, bool narrow) {
    if (narrow) return Column(children: [left, const SizedBox(height: 13), right]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: left), const SizedBox(width: 14), Expanded(child: right),
    ]);
  }

  Future<void> register() async {
    final name = TextEditingController();
    final brand = TextEditingController();
    final serial = TextEditingController();
    final location = TextEditingController();
    final holder = TextEditingController();
    final cost = TextEditingController(text: '0');
    var category = 'IT';
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, update) {
        final available = MediaQuery.sizeOf(ctx).width;
        final narrow = available < 680;
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: SizedBox(
            width: available < 780 ? available - 70 : 720,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.88),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(narrow ? 18 : 26),
                child: Form(key: formKey, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      Container(width: 43, height: 43,
                        decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add_box_outlined, color: blue)),
                      const SizedBox(width: 13),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Registrasi Aset Baru', style: TextStyle(
                          fontSize: 19, color: ink, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('Lengkapi identitas dan informasi penempatan aset.',
                          style: TextStyle(color: muted, fontSize: 12)),
                      ])),
                      IconButton(onPressed: () => Navigator.pop(ctx, false),
                        icon: const Icon(Icons.close_rounded, color: muted)),
                    ]),
                    const SizedBox(height: 20),
                    Container(width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        const Icon(Icons.qr_code_2_rounded, size: 18, color: blue),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Kode berikutnya: UDL-AST-' +
                          store.nextNumber.toString().padLeft(6, '0'),
                          style: const TextStyle(color: blue, fontWeight: FontWeight.w800, fontSize: 12))),
                        const Text('OTOMATIS', style: TextStyle(color: blue,
                          fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    const Text('IDENTITAS ASET', style: TextStyle(color: muted,
                      fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                    const SizedBox(height: 12),
                    dialogField(name, 'Nama aset *', mandatory: true, hint: 'Contoh: Laptop Lenovo ThinkPad T14'),
                    const SizedBox(height: 13),
                    twoFields(
                      DropdownButtonFormField<String>(
                        initialValue: category, isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Kategori', filled: true,
                          fillColor: Color(0xFFF9FBFD)),
                        items: ['IT', 'Elektronik', 'Furnitur', 'Kendaraan', 'Mesin', 'Bangunan', 'Lainnya']
                          .map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                        onChanged: (x) => update(() => category = x ?? category)),
                      dialogField(brand, 'Merek', hint: 'Contoh: Lenovo'),
                      narrow,
                    ),
                    const SizedBox(height: 13),
                    twoFields(
                      dialogField(serial, 'Nomor seri', hint: 'Opsional, jika tersedia'),
                      TextFormField(
                        controller: cost, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Nilai perolehan (Rp)',
                          filled: true, fillColor: Color(0xFFF9FBFD)),
                        validator: (v) => int.tryParse(v ?? '') == null ||
                          int.parse(v!) < 0 ? 'Isi angka 0 atau lebih' : null,
                      ),
                      narrow,
                    ),
                    const SizedBox(height: 23),
                    const Text('PENEMPATAN AWAL', style: TextStyle(color: muted,
                      fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                    const SizedBox(height: 12),
                    twoFields(
                      dialogField(location, 'Lokasi awal *', mandatory: true, hint: 'Contoh: Outlet Jepara'),
                      dialogField(holder, 'Penanggung jawab', hint: 'Opsional'),
                      narrow,
                    ),
                    const SizedBox(height: 22),
                    const Divider(color: border, height: 1),
                    const SizedBox(height: 18),
                    Wrap(spacing: 10, runSpacing: 8,
                      alignment: WrapAlignment.end, children: [
                        outlineButton('Batal', Icons.close_rounded, () => Navigator.pop(ctx, false)),
                        primaryButton('Simpan Aset', Icons.check_rounded, () {
                          if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
                        }),
                      ]),
                  ]),
                ),
              ),
            ),
          ),
        );
      }),
    );
    if (ok == true) {
      try {
        await store.add(name.text, category, brand.text, serial.text,
          location.text, holder.text, int.parse(cost.text));
        setState(() {
          page = 1;
          query = '';
          statusFilter = 'Semua status';
          categoryFilter = 'Semua kategori';
        });
        notify('Aset berhasil diregistrasikan');
      } catch (e) {
        notify('Gagal menyimpan aset: ' + e.toString());
      }
    }
    for (final ctrl in [name, brand, serial, location, holder, cost]) {
      ctrl.dispose();
    }
  }

  Future<void> mutate(AssetRecord a) async {
    final location = TextEditingController(text: a.location);
    final holder = TextEditingController(text: a.holder);
    final reason = TextEditingController();
    var status = a.status;
    var condition = a.condition;
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, update) {
        final narrow = MediaQuery.sizeOf(ctx).width < 680;
        return Dialog(backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: SizedBox(
            width: MediaQuery.sizeOf(ctx).width < 720 ? MediaQuery.sizeOf(ctx).width - 70 : 650,
            child: SingleChildScrollView(padding: const EdgeInsets.all(24),
              child: Form(key: formKey, child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.swap_horiz_rounded, color: blue, size: 27),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Perubahan / Mutasi Aset',
                      style: TextStyle(fontSize: 19, color: ink, fontWeight: FontWeight.w800))),
                    IconButton(onPressed: () => Navigator.pop(ctx, false),
                      icon: const Icon(Icons.close_rounded, color: muted)),
                  ]),
                  const SizedBox(height: 6),
                  Text(a.code + '  ·  ' + a.name, style: const TextStyle(color: muted, fontSize: 12)),
                  const SizedBox(height: 19),
                  twoFields(
                    dialogField(location, 'Lokasi *', mandatory: true),
                    dialogField(holder, 'Penanggung jawab'), narrow),
                  const SizedBox(height: 13),
                  twoFields(
                    DropdownButtonFormField<String>(
                      initialValue: status, isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Status', filled: true,
                        fillColor: Color(0xFFF9FBFD)),
                      items: ['Tersedia', 'Digunakan', 'Dalam Perbaikan', 'Hilang', 'Dihapuskan']
                        .map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                      onChanged: (x) => update(() => status = x ?? status)),
                    DropdownButtonFormField<String>(
                      initialValue: condition, isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Kondisi', filled: true,
                        fillColor: Color(0xFFF9FBFD)),
                      items: ['Baru', 'Baik', 'Cukup', 'Kurang Baik', 'Rusak']
                        .map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                      onChanged: (x) => update(() => condition = x ?? condition)),
                    narrow),
                  const SizedBox(height: 13),
                  dialogField(reason, 'Alasan perubahan *', mandatory: true,
                    hint: 'Contoh: Pemindahan operasional antarunit'),
                  const SizedBox(height: 14),
                  Container(padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(10)),
                    child: const Row(children: [
                      Icon(Icons.info_outline_rounded, color: blue, size: 18),
                      SizedBox(width: 9),
                      Expanded(child: Text('Kode aset tetap; seluruh perubahan masuk ke Riwayat.',
                        style: TextStyle(fontSize: 12, color: blue))),
                    ])),
                  const SizedBox(height: 20),
                  Wrap(spacing: 10, alignment: WrapAlignment.end, children: [
                    outlineButton('Batal', Icons.close_rounded, () => Navigator.pop(ctx, false)),
                    primaryButton('Simpan Perubahan', Icons.check_rounded, () {
                      if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
                    })
                  ])
                ]),
              ))));
      }),
    );
    if (ok == true) {
      try {
        await store.change(a, location.text, holder.text, status, condition, reason.text);
        notify('Perubahan aset dan riwayat berhasil disimpan');
      } catch (e) {
        notify('Tidak dapat menyimpan: ' + e.toString());
      }
    }
    location.dispose();
    holder.dispose();
    reason.dispose();
  }

  Widget detailValue(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 155, child: Text(label, style: const TextStyle(fontSize: 12.5, color: muted))),
        Expanded(child: Text(value.isEmpty ? '—' : value,
          style: const TextStyle(fontSize: 12.8, color: ink, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget identityCard(AssetRecord a) {
    return surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 46, height: 46,
          decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.inventory_2_outlined, color: blue, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 3),
          Text(a.code, style: const TextStyle(fontSize: 12, color: blue, fontWeight: FontWeight.w700)),
        ])),
        badge(a.status, compact: true),
      ]),
      const SizedBox(height: 18),
      const Divider(height: 1, color: border),
      const SizedBox(height: 14),
      sectionHeader('Identitas aset'),
      const SizedBox(height: 9),
      detailValue('Kategori', a.category),
      detailValue('Merek', a.brand),
      detailValue('Nomor seri', a.serial),
      detailValue('Nilai perolehan', rupiah(a.cost)),
      const Divider(height: 28, color: border),
      sectionHeader('Penempatan dan kondisi'),
      const SizedBox(height: 9),
      detailValue('Lokasi saat ini', a.location),
      detailValue('Penanggung jawab', a.holder),
      detailValue('Kondisi fisik', a.condition),
      const SizedBox(height: 16),
      if (a.status != 'Dihapuskan')
        primaryButton('Mutasi / Ubah Status', Icons.swap_horiz_rounded, () => mutate(a)),
    ]));
  }

  Widget qrCard(AssetRecord a) {
    return surface(child: Column(children: [
      const Row(children: [
        Icon(Icons.qr_code_2_rounded, color: blue, size: 20),
        SizedBox(width: 9),
        Text('Identitas QR', style: TextStyle(fontSize: 15, color: ink, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 15),
      Center(child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(border: Border.all(color: border),
          borderRadius: BorderRadius.circular(13)),
        child: QrImageView(data: a.code, size: 176, padding: EdgeInsets.zero),
      )),
      const SizedBox(height: 13),
      SelectableText(a.code, style: const TextStyle(fontSize: 14,
        color: ink, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      const Text('QR demo berisi kode aset. Belum terhubung ke sistem produksi.',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: muted)),
      const SizedBox(height: 13),
      outlineButton('Salin kode', Icons.copy_rounded, () async {
        await Clipboard.setData(ClipboardData(text: a.code));
        notify('Kode aset disalin');
      })
    ]));
  }

  Widget assetTimeline(AssetRecord a) {
    final entries = store.events.where((e) => e.assetId == a.id).toList();
    return surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      sectionHeader('Riwayat aset', subtitle: 'Peristiwa terkait ' + a.code),
      const SizedBox(height: 12),
      for (final e in entries) activityLine(e),
      if (entries.isEmpty)
        const Padding(padding: EdgeInsets.all(20), child: Text('Belum ada riwayat.',
          style: TextStyle(color: muted))),
    ]));
  }

  Widget detail(AssetRecord a) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 820;
      if (!wide) return Column(children: [
        identityCard(a), const SizedBox(height: 16), qrCard(a),
        const SizedBox(height: 16), assetTimeline(a)
      ]);
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(children: [
          identityCard(a), const SizedBox(height: 16), assetTimeline(a)
        ])),
        const SizedBox(width: 16),
        SizedBox(width: 300, child: qrCard(a)),
      ]);
    });
  }

  Widget history() {
    final logs = [...store.events];
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      sectionHeader('Log aktivitas', subtitle: logs.length.toString() +
        ' peristiwa tercatat dalam penyimpanan lokal'),
      const SizedBox(height: 13),
      for (final e in logs) activityLine(e),
      if (logs.isEmpty)
        const Padding(padding: EdgeInsets.all(24), child: Text('Belum ada aktivitas.',
          style: TextStyle(color: muted))),
      const SizedBox(height: 13),
      const Text('Catatan: data riwayat lokal belum memakai autentikasi atau audit server.',
        style: TextStyle(fontSize: 11, color: muted)),
    ]));
  }

  Future<void> restoreDialog() async {
    final input = TextEditingController();
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Pulihkan Data dari JSON'),
        content: SizedBox(width: 570,
          child: TextField(controller: input, minLines: 6, maxLines: 12,
            decoration: const InputDecoration(hintText: 'Tempel salinan backup JSON di sini',
              filled: true, fillColor: Color(0xFFF9FBFD)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pulihkan')),
        ],
      ),
    );
    if (proceed == true) {
      try {
        // Preserve the current in-memory state when the backup cannot be parsed.
        final raw = input.text;
        final checked = jsonDecode(raw);
        if (checked is! Map || checked['assets'] is! List ||
            checked['events'] is! List || checked['nextNumber'] is! num) {
          throw const FormatException('Struktur backup tidak sesuai');
        }
        store.restore(raw);
        await store.persist();
        notify('Data lokal berhasil dipulihkan');
      } catch (_) {
        notify('Format backup tidak valid; periksa kembali berkas JSON');
      }
    }
    input.dispose();
  }

  Future<void> resetDemo() async {
    final agree = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Kembalikan Data Simulasi?'),
        content: const Text('Seluruh perubahan lokal akan diganti dengan lima data contoh. ' +
          'Salin backup JSON terlebih dahulu bila diperlukan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset Demo')),
        ],
      ));
    if (agree == true) {
      store.seed();
      await store.persist();
      setState(() { selected = null; query = ''; statusFilter = 'Semua status'; categoryFilter = 'Semua kategori'; });
      notify('Data simulasi dikembalikan');
    }
  }

  Widget settings() {
    return LayoutBuilder(builder: (context, box) {
      final narrow = box.maxWidth < 920;
      final main = surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        sectionHeader('Penyimpanan lokal', subtitle: 'Kelola data pratinjau di browser saat ini'),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFFFF7E9),
            borderRadius: BorderRadius.circular(11)),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline_rounded, size: 20, color: amber),
            SizedBox(width: 10),
            Expanded(child: Text('Ini prototipe lokal tanpa autentikasi atau server. ' +
              'Data hanya tersimpan di browser ini. Jangan gunakan data operasional nyata.',
              style: TextStyle(fontSize: 12.5, color: ink, height: 1.5))),
          ])),
        const SizedBox(height: 21),
        Wrap(spacing: 10, runSpacing: 10, children: [
          primaryButton('Salin Backup JSON', Icons.content_copy_rounded, () async {
            await Clipboard.setData(ClipboardData(text: store.backup()));
            notify('Backup JSON berhasil disalin');
          }),
          outlineButton('Impor JSON', Icons.upload_file_outlined, restoreDialog),
          outlineButton('Reset Data Demo', Icons.restart_alt_rounded, resetDemo),
        ]),
        const Divider(color: border, height: 35),
        detailValue('Total data aset', store.assets.length.toString()),
        detailValue('Riwayat peristiwa', store.events.length.toString()),
        detailValue('Nomor berikutnya', 'UDL-AST-' + store.nextNumber.toString().padLeft(6, '0')),
      ]));
      final rules = surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        sectionHeader('Standar Kode Aset', subtitle: 'Identitas permanen aset UD. LUTHFI'),
        const SizedBox(height: 17),
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(12)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('UDL-AST-000001', style: TextStyle(fontSize: 22,
              fontWeight: FontWeight.w900, letterSpacing: 0.2, color: blue)),
            SizedBox(height: 5),
            Text('Perusahaan · Aset · Nomor urut global',
              style: TextStyle(color: muted, fontSize: 11.5)),
          ])),
        const SizedBox(height: 15),
        const Text('Kode tidak berubah ketika aset berpindah unit, lokasi, atau penanggung jawab.',
          style: TextStyle(color: muted, fontSize: 12.5, height: 1.5)),
        const SizedBox(height: 13),
        const Row(children: [
          Icon(Icons.verified_outlined, size: 17, color: green),
          SizedBox(width: 8),
          Expanded(child: Text('Nomor tidak direset per tahun',
            style: TextStyle(fontSize: 12.5, color: ink))),
        ]),
        const SizedBox(height: 9),
        const Row(children: [
          Icon(Icons.verified_outlined, size: 17, color: green),
          SizedBox(width: 8),
          Expanded(child: Text('Penghapusan tidak menggunakan ulang kode',
            style: TextStyle(fontSize: 12.5, color: ink))),
        ]),
      ]));
      if (narrow) return Column(children: [main, const SizedBox(height: 16), rules]);
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 6, child: main), const SizedBox(width: 16),
        Expanded(flex: 4, child: rules),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 920;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: navy, foregroundColor: Colors.white, toolbarHeight: 62,
        titleSpacing: compact ? 4 : 24,
        title: appHeader(),
        actions: [
          if (!compact) ...[
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF274D75), borderRadius: BorderRadius.circular(20)),
              child: const Row(children: [
                Icon(Icons.laptop_chromebook_outlined, size: 15, color: Colors.white),
                SizedBox(width: 7),
                Text('LOCAL PREVIEW', style: TextStyle(color: Colors.white,
                  fontSize: 10.5, letterSpacing: 0.8, fontWeight: FontWeight.w800)),
              ])),
            const SizedBox(width: 18),
            const CircleAvatar(radius: 17, backgroundColor: Color(0xFF41668C),
              child: Icon(Icons.person_outline_rounded, color: Colors.white, size: 19)),
            const SizedBox(width: 24),
          ],
        ],
      ),
      drawer: compact ? Drawer(backgroundColor: Colors.white, child: sidebar(inDrawer: true)) : null,
      body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!compact)
          SizedBox(width: 238, child: DecoratedBox(
            decoration: const BoxDecoration(border: Border(right: BorderSide(color: border))),
            child: sidebar())),
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          final contentPadding = constraints.maxWidth < 720 ? 16.0 : 28.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(contentPadding, 24, contentPadding, 45),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1520),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  titleArea(),
                  const SizedBox(height: 23),
                  if (selected != null) detail(selected!)
                  else if (page == 0) dashboard()
                  else if (page == 1) catalog()
                  else if (page == 2) history()
                  else settings(),
                ]),
              ),
            ),
          );
        })),
      ]),
    );
  }
}
