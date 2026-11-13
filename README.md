# UD. LUTHFI — Manajemen Aset

Aplikasi manajemen aset berbasis **Flutter**, dengan fokus awal pada **Flutter Web yang dijalankan lokal**. Repositori ini untuk prototipe/review internal, **bukan** sistem produksi.

## Menjalankan lokal

Prasyarat: Flutter SDK (stable), Dart (dibundel), Chrome/Edge.

```powershell
git clone https://github.com/q-udl/udl-assets.git
cd udl-assets
flutter create . --platforms web
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 8080
```

Buka http://localhost:8080. Jika Chrome tidak terdeteksi, jalankan `flutter devices` dan pilih web device yang tersedia.

## Cakupan prototipe
- Ringkasan, katalog/master aset, pencarian dan filter
- Registrasi aset dengan kode unik permanen `UDL-AST-000001`
- Detail dan QR label (QR berisi kode aset, belum URL sistem produksi)
- Pembaruan penanggung jawab, mutasi lokasi, status dan penghapusan logis
- Riwayat perubahan yang tidak ditimpa, kategori dan lokasi sebagai atribut
- Data contoh untuk UAT lokal, penyimpanan **per-browser** lewat SharedPreferences
- Salin/impor backup JSON manual

**Peringatan:** data tersimpan hanya di browser/perangkat yang digunakan. Bukan untuk data riil, tidak memiliki autentikasi, server, atau sinkronisasi antar-perangkat. Hapus data browser dapat menghapus data aplikasi. Tinjau UI/UX dan proses bisnis dulu sebelum mengintegrasikan backend produksi.

## Prinsip desain
Identitas `AssetUUID` internal terpisah dari kode `UDL-AST-NNNNNN`, yang tidak berubah walaupun lokasi/penanggung jawab berubah. Semua transaksi operasional menghasilkan catatan riwayat. Aset yang dikeluarkan dari penggunaan diberi status `Dihapuskan`, bukan dihapus permanen.

Lihat kode sumber dalam `lib/`. Tidak ada deployment UAT/production yang dikonfigurasi.

## Pemeriksaan kualitas
Jalankan `flutter analyze`, `flutter test`, dan `flutter build web --release`.
Workflow GitHub Actions di `.github/workflows/flutter-ci.yml` menjalankan ketiganya pada setiap push ke `main` dan pull request. **Pengujian belum diklaim PASS sebelum workflow selesai.**

## Batasan MVP
Form belum mencakup dokumen serah terima, foto, persetujuan, stock opname, jadwal pemeliharaan, integrasi keuangan, atau backend multiuser. Fitur tersebut masuk tahap review lanjutan. Penghapusan berupa perubahan status sehingga kode dan riwayat tidak hilang. Contoh QR hanya memuat kode aset, bukan tautan detail yang diautentikasi.
