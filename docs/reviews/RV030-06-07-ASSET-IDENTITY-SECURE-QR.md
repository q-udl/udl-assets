# UDL Assets — Keputusan RV030-06 & RV030-07
## Identitas Kode Aset 8 Digit dan Secure QR

**Proyek:** UDL Assets — UD. LUTHFI  
**Tanggal keputusan:** 14 November 2026  
**Status:** Keputusan review disetujui; **BELUM DIIMPLEMENTASIKAN**  
**Referensi:** PR #2 (draft), branch review `agent/udl-assets-v040-local-20261114`  
**Kendali perubahan:** Dokumen ini adalah pengingat/spesifikasi review. Penulisan dokumen tidak mengizinkan implementasi fitur, merge, deploy, atau perubahan data operasional. Tunggu perintah eksplisit **GAS RV030**.

> **PENTING UNTUK IMPLEMENTOR BERIKUTNYA**  
> Jangan mengasumsikan isi dokumen ini telah diterapkan pada source, backup, PDF, maupun label QR. Lakukan audit HEAD dan migrasi kompatibel sebelum implementasi. Jangan mengklaim Secure QR lokal sebagai verifikasi aman production.

---

## 1. RV030-06 — Keputusan final: kode aset global minimal 8 digit

**Keputusan pengguna: kode aset baru menggunakan minimal DELAPAN digit.**

- Pola kode: `UDL-AST-00000001`, `UDL-AST-00000002`, dan seterusnya.
- Nomor berurutan **global untuk perusahaan**, tidak diulang berdasarkan kategori, subkategori, jenis aset, unit organisasi, lokasi, maupun tahun.
- Setiap **unit fisik** mendapat satu kode unik. Contoh: 5 mouse Logitech M170 identik = 5 kode aset berbeda.
- Kode bersifat **permanen dan tidak digunakan ulang**, bahkan jika aset berpindah unit, direklasifikasi, dikembalikan, dilepas, atau diarsipkan.
- Kategori/subkategori/jenis adalah atribut master terpisah. Jangan menyisipkan nomor klasifikasi ke kode aset fisik.
- UUID internal aset tetap menjadi primary identifier/foreign key; kode aset adalah identitas bisnis yang dapat dibaca manusia; nomor seri produsen tetap terpisah.
- Delapan digit adalah **lebar minimum**, bukan batas maksimal: setelah `UDL-AST-99999999`, nomor selanjutnya tetap dapat bertambah digit; tidak boleh wrap atau truncate.

### Kompatibilitas dan migrasi yang wajib

1. **Pertahankan kode aset historis** seperti `UDL-AST-000001`; jangan mengganti kode maupun label aset yang sudah diterbitkan secara diam-diam.
2. Setelah implementasi, semua registrasi baru menggunakan minimum 8 digit, sementara validasi baca/impor/restore tetap menerima kode historis minimum 6 digit.
3. Nomor urut baru harus meneruskan nomor terbesar yang sudah dicadangkan/diterbitkan, termasuk metadata `nextNumber`; pastikan tidak ada duplikasi, termasuk pada pemulihan backup.
4. Pembaruan model, generator registrasi tunggal maupun massal, template impor Excel, tampilan, filter, riwayat, snapshot transaksi, BAST/BA pengembalian, PDF, backup, restore dan tes harus kompatibel.
5. Di masa production, **global** memerlukan penerbitan nomor secara **terpusat dan atomik** di backend agar dua pengguna/perangkat tidak menerima nomor sama; penyimpanan browser UAT saat ini tidak dapat menjamin unik lintas perangkat atau profil.
6. QR harus menunjuk UUID/internal asset reference melalui pemetaan token, bukan melalui pemecahan angka kode.

### Tes penerimaan RV030-06

