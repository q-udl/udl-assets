part of 'main.dart';

/// Operasional, bukan bagan akun FA. Tanah, bangunan dan renovasi struktur
/// sengaja dikecualikan dari UDL Assets.
// IDs are stable across renames. Legacy v0.3 names get deterministic IDs.
String taxonomySlug(String value) =>
  value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+

class AssetClassification {
  final String category;
  final String subcategory;
  final String type;
  const AssetClassification(this.category, this.subcategory, this.type);
}

List<AssetCategory> defaultTaxonomy() => [
  AssetCategory('01', 'Furnitur', [
    AssetSubcategory('Meja', ['Meja Kerja', 'Meja Rapat', 'Meja Layanan', 'Meja Lainnya']),
    AssetSubcategory('Kursi', ['Kursi Kerja', 'Kursi Tamu', 'Kursi Tunggu', 'Kursi Lainnya']),
    AssetSubcategory('Penyimpanan Furnitur', ['Lemari', 'Loker', 'Kabinet']),
    AssetSubcategory('Furnitur Lainnya', ['Sofa', 'Partisi Lepas Pasang', 'Furnitur Lainnya']),
  ]),
  AssetCategory('02', 'Perlengkapan Outlet & Penyimpanan', [
    AssetSubcategory('Display Penjualan', ['Rak Display', 'Etalase', 'Gondola', 'Display Stand']),
    AssetSubcategory('Perlengkapan Kasir Fisik', ['Meja Kasir', 'Counter Pelayanan']),
    AssetSubcategory('Penyimpanan Gudang', ['Rak Gudang', 'Pallet Rack', 'Kabinet Gudang']),
    AssetSubcategory('Perlengkapan Lainnya', ['Troli Display', 'Perlengkapan Lainnya']),
  ]),
  AssetCategory('03', 'Teknologi Informasi & Komunikasi', [
    AssetSubcategory('Komputer', ['Laptop', 'Desktop', 'Mini PC', 'Server', 'Tablet Kerja']),
    AssetSubcategory('Periferal Komputer', [
      'Monitor', 'Printer Dokumen', 'Scanner Dokumen', 'Keyboard', 'Mouse',
      'Docking Station', 'UPS Komputer',
    ]),
    AssetSubcategory('Perangkat Jaringan', [
      'Router', 'Switch', 'Access Point', 'Firewall', 'Network Storage',
    ]),
    AssetSubcategory('Perangkat Komunikasi', ['Telepon IP', 'Handy Talky', 'Telepon Kerja']),
    AssetSubcategory('Perangkat POS', [
      'Terminal POS', 'Printer Struk', 'Barcode Scanner', 'Laci Kas Elektronik',
    ]),
  ]),
  AssetCategory('04', 'Peralatan Kantor & Audio Visual', [
    AssetSubcategory('Mesin Kantor Non-TIK', ['Mesin Penghancur Kertas', 'Mesin Laminasi', 'Mesin Jilid']),
    AssetSubcategory('Presentasi', ['Proyektor', 'Layar Proyektor', 'Interactive Display']),
    AssetSubcategory('Audio Visual', ['Speaker', 'Mikrofon', 'Kamera Meeting', 'Mixer Audio']),
  ]),
  AssetCategory('05', 'Peralatan Fasilitas & Utilitas', [
    AssetSubcategory('Pendingin Ruangan', ['AC', 'Kipas Angin', 'Air Cooler']),
    AssetSubcategory('Kelistrikan', ['Genset', 'Stabilizer', 'Panel Listrik Terpisah']),
    AssetSubcategory('Air & Sanitasi', ['Pompa Air', 'Water Dispenser', 'Filter Air']),
    AssetSubcategory('Fasilitas Lainnya', ['Vacuum Cleaner', 'Mesin Pembersih Lantai']),
  ]),
  AssetCategory('06', 'Kendaraan Operasional', [
    AssetSubcategory('Kendaraan Penumpang', ['Mobil Operasional', 'Minibus']),
    AssetSubcategory('Kendaraan Barang', ['Pick-up', 'Van', 'Truk', 'Truk Boks']),
    AssetSubcategory('Sepeda Motor', ['Motor Operasional', 'Motor Pengiriman']),
  ]),
  AssetCategory('07', 'Peralatan Gudang & Logistik', [
    AssetSubcategory('Penanganan Material', ['Forklift', 'Hand Pallet', 'Stacker', 'Troli Angkut']),
    AssetSubcategory('Pemindahan Barang', ['Conveyor', 'Loading Ramp']),
    AssetSubcategory('Pengukuran Logistik', ['Timbangan Barang', 'Dimensioner']),
  ]),
  AssetCategory('08', 'Peralatan Teknik & Pemeliharaan', [
    AssetSubcategory('Perkakas Elektrik', ['Bor Listrik', 'Gerinda', 'Impact Driver']),
    AssetSubcategory('Perkakas Manual', ['Set Kunci', 'Dongkrak', 'Tangga Portabel']),
    AssetSubcategory('Alat Ukur', ['Multimeter', 'Laser Meter', 'Clamp Meter']),
    AssetSubcategory('Mesin Teknik', ['Mesin Las', 'Kompresor Portabel']),
  ]),
  AssetCategory('09', 'Peralatan Keamanan & Keselamatan', [
    AssetSubcategory('Pengawasan', ['Kamera CCTV', 'Perekam CCTV', 'Monitor Pengawasan']),
    AssetSubcategory('Keamanan & Akses', ['Alarm Keamanan', 'Kontrol Akses', 'Metal Detector']),
    AssetSubcategory('Keselamatan', ['APAR', 'Kotak P3K Terkendali', 'Detektor Asap']),
  ]),
];

