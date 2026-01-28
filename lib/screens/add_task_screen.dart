import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task;

  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedMinutesController = TextEditingController();

  String _priority = 'media';
  String _status = 'pendiente';
  DateTime? _dueDate;
  bool _isLoading = false;
  bool _isDaily = false; // <-- NUEVA LÍNEA

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _estimatedMinutesController.text = widget.task!.estimatedMinutes.toString();
      _priority = widget.task!.priority;
      _status = widget.task!.status;
      _dueDate = widget.task!.dueDate;
      _isDaily = widget.task!.isDaily; // <-- NUEVA LÍNEA
    }
  }

  // ... (Método _selectDueDate se mantiene igual)
  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _dueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final estimatedMinutes = int.parse(_estimatedMinutesController.text);

      if (widget.task == null) {
        final newTask = Task(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          createdAt: DateTime.now(),
          dueDate: _dueDate,
          estimatedMinutes: estimatedMinutes,
          priority: _priority,
          status: _status,
          userId: user.uid,
          isDaily: _isDaily, // <-- NUEVA LÍNEA
        );

        await FirestoreService.createTask(newTask);
        // ... rest of snackbar logic
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: _dueDate,
          estimatedMinutes: estimatedMinutes,
          priority: _priority,
          status: _status,
          isDaily: _isDaily, // <-- NUEVA LÍNEA
        );

        await FirestoreService.updateTask(updatedTask);
        // ... rest of snackbar logic
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Nueva Tarea' : 'Editar Tarea'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... (Campos de Título, Descripción, Tiempo y Prioridad se mantienen igual)
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _estimatedMinutesController,
                decoration: const InputDecoration(
                  labelText: 'Tiempo estimado',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                  suffixText: 'minutos',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el tiempo estimado';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Prioridad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _priority,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'alta', child: Text('🔴 Alta')),
                      DropdownMenuItem(value: 'media', child: Text('🟠 Media')),
                      DropdownMenuItem(value: 'baja', child: Text('🟢 Baja')),
                    ],
                    onChanged: (value) {
                      setState(() => _priority = value!);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // SECCIÓN DE ESTADO
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.track_changes),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _status,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'pendiente', child: Text('⏳ Pendiente')),
                      DropdownMenuItem(value: 'en_progreso', child: Text('🔵 En progreso')),
                      DropdownMenuItem(value: 'completada', child: Text('✅ Completada')),
                    ],
                    onChanged: (value) {
                      setState(() => _status = value!);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // NUEVA FUNCIONALIDAD: INTERRUPTOR DIARIO
              SwitchListTile(
                title: const Text('Tarea Diaria'),
                subtitle: const Text('Se reinicia cada día y afecta la disciplina'),
                secondary: const Icon(Icons.repeat),
                value: _isDaily,
                onChanged: (bool value) {
                  setState(() => _isDaily = value);
                },
              ),
              const SizedBox(height: 16),

              // ... (Botones de Fecha y Guardar se mantienen igual)
              OutlinedButton.icon(
                onPressed: _selectDueDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _dueDate == null
                      ? 'Fecha límite (opcional)'
                      : 'Fecha límite: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year} ${_dueDate!.hour}:${_dueDate!.minute.toString().padLeft(2, '0')}',
                ),
              ),
              if (_dueDate != null)
                TextButton(
                  onPressed: () {
                    setState(() => _dueDate = null);
                  },
                  child: const Text('Quitar fecha límite'),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _saveTask,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.task == null ? 'Crear Tarea' : 'Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedMinutesController.dispose();
    super.dispose();
  }
}