import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task_master_2_0/models/task_model.dart';
import 'package:task_master_2_0/services/task_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar View'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          TableCalendar(
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
              markersMaxCount: 3,
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
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedEvents.isEmpty
                ? Center(
                    child: Text(
                      'No tasks for selected day',
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    itemCount: _selectedEvents.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final task = _selectedEvents[index];
                      return ListTile(
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isCompleted 
                                ? TextDecoration.lineThrough 
                                : null,
                          ),
                        ),
                        subtitle: task.description?.isNotEmpty == true
                            ? Text(task.description!)
                            : null,
                        leading: Icon(
                          task.isCompleted
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onTap: () {
                          // Show task details
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
