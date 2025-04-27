import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Task> _tasks = [];
  TaskCategory _selectedCategory = TaskCategory.all;
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  String? _currentUserId;
  String? _error;

  TaskViewModel(this._firebaseService);

  // Getters
  List<Task> get tasks => _filterTasks();
  TaskCategory get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // Set selected category
  void setCategory(TaskCategory category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  // Filter tasks based on selected category
  List<Task> _filterTasks() {
    if (_selectedCategory == TaskCategory.all) {
      return _tasks;
    }
    return _tasks.where((task) => task.category == _selectedCategory).toList();
  }

  // Load initial tasks for a user
  Future<void> loadTasks(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Query for tasks where user is the owner
      final ownedTasksQuery = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('tasks')
          .where('ownerId', isEqualTo: currentUser.uid);

      // Query for tasks assigned to the user
      final assignedTasksQuery = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('tasks')
          .where('assigneeId', isEqualTo: currentUser.uid);

      // Execute both queries
      final ownedTasksSnapshot = await ownedTasksQuery.get();
      final assignedTasksSnapshot = await assignedTasksQuery.get();

      // Combine and deduplicate tasks
      final Map<String, Task> tasksMap = {};
      
      // Add owned tasks
      for (var doc in ownedTasksSnapshot.docs) {
        final task = Task.fromFirestore(doc);
        tasksMap[task.id] = task;
      }
      
      // Add assigned tasks
      for (var doc in assignedTasksSnapshot.docs) {
        final task = Task.fromFirestore(doc);
        tasksMap[task.id] = task;
      }

      // Convert map to list
      _tasks = tasksMap.values.toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more tasks (pagination)
  Future<void> loadMoreTasks(String userId) async {
    if (_isLoading || !_hasMore || _lastDocument == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _firebaseService.getTasks(
        userId,
        limit: _pageSize,
        startAfter: _lastDocument,
      );
      _tasks.addAll(result.tasks);
      _lastDocument = result.lastDocument;
      _hasMore = result.tasks.length >= _pageSize;
    } catch (e) {
      debugPrint('Error loading more tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new task
  Future<void> createTask(Task task) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final docRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('tasks')
          .doc();

      final newTask = task.copyWith(
        id: docRef.id,
        ownerId: currentUser.uid,
      );

      // Save task in owner's collection
      await docRef.set(newTask.toMap());

      // If task is assigned, save it in assignee's collection too
      if (newTask.assigneeId != null) {
        await _firestore
          .collection('users')
          .doc(newTask.assigneeId)
          .collection('tasks')
          .doc(newTask.id)
          .set(newTask.toMap());
      }

      _tasks.add(newTask);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update a task
  Future<void> updateTask(Task task) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Update in owner's collection
      await _firestore
          .collection('users')
          .doc(task.ownerId)
          .collection('tasks')
          .doc(task.id)
          .update(task.toMap());

      // If task is assigned, update in assignee's collection too
      if (task.assigneeId != null) {
        await _firestore
            .collection('users')
            .doc(task.assigneeId)
            .collection('tasks')
            .doc(task.id)
            .update(task.toMap());
      }

      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get the task to check assignee
      final task = _tasks.firstWhere((t) => t.id == taskId);

      // Delete from owner's collection
      await _firestore
          .collection('users')
          .doc(task.ownerId)
          .collection('tasks')
          .doc(taskId)
          .delete();

      // If task was assigned, delete from assignee's collection too
      if (task.assigneeId != null) {
        await _firestore
            .collection('users')
            .doc(task.assigneeId)
            .collection('tasks')
            .doc(taskId)
            .delete();
      }

      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Share a task
  Future<void> shareTask(String taskId, List<String> userIds) async {
    try {
      await _firebaseService.shareTask(taskId, userIds);
    } catch (e) {
      debugPrint('Error sharing task: $e');
      rethrow;
    }
  }

  // Unshare a task
  Future<void> unshareTask(String taskId, List<String> userIds) async {
    try {
      await _firebaseService.unshareTask(taskId, userIds);
    } catch (e) {
      debugPrint('Error unsharing task: $e');
      rethrow;
    }
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );
    await updateTask(updatedTask);
  }

  // Search tasks
  Future<void> searchTasks(String query) async {
    if (_currentUserId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final searchResults = await _firebaseService.searchTasks(_currentUserId!, query);
      _tasks = searchResults;
      _hasMore = false;
    } catch (e) {
      debugPrint('Error searching tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> assignTask(Task task, String assigneeId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final updatedTask = task.copyWith(
        assigneeId: assigneeId,
        status: TaskStatus.pending,
      );

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('tasks')
          .doc(task.id)
          .update(updatedTask.toMap());

      // Also create the task in assignee's collection
      await _firestore
          .collection('users')
          .doc(assigneeId)
          .collection('tasks')
          .doc(task.id)
          .set(updatedTask.toMap());

      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTaskStatus(Task task, TaskStatus newStatus) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final updatedTask = task.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      // Update in owner's collection
      await _firestore
          .collection('users')
          .doc(task.ownerId)
          .collection('tasks')
          .doc(task.id)
          .update(updatedTask.toMap());

      // Update in assignee's collection if assigned
      if (task.assigneeId != null) {
        await _firestore
            .collection('users')
            .doc(task.assigneeId!)
            .collection('tasks')
            .doc(task.id)
            .update(updatedTask.toMap());
      }

      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
} 