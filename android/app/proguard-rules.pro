# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
```

## ✅ Checklist final
```
✅ settings.gradle.kts corregido (sintaxis Kotlin DSL)
✅ build.gradle.kts raíz con AGP 8.5.1
✅ app/build.gradle.kts con Java 17
✅ gradle.properties configurado
✅ proguard-rules.pro creado