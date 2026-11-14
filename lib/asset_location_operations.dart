part of 'main.dart';

extension AssetLocationOperations on AssetStore {
  AssetSite legacySite(String name, int number) => AssetSite(
    id: 'legacy-' + base64Url.encode(utf8.encode(name.toLowerCase()))
      .replaceAll('=', ''),
    code: 'LOC-' + number.toString().padLeft(3, '0'), name: name);

  void migrateLocationMaster(Map<String, dynamic> raw) {
    final names = <String>{
      ...locations.where((x) => x.trim().isNotEmpty),
      ...assets.map((x) => x.location).where((x) => x.trim().isNotEmpty),
    }.toList();
    if (raw['locationSites'] is List) {
      locationSites = (raw['locationSites'] as List).map((v) =>
        AssetSite.fromJson(Map<String, dynamic>.from(v as Map))).toList();
      validateLocationMaster();
      for (final name in names) {
        if (siteByName(name) == null) {
          locationSites.add(legacySite(name, locationSites.length + 1));
        }
      }
    } else {
      locationSites = [
        for (var i = 0; i < names.length; i++) legacySite(names[i], i + 1)
      ];
    }
    final maxCode = locationSites.fold<int>(0, (current, site) {
      final value = int.tryParse(site.code.replaceFirst('LOC-', '')) ?? 0;
      return value > current ? value : current;
    });
    final next = (raw['nextLocationNumber'] as num?)?.toInt() ?? 1;
    nextLocationNumber = next > maxCode ? next : maxCode + 1;
    for (final asset in assets) {
      if (asset.locationSiteId.isEmpty) {
        asset.locationSiteId = siteByName(asset.location)?.id ?? '';
      }
      if (!validPlacement(AssetPlacement(asset.locationSiteId,
          areaId: asset.locationAreaId, spotId: asset.locationSpotId),
          allowInactive: true) ||
          siteById(asset.locationSiteId)?.name != asset.location) {
        throw FormatException('Referensi lokasi aset ' +
          asset.code + ' tidak valid.');
      }
    }
    locations = locationSites.map((s) => s.name).toList()..sort();
  }

  void validateLocationMaster() {
    final ids = <String>{}, codes = <String>{}, names = <String>{};
    for (final site in locationSites) {
      if (site.id.trim().isEmpty || site.code.trim().isEmpty ||
          site.name.trim().isEmpty || !ids.add(site.id) ||
          !codes.add(site.code) || !names.add(site.name.toLowerCase())) {
        throw const FormatException('Lokasi utama duplikat/tidak valid.');
      }
      final areaIds = <String>{}, areaNames = <String>{};
      for (final area in site.areas) {
        if (area.id.isEmpty || area.name.trim().isEmpty ||
            !areaIds.add(area.id) || !areaNames.add(area.name.toLowerCase())) {
          throw const FormatException('Area duplikat/tidak valid.');
        }
        final spotIds = <String>{}, spotNames = <String>{};
        for (final spot in area.spots) {
          if (spot.id.isEmpty || spot.name.trim().isEmpty ||
              !spotIds.add(spot.id) ||
              !spotNames.add(spot.name.toLowerCase())) {
            throw const FormatException('Titik penempatan duplikat/tidak valid.');
          }
        }
      }
    }
  }

  AssetSite? siteById(String id) {
    for (final s in locationSites) {
      if (s.id == id) return s;
    }
    return null;
  }

  AssetSite? siteByName(String name) {
    for (final s in locationSites) {
      if (s.name.toLowerCase() == name.toLowerCase()) return s;
    }
    return null;
  }

  AssetArea? areaById(AssetSite site, String id) {
    for (final a in site.areas) {
      if (a.id == id) return a;
    }
    return null;
  }

