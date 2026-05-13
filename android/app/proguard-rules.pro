# Flutter Local Notifications
-keep class com.dexterous.** { *; }

# Keep Gson TypeToken (fixes "Missing type parameter" error)
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep generic signatures for Gson
-keepattributes Signature
-keepattributes *Annotation*
