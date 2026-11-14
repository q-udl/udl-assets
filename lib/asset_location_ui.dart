part of 'main.dart';

extension _AssetLocationMasterUI on _AssetScreenState {
  Widget v6Locations() {
    final q = v6LocationSearch.trim().toLowerCase();
    final matches = store.locationSites.where((s) {
      return s.name.toLowerCase().contains(q) || s.areas.any((a) =>
        a.name.toLowerCase().contains(q) ||
        a.spots.any((p) => p.name.toLowerCase().contains(q)));
    }).toList();
    AssetSite? site;
    for (final candidate in matches) {
      if (candidate.id == v6SiteId) site = candidate;
    }
    site ??= matches.isEmpty ? null : matches.first;
    AssetArea? area;
    if (site != null) {
      for (final candidate in site.areas) {
        if (candidate.id == v6AreaId) area = candidate;
      }
      area ??= site.areas.isEmpty ? null : site.areas.first;
    }
    final selectedSite = site, selectedArea = area;

    int siteCount(AssetSite s) => store.assets.where((asset) =>
      asset.locationSiteId == s.id ||
      (asset.locationSiteId.isEmpty && asset.location == s.name)).length;
    int areaCount(String id) => store.assets
      .where((asset) => asset.locationAreaId == id).length;
    int spotCount(String id) => store.assets
      .where((asset) => asset.locationSpotId == id).length;

    Widget actionMenu({
      required String name,
      required bool active,
      required VoidCallback rename,
      required VoidCallback toggle,
    }) => PopupMenuButton<String>(
      tooltip: 'Kelola ' + name,
      onSelected: (value) =>
        value == 'rename' ? rename() : toggle(),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'rename',
          child: Text('Ubah Nama')),
        PopupMenuItem(value: 'toggle',
          child: assetMenuActionLabel(active ? 'Nonaktifkan' : 'Aktifkan',
            active ? AssetActionTone.warning : AssetActionTone.success)),
      ],
    );

    final columns = <Widget>[
      v4MasterPanel('Lokasi Utama', 'Tambah Lokasi Utama',
        () => v4MasterPrompt('Tambah Lokasi Utama','',
          (name) async {
            final added = await store.addSite(name);
            v6SiteId = added.id;
            v6AreaId = '';
          }),
        [for (final s in matches)
          ListTile(
            dense: true,
            selected: selectedSite?.id == s.id,
            title: Text(s.name, maxLines: 2,
              overflow: TextOverflow.ellipsis),
            subtitle: Text(s.code + ' · ' + siteCount(s).toString() +
              ' aset' + (s.active ? '' : ' · Nonaktif')),
            onTap: () => v4Change(() {
              v6SiteId = s.id; v6AreaId = '';
            }),
            trailing: actionMenu(
              name: s.name, active: s.active,
              rename: () => v4MasterPrompt('Ubah Lokasi Utama',s.name,
                (name) => store.renameSite(s,name)),
              toggle: () => store.setSiteActive(s, !s.active)
                .then((_) => repaint())
                .catchError((Object e) => notify(e.toString())),
            ),
          )]),
      v4MasterPanel('Area', 'Tambah Area',
        selectedSite == null || !selectedSite.active ? null :
          () => v4MasterPrompt('Tambah Area','',
            (name) => store.addArea(selectedSite,name)),
        [
          if (selectedSite != null)
            for (final a in selectedSite.areas.where((a) =>
              q.isEmpty || a.name.toLowerCase().contains(q) ||
              selectedSite.name.toLowerCase().contains(q) ||
              a.spots.any((p) => p.name.toLowerCase().contains(q))))
              ListTile(
                dense: true,
                selected: selectedArea?.id == a.id,
                title: Text(a.name),
                subtitle: Text(areaCount(a.id).toString() +
                  ' aset' + (a.active ? '' : ' · Nonaktif')),
                onTap: () => v4Change(() => v6AreaId = a.id),
                trailing: actionMenu(
                  name: a.name, active: a.active,
                  rename: () => v4MasterPrompt('Ubah Area',a.name,
                    (name) => store.renameArea(selectedSite,a,name)),
                  toggle: () => store.setAreaActive(
                    selectedSite,a,!a.active).then((_) => repaint())
                    .catchError((Object e) => notify(e.toString())),
                ),
              ),
        ]),
      v4MasterPanel('Titik Penempatan', 'Tambah Titik',
        selectedSite == null || selectedArea == null ||
          !selectedSite.active || !selectedArea.active ? null :
          () => v4MasterPrompt('Tambah Titik Penempatan','',
            (name) => store.addSpot(selectedSite,selectedArea,name)),
        [
          if (selectedSite != null && selectedArea != null)
            for (final spot in selectedArea.spots.where((spot) =>
              q.isEmpty || spot.name.toLowerCase().contains(q) ||
              selectedArea.name.toLowerCase().contains(q) ||
              selectedSite.name.toLowerCase().contains(q)))
              ListTile(
                dense: true,
                title: Text(spot.name),
                subtitle: Text(spotCount(spot.id).toString() +
                  ' aset' + (spot.active ? '' : ' · Nonaktif')),
                onTap: () => openAssetListFromMaster(
                  location: selectedSite.name,
                  areaId: selectedArea.id, spotId: spot.id),
                trailing: actionMenu(
                  name: spot.name, active: spot.active,
                  rename: () => v4MasterPrompt('Ubah Titik Penempatan',
                    spot.name, (name) =>
                      store.renameSpot(selectedSite,selectedArea,spot,name)),
                  toggle: () => store.setSpotActive(
                    selectedSite,selectedArea,spot,!spot.active)
                    .then((_) => repaint())
                    .catchError((Object e) => notify(e.toString())),
                ),
              ),
        ]),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      surface(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        sectionHeader('Master Lokasi Aset',
          subtitle: 'Lokasi Utama → Area → Titik Penempatan'),
        const SizedBox(height: 12),
        TextField(
          controller: _locationSearchController,
          decoration: const InputDecoration(
            hintText: 'Cari lokasi, area, atau titik penempatan...',
            prefixIcon: Icon(Icons.search)),
          onChanged: (value) => v4Change(
            () => v6LocationSearch = value),
        ),
        const SizedBox(height: 8),
        Text(store.locationSites.length.toString() +
          ' lokasi utama · data aset lama tetap terhubung tanpa '
          'membuat area/titik fiktif',
          style: const TextStyle(fontSize: 11, color: muted)),
      ])),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (ctx, box) {
        if (box.maxWidth < 850) {
          return Column(children: [
            for (final column in columns) Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: column),
          ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: columns[0]), const SizedBox(width: 12),
            Expanded(child: columns[1]), const SizedBox(width: 12),
            Expanded(child: columns[2]),
          ]);
      }),
    ]);
  }
}
