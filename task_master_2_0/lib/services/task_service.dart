import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_master_2_0/models/task_model.dart';
import 'package:task_master_2_0/services/auth_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _tasksCollection = FirebaseFirestore.instance.collection('tasks');
  final AuthService _authService = AuthService();

  // Create a new task
  Future<void> addTask(TaskModel task) async {
    await _tasksCollection.add(task.toMap());
  }

  // Read all tasks for the current user
  Stream<List<TaskModel>> getTasks() async* {
    final currentUser = await _authService.getCurrentUser();
    
    if (currentUser == null) {
      yield [];
      return;
    }

    yield* _firestore
        .collection('tasks')
        .where('userId', isEqualTo: currentUser.id)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList();
          
          // Sort by created date desc
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tasks;
        });
  }
  
  // Get active tasks
  Stream<List<TaskModel>> getActiveTasks() async* {
    final currentUser = await _authService.getCurrentUser();
    
    if (currentUser == null) {
      yield [];
      return;
    }

    yield* _firestore
        .collection('tasks')
        .where('userId', isEqualTo: currentUser.id)
        .where('isCompleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList();
          
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tasks;
        });
  }
  
  // Get completed tasks
  Stream<List<TaskModel>> getCompletedTasks() async* {
    final currentUser = await _authService.getCurrentUser();
    
    if (currentUser == null) {
      yield [];
      return;
    }

    yield* _firestore
        .collection('tasks')
        .where('userId', isEqualTo: currentUser.id)
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList();
          
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tasks;
        });
  }

  // Update a task
  Future<void> updateTask(TaskModel task) async {
    await _tasksCollection.doc(task.id).update(task.toMap());
  }
  
  // Toggle task completion status
  Future<void> toggleTaskCompletion(TaskModel task) async {
    await _tasksCollection.doc(task.id).update({
      'isCompleted': !task.isCompleted,
    });
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }
  
  // Update task time tracking
  Future<void> updateTaskTracking(TaskModel task) async {
    await _tasksCollection.doc(task.id).update({
      'startTime': task.startTime?.millisecondsSinceEpoch,
      'endTime': task.endTime?.millisecondsSinceEpoch,
      'workSessions': task.workSessions.map((d) => d.inSeconds).toList(),
    });
  }
  
  // Search tasks
  Stream<List<TaskModel>> searchTasks(String query) async* {
    final currentUser = await _authService.getCurrentUser();
    
    if (currentUser == null) {
      yield [];
      return;
    }

    yield* _firestore
        .collection('tasks')
        .where('userId', isEqualTo: currentUser.id)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .where((task) => 
                  task.title.toLowerCase().contains(query.toLowerCase()) ||
                  (task.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
              .toList();
          
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tasks;
        });
  }
}