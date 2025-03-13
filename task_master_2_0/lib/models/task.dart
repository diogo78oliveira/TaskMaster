import 'package:equatable/equatable.dart';

// Using Equatable for efficient equality checks
class Task extends Equatable {
  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final bool isCompleted;
  final DateTime createdAt;
  

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.isCompleted = false,
    required this.createdAt,
  });

  // Create a copy with modified properties (immutable pattern)
  Task copyWith({
    String? title,
    String? description,
    String? imageUrl,
    bool? isCompleted,
    DateTime? completedDate,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  // For efficient equality checks without unnecessary rebuilds
  @override
  List<Object?> get props => [id, title, description, imageUrl, isCompleted];

  // For Map serialization (efficient JSON conversion)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Factory constructor for deserialization
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      imageUrl: map['imageUrl'] as String?,
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
