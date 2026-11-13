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

## Memperbarui pratinjau di Windows

Jika aplikasi masih berjalan di PowerShell, tekan `q` untuk menghentikannya, lalu:

```powershell
cd C:\Project\udl-assets
git pull origin main
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 8080
```

Gunakan alamat dan port yang sama agar data simulasi yang tersimpan di browser tetap terbaca. Jangan klik **Reset Data Demo** jika masih ingin menyimpan perubahan. Salin backup JSON melalui Pengaturan sebelum mengganti browser.

## Tampilan v0.2.0 (baseline)

- Workspace responsif rata atas dan memanfaatkan lebar area kerja, dengan header navy dan navigasi putih.
- KPI adaptif dengan nilai perolehan ringkas (misalnya Rp206,1 jt), grafik distribusi status, aktivitas dan kartu perhatian.
- Katalog berbentuk tabel di desktop serta kartu responsif di layar kecil, dengan pencarian dan filter terpadu.
- Form registrasi dan mutasi lebih lebar, dua kolom pada desktop, kelompok informasi, dan validasi.
- Detail aset, QR kode, log aktivitas, dan halaman pengaturan dirapikan.
- **Tidak ada migrasi data**: penyimpanan `SharedPreferences` dan struktur JSON dasar tetap dipakai.

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


## Pratinjau v0.3 — Klasifikasi & Foto Aset

- Taksonomi default **9 kategori** khusus aset fisik selain tanah dan bangunan.
- **Kategori → Subkategori → Jenis Aset**, dengan opsi penambahan master lokal.
- Form registrasi memakai pilihan bertingkat; kode permanen `UDL-AST-000001` tidak berubah.
- Daftar aset berbentuk tabel desktop dengan **thumbnail foto aktual per unit**, bukan foto generik produk.
- Halaman detail menyediakan **galeri foto aset**, foto utama, dan dokumentasi: foto utama, kondisi, label/nomor seri, kerusakan/perbaikan.
- Saat foto ditambahkan atau dijadikan utama, jejak aktivitas aset dicatat.
- Data v0.2 otomatis dibaca menggunakan key browser yang sama. Kategori lama dipetakan bila jelas; kategori lama `Tanah/Bangunan` tidak otomatis dihapus, melainkan ditandai untuk peninjauan.
- Master dan foto ikut masuk dalam backup JSON.

**Batasan foto prototipe lokal:** unggahan JPEG/PNG/WebP melalui file picker, gambar dikecilkan oleh image picker bila didukung browser, paling besar 500 KB per foto, delapan foto per aset, dan total data foto terenkode maksimal sekitar 2,9 MB. Browser bisa memiliki kuota lebih ketat. Ini hanya untuk demonstrasi; ketika tersambung ke backend, foto harus menggunakan object storage dan otorisasi akses. Jangan unggah aset/dokumen operasional sensitif ke prototipe.

**Catatan lingkup:** UDL Assets mengecualikan **tanah, bangunan, dan renovasi struktur bangunan**. AC, CCTV, peralatan IT, dan aset bergerak lain tetap dapat dicatat menurut kategori masing-masing. Keputusan kapitalisasi dan kelas aset akuntansi FA dikelola terpisah.

## Batasan MVP
Form belum mencakup dokumen serah terima, foto, persetujuan, stock opname, jadwal pemeliharaan, integrasi keuangan, atau backend multiuser. Fitur tersebut masuk tahap review lanjutan. Penghapusan berupa perubahan status sehingga kode dan riwayat tidak hilang. Contoh QR hanya memuat kode aset, bukan tautan detail yang diautentikasi.