/// Digunakan hanya untuk memperkaya data versi lama tanpa menghapus entri.
AssetClassification classifyLegacyAsset(String category, String name) {
  final normalized = name.toLowerCase();
  if (normalized.contains('forklift')) {
    return const AssetClassification(
      'Peralatan Gudang & Logistik', 'Penanganan Material', 'Forklift');
  }
  if (normalized.contains('printer')) {
    return const AssetClassification(
      'Teknologi Informasi & Komunikasi', 'Periferal Komputer', 'Printer Dokumen');
  }
  if (normalized.contains('laptop')) {
    return const AssetClassification(
      'Teknologi Informasi & Komunikasi', 'Komputer', 'Laptop');
  }
  if (normalized.contains('ac ') || normalized.startsWith('ac ')) {
    return const AssetClassification(
      'Peralatan Fasilitas & Utilitas', 'Pendingin Ruangan', 'AC');
  }
  if (normalized.contains('meja')) {
    return const AssetClassification('Furnitur', 'Meja', 'Meja Kerja');
  }
  if (category == 'IT') {
    return const AssetClassification(
      'Teknologi Informasi & Komunikasi', 'Komputer', 'Desktop');
  }
  if (category == 'Furnitur') {
    return const AssetClassification('Furnitur', 'Furnitur Lainnya', 'Furnitur Lainnya');
  }
  if (category == 'Kendaraan') {
    return const AssetClassification(
      'Kendaraan Operasional', 'Kendaraan Penumpang', 'Mobil Operasional');
  }
  if (category == 'Bangunan' || category == 'Tanah') {
    // Aset lama tetap terlihat untuk ditinjau; tidak ada jenis properti baru.
    return const AssetClassification('Perlu Klasifikasi Ulang', '', '');
  }
  return const AssetClassification('Perlu Klasifikasi Ulang', '', '');
}
), '');

class AssetCategory {
  final String code;
  String name;
  bool active;
  final List<AssetSubcategory> subcategories;
  AssetCategory(this.code, this.name, this.subcategories, {this.active = true});

  Map<String, dynamic> toJson() => {
    'code': code, 'name': name, 'active': active,
    'subcategories': subcategories.map((s) => s.toJson()).toList(),
  };

  factory AssetCategory.fromJson(Map<String, dynamic> json) => AssetCategory(
    json['code'] as String,
    json['name'] as String,
    (json['subcategories'] as List<dynamic>).map((v) =>
      AssetSubcategory.fromJson(Map<String, dynamic>.from(v as Map))).toList(),
    active: json['active'] != false,
  );
}

