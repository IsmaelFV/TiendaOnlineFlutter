## Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## Stripe
-dontwarn com.stripe.android.**
-keep class com.stripe.android.** { *; }

## Supabase / GoTrue
-keep class io.supabase.** { *; }

## Gson (used by some plugins)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }

## Keep Freezed/json_serializable generated classes
-keep class **.g.dart { *; }
-keep class **.freezed.dart { *; }
