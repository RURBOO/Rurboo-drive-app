# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase App Check
-keep class com.google.firebase.appcheck.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.maps.android.** { *; }

# Razorpay
-keepattributes *Annotation*
-keep class com.razorpay.** { *; }
-keep @interface proguard.annotation.Keep
-keep @proguard.annotation.Keep class * {*;}
-dontwarn com.razorpay.**

# Keep model classes for Firestore serialization
-keepattributes Signature
-keep class com.rurboo.driver.** { *; }

# OkHttp (used by Firebase/http)
-dontwarn okhttp3.**
-dontwarn okio.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**

# Flutter Play Core (referenced by Flutter embedder, not used in project)
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn com.google.android.play.core.**