class AssetSubcategory {
  String name;
  final String id;
  bool active;
  final List<String> types;
  final Map<String, String> typeIds;
  final Set<String> inactiveTypes;
  AssetSubcategory(this.name, this.types, {String? id, this.active = true,
      Map<String, String>? typeIds, Set<String>? inactiveTypes})
      : id = id ?? 'sub-' + taxonomySlug(name),
        typeIds = typeIds ?? {for (final t in types) t: 'type-' + taxonomySlug(t)},
        inactiveTypes = inactiveTypes ?? <String>{};

  String typeId(String name) => typeIds[name] ?? 'type-' + taxonomySlug(name);
  bool typeIsActive(String name) => !inactiveTypes.contains(name);

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'active': active, 'types': types,
    'typeIds': typeIds, 'inactiveTypes': inactiveTypes.toList(),
  };

  factory AssetSubcategory.fromJson(Map<String, dynamic> json) =>
    AssetSubcategory(json['name'] as String,
      List<String>.from(json['types'] as List<dynamic>),
      id: json['id']?.toString(),
      active: json['active'] != false,
      typeIds: json['typeIds'] is Map ? Map<String, String>.from(json['typeIds'] as Map) : null,
      inactiveTypes: (json['inactiveTypes'] as List<dynamic>? ?? []).map((x) => x.toString()).toSet());
}

class AssetClassification {
  final String category;
  final String subcategory;
  final String type;
  const AssetClassification(this.category, this.subcategory, this.type);
}

List<AssetCategory> defaultTaxonomy() => [
  AssetCategory('01', 'Furnitur', [
    AssetSubcategory('Meja', ['Meja Kerja', 'Meja Rapat', 'Meja Layanan', 'Meja Lainnya']),
    AssetSubcategory('Kursi', ['Kursi Kerja', 'Kursi Tamu', 'Kursi Tunggu', 'Kursi Lainnya']),
    AssetSubcategory('Penyimpanan Furnitur', ['Lemari', 'Loker', 'Kabinet']),
    AssetSubcategory('Furnitur Lainnya', ['Sofa', 'Partisi Lepas Pasang', 'Furnitur Lainnya']),
  ]),
  AssetCategory('02', 'Perlengkapan Outlet & Penyimpanan', [
    AssetSubcategory('Display Penjualan', ['Rak Display', 'Etalase', 'Gondola', 'Display Stand']),
    AssetSubcategory('Perlengkapan Kasir Fisik', ['Meja Kasir', 'Counter Pelayanan']),
    AssetSubcategory('Penyimpanan Gudang', ['Rak Gudang', 'Pallet Rack', 'Kabinet Gudang']),
    AssetSubcategory('Perlengkapan Lainnya', ['Troli Display', 'Perlengkapan Lainnya']),
  ]),
  AssetCategory('03', 'Teknologi Informasi & Komunikasi', [
    AssetSubcategory('Komputer', ['Laptop', 'Desktop', 'Mini PC', 'Server', 'Tablet Kerja']),
    AssetSubcategory('Periferal Komputer', [
      'Monitor', 'Printer Dokumen', 'Scanner Dokumen', 'Keyboard', 'Mouse',
      'Docking Station', 'UPS Komputer',
    ]),
    AssetSubcategory('Perangkat Jaringan', [
      'Router', 'Switch', 'Access Point', 'Firewall', 'Network Storage',
    ]),
    AssetSubcategory('Perangkat Komunikasi', ['Telepon IP', 'Handy Talky', 'Telepon Kerja']),
    AssetSubcategory('Perangkat POS', [
      'Terminal POS', 'Printer Struk', 'Barcode Scanner', 'Laci Kas Elektronik',
    ]),
  ]),
  AssetCategory('04', 'Peralatan Kantor & Audio Visual', [
    AssetSubcategory('Mesin Kantor Non-TIK', ['Mesin Penghancur Kertas', 'Mesin Laminasi', 'Mesin Jilid']),
    AssetSubcategory('Presentasi', ['Proyektor', 'Layar Proyektor', 'Interactive Display']),
    AssetSubcategory('Audio Visual', ['Speaker', 'Mikrofon', 'Kamera Meeting', 'Mixer Audio']),
  ]),
  AssetCategory('05', 'Peralatan Fasilitas & Utilitas', [
    AssetSubcategory('Pendingin Ruangan', ['AC', 'Kipas Angin', 'Air Cooler']),
    AssetSubcategory('Kelistrikan', ['Genset', 'Stabilizer', 'Panel Listrik Terpisah']),
    AssetSubcategory('Air & Sanitasi', ['Pompa Air', 'Water Dispenser', 'Filter Air']),
    AssetSubcategory('Fasilitas Lainnya', ['Vacuum Cleaner', 'Mesin Pembersih Lantai']),
  ]),
  AssetCategory('06', 'Kendaraan Operasional', [
    AssetSubcategory('Kendaraan Penumpang', ['Mobil Operasional', 'Minibus']),
    AssetSubcategory('Kendaraan Barang', ['Pick-up', 'Van', 'Truk', 'Truk Boks']),
    AssetSubcategory('Sepeda Motor', ['Motor Operasional', 'Motor Pengiriman']),
  ]),
  AssetCategory('07', 'Peralatan Gudang & Logistik', [
    AssetSubcategory('Penanganan Material', ['Forklift', 'Hand Pallet', 'Stacker', 'Troli Angkut']),
    AssetSubcategory('Pemindahan Barang', ['Conveyor', 'Loading Ramp']),
    AssetSubcategory('Pengukuran Logistik', ['Timbangan Barang', 'Dimensioner']),
  ]),
  AssetCategory('08', 'Peralatan Teknik & Pemeliharaan', [
    AssetSubcategory('Perkakas Elektrik', ['Bor Listrik', 'Gerinda', 'Impact Driver']),
    AssetSubcategory('Perkakas Manual', ['Set Kunci', 'Dongkrak', 'Tangga Portabel']),
    AssetSubcategory('Alat Ukur', ['Multimeter', 'Laser Meter', 'Clamp Meter']),
    AssetSubcategory('Mesin Teknik', ['Mesin Las', 'Kompresor Portabel']),
  ]),
  AssetCategory('09', 'Peralatan Keamanan & Keselamatan', [
    AssetSubcategory('Pengawasan', ['Kamera CCTV', 'Perekam CCTV', 'Monitor Pengawasan']),
    AssetSubcategory('Keamanan & Akses', ['Alarm Keamanan', 'Kontrol Akses', 'Metal Detector']),
    AssetSubcategory('Keselamatan', ['APAR', 'Kotak P3K Terkendali', 'Detektor Asap']),
  ]),
];

