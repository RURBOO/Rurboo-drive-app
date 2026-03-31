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

# Firebase Messaging (explicit — background handler must not be stripped)
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.messaging.FirebaseMessagingService { *; }

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

# Flutter Play Core
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn com.google.android.play.core.**

# -------------------------------------------------------
# flutter_local_notifications
# Release build mein R8 in classes ko strip kar deta hai
# jisse notifications silently fail ho jaati hain
# -------------------------------------------------------
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# Keep R resource IDs — alert_sound aur drawable references
# string-based hain, R8 inhe statically trace nahi kar sakta
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Flutter background isolate entry points
-keepattributes InnerClasses
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keep class io.flutter.view.FlutterMain { *; }

# Geolocator background location service
-keep class com.baseflow.geolocator.** { *; }

# Wakelock — screen on during active trips
-keep class dev.flutter.plugins.wakelock_plus.** { *; }
