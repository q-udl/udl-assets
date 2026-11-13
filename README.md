# UD. LUTHFI — Manajemen Aset

Aplikasi manajemen aset berbasis **Flutter**, dengan fokus awal pada **Flutter Web yang dijalankan lokal**. Repositori ini untuk prototipe/review internal, **bukan** sistem produksi.

## Menjalankan lokal

Prasyarat: Flutter SDK (stable), Dart (dibundel), Chrome/Edge.

```powershell
git clone https://github.com/q-udl/udl-assets.git
cd udl-assets
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 8080
```

Buka http://localhost:8080. Jika Chrome tidak terdeteksi, jalankan `flutter devices` dan pilih web device yang tersedia.

## Cakupan prototipe
- Ringkasan, katalog/master aset, pencarian dan filter
- Registrasi aset dengan kode unik permanen `UDL-AST-000001`
- Detail dan QR label (QR berisi kode aset, belum URL sistem produksi)
- Serah terima, mutasi lokasi, pengembalian, penghapusan
- Jadwal perawatan, riwayat perubahan, kategori dan lokasi
- Data contoh untuk UAT lokal, penyimpanan **per-browser** lewat SharedPreferences
- Salin/restore backup JSON manual

**Peringatan:** data tersimpan hanya di browser/perangkat yang digunakan. Bukan untuk data riil, tidak memiliki autentikasi, server, atau sinkronisasi antar-perangkat. Hapus data browser dapat menghapus data aplikasi. Tinjau UI/UX dan proses bisnis dulu sebelum mengintegrasikan backend produksi.

## Prinsip desain
Identitas `AssetUUID` internal terpisah dari kode `UDL-AST-NNNNNN`, yang tidak berubah walaupun lokasi/penanggung jawab berubah. Semua transaksi operasional menghasilkan catatan riwayat. Aset yang dikeluarkan dari penggunaan diberi status `Dihapuskan`, bukan dihapus permanen.

Lihat kode sumber dalam `lib/`. Tidak ada deployment UAT/production yang dikonfigurasi.
