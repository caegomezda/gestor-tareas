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
        title: const Text('Estadísticas y Rendimiento'),
        centerTitle: true,
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

          // Extraemos los valores con seguridad por si son nulos
          final double disciplineScore = (stats['disciplineScore'] ?? 100.0).toDouble();
          final int totalFailures = stats['totalFailures'] ?? 0;
          final int totalTasks = stats['totalTasks'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. SECCIÓN DE DISCIPLINA (INDICADORES NEGATIVOS)
                _buildDisciplineCard(context, disciplineScore, totalFailures),
                
                const SizedBox(height: 16),

                // 2. RESUMEN GENERAL
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Resumen de Actividades', 
                          style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatCard(
                              icon: Icons.task_alt,
                              label: 'Total',
                              value: totalTasks.toString(),
                              color: Colors.blue,
                            ),
                            _StatCard(
                              icon: Icons.check_circle,
                              label: 'Logradas',
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

                // 3. TASA DE COMPLETITUD (GRÁFICO CIRCULAR)
                _buildCompletionRateCard(context, (stats['completionRate'] as num?)?.toDouble() ?? 0.0),

                const SizedBox(height: 16),

                // 4. GESTIÓN DEL TIEMPO
                _buildTimeManagementCard(context, stats),

                const SizedBox(height: 16),

                // 5. PRIORIDADES
                _buildPriorityCard(context, stats, totalTasks),
                
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS DE SECCIONES ---

  Widget _buildDisciplineCard(BuildContext context, double score, int failures) {
    final bool isLowPerformance = score < 70;
    return Card(
      color: isLowPerformance ? Colors.red[50] : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: isLowPerformance ? Colors.red : Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, 
                  color: isLowPerformance ? Colors.red : Colors.orange),
                const SizedBox(width: 10),
                Text(
                  'DISCIPLINA Y CONSISTENCIA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isLowPerformance ? Colors.red[900] : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${score.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: isLowPerformance ? Colors.red : Colors.green,
                      ),
                    ),
                    const Text('Score Actual', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Container(width: 1, height: 50, color: Colors.grey[300]),
                _StatCard(
                  icon: Icons.dangerous,
                  label: 'Días Fallidos',
                  value: failures.toString(),
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              'Cada tarea diaria fallida resta un 5% de tu honor.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.red[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionRateCard(BuildContext context, double rate) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Tasa de Completitud', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: CircularProgressIndicator(
                    value: rate / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[200],
                    color: Colors.green,
                  ),
                ),
                Text('${rate.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeManagementCard(BuildContext context, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gestión del Tiempo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _TimeRow(
              icon: Icons.access_time,
              label: 'Tiempo Estimado',
              value: '${stats['totalEstimatedMinutes']}m',
              subtitle: '${(stats['totalEstimatedMinutes'] / 60).toStringAsFixed(1)}h',
            ),
            const Divider(),
            _TimeRow(
              icon: Icons.timer,
              label: 'Tiempo Real',
              value: '${stats['totalActualMinutes']}m',
              subtitle: '${(stats['totalActualMinutes'] / 60).toStringAsFixed(1)}h',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityCard(BuildContext context, Map<String, dynamic> stats, int total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distribución por Prioridad', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _PriorityBar(label: 'Alta', value: stats['highPriority'] ?? 0, total: total, color: Colors.red),
            const SizedBox(height: 8),
            _PriorityBar(label: 'Media', value: stats['mediumPriority'] ?? 0, total: total, color: Colors.orange),
            const SizedBox(height: 8),
            _PriorityBar(label: 'Baja', value: stats['lowPriority'] ?? 0, total: total, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

// --- COMPONENTES AUXILIARES ---

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 30, color: color),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  const _TimeRow({required this.icon, required this.label, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

class _PriorityBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _PriorityBar({required this.label, required this.value, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final double percentage = total > 0 ? (value / total) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text('$value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          color: color,
          minHeight: 6,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }
}