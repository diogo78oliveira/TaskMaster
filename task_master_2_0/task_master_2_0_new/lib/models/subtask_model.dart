class SubtaskModel {
  final String? id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  SubtaskModel({
    this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  SubtaskModel copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return SubtaskModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory SubtaskModel.fromJson(String id, Map<String, dynamic> json) {
    return SubtaskModel(
      id: id,
      taskId: json['taskId'],
      title: json['title'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }
}
