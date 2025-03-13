import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TaskItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            // Use Hero widget for smooth transitions if navigating to details
            if (task.imageUrl != null)
              Hero(
                tag: 'task-image-${task.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  // Use FadeInImage for smooth loading
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/images/placeholder.png',
                    image: task.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    // Image caching is built into Flutter
                  ),
                ),
              ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (task.description != null)
                    Text(
                      task.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
