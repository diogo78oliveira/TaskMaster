import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String? id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;
  final String userId;
  final TaskCategory category;
  final TaskPriority priority;
  final DateTime? dueDate;
  final RecurrencePattern recurrence;
  final String? recurrenceRule; // For custom recurrence patterns
  final DateTime? lastCompleted;
  
  

  TaskModel({
    this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    DateTime? createdAt,
    required this.userId,
    this.category = TaskCategory.other,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.recurrence = RecurrencePattern.none,
    this.recurrenceRule,
    this.lastCompleted,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      // Store dates as Firestore Timestamps for consistency
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'category': category.index,
      'priority': priority.index,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    };
  }

  // Create from Firestore document
  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    // Safely handle timestamps
    DateTime? getDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return null;
    }
    
    // Safely handle integer values
    int getIntValue(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (_) {
          return defaultValue;
        }
      }
      return defaultValue;
    }

    return TaskModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      isCompleted: map['isCompleted'] ?? false,
      createdAt: getDateTime(map['createdAt']) ?? DateTime.now(),
      userId: map['userId'] ?? '',
      category: TaskCategory.values[getIntValue(map['category'], TaskCategory.other.index)],
      priority: TaskPriority.values[getIntValue(map['priority'], TaskPriority.medium.index)],
      dueDate: getDateTime(map['dueDate']),
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    String? userId,
    TaskCategory? category,
    TaskPriority? priority,
    DateTime? dueDate,
    RecurrencePattern? recurrence,
    String? recurrenceRule,
    DateTime? lastCompleted,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      recurrence: recurrence ?? this.recurrence,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      lastCompleted: lastCompleted ?? this.lastCompleted,
    );
  }

  // Calculate the next occurrence of this task after completion
  DateTime? calculateNextOccurrence() {
    if (recurrence == RecurrencePattern.none || dueDate == null) {
      return null;
    }
    
    final DateTime baseDate = lastCompleted ?? dueDate!;
    
    switch (recurrence) {
      case RecurrencePattern.daily:
        return baseDate.add(const Duration(days: 1));
      case RecurrencePattern.weekly:
        return baseDate.add(const Duration(days: 7));
      case RecurrencePattern.monthly:
        // Handle month changes appropriately
        int year = baseDate.year;
        int month = baseDate.month + 1;
        
        if (month > 12) {
          month = 1;
          year += 1;
        }
        
        return DateTime(year, month, baseDate.day);
      case RecurrencePattern.yearly:
        return DateTime(baseDate.year + 1, baseDate.month, baseDate.day);
      default:
        return null;
    }
  }
}

enum TaskPriority { low, medium, high }

enum TaskCategory { personal, work, shopping, health, education, other, finance, social }

enum RecurrencePattern {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  custom
}