- Registrasi satu unit/massal menghasilkan kode 8 digit berurutan dan unik.
- Kode tidak berubah ketika kategori, jenis, lokasi, PIC, atau lifecycle berubah.
- 5 unit barang model sama menghasilkan 5 kode/riwayat berbeda.
- Data lama enam digit terbaca, dapat dicari, dan dapat dicetak ulang tanpa perubahan identitas.
- Backup lama dapat dipulihkan; nomor berikutnya aman dan tidak menduplikasi kode.
- Kasus nomor mendekati 99.999.999 dan sesudahnya tidak menyebabkan overflow, truncation, atau benturan.

---

## 2. RV030-07 — Keputusan: Secure QR token acak, diterapkan bertahap

**Keputusan pengguna: mengikuti rekomendasi Secure QR berbasis token acak + verifikasi sistem.**

### Prinsip arsitektur

- Label fisik **boleh menampilkan Kode Aset sebagai teks manusia**, misalnya `UDL-AST-00000001`.
- Isi QR **tidak boleh langsung berupa kode aset atau angka urut yang dapat ditebak**.
- Terbitkan token acak menggunakan **cryptographically secure random number generator (CSPRNG)**; rekomendasi panjang token **32 byte (256 bit)** yang di-encode URL-safe.
- Token adalah **identitas verifikasi yang terpisah**, dengan pemetaan satu token aktif ke satu UUID aset. Penggantian atau pencabutan token **tidak mengubah Kode Aset, UUID, atau riwayat**.
- Token **bukan enkripsi** dan bukan bukti keaslian stiker fisik. QR statis yang valid tetap dapat difotokopi/diduplikasi.
- QR tidak boleh membuka data karyawan, pemegang aset, lokasi internal sensitif, atau data lain tanpa autentikasi dan otorisasi.

### Ketersediaan tombol "Scan QR Code" — keputusan final 14 November 2026

**Tombol/menu/aksi "Scan QR Code" hanya ditampilkan bila perangkat memiliki kamera yang terdeteksi dan lingkungan aplikasi mendukung pemindaian kamera. Aturan berlaku sama untuk desktop, laptop, tablet, dan mobile.**

| Perangkat / keadaan | Perilaku |
|---|---|
| Desktop/laptop tanpa kamera | **Scan QR Code tidak ditampilkan sama sekali**, bukan tombol disabled |
| Desktop/laptop dengan webcam yang terdeteksi dan didukung | Scan QR Code ditampilkan |
| HP/tablet dengan kamera yang terdeteksi dan didukung | Scan QR Code ditampilkan |
| HP/tablet tanpa kamera atau fungsi kamera tidak tersedia | Scan QR Code disembunyikan |
| Pendeteksian masih berlangsung | Jangan tampilkan tombol sebelum kemampuan perangkat dipastikan |
| Kamera terdeteksi tetapi akses ditolak pengguna | Tampilkan penjelasan izin/kegagalan saat scan dimulai; jangan menyimpulkan perangkat tidak memiliki kamera |

**Ketentuan implementasi yang wajib diingat:**

