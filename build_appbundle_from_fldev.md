# 📦 Panduan Build Flutter dengan Auto-Versioning

Proyek ini menggunakan script `build.sh` yang secara **otomatis menaikkan `versionCode`** setiap kali build, sehingga kamu tidak perlu mengubah `pubspec.yaml` secara manual sebelum upload ke Google Play Console.

---

## ✅ Prasyarat

Sebelum menggunakan script ini, pastikan:

1. **Flutter SDK** sudah terinstall dan tersedia di PATH
   ```bash
   flutter --version
   ```

2. **File `pubspec.yaml`** memiliki format versi seperti ini:
   ```yaml
   version: 1.0.2+15
   #         ─────┬── ──
   #         versionName  versionCode (angka setelah +)
   ```

3. **Script sudah dapat dieksekusi.** Jalankan sekali saja:
   ```bash
   chmod +x build.sh
   ```

---

## 🚀 Cara Pakai

### 1. Build App Bundle (untuk Google Play Store)
```bash
./build.sh
```
Ini akan:
- Menaikkan `versionCode` di `pubspec.yaml` (+1)
- Menjalankan `flutter build appbundle --release`
- Menghasilkan file `.aab` di:
  ```
  build/app/outputs/bundle/release/app-release.aab
  ```

---

### 2. Build APK (untuk distribusi langsung / testing)
```bash
./build.sh apk
```
Ini akan:
- Menaikkan `versionCode` di `pubspec.yaml` (+1)
- Menjalankan `flutter build apk --release`
- Menghasilkan file `.apk` di:
  ```
  build/app/outputs/flutter-apk/app-release.apk
  ```

---

### 3. Hanya Naikkan versionCode (tanpa build)
```bash
./build.sh --no-build
```
Berguna jika kamu ingin menaikkan versi dulu tanpa langsung build.

---

## 📁 Cara Menerapkan di Project Lain

Cukup **copy file `build.sh`** ke root folder project Flutter lain:

```bash
cp build.sh /path/ke/project-lain/build.sh
chmod +x /path/ke/project-lain/build.sh
```

Tidak perlu konfigurasi apapun — script otomatis membaca `pubspec.yaml` dari folder yang sama.

> **Syarat:** `pubspec.yaml` harus menggunakan format `version: X.Y.Z+N` (format standar Flutter).

---

## 🔍 Contoh Output

```
📦 Versi saat ini : 1.0.2+15
🔼 Versi baru      : 1.0.2+16

🔨 Membangun App Bundle...

✅ App Bundle selesai! (versi 1.0.2+16)
```

---

## ⚠️ Troubleshooting

### Error: `Unable to delete file at ios/Flutter/ephemeral/Packages/.packages`
Ini terjadi karena folder tersebut terkunci oleh proses sebelumnya. Jalankan:
```bash
chmod -R u+w ios/Flutter/ephemeral/Packages/.packages
rm -rf ios/Flutter/ephemeral/Packages/.packages
```
Lalu jalankan `./build.sh` kembali.

### Error: `permission denied: ./build.sh`
Script belum diberi izin eksekusi. Jalankan:
```bash
chmod +x build.sh
```

---

## 📝 Isi Script `build.sh`

```bash
#!/bin/bash
# Baca versi saat ini dari pubspec.yaml
CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
BUILD_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

# Naikkan versionCode +1
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
NEW_VERSION="$BUILD_NAME+$NEW_BUILD_NUMBER"

# Tulis versi baru ke pubspec.yaml
sed -i '' "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml

# Build sesuai argumen
if [ "$1" = "apk" ]; then
  flutter build apk --release
elif [ "$1" = "--no-build" ]; then
  echo "✅ versionCode dinaikkan. Build dilewati."
else
  flutter build appbundle --release
fi
```

---

*Dokumentasi ini dibuat untuk proyek **Dil-Alquran** dan dapat direplikasi ke project Flutter lainnya.*