/// Digunakan hanya untuk memperkaya data versi lama tanpa menghapus entri.
AssetClassification classifyLegacyAsset(String category, String name) {
  final normalized = name.toLowerCase();
  if (normalized.contains('forklift')) {
    return const AssetClassification(
      'Peralatan Gudang & Logistik', 'Penanganan Material', 'Forklift');
  }
  if (normalized.contains('printer')) {
    return const AssetClassification(
      'Teknologi Informasi & Komunikasi', 'Periferal Komputer', 'Printer Dokumen');
  }
  if (normalized.contains('laptop')) {
    return const AssetClassification(
      'Teknologi Informasi & Komunikasi', 'Komputer', 'Laptop');
  }
  if (normalized.contains('ac ') || normalized.startsWith('ac ')) {
    return const AssetClassification(
      'Peralatan Fasilitas & Utilitas', 'Pendingin Ruangan', 'AC');
  }
  if (normalized.contains('meja')) {
    return const AssetClassification('Furnitur', 'Meja', 'Meja Kerja');
  }
  if (category == 'IT') {
    return const AssetClassification(
      'Teknologi Informasi & Komunikasi', 'Komputer', 'Desktop');
  }
  if (category == 'Furnitur') {
    return const AssetClassification('Furnitur', 'Furnitur Lainnya', 'Furnitur Lainnya');
  }
  if (category == 'Kendaraan') {
    return const AssetClassification(
      'Kendaraan Operasional', 'Kendaraan Penumpang', 'Mobil Operasional');
  }
  if (category == 'Bangunan' || category == 'Tanah') {
    // Aset lama tetap terlihat untuk ditinjau; tidak ada jenis properti baru.
    return const AssetClassification('Perlu Klasifikasi Ulang', '', '');
  }
  return const AssetClassification('Perlu Klasifikasi Ulang', '', '');
}
