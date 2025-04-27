import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_app/models/task.dart';
import 'package:flutter/foundation.dart';

class TaskQueryResult {
  final List<Task> tasks;
  final DocumentSnapshot? lastDocument;

  TaskQueryResult(this.tasks, this.lastDocument);
}

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tasks';

  // Create a new task
  Future<void> createTask(Task task) async {
    await _firestore.collection(_collection).doc(task.id).set(task.toMap());
  }

  // Get tasks for a user with pagination
  Future<TaskQueryResult> getTasks(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      // First try with ordering
      try {
        // Get owned tasks
        Query ownedQuery = _firestore
            .collection(_collection)
            .where('ownerId', isEqualTo: userId)
            .orderBy('createdAt', descending: true);

        if (startAfter != null) {
          ownedQuery = ownedQuery.startAfterDocument(startAfter);
        }

        final ownedSnapshot = await ownedQuery.get();
        final tasks = ownedSnapshot.docs
            .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        return TaskQueryResult(tasks, ownedSnapshot.docs.isEmpty ? null : ownedSnapshot.docs.last);
      } catch (e) {
        if (e.toString().contains('failed-precondition') || e.toString().contains('requires an index')) {
          // Fallback: get all tasks without ordering if index is not ready
          debugPrint('Index not ready, falling back to simple query');
          final snapshot = await _firestore
              .collection(_collection)
              .where('ownerId', isEqualTo: userId)
              .get();

          final tasks = snapshot.docs
              .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          // Sort in memory
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Apply pagination in memory
          final paginatedTasks = tasks.take(limit).toList();
          
          return TaskQueryResult(paginatedTasks, null);
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Error in getTasks: $e');
      return TaskQueryResult([], null); // Return empty list instead of throwing
    }
  }

  // Listen to real-time task updates
  void listenToTaskUpdates(String userId, Function(Task) onTaskUpdated) {
    try {
      // Listen to owned tasks
      _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: userId)
          .snapshots()
          .listen(
            (snapshot) => _handleTaskUpdates(snapshot, onTaskUpdated),
            onError: (error) {
              debugPrint('Error in listenToTaskUpdates: $error');
            },
          );
    } catch (e) {
      debugPrint('Error setting up task listener: $e');
    }
  }

  void _handleTaskUpdates(QuerySnapshot snapshot, Function(Task) onTaskUpdated) {
    try {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final task = Task.fromMap(change.doc.data() as Map<String, dynamic>);
          onTaskUpdated(task);
        }
      }
    } catch (e) {
      debugPrint('Error handling task updates: $e');
    }
  }

  // Update a task
  Future<void> updateTask(Task task) async {
    await _firestore
        .collection(_collection)
        .doc(task.id)
        .update(task.toMap());
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection(_collection).doc(taskId).delete();
  }

  // Share a task with users
  Future<void> shareTask(String taskId, List<String> userIds) async {
    await _firestore.collection(_collection).doc(taskId).update({
      'sharedWith': FieldValue.arrayUnion(userIds),
    });
  }

  // Remove users from shared task
  Future<void> unshareTask(String taskId, List<String> userIds) async {
    await _firestore.collection(_collection).doc(taskId).update({
      'sharedWith': FieldValue.arrayRemove(userIds),
    });
  }

  // Search tasks
  Future<List<Task>> searchTasks(String userId, String query) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: userId)
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThan: query + 'z')
        .get();

    return snapshot.docs
        .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
} 