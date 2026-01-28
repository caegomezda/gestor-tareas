import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _tasksCollection = 'tasks';

  // Crear tarea
  static Future<String> createTask(Task task) async {
    try {
      DocumentReference docRef = await _db
          .collection(_tasksCollection)
          .add(task.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear tarea: $e');
    }
  }

  // Obtener tareas del usuario
  static Stream<List<Task>> getUserTasks(String userId) {
    return _db
        .collection(_tasksCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList());
  }

  // Obtener tareas por estado
  static Stream<List<Task>> getTasksByStatus(String userId, String status) {
    return _db
        .collection(_tasksCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList());
  }

  // Actualizar tarea
  static Future<void> updateTask(Task task) async {
    try {
      await _db
          .collection(_tasksCollection)
          .doc(task.id)
          .update(task.toMap());
    } catch (e) {
      throw Exception('Error al actualizar tarea: $e');
    }
  }

  // Eliminar tarea
  static Future<void> deleteTask(String taskId) async {
    try {
      await _db.collection(_tasksCollection).doc(taskId).delete();
    } catch (e) {
      throw Exception('Error al eliminar tarea: $e');
    }
  }

  // Marcar tarea como completada
  static Future<void> completeTask(String taskId, int actualMinutes) async {
    try {
      await _db.collection(_tasksCollection).doc(taskId).update({
        'status': 'completada',
        'actualMinutes': actualMinutes,
      });
    } catch (e) {
      throw Exception('Error al completar tarea: $e');
    }
  }

  // Obtener estadísticas del usuario
  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final snapshot = await _db
          .collection(_tasksCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final tasks = snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
      // OBTENER FALLOS DIARIOS
      final failuresSnapshot = await _db.collection('daily_failures')
          .where('userId', isEqualTo: userId)
          .get();

      int totalTasks = tasks.length;
      int totalFailures = failuresSnapshot.docs.length;
      int completedTasks = tasks.where((t) => t.status == 'completada').length;
      int pendingTasks = tasks.where((t) => t.status == 'pendiente').length;
      int inProgressTasks = tasks.where((t) => t.status == 'en_progreso').length;

      int totalEstimatedMinutes = tasks.fold(0, (sum, task) => sum + task.estimatedMinutes);
      int totalActualMinutes = tasks
          .where((t) => t.actualMinutes != null)
          .fold(0, (sum, task) => sum + task.actualMinutes!);

      // Tareas por prioridad
      int highPriority = tasks.where((t) => t.priority == 'alta').length;
      int mediumPriority = tasks.where((t) => t.priority == 'media').length;
      int lowPriority = tasks.where((t) => t.priority == 'baja').length;

      // Calculamos una "Puntuación de Disciplina" (ejemplo: base 100, resta 5 por cada fallo)
      double disciplineScore = 100.0 - (totalFailures * 5.0);
      if (disciplineScore < 0) disciplineScore = 0;

      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'pendingTasks': pendingTasks,
        'inProgressTasks': inProgressTasks,
        'totalEstimatedMinutes': totalEstimatedMinutes,
        'totalActualMinutes': totalActualMinutes,
        'highPriority': highPriority,
        'mediumPriority': mediumPriority,
        'lowPriority': lowPriority,
        'completionRate': totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0,
        'totalFailures': totalFailures, // Nuevo dato
        'disciplineScore': disciplineScore, // Nuevo dato
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Nueva función para procesar tareas al inicio del día
  static Future<void> checkAndResetDailyTasks(String userId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final snapshot = await _db
        .collection(_tasksCollection)
        .where('userId', isEqualTo: userId)
        .where('isDaily', isEqualTo: true)
        .get();

    WriteBatch batch = _db.batch();

    for (var doc in snapshot.docs) {
      final task = Task.fromFirestore(doc);
      
      // Si la tarea no se ha reseteado hoy
      if (task.lastReset == null || task.lastReset!.isBefore(todayStart)) {
        
        // SI NO SE COMPLETÓ: Generar indicador negativo
        if (task.status != 'completada') {
          DocumentReference failRef = _db.collection('daily_failures').doc();
          batch.set(failRef, {
            'userId': userId,
            'taskId': task.id,
            'taskTitle': task.title,
            'date': Timestamp.fromDate(task.lastReset ?? task.createdAt),
            'penaltyPoints': 10, // Valor arbitrario para el dashboard
          });
        }

        // RESETEAR para el nuevo día
        batch.update(doc.reference, {
          'status': 'pendiente',
          'actualMinutes': 0,
          'lastReset': Timestamp.fromDate(todayStart),
        });
      }
    }
    await batch.commit();
  }
}