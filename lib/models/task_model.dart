import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? dueDate;
  final int estimatedMinutes; // Tiempo estimado en minutos
  final int? actualMinutes; // Tiempo real en minutos
  final String priority; // 'alta', 'media', 'baja'
  final String status; // 'pendiente', 'en_progreso', 'completada'
  final String userId;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.dueDate,
    required this.estimatedMinutes,
    this.actualMinutes,
    required this.priority,
    required this.status,
    required this.userId,
  });

  // Convertir de Firestore a Task
  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null 
          ? (data['dueDate'] as Timestamp).toDate() 
          : null,
      estimatedMinutes: data['estimatedMinutes'] ?? 0,
      actualMinutes: data['actualMinutes'],
      priority: data['priority'] ?? 'media',
      status: data['status'] ?? 'pendiente',
      userId: data['userId'] ?? '',
    );
  }

  // Convertir de Task a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'estimatedMinutes': estimatedMinutes,
      'actualMinutes': actualMinutes,
      'priority': priority,
      'status': status,
      'userId': userId,
    };
  }

  // Crear copia con cambios
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? dueDate,
    int? estimatedMinutes,
    int? actualMinutes,
    String? priority,
    String? status,
    String? userId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      userId: userId ?? this.userId,
    );
  }
}