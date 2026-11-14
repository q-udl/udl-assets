part of 'main.dart';

/// Location master is distinct from department, unit, and accounting class.
/// Hierarchy: Lokasi Utama -> Area -> Titik Penempatan.
class AssetSite {
  final String id, code;
  String name;
  bool active;
  final List<AssetArea> areas;

  AssetSite({
    required this.id, required this.code, required this.name,
    this.active = true, List<AssetArea>? areas,
  }) : areas = areas ?? [];

  Map<String, dynamic> toJson() => {
    'id': id, 'code': code, 'name': name, 'active': active,
    'areas': areas.map((v) => v.toJson()).toList(),
  };

  factory AssetSite.fromJson(Map<String, dynamic> m) => AssetSite(
    id: m['id']?.toString() ?? '',
    code: m['code']?.toString() ?? '',
    name: m['name']?.toString() ?? '',
    active: m['active'] != false,
    areas: (m['areas'] as List<dynamic>? ?? [])
      .map((v) => AssetArea.fromJson(
        Map<String, dynamic>.from(v as Map))).toList(),
  );
}

class AssetArea {
  final String id;
  String name;
  bool active;
  final List<AssetSpot> spots;
  AssetArea({
    required this.id, required this.name,
    this.active = true, List<AssetSpot>? spots,
  }) : spots = spots ?? [];

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'active': active,
    'spots': spots.map((v) => v.toJson()).toList(),
  };

  factory AssetArea.fromJson(Map<String, dynamic> m) => AssetArea(
    id: m['id']?.toString() ?? '',
    name: m['name']?.toString() ?? '',
    active: m['active'] != false,
    spots: (m['spots'] as List<dynamic>? ?? [])
      .map((v) => AssetSpot.fromJson(
        Map<String, dynamic>.from(v as Map))).toList(),
  );
}

class AssetSpot {
  final String id;
  String name;
  bool active;
  AssetSpot({required this.id, required this.name, this.active = true});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'active': active,
  };

  factory AssetSpot.fromJson(Map<String, dynamic> m) => AssetSpot(
    id: m['id']?.toString() ?? '',
    name: m['name']?.toString() ?? '',
    active: m['active'] != false,
  );
}

class AssetLocationSelection {
  final String siteId, areaId, spotId;
  const AssetLocationSelection({
    required this.siteId, this.areaId = '', this.spotId = '',
  });

  bool get hasSite => siteId.isNotEmpty;
  AssetLocationSelection withSite(String value) =>
    AssetLocationSelection(siteId: value);
  AssetLocationSelection withArea(String value) =>
    AssetLocationSelection(siteId: siteId, areaId: value);
  AssetLocationSelection withSpot(String value) =>
    AssetLocationSelection(siteId: siteId, areaId: areaId, spotId: value);
}
