# Flutter & AndroidX keep rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# WorkManager & Room keep rules (used by Google Mobile Ads SDK & background sync)
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.impl.WorkDatabase { *; }
-keep class * extends androidx.work.InputMerger { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class * extends androidx.room.RoomOpenHelper$Delegate { *; }
-keepclassmembers class * extends androidx.room.RoomDatabase {
    <init>();
}
-dontwarn androidx.work.**
-dontwarn androidx.room.**

# Google Mobile Ads (AdMob) keep rules
-keep class com.google.android.gms.ads.** { *; }
-keep interface com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Play Core (deferred components not used)
-dontwarn com.google.android.play.core.**
