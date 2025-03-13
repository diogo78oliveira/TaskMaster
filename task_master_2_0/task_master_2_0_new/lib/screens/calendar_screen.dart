import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task_master_2_0/models/task_model.dart';
import 'package:task_master_2_0/services/task_service.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TaskService _taskService = TaskService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<TaskModel>> _events = {};
  List<TaskModel> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadTasks();
  }

  void _loadTasks() {
    _taskService.getTasks().listen((tasks) {
      final events = <DateTime, List<TaskModel>>{};
      
      for (final task in tasks) {
        if (task.dueDate != null) {
          final date = DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
          );
          
          if (events[date] != null) {
            events[date]!.add(task);
          } else {
            events[date] = [task];
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _events = events;
          _selectedEvents = _getEventsForDay(_selectedDay!);
        });
      }
    });
  }

  List<TaskModel> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }
  
  // Get color based on task category
  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        return Colors.blue;
      case TaskCategory.personal:
        return Colors.purple;
      case TaskCategory.shopping:
        return Colors.green;
      case TaskCategory.health:
        return Colors.red;
      case TaskCategory.education:
        return Colors.orange;
      case TaskCategory.finance:
        return Colors.teal;
      case TaskCategory.social:
        return Colors.pink;
      case TaskCategory.other:
      default:
        return Colors.grey;
    }
  }
  
  // Get priority color
  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  // Get appropriate icon based on task category
  IconData _getCategoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        return Icons.work_outline;
      case TaskCategory.personal:
        return Icons.person_outline;
      case TaskCategory.shopping:
        return Icons.shopping_cart_outlined;
      case TaskCategory.health:
        return Icons.favorite_border;
      case TaskCategory.education:
        return Icons.school_outlined;
      case TaskCategory.finance:
        return Icons.attach_money;
      case TaskCategory.social:
        return Icons.people_outline;
      case TaskCategory.other:
      default:
        return Icons.label_outline;
    }
  }
  
  // Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == tomorrow) {
      return 'Tomorrow';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      // Close when tapping outside of any interactive elements
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Remove AppBar and use a custom dismissible header instead
        body: DraggableScrollableSheet(
          initialChildSize: 0.95, // Almost full screen
          minChildSize: 0.5, // Minimum size before dismissing
          maxChildSize: 0.95, // Maximum expansion
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  // Close the sheet if dragged below threshold
                  if (notification.extent < 0.6) {
                    Navigator.of(context).pop();
                    return true;
                  }
                  return false;
                },
                child: Column(
                  children: [
                    // Drag handle
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Calendar header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Calendar View',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // Optional info tooltip
                          IconButton(
                            icon: Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Select a date to create a task for that day'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Calendar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            eventLoader: _getEventsForDay,
                            selectedDayPredicate: (day) {
                              return isSameDay(_selectedDay, day);
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                                _selectedEvents = _getEventsForDay(selectedDay);
                              });
                            },
                            onFormatChanged: (format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            },
                            onPageChanged: (focusedDay) {
                              _focusedDay = focusedDay;
                            },
                            calendarStyle: CalendarStyle(
                              markersMaxCount: 4,
                              markerSize: 8,
                              markerDecoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              weekendTextStyle: TextStyle(color: theme.colorScheme.error.withOpacity(0.7)),
                              outsideTextStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                            ),
                            headerStyle: HeaderStyle(
                              titleCentered: true,
                              formatButtonDecoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              formatButtonTextStyle: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              leftChevronIcon: Icon(
                                Icons.chevron_left, 
                                color: theme.colorScheme.primary,
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right, 
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDay != null 
                                ? _formatDate(_selectedDay!) 
                                : _formatDate(DateTime.now()),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_selectedEvents.length} Tasks',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _selectedEvents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_available,
                                    size: 64,
                                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tasks for selected day',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _selectedEvents.length,
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, index) {
                                final task = _selectedEvents[index];
                                final categoryColor = _getCategoryColor(task.category);
                                final priorityColor = _getPriorityColor(task.priority);
                                
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      // Don't dismiss the calendar when tapping a task
                                      // as user might be browsing
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: categoryColor,
                                            width: 6,
                                          ),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  _getCategoryIcon(task.category),
                                                  size: 18,
                                                  color: categoryColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  task.category.toString().split('.').last,
                                                  style: TextStyle(
                                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: priorityColor.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    task.priority.toString().split('.').last,
                                                    style: TextStyle(
                                                      color: priorityColor,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  task.isCompleted
                                                      ? Icons.check_circle
                                                      : Icons.circle_outlined,
                                                  color: task.isCompleted
                                                      ? theme.colorScheme.primary
                                                      : theme.colorScheme.onSurface.withOpacity(0.6),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    task.title,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                      decoration: task.isCompleted
                                                          ? TextDecoration.lineThrough
                                                          : null,
                                                      color: task.isCompleted
                                                          ? theme.colorScheme.onSurface.withOpacity(0.6)
                                                          : theme.colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (task.description?.isNotEmpty == true) ...[
                                              const SizedBox(height: 8),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 36.0),
                                                child: Text(
                                                  task.description!,
                                                  style: TextStyle(
                                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                                  ),
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Return the selected day to create a new task
            Navigator.of(context).pop(_selectedDay);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
