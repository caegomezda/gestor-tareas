# Mantener clases de Firebase y Google Play Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
# Prevenir errores de ofuscación en modelos de datos (Tus tareas)
-keepclassmembers class com.example.gestor_tareas.models.** { *; }