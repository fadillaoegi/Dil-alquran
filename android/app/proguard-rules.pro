# =============================================================================
# flutter_local_notifications
# -----------------------------------------------------------------------------
# Plugin menyimpan detail notifikasi terjadwal sebagai JSON (Gson) lalu
# membacanya kembali di ScheduledNotificationReceiver saat alarm berbunyi.
# Bila R8 mengobfuscate/menghapus kelas model tersebut, deserialisasi GAGAL
# SENYAP -> notifikasi terjadwal (pengingat shalat) tidak pernah muncul pada
# build release, meski normal di debug. Aturan di bawah mencegahnya.
# =============================================================================
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.styleinformation.** { *; }

# Receiver yang dipicu AlarmManager & saat perangkat menyala ulang.
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver { *; }

# =============================================================================
# Gson — dibutuhkan plugin di atas untuk serialisasi model notifikasi.
# =============================================================================
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-dontwarn sun.misc.**

-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Field yang diserialisasi Gson tidak boleh dihapus/di-rename.
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Tipe generik yang dipakai Gson lewat TypeToken.
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# =============================================================================
# Umum
# =============================================================================
# Kelas yang dirujuk lewat refleksi dari Flutter engine.
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
