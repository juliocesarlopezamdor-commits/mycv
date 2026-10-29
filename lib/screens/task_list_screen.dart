// screens/task_list_screen.dart
import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/firestore_service.dart';

class TaskListScreen extends StatelessWidget {
  TaskListScreen({super.key});

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: StreamBuilder<List<Task>>(
        stream: _firestoreService.streamTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data!;
          if (tasks.isEmpty) {
            return const Center(child: Text('No tasks yet. Add one!'));
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Dismissible(
                key: Key(task.id),
                onDismissed: (_) => _firestoreService.deleteTask(task.id),
                background: Container(color: Colors.red),
                child: CheckboxListTile(
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Text(task.description),
                  value: task.isCompleted,
                  onChanged: (value) {
                    _firestoreService.toggleTask(task.id, value ?? false);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              await _firestoreService.addTask(
                title: title,
                description: descriptionController.text.trim(),
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    titleController.dispose();
    descriptionController.dispose();
  }
}