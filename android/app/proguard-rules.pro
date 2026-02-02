# Reglas para Firebase y tus modelos
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Reemplaza con el nombre real de tu paquete si es distinto
-keepclassmembers class com.example.gestor_tareas.models.** { *; }