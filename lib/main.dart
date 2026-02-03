import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // IMPORTANTE: Añade esta línea
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart'; // Asegúrate de importar tu pantalla principal de tareas

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Intenta envolverlo en un try-catch para ver si el error ocurre justo aquí
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Error inicializando Firebase: $e");
  }
  
  runApp(const GestorTareasApp());
}

class GestorTareasApp extends StatelessWidget {
  const GestorTareasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Tareas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // Usamos StreamBuilder para manejar la persistencia del usuario
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Si la conexión está cargando (comprobando sesión)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // 2. Si el usuario ya inició sesión previamente
          if (snapshot.hasData) {
            return const HomeScreen(); // Cambia 'HomeScreen' por el nombre de tu pantalla de tareas
          }
          
          // 3. Si no hay sesión activa, mostrar Login
          return const LoginScreen();
        },
      ),
    );
  }
}