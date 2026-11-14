# UDL Assets — RV030-12: Aset vs Item Penyerta Non-Aset

**Tanggal keputusan:** 15 November 2026  
**Status:** Disetujui pengguna dan diimplementasikan pada branch review `agent/udl-assets-v040-local-20261114`. **Belum merge/deploy.**  
**Dependensi:** RV030-09/10/11 BAST pascaserah-terima, RV030-06 kode aset per unit, serta RV030-07 QR token per aset.

## Keputusan utama

1. **Kelengkapan dihapus dari kolom tabel utama BAST.** Tabel menampilkan aset terdaftar dengan identitas/kondisi masing-masing, bukan daftar aksesoris yang status pengendaliannya tidak jelas.
2. **Charger, adaptor, case HP, dan barang lain dapat didaftarkan sebagai aset tersendiri** apabila perlu dilacak/ditugaskan/dikembalikan secara independen. Setiap unit aset fisik mempunyai UUID, Kode Aset, riwayat dan QR sendiri. Jenis barang maupun harga saja tidak otomatis menentukan apakah ia aset.
3. **Item Penyerta Non-Aset bersifat opsional** dan tidak menghasilkan Kode Aset, stok ataupun QR. Ini adalah catatan teks terikat ke baris penugasan aset terkait, bukan registrasi mandiri. Contohnya buku panduan atau kemasan.
4. Pencatatan item penyerta dapat dilanjutkan ketika pengembalian aset, termasuk pengembalian parsial. Catatan saat penyerahan dan catatan saat pengembalian tetap disimpan **secara terpisah**.
5. **Data historis tidak ditulis ulang atau diasumsikan berubah klasifikasi.** Field lama bernama `accessories`/`accessoriesReturned` dipertahankan untuk kompatibilitas. Catatan backup historis tanpa penanda klasifikasi ditampilkan sebagai **Kelengkapan historis (belum diverifikasi)**, bukan langsung dinyatakan sebagai non-aset.

## Realisasi aplikasi

- **Registrasi Aset:** panduan bahwa barang yang dikendalikan sendiri perlu registrasi dan kode aset per unit, sedangkan item non-aset dicatat pada penugasan.
- **Tugaskan Aset:** semua aset berkode dipilih sebagai baris penugasan tersendiri; input opsional menjadi **Item Penyerta Non-Aset** per aset dengan penjelasan tidak melacak barang berkode.
- **Detail Penugasan / Detail Karyawan:** tampilkan catatan penyerta hanya bila terisi dan beri label berbeda untuk data lama yang belum diverifikasi.
- **Pengembalian Aset:** petugas melihat catatan item saat penyerahan, mencatat item yang benar-benar kembali secara opsional, dan melihat hasilnya pada langkah tinjau.
- **BAST:** tabel aset tidak mempunyai kolom Kelengkapan. Bila ada item penyerta, tampilkan **CATATAN ITEM PENYERTA (OPSIONAL)** di bawah tabel beserta kode aset induk dan deskripsi, bukan di dalam tabel. Untuk data historis, gunakan label `Kelengkapan arsip (belum diklasifikasikan)`.
- **BA Pengembalian:** tabel pemeriksaan juga tidak mempunyai kolom Kelengkapan. Catatan item saat penyerahan dan saat kembali ditampilkan terpisah dari tabel apabila tersedia. Isian kosong ditulis **Tidak dicatat**, **bukan** dinyatakan hilang secara otomatis.
- **Model/backup:** `AssignedAssetLine.accessoriesClassification` dan `AssetReturnLine.accessoriesClassification` menyimpan `non_asset` untuk data baru. Pada backup lama yang belum memiliki key tersebut, `fromJson` memberi `legacy_unclassified`, dengan teks lama dipertahankan. Tidak ada migrasi destruktif atau perubahan UUID/Kode Aset.

## Keputusan tata letak BAST terkait

**Hapus judul `PARA PIHAK`** pada bagian identitas BAST. Subjudul **Penyerah** dan **Penerima** tetap tampil berdampingan tepat setelah informasi waktu/lokasi. Judul **RINCIAN ASET** serta **PERNYATAAN SERAH TERIMA** dipertahankan. Blok tanda tangan tidak berubah.

## Syarat pengujian dan keamanan data

- Satu model fisik dengan beberapa unit terdaftar tetap mempunyai kode aset masing-masing. Item Penyerta Non-Aset tidak menambah unit atau kode.
- Penugasan dengan dan tanpa item penyerta; catatan historis yang tidak memiliki klasifikasi; backup, restore, dan ekspor ulang seluruhnya harus lolos.
- Pengembalian sebagian hanya memengaruhi aset yang dipilih; input item yang kembali dicatat terpisah dan tidak menimpa item saat penyerahan.
- PDF satu aset, delapan aset, dan pengembalian sebagian dirender serta diperiksa pada CI. Dokumen tidak boleh memuat judul `PARA PIHAK` atau kolom utama `Kelengkapan`, dan catatan item hanya muncul jika memang ada data.
- Jangan menyatakan item lama sebagai barang non-aset tanpa verifikasi manual.
- Perubahan tetap di **PR #2 (Draft)**; tidak merge/deploy atau menghapus data operasional tanpa izin baru.

## Catatan lingkup

Pada tahap ini, Item Penyerta Non-Aset masih berupa **teks bebas opsional** terkait baris penugasan, **bukan modul inventaris baru**. Jika perusahaan ingin melacak pergerakan, nilai, kehilangan, atau tanggung jawab masing-masing penyerta, daftarkan sebagai aset tersendiri. Pengembangan struktur item penyerta menjadi daftar tersendiri memerlukan review baru sebelum implementasi.