1. Deteksi kemampuan aktual perangkat, **bukan hanya** user-agent, lebar layar, atau asumsi "mobile pasti ada kamera".
2. Pada Flutter Web, cek dukungan API kamera dan keberadaan input video (misalnya `navigator.mediaDevices.enumerateDevices()` dan perangkat `videoinput`), dengan penanganan bila browser menutupi informasi akibat kebijakan izin/privasi. Jangan menganggap deteksi yang tidak pasti otomatis berarti ada kamera.
3. **Tidak boleh meminta izin atau mengaktifkan kamera saat halaman baru dibuka.** Permission dan stream kamera hanya diminta setelah pengguna menekan aksi scan yang tersedia.
4. Jika terdeteksi tidak ada kamera, hilangkan aksi scan dari menu, toolbar, atau lokasi lain tanpa menyisakan ruang kosong. Pengaturan ini juga berlaku saat kamera dilepas/disambungkan atau halaman dibuka ulang; lakukan pemeriksaan ulang yang sesuai.
5. Saat pemindaian dimulai, tampilkan preview kamera, petunjuk arahkan kamera ke QR, dan kontrol tutup/batal yang jelas; berhenti dan lepas stream kamera setelah selesai, dibatalkan, atau halaman ditinggalkan.
6. Jika izin kamera ditolak, perangkat sedang digunakan aplikasi lain, atau kamera gagal saat scan, tampilkan pesan yang jelas dan opsi mencoba lagi tanpa merusak navigasi.
7. **Bedakan "Scan QR Code" dari "Lihat/Cetak QR Code"**: melihat/mencetak label QR tidak memerlukan kamera dan tetap dapat tersedia di desktop tanpa webcam.
8. Jangan otomatis mengganti "Scan QR Code" dengan unggah gambar QR pada perangkat tanpa kamera. Kebijakan pemilihan foto katalog/bukti yang sudah ada pada RV027–RV029 adalah fitur terpisah, jangan diubah oleh keputusan ini.

**Tes wajib:** desktop dengan webcam, desktop tanpa webcam, webcam dilepas/ditambahkan, Android Chrome, iPhone Safari, mobile tanpa kamera/emulator, izin belum diminta/ditolak, browser tanpa dukungan API, kondisi deteksi tidak pasti, serta pembersihan stream ketika dialog ditutup. Verifikasi tombol benar-benar **tidak dirender** pada perangkat tanpa kamera, bukan hanya dalam kondisi disabled.

---

### Tahap A — UAT lokal (implementasi hanya setelah GAS RV030)

Tujuan: memverifikasi alur UI/data dan hubungan token–aset, **bukan** mengklaim keamanan verifikasi lintas perangkat.

1. Buat dan simpan identitas token QR terpisah dari `AssetRecord.code`; kaitkan ke UUID aset dan status token.
2. Alur pemindaian internal mengidentifikasi token yang terdaftar; token tak dikenal, tidak aktif, atau dicabut harus ditolak.
3. Dukung penerbitan ulang/rotasi token dan pembaruan QR label; token lama ditolak setelah dicabut.
4. Gunakan sumber acak kriptografis yang tersedia di platform web dan tes untuk memastikan token tidak menurunkan keamanan menjadi pola berurutan.
5. Karena belum ada domain/backend verifikasi, boleh gunakan payload token non-URL yang hanya dimengerti pemindai di aplikasi lokal. **Jangan mengarang URL production** atau menjanjikan pemindaian lewat kamera umum dapat membuka aset.
6. Perlakukan penyimpanan browser sebagai fixture terisolasi: dapat hilang, disalin, dimodifikasi, dan tidak dapat menjadi otoritas verifikasi antarpengguna.
7. Jangan menanam secret key atau kunci tanda tangan production di Flutter Web.
8. Jika perlu menguji data lama, sediakan skenario QR legacy untuk migrasi; QR yang langsung berisi kode aset **tidak diberi status "aman/terverifikasi"** secara otomatis.

### Tahap B — Production (wajib sebelum verifikasi QR dinyatakan aman)

1. Sediakan endpoint verifikasi backend melalui HTTPS dan domain perusahaan yang **benar-benar telah dikonfigurasi**.
2. Terbitkan token secara server-side; simpan **hash token** (bukan plaintext) di backend untuk pencocokan, beserta UUID aset, status, tanggal dibuat/dicabut, dan versi token.
3. Gunakan autentikasi/otorisasi berbasis peran untuk membuka data internal atau memproses transaksi; mengetahui token saja tidak memberikan hak operasi.
4. Pencabutan dan rotasi token harus menonaktifkan token lama, memerlukan penerbitan label pengganti, dan memiliki audit trail.
5. Terapkan rate limiting, penanganan token tidak valid dengan respons aman, proteksi terhadap pembocoran token di log/analytics/referrer, dan monitoring penyalahgunaan.
6. Saat URL verifikasi resmi tersedia, format konseptual `https://<domain-terkonfigurasi>/q/<token>`; **ini placeholder, bukan URL deployment saat ini**.
7. Perlindungan fisik tambahan (misalnya stiker tamper-evident) disarankan. Aset berisiko tinggi dapat dipertimbangkan memakai NFC dengan autentikasi kriptografis.

