# Paket UAT Windows Satu Klik - UDL Assets RV030

**Mode:** UAT lokal, tanpa deploy atau koneksi production.

1. Buka PR #2 -> **Checks** -> workflow Flutter Web checks yang PASS -> **Artifacts**.
2. Unduh `udl-assets-uat-windows-rv030` lalu ekstrak ZIP utuh ke folder tersendiri di Windows.
3. Jalankan `JALANKAN-UDL-ASSETS.cmd` (double-click). Chrome/Edge dan server lokal akan terbuka.
4. Browser menggunakan profil terpisah di `%LOCALAPPDATA%\UDLAssets\RV030-UAT\BrowserProfile`. Profil browser utama tidak disentuh.
5. Hentikan server dengan menutup konsol atau Ctrl+C. Saat menjalankan ulang, data UAT dalam profil khusus tetap tersedia kecuali dibersihkan secara eksplisit.

**Keterbatasan:** Data browser hanya tersimpan pada perangkat/profil ini dan **belum memiliki autentikasi, sinkronisasi server, ataupun verifikasi QR production**. Jangan memasukkan data operasional nyata. Untuk tes kamera, izinkan akses saat menekan tombol Scan atau Ambil Foto; browser tidak meminta izin otomatis saat halaman dibuka.

**Jika tidak membuka:** cek bahwa `web/index.html` ada berdampingan dengan `start-uat.ps1`, port 8765 belum dipakai, dan Chrome/Edge tersedia. File hasil CI adalah build Flutter Web statis, bukan sumber Flutter SDK. Tidak memerlukan Flutter SDK untuk menjalankan UAT ini.

**Keamanan Windows:** `JALANKAN-UDL-ASSETS.cmd` memanggil PowerShell hanya untuk server localhost. Periksa isi skrip sebelum menjalankan. Jangan membagikan folder profil browser atau backup UAT yang memuat data.
