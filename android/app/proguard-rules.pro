# 1. Mantener Flutter y sus canales de comunicación
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.app.** { *; }
-keep class androidx.lifecycle.** { *; }

# 2. Firebase y Firestore (Reglas agresivas de preservación)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.firestore.** { *; }
-keep class io.flutter.plugins.firebase.firestore.** { *; }

# 3. Importante: Mantener las interfaces de Pigeon (tu error viene de aquí)
-keep class com.google.firebase.firestore.FirebaseFirestoreHostApi { *; }
-keep class com.google.firebase.firestore.FirebaseFirestoreHostApi$* { *; }

# 4. Mantener clases de soporte de Google
-keep class com.google.android.gms.** { *; }

# 4. Tus modelos (ajusta la ruta si es necesario)
-keep class com.example.gestor_tareas.models.** { *; }

# 5. Ignorar advertencias de Play Core que vimos antes
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**