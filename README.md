# BINUSA SafeSpace - Aplikasi Bimbingan Konseling Mobile

Aplikasi mobile berbasis Flutter untuk sistem bimbingan konseling sekolah. Didesain untuk memudahkan komunikasi dan monitoring antara siswa, wali kelas, dan guru BK (Bimbingan Konseling).

## Fitur Utama

- **Multi-role**: Login sebagai Siswa, Wali Kelas, atau Admin BK
- **Konseling**: Siswa dapat mengajukan permohonan konseling dan chat dengan guru BK
- **Pelanggaran & Poin**: Input dan monitoring poin pelanggaran siswa
- **Surat Panggilan**: Pembuatan dan pengelolaan surat panggilan orang tua
- **Monitoring**: Wali kelas dapat memantau perkembangan siswa
- **Notifikasi**: Notifikasi real-time untuk pengajuan konseling dan pelanggaran
- **Laporan PDF**: Generate laporan dalam format PDF

## Tech Stack

- **Framework**: Flutter (Dart)
- **Backend**: Firebase (Auth, Firestore, Storage, Functions)
- **Platform**: Android, iOS, Web, Windows, Linux, macOS

## Cara Menjalankan

```bash
flutter pub get
flutter run
```

## Struktur Proyek

```
lib/
├── core/          # Tema, konstanta, utilitas
├── models/        # Model data
├── providers/     # State management
├── routes/        # Routing
├── screens/       # Halaman (admin, auth, student, teacher)
├── services/      # Layanan Firebase & lainnya
└── widgets/       # Widget reusable
```
