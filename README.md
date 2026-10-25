# Naracodex

Fondasi game tactical RPG turn-based 2D untuk Android menggunakan Godot 4.3+, bukan WebView.

## Prototype saat ini
- Arena grid isometrik 8×6.
- Dua unit pemain dan dua musuh.
- Pilih unit pemain lalu tap petak untuk bergerak.
- Tekan `M` untuk mengganti mode gerak/serang.
- Dalam mode serang, pilih musuh yang bersebelahan.
- Tekan `E` untuk mengakhiri giliran; musuh akan bergerak atau menyerang.
- Kondisi menang/kalah dasar.

## Menjalankan
Buka folder proyek ini di Godot 4.3 atau lebih baru, lalu tekan Play.

## Catatan
Token unit masih berupa bentuk placeholder, belum memakai sprite final. Fondasi ini belum menyertakan ekspor APK; konfigurasi Android export Godot dan Android SDK/JDK perlu disiapkan di CI setelah proyek diunggah ke GitHub.
