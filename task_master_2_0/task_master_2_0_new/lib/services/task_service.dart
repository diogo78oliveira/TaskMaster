import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_master_2_0/models/task_model.dart';
import 'package:task_master_2_0/services/auth_service.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Create a new task
  Future<void> addTask(TaskModel task) async {
    try {
      await _db.collection('tasks').add(task.toMap());
    } catch (e) {
      print('Error adding task: $e');
      rethrow;
    }
  }

  // Update the getTasks method to properly include all tasks
  Stream<List<TaskModel>> getTasks() async* {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        yield [];
        return;
      }
      
      // Make sure we're not filtering by completion status at all
      yield* _db
        .collection('tasks')
        .where('userId', isEqualTo: user.id)
        // No .where('isCompleted', isEqualTo: X) filter here
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => TaskModel.fromMap(doc.data(), doc.id)).toList();
        });
    } catch (e) {
      print('Error getting all tasks: $e');
      yield [];
    }
  }

  // Get only active (non-completed) tasks
  Stream<List<TaskModel>> getActiveTasks() async* {
    final currentUser = await _authService.getCurrentUser();
    
    if (currentUser == null) {
      yield [];
      return;
    }

    try {
      yield* _db
          .collection('tasks')
          .where('userId', isEqualTo: currentUser.id)
          .where('isCompleted', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      print('Error getting active tasks: $e');
      yield [];
    }
  }

  // Get only completed tasks
  Stream<List<TaskModel>> getCompletedTasks() async* {
    final currentUser = await _authService.getCurrentUser();
    
    if (currentUser == null) {
      yield [];
      return;
    }

    try {
      yield* _db
          .collection('tasks')
          .where('userId', isEqualTo: currentUser.id)
          .where('isCompleted', isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      print('Error getting completed tasks: $e');
      yield [];
    }
  }
  
  // Toggle task completion status
  Future<void> toggleTaskCompletion(TaskModel task) async {
    if (task.id == null) return;
    
    try {
      // Create copy with toggled status
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      
      // Update in Firestore 
      await _db.collection('tasks').doc(task.id).update({
        'isCompleted': updatedTask.isCompleted,
      });
    } catch (e) {
      print('Error toggling task completion: $e');
      rethrow;
    }
  }

  // Update an existing task
  Future<void> updateTask(TaskModel task) async {
    if (task.id == null) return;
    
    try {
      await _db.collection('tasks').doc(task.id).update(task.toMap());
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  // Delete a task
  Future<void> deleteTask(TaskModel task) async {
    if (task.id == null) return;
    
    try {
      await _db.collection('tasks').doc(task.id).delete();
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  // Search for tasks
  Stream<List<TaskModel>> searchTasks(String query) async* {
    final currentUser = await _authService.getCurrentUser();
    
    if (currentUser == null) {
      yield [];
      return;
    }

    try {
      // Search by title or description containing the query
      // Note: This is a simple implementation that doesn't use full-text search
      final lowerQuery = query.toLowerCase();
      
      yield* _db
          .collection('tasks')
          .where('userId', isEqualTo: currentUser.id)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
                .where((task) => 
                    task.title.toLowerCase().contains(lowerQuery) ||
                    (task.description?.toLowerCase() ?? '').contains(lowerQuery))
                .toList();
          });
    } catch (e) {
      print('Error searching tasks: $e');
      yield [];
    }
  }
}