  AssetSpot? spotById(AssetArea area, String id) {
    for (final p in area.spots) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool validPlacement(AssetPlacement p, {bool allowInactive = false}) {
    final site = siteById(p.siteId);
    if (site == null || (!allowInactive && !site.active)) return false;
    if (p.areaId.isEmpty) return p.spotId.isEmpty;
    final area = areaById(site, p.areaId);
    if (area == null || (!allowInactive && !area.active)) return false;
    if (p.spotId.isEmpty) return true;
    final spot = spotById(area, p.spotId);
    return spot != null && (allowInactive || spot.active);
  }

  List<AssetSite> get activeSites =>
    locationSites.where((s) => s.active).toList();

  String placementPath(AssetPlacement p, {String fallback = ''}) {
    final site = siteById(p.siteId);
    if (site == null) return fallback;
    final segments = <String>[site.name];
    if (p.areaId.isNotEmpty) {
      final area = areaById(site, p.areaId);
      if (area != null) {
        segments.add(area.name);
        if (p.spotId.isNotEmpty) {
          final spot = spotById(area, p.spotId);
          if (spot != null) segments.add(spot.name);
        }
      }
    }
    return segments.join(' / ');
  }

  String locationPath(AssetRecord a) => placementPath(
    AssetPlacement(a.locationSiteId,
      areaId: a.locationAreaId, spotId: a.locationSpotId),
    fallback: a.location);

  void applyPlacement(AssetRecord a, AssetPlacement p) {
    if (!validPlacement(p, allowInactive: true)) {
      throw const FormatException('Penempatan tidak valid.');
    }
    a.location = siteById(p.siteId)!.name;
    a.locationSiteId = p.siteId;
    a.locationAreaId = p.areaId;
    a.locationSpotId = p.spotId;
  }

  void locationAudit(String detail) => events.insert(0,
    EventRecord('', 'Master Lokasi', detail,
      DateTime.now().toIso8601String()));

  Future<AssetSite> addSite(String text) async {
    final name = text.trim();
    if (name.length < 3 || siteByName(name) != null) {
      throw const FormatException('Lokasi utama tidak valid atau duplikat.');
    }
    final s = AssetSite(id: uuid.v4(),
      code: 'LOC-' + nextLocationNumber.toString().padLeft(3,'0'),
      name: name);
    nextLocationNumber++;
    locationSites.add(s);
    locations = locationSites.map((x) => x.name).toList()..sort();
    locationAudit('Tambah lokasi: ' + name);
    await persist();
    return s;
  }

  Future<void> renameSite(AssetSite s, String text) async {
    final name = text.trim();
    if (name.length < 3 ||
        locationSites.any((v) => v.id != s.id &&
          v.name.toLowerCase() == name.toLowerCase())) {
      throw const FormatException('Nama lokasi duplikat/tidak valid.');
    }
    if (transfers.any((t) => t.state == 'Menunggu Penerimaan' &&
        (t.fromLocation == s.name || t.toLocation == s.name))) {
      throw const FormatException('Selesaikan mutasi tertunda terlebih dahulu.');
    }
    if (name == s.name) return;
    final old = s.name;
    s.name = name;
    for (final asset in assets.where((a) => a.location == old)) {
      asset.location = name;
      log(asset, 'Penyesuaian Nama Lokasi', old + ' → ' + name,
        changes: {'Lokasi': {'from': old, 'to': name}});
    }
    for (final employee in employees.where((e) => e.workLocation == old)) {
      employee.workLocation = name;
    }
    locations = locationSites.map((x) => x.name).toList()..sort();
    locationAudit('Ubah lokasi: ' + old + ' → ' + name);
    await persist();
  }

  Future<AssetArea> addArea(AssetSite s, String text) async {
    final name = text.trim();
    if (name.length < 2 || !s.active ||
        s.areas.any((a) => a.name.toLowerCase() == name.toLowerCase())) {
      throw const FormatException('Area tidak valid/duplikat.');
    }
    final a = AssetArea(id: uuid.v4(), name: name);
    s.areas.add(a);
    locationAudit('Tambah area: ' + s.name + ' / ' + name);
    await persist();
    return a;
  }

  Future<void> renameArea(AssetSite s, AssetArea a, String text) async {
    final name = text.trim();
    if (name.length < 2 || s.areas.any((x) => x.id != a.id &&
        x.name.toLowerCase() == name.toLowerCase())) {
      throw const FormatException('Area duplikat/tidak valid.');
    }
    final old = a.name;
    a.name = name;
    locationAudit('Ubah area: ' + s.name + ' / ' + old + ' → ' + name);
    await persist();
  }

  Future<AssetSpot> addSpot(AssetSite s, AssetArea a, String text) async {
    final name = text.trim();
    if (!s.active || !a.active || name.length < 2 ||
        a.spots.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
      throw const FormatException('Titik penempatan tidak valid/duplikat.');
    }
    final p = AssetSpot(id: uuid.v4(), name: name);
    a.spots.add(p);
    locationAudit('Tambah titik: ' + s.name + ' / ' + a.name + ' / ' + name);
    await persist();
    return p;
  }

  Future<void> renameSpot(
      AssetSite s, AssetArea a, AssetSpot p, String text) async {
    final name = text.trim();
    if (name.length < 2 || a.spots.any((v) => v.id != p.id &&
        v.name.toLowerCase() == name.toLowerCase())) {
      throw const FormatException('Titik duplikat/tidak valid.');
    }
    final old = p.name;
    p.name = name;
    locationAudit('Ubah titik: ' + s.name + ' / ' + a.name +
      ' / ' + old + ' → ' + name);
    await persist();
  }

  Future<void> setSiteActive(AssetSite s, bool active) async {
    s.active = active;
    locationAudit((active ? 'Aktifkan' : 'Nonaktifkan') +
      ' lokasi: ' + s.name);
    await persist();
  }

  Future<void> setAreaActive(AssetSite s, AssetArea a, bool active) async {
    a.active = active;
    locationAudit((active ? 'Aktifkan' : 'Nonaktifkan') +
      ' area: ' + s.name + ' / ' + a.name);
    await persist();
  }

  Future<void> setSpotActive(
      AssetSite s, AssetArea a, AssetSpot p, bool active) async {
    p.active = active;
    locationAudit((active ? 'Aktifkan' : 'Nonaktifkan') +
      ' titik: ' + s.name + ' / ' + a.name + ' / ' + p.name);
    await persist();
  }
}
