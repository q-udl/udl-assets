# RV030-08 — Konfirmasi Serah Terima dan Pembatalan Penugasan

**Tanggal keputusan:** 14 November 2026  
**Aplikasi:** UDL Assets (UD. LUTHFI)  
**Status:** Disetujui dan diimplementasikan di branch review `agent/udl-assets-v040-local-20261114`; **belum merge/deploy**.

## Latar belakang

Dalam Detail Penugasan sebelumnya terdapat **"Terima Penugasan"** dan **"Tolak Penugasan"**, memberi kesan bahwa karyawan penerima sedang memberikan persetujuan di portal. Padahal, aplikasi belum memiliki akun penerima maupun verifikasi tanda tangan elektronik. Fungsi sesungguhnya adalah catatan operasional oleh petugas GA.

## Keputusan nomenklatur final

| Sebelumnya | Sekarang |
| --- | --- |
| Menunggu Penerimaan | **Menunggu Serah Terima** |
| Terima Penugasan | **Konfirmasi Serah Terima** |
| Tolak Penugasan | **Batalkan Penugasan** |
| Ditolak | **Dibatalkan** |
| Alasan penolakan | **Alasan pembatalan** |

**Penting:** Perubahan nomenklatur berlaku **khusus Assigned Assets / penugasan aset**. Mutasi antar lokasi masih memiliki status terpisah seperti *Menunggu Penerimaan* dan *Ditolak*; jangan ubah alurnya tanpa review lain.

## Ketentuan transaksi

1. Membuat penugasan menetapkan status **Menunggu Serah Terima** dan mengunci aset dari penugasan lain, tetapi **belum** mengubah lokasi, pemegang aset, atau status menjadi Digunakan.
2. **Konfirmasi Serah Terima** oleh petugas mensyaratkan nama **Yang Menyerahkan** dan satu foto bukti aktual **per unit fisik**. Setelah lolos validasi, penugasan **Aktif**, aset **Digunakan**, pemegang aset ditautkan ke UUID karyawan, dan dokumen BAST memuat nama pihak dan lampiran foto.
3. **Batalkan Penugasan** sebelum serah terima mensyaratkan alasan wajib; saat dikonfirmasi, status penugasan dan setiap baris menjadi **Dibatalkan**, waktu pembatalan dicatat, log per aset ditulis sebagai **Pembatalan Penugasan**, dan reservasi aset dilepas. **Jangan** mengubah kode, UUID, lokasi, pemegang fisik, kondisi, atau membuat bukti penyerahan fiktif.
4. Penugasan yang sudah Aktif/Selesai tidak dapat dibatalkan melalui aksi ini. Gunakan alur **Pengembalian Aset** untuk aset yang sudah diserahterimakan.
5. Detail Penugasan menampilkan alasan dan waktu pembatalan. Tombol **Lihat/Cetak BAST** tidak ditampilkan untuk penugasan yang dibatalkan sebelum serah terima.
6. Pencatatan petugas tidak boleh diklaim sebagai tanda tangan digital maupun penerimaan terautentikasi oleh karyawan.

## Migrasi dan kompatibilitas

- Restore backup lama dengan `status: "Menunggu Penerimaan"` (pada record/barís penugasan) dinormalisasi menjadi `"Menunggu Serah Terima"`.
- Restore backup lama dengan `status: "Ditolak"` pada record/baris penugasan menjadi `"Dibatalkan"`.
- Field lama `rejectionReason` dibaca sebagai `cancellationReason` dalam model baru; penulisan backup baru menggunakan key baru.
- UUID aset/karyawan, referensi BAST, foto transaksi, dan relasi historis tidak diganti.
- Riwayat peristiwa lama tidak dipalsukan atau ditulis ulang. Data lama tanpa cap waktu pembatalan tidak diberi tanggal hasil perkiraan.
- Ketentuan migrasi penugasan **tidak diterapkan** ke catatan mutasi aset.

## RV030-07 — Penempatan aksi Scan QR Code

Keputusan UI terhubung: **Scan QR Code hanya tampil pada halaman Daftar Aset**, di kelompok tindakan bersama **Impor Data Aset** dan **Tambah Aset**, serta **hanya bila kamera perangkat terdeteksi**. Tidak ada tombol Scan QR pada breadcrumb/header global, Detail Penugasan, Master Klasifikasi, Master Lokasi, Master Karyawan, Riwayat, atau Pengaturan. Desktop tanpa kamera tidak menampilkan tombol. Pemindaian dan akses izin kamera hanya dimulai setelah petugas menekan tombol.

Keamanan QR (token acak, rotasi, pencabutan, keterbatasan verifikasi lokal, kebutuhan backend production) mengikuti [RV030-06-07-ASSET-IDENTITY-SECURE-QR.md](RV030-06-07-ASSET-IDENTITY-SECURE-QR.md).

## Tes penerimaan

- Pending → konfirmasi valid (foto + nama) → Aktif; konfirmasi kurang bukti/nama harus ditolak tanpa mutasi data.
- Pending → pembatalan tanpa alasan harus ditolak; dengan alasan → Dibatalkan, aset tersedia untuk draf baru, lokasi/UUID/kode tidak berubah.
- Pembatalan kedua kali atau pembatalan penugasan aktif ditolak.
- Backup baru dan legacy mempertahankan penugasan, alasan, foto dan relasi; transfer tetap tidak terpengaruh.
- Desktop dan mobile menampilkan label/tombol/warna status yang konsisten, tanpa label Terima/Tolak Penugasan.
- Scan QR tidak tampil di halaman master, riwayat, atau detail meski perangkat mempunyai kamera; tetap tidak tampil di Daftar Aset jika tidak ada kamera.
- `flutter analyze`, `flutter test`, `flutter build web --release`, dan artefak UAT Windows diuji pada workflow **PR #2** sebelum dianggap lulus QA.

**Aturan rilis:** hanya branch review, tidak merge atau deploy tanpa izin terpisah. Pemeriksaan manual UAT Windows/Android/iOS tetap diperlukan.
