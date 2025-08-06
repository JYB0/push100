# Preserve generic type information (필수)
-keepattributes Signature
-keepattributes *Annotation*

# Prevent obfuscation of Gson-related classes
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken

# Keep classes that extend TypeToken (중요)
-keep class * extends com.google.gson.reflect.TypeToken

# flutter_local_notifications 관련 (optional but recommended)
-keep class com.dexterous.flutterlocalnotifications.** { *; }
