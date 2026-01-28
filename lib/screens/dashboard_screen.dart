import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: FirestoreService.getUserStats(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final stats = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Resumen general
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Resumen General',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatCard(
                              icon: Icons.task_alt,
                              label: 'Total',
                              value: stats['totalTasks'].toString(),
                              color: Colors.blue,
                            ),
                            _StatCard(
                              icon: Icons.check_circle,
                              label: 'Completadas',
                              value: stats['completedTasks'].toString(),
                              color: Colors.green,
                            ),
                            _StatCard(
                              icon: Icons.pending,
                              label: 'Pendientes',
                              value: stats['pendingTasks'].toString(),
                              color: Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tasa de completitud
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Tasa de Completitud',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 150,
                              width: 150,
                              child: CircularProgressIndicator(
                                value: stats['completionRate'] / 100,
                                strokeWidth: 12,
                                backgroundColor: Colors.grey[200],
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              '${stats['completionRate'].toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tiempo
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestión del Tiempo',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _TimeRow(
                          icon: Icons.access_time,
                          label: 'Tiempo estimado total',
                          value: '${stats['totalEstimatedMinutes']} min',
                          subtitle: '${(stats['totalEstimatedMinutes'] / 60).toStringAsFixed(1)} horas',
                        ),
                        const Divider(),
                        _TimeRow(
                          icon: Icons.timer,
                          label: 'Tiempo real total',
                          value: '${stats['totalActualMinutes']} min',
                          subtitle: '${(stats['totalActualMinutes'] / 60).toStringAsFixed(1)} horas',
                        ),
                        if (stats['totalActualMinutes'] > 0) ...[
                          const Divider(),
                          _TimeRow(
                            icon: Icons.compare_arrows,
                            label: 'Diferencia',
                            value: '${stats['totalActualMinutes'] - stats['totalEstimatedMinutes']} min',
                            subtitle: stats['totalActualMinutes'] > stats['totalEstimatedMinutes']
                                ? 'Tardaste más de lo estimado'
                                : 'Fuiste más rápido de lo estimado',
                            color: stats['totalActualMinutes'] > stats['totalEstimatedMinutes']
                                ? Colors.red
                                : Colors.green,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Prioridades
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distribución por Prioridad',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _PriorityBar(
                          label: 'Alta',
                          value: stats['highPriority'],
                          total: stats['totalTasks'],
                          color: Colors.red,
                        ),
                        const SizedBox(height: 8),
                        _PriorityBar(
                          label: 'Media',
                          value: stats['mediumPriority'],
                          total: stats['totalTasks'],
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 8),
                        _PriorityBar(
                          label: 'Baja',
                          value: stats['lowPriority'],
                          total: stats['totalTasks'],
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Estado de tareas
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado de Tareas',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatCard(
                              icon: Icons.pending_actions,
                              label: 'En progreso',
                              value: stats['inProgressTasks'].toString(),
                              color: Colors.blue,
                            ),
                            _StatCard(
                              icon: Icons.hourglass_empty,
                              label: 'Pendientes',
                              value: stats['pendingTasks'].toString(),
                              color: Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color? color;

  const _TimeRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PriorityBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _PriorityBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (value / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$value (${(percentage * 100).toStringAsFixed(0)}%)'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          color: color,
          minHeight: 8,
        ),
      ],
    );
  }
}