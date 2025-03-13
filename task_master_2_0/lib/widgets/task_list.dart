import 'package:flutter/material.dart';
import '../models/task.dart';
import 'task_item.dart';

class TaskList extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task) onTaskLongPress;

  const TaskList({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Use builder for efficient rendering
      itemCount: tasks.length,
      // Add caching for better scroll performance
      cacheExtent: 100,
      // Add physics for smooth scrolling
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskItem(
          task: task,
          onTap: () => onTaskTap(task),
          onLongPress: () => onTaskLongPress(task),
        );
      },
    );
  }
}
