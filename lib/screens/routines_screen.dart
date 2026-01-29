import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';
import 'add_task_screen.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Rutinas Diarias')),
      body: StreamBuilder<List<Task>>(
        // Necesitaremos crear este método en FirestoreService o filtrar aquí
        stream: FirestoreService.getUserTasks(user!.uid), 
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          // Filtramos solo las diarias
          final routines = snapshot.data!.where((t) => t.isDaily).toList();

          if (routines.isEmpty) {
            return const Center(child: Text('No tienes tareas diarias configuradas.'));
          }

          return ListView.builder(
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final task = routines[index];
              return ListTile(
                leading: const Icon(Icons.repeat, color: Colors.purple),
                title: Text(task.title),
                subtitle: Text('${task.estimatedMinutes} min - ${task.priority}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddTaskScreen(task: task)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}