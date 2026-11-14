# UDL Assets — RV030-09/10/11: BAST Serah Terima

**Tanggal review:** 14 November 2026  
**Status:** Implementasi pada branch review `agent/udl-assets-v040-local-20261114`, belum merge/deploy.  
**Cakupan:** Dokumen **Berita Acara Serah Terima Aset (BAST)**. Dokumen **BA Pengembalian** masih memakai desainnya sendiri dan tidak disamakan secara diam-diam.

## 1. Keputusan RV030-09: BAST hanya setelah serah terima

- Saat `Menunggu Serah Terima` atau `Dibatalkan`, **tombol Lihat/Cetak BAST tidak ditampilkan**.
- Saat `Aktif` atau `Selesai`, BAST dapat dicetak **hanya** jika tanggal konfirmasi serah terima, nama Penyerah, lokasi serah terima aktual, dan Nomor BAST telah tercatat.
- API generator PDF juga **menolak** pembuatan BAST untuk transaksi belum dikonfirmasi atau metadata belum lengkap. Penyembunyian tombol bukan satu-satunya pengaman.
- Setelah seluruh aset dikembalikan, BAST tetap tersedia sebagai bagian dari sejarah penugasan.
- Tidak ada dokumen BAST fiktif untuk penugasan yang dibatalkan.

## 2. Keputusan RV030-10: Label pihak dan ruang tanda tangan

- Di BAST, ganti label `Yang Menyerahkan` dan `Yang Menerima` menjadi **Penyerah** dan **Penerima**.
- Nama Penyerah/Penerima tampil dari snapshot catatan transaksi; informasi jabatan/unit Penyerah **opsional**, bukan diisi otomatis berdasarkan asumsi.
- Sediakan ruang kosong untuk para pihak menandatangani dokumen, **tanpa** teks atau garis `Tanda tangan: _________`.
- Tidak menampilkan klaim bahwa tanda tangan telah dilaksanakan/terverifikasi secara otomatis.

## 3. Keputusan RV030-11: Substansi dokumen BAST

### Header
- `UD. LUTHFI`.
- `BERITA ACARA SERAH TERIMA ASET`.
- **Nomor BAST** (terpisah dari referensi penugasan).
- **Referensi Penugasan** (misalnya `ASG-000002`).
- Tanpa label merah **DRAF**, `Referensi lokal`, maupun placeholder `Nomor dokumen resmi: _____`.

### Informasi transaksi
- **Tanggal Serah Terima:** timestamp **konfirmasi fisik** (`acceptedAt`), bukan tanggal pembuatan penugasan.
- **Lokasi Serah Terima:** input aktual petugas pada saat konfirmasi.
- Jenis Penugasan, Batas Pengembalian, dan Catatan jika relevan.
- **Penyerah** (nama, jabatan/unit bila diketahui) dan **Penerima** (nama, jabatan, unit/departemen, lokasi kerja) ditampilkan berdampingan, tanpa judul bagian `PARA PIHAK` (revisi RV030-12).

### Rincian dan pernyataan
- Daftar unit aset: nomor, kode aset, nama, nomor seri, dan kondisi. Kolom `Kelengkapan` dihapus berdasarkan RV030-12; Item Penyerta Non-Aset (jika dicatat) tampil sebagai catatan terpisah di bawah tabel, sementara data kelengkapan historis tidak diubah klasifikasinya.
- Narasi faktual bahwa aset telah diserahterimakan menurut konfirmasi operator.
- Tanggung jawab penerima untuk penggunaan, penjagaan, pemeliharaan, dan pengembalian aset sesuai ketentuan perusahaan.
- Dokumen disediakan agar ditandatangani Penyerah dan Penerima secara terpisah; sistem **tidak** mengesahkan tanda tangan.
- Hapus `Status sistem` dari PDF.

### Foto bukti
- Gunakan foto **transaksi** (`assignment_handover`), bukan foto katalog.
- Lampiran foto dimulai pada halaman terpisah; tampilkan nama dan kode unit, waktu, bukti file.
- Tidak ada lampiran kosong bila tidak ada foto pada transaksi historis; untuk konfirmasi baru, satu foto per unit wajib.
- Penomoran halaman, PDF A4, dan pemeriksaan render termasuk gate CI.

## 4. Referensi internal versus nomor resmi DMS

**Referensi penugasan** diterbitkan oleh UDL Assets secara berurutan, dalam format `ASG-000001`, bukan kode resmi dokumen perusahaan. Backup historis yang menyimpan `DRAF-BAST-ASG-000001` tetap dipertahankan, namun antarmuka dan PDF menampilkan `ASG-000001`.

**Nomor BAST resmi** bukan ditebak dari referensi penugasan. Pada implementasi lokal ini, petugas memasukkan nomor yang diperoleh dari sistem/ketentuan DMS, baik saat konfirmasi maupun setelahnya. **Serah terima fisik tidak ditunda jika nomor DMS belum tersedia**, tetapi tombol Lihat/Cetak BAST baru muncul ketika nomornya sudah lengkap. Sistem mengecek tidak kosong dan tidak duplikat dalam data lokal (case-insensitive). **Belum** ada integrasi langsung ke DMS atau penjaminan penerbitan nomor unik lintas browser/perangkat; server production harus menjadi sumber otoritatif untuk integrasi/registrasi nomor.

Untuk penugasan yang baru saja dikonfirmasi tanpa nomor DMS, atau data lama yang sudah Aktif/Selesai dan memiliki waktu konfirmasi, aplikasi menyediakan **Lengkapi Data BAST**; pengisian metadata lama dicatat di riwayat, tidak menimpa data yang sudah terisi dan **tidak mengubah waktu konfirmasi historis**. Data lama tanpa bukti waktu konfirmasi tidak diperlakukan otomatis sebagai sudah diserahterimakan.

## 5. Pengujian minimum

1. Pending/Cancelled: aksi cetak tidak ada; pemanggilan generator langsung menghasilkan `FormatException`.
2. Aktif/Selesai: aksi cetak muncul hanya dengan metadata lengkap.
3. Nomor BAST wajib dan unik; kegagalan validasi tidak mengubah status, bukti atau aset.
4. Backup lama dan baru dapat dibaca tanpa mengganti UUID, kode aset atau relasi historis.
5. Output PDF memuat nomor, referensi, tanggal konfirmasi, lokasi, para pihak, rincian, pernyataan dan nama pada area tanda tangan; tidak memuat DRAF, status sistem, atau garis tanda tangan.
6. BAST dan lampiran foto dirender dengan Poppler di GitHub Actions, termasuk skenario multi-aset dan pengembalian sebagian.
7. Build Flutter Web, tes, dan paket UAT lokal Windows **PASS** sebelum dinyatakan siap review pengguna.

**Batas rilis:** tidak merge/deploy tanpa persetujuan terpisah. UAT fisik printer, browser, dan perangkat masih perlu verifikasi manual.
