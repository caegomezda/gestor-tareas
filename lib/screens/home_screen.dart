import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import 'add_task_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'todas'; // todas, pendiente, en_progreso, completada

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'alta':
        return Icons.priority_high;
      case 'media':
        return Icons.remove;
      case 'baja':
        return Icons.arrow_downward;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completada':
        return Colors.green;
      case 'en_progreso':
        return Colors.blue;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completada':
        return 'Completada';
      case 'en_progreso':
        return 'En progreso';
      case 'pendiente':
        return 'Pendiente';
      default:
        return status;
    }
  }

  Future<void> _logout() async {
    await FirebaseAuthService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showTaskOptions(Task task) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.status != 'completada')
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Marcar como completada'),
                onTap: () async {
                  Navigator.pop(context);
                  _showCompleteTaskDialog(task);
                },
              ),
            if (task.status != 'en_progreso')
              ListTile(
                leading: const Icon(Icons.play_arrow, color: Colors.blue),
                title: const Text('Marcar en progreso'),
                onTap: () async {
                  Navigator.pop(context);
                  await FirestoreService.updateTask(
                    task.copyWith(status: 'en_progreso'),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTaskScreen(task: task),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar'),
              onTap: () async {
                // 1. Guardamos la referencia al Messenger ANTES de cerrar nada
                final messenger = ScaffoldMessenger.of(context);
                
                // 2. Cerramos el diálogo/BottomSheet
                Navigator.pop(context);
                
                try {
                  // 3. Borramos la tarea
                  await FirestoreService.deleteTask(task.id);
                  
                  // 4. Usamos la referencia guardada (ya no necesitamos 'mounted' del widget local)
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Tarea eliminada')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCompleteTaskDialog(Task task) {
    final minutesController = TextEditingController(
      text: task.estimatedMinutes.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar tarea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Cuántos minutos te tomó completar "${task.title}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutos',
                border: OutlineInputBorder(),
                suffixText: 'min',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final minutes = int.tryParse(minutesController.text) ?? 0;
              await FirestoreService.completeTask(task.id, minutes);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Tarea completada!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Completar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bar_chart,
              size: 50.0,
              color: Colors.blueAccent
              ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
            },
            tooltip: 'Estadísticas',
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(
              Icons.logout, 
              size: 50.0,
              color: Colors.redAccent,
              ),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todas'),
                    selected: _selectedFilter == 'todas',
                    onSelected: (selected) {
                      setState(() => _selectedFilter = 'todas');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Pendientes'),
                    selected: _selectedFilter == 'pendiente',
                    onSelected: (selected) {
                      setState(() => _selectedFilter = 'pendiente');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('En progreso'),
                    selected: _selectedFilter == 'en_progreso',
                    onSelected: (selected) {
                      setState(() => _selectedFilter = 'en_progreso');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Completadas'),
                    selected: _selectedFilter == 'completada',
                    onSelected: (selected) {
                      setState(() => _selectedFilter = 'completada');
                    },
                  ),
                ],
              ),
            ),
          ),
          // Lista de tareas
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _selectedFilter == 'todas'
                  ? FirestoreService.getUserTasks(user!.uid)
                  : FirestoreService.getTasksByStatus(user!.uid, _selectedFilter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final tasks = snapshot.data ?? [];

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay tareas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toca el botón + para agregar una',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getPriorityColor(task.priority).withOpacity(0.2),
                          child: Icon(
                            _getPriorityIcon(task.priority),
                            color: _getPriorityColor(task.priority),
                          ),
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.status == 'completada'
                                ? TextDecoration.lineThrough
                                : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task.description.isNotEmpty)
                              Text(
                                task.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${task.estimatedMinutes} min',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(task.status).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusText(task.status),
                                    style: TextStyle(
                                      color: _getStatusColor(task.status),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showTaskOptions(task),
                        ),
                        onTap: () => _showTaskOptions(task),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTaskScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}