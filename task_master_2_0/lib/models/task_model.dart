import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { low, medium, high }
enum TaskCategory { personal, work, shopping, health, education, other }

class TaskModel {
  final String? id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskCategory category;
  final DateTime createdAt;
  final String userId;
  final DateTime? startTime;
  final DateTime? endTime; 
  final List<Duration> workSessions;

  TaskModel({
    this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.other,
    DateTime? createdAt,
    required this.userId,
    this.startTime,
    this.endTime,
    List<Duration>? workSessions,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.workSessions = workSessions ?? [];

  // Calculate total time spent
  Duration get totalTimeSpent {
    Duration total = Duration.zero;
    
    // Add completed sessions
    for (var session in workSessions) {
      total += session;
    }
    
    // Add current session if active
    if (startTime != null && endTime == null) {
      total += DateTime.now().difference(startTime!);
    }
    
    return total;
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'priority': priority.index,
      'category': category.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'userId': userId,
      'startTime': startTime?.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'workSessions': workSessions.map((d) => d.inSeconds).toList(),
    };
  }

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Safely handle workSessions
    List<Duration> sessions = [];
    if (data['workSessions'] != null) {
      final rawSessions = data['workSessions'] as List<dynamic>;
      sessions = rawSessions.map((seconds) => Duration(seconds: seconds)).toList();
    }
    
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      isCompleted: data['isCompleted'] ?? false,
      dueDate: data['dueDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['dueDate']) 
          : null,
      priority: TaskPriority.values[data['priority'] ?? TaskPriority.medium.index],
      category: TaskCategory.values[data['category'] ?? TaskCategory.other.index],
      createdAt: data['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
      userId: data['userId'] ?? '',
      startTime: data['startTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['startTime']) 
          : null,
      endTime: data['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['endTime']) 
          : null,
      workSessions: sessions,
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskCategory? category,
    DateTime? createdAt,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    List<Duration>? workSessions,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      workSessions: workSessions ?? this.workSessions,
    );
  }
}