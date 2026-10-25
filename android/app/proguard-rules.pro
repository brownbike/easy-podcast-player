# audio_service — uses reflection to locate the AudioService class
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.bgaudioservice.** { *; }

# background_downloader — WorkManager tasks loaded by class name
-keep class com.bbflight.background_downloader.** { *; }

# WorkManager — Room finds WorkDatabase_Impl at runtime via Class.forName using
# the canonical name of WorkDatabase. R8 must not rename or strip any of these.
-keep class androidx.work.** { *; }

# Flutter — keep the embedding classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Play Store split-APK classes are not present in a standard APK build;
# suppress the R8 missing-class warning.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.**
