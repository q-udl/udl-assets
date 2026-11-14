part of 'main.dart';

/// Identity of a location node never depends on its editable name.
/// Empty area/spot means "belum dirinci", not an invented room or rack.
class AssetSite {
  final String id, code;
  String name;
  bool active;
  final List<AssetArea> areas;

  AssetSite({required this.id, required this.code, required this.name,
    this.active = true, List<AssetArea>? areas})
    : areas = areas ?? [];

  Map<String, dynamic> toJson() => {
    'id': id, 'code': code, 'name': name,
    'active': active, 'areas': areas.map((x) => x.toJson()).toList(),
  };

  factory AssetSite.fromJson(Map<String, dynamic> x) => AssetSite(
    id: x['id']?.toString() ?? '',
    code: x['code']?.toString() ?? '',
    name: x['name']?.toString() ?? '',
    active: x['active'] != false,
    areas: (x['areas'] as List<dynamic>? ?? [])
      .map((item) => AssetArea.fromJson(
        Map<String, dynamic>.from(item as Map))).toList(),
  );
}

class AssetArea {
  final String id;
  String name;
  bool active;
  final List<AssetSpot> spots;

  AssetArea({required this.id, required this.name,
    this.active = true, List<AssetSpot>? spots})
    : spots = spots ?? [];

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'active': active,
    'spots': spots.map((x) => x.toJson()).toList(),
  };

  factory AssetArea.fromJson(Map<String, dynamic> x) => AssetArea(
    id: x['id']?.toString() ?? '',
    name: x['name']?.toString() ?? '',
    active: x['active'] != false,
    spots: (x['spots'] as List<dynamic>? ?? [])
      .map((item) => AssetSpot.fromJson(
        Map<String, dynamic>.from(item as Map))).toList(),
  );
}

class AssetSpot {
  final String id;
  String name;
  bool active;

  AssetSpot({required this.id, required this.name, this.active = true});

  Map<String, dynamic> toJson() =>
    {'id': id, 'name': name, 'active': active};

  factory AssetSpot.fromJson(Map<String, dynamic> x) => AssetSpot(
    id: x['id']?.toString() ?? '',
    name: x['name']?.toString() ?? '',
    active: x['active'] != false,
  );
}

class AssetPlacement {
  final String siteId, areaId, spotId;
  const AssetPlacement(this.siteId, {this.areaId = '', this.spotId = ''});
}