### Tes penerimaan RV030-07

- Token tidak mengandung atau mengungkap pola Kode Aset.
- QR valid mengarah ke UUID aset yang tepat; token palsu, dicabut, dan kedaluwarsa (jika kebijakan expiry diterapkan) ditolak.
- Reklasifikasi/pindah lokasi tidak mengubah identitas aset atau merusak kaitan QR.
- Rotasi memutus token lama, tanpa menghapus riwayat atau mengganti Kode Aset.
- Ekspor, backup, restore, reprint label, dan pemindaian diuji terpisah untuk UAT dan production.
- Tidak ada klaim keamanan production hanya berdasarkan lolos tes lokal.
- Pada production, verifikasi endpoint, hak akses, audit, rate limiting, dan kebocoran token harus diuji.

---

## 3. Temuan baseline yang menjelaskan pekerjaan belum selesai

Pada baseline sebelum RV030:
- Generator kode aset masih menggunakan `padLeft(6, '0')` (setidaknya di `lib/asset_data.dart` dan `lib/asset_operations.dart`).
- QR masih menggunakan `QrImageView(data: a.code)` di `lib/asset_v4_detail.dart`.
- Pemulihan backup masih memvalidasi format aset lama minimum enam digit. Kompatibilitas ini perlu dijaga.
- Aplikasi masih berjalan dalam pola penyimpanan per-browser, tanpa backend otoritatif.

**Artinya: keputusan sudah final secara desain, tetapi belum berlaku sebagai fungsi aplikasi.**

---

## 4. Dependensi review RV030 lain yang tidak boleh rusak

- **RV030-03:** Hapus Kode Karyawan dari antarmuka/model aktif; relasi karyawan tetap menggunakan UUID internal, migrasi backup historis aman.
- **RV030-02:** Catat snapshot nama pihak menyerahkan/menerima; nama otomatis muncul pada blok tanda tangan BAST/BA pengembalian, tanpa klaim tanda tangan sudah dilakukan.
- **RV030 PDF-01:** Lampiran foto bukti transaksi terpisah dan tidak terpotong; jangan mengambil foto katalog sebagai foto bukti.
- **RV030-05:** Modernisasi UI/UX konsisten untuk semua halaman operasional kecuali Pengaturan.
- **Production-like UAT:** hilangkan bahasa demo dari pengalaman operasional tetapi jangan menyamarkan keterbatasan autentikasi atau keamanan.

Keputusan detail UI/UX yang belum disetujui tetap berstatus review, **tidak otomatis menjadi spesifikasi final karena adanya dokumen ini**.

---

## 5. Batas kewenangan dan langkah selanjutnya

- Dokumen ini boleh ditambahkan sebagai **commit dokumentasi saja di branch review**.
- **BELUM ADA IMPLEMENTASI RV030**; tidak ada perubahan kode, model, tes, migrasi, build, maupun dataset sebagai bagian dari pencatatan keputusan ini.
- **JANGAN** melakukan merge, deploy UAT/PROD, reset browser storage, atau mengubah data operasional.
- Ketika pengguna memberi perintah **GAS RV030**, implementor harus membaca dokumen ini, memverifikasi source HEAD terbaru, membuat rencana migrasi, mengimplementasikan dan menjalankan test/QA lengkap.
- Setelah fitur selesai, perbarui dokumen ini dengan versi, commit, tanggal implementasi, hasil pengujian, dan status production sebenarnya.
