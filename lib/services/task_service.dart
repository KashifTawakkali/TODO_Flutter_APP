import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:todo_app/models/task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Stream of tasks for the current user (both owned and assigned)
  Stream<List<Task>> getUserTasks() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('tasks')
        .where(Filter.or(
          Filter('ownerId', isEqualTo: userId),
          Filter('assignedUsers', arrayContains: userId),
        ))
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList());
  }

  // Create a new task
  Future<void> createTask(Task task) async {
    final docRef = _firestore.collection('tasks').doc();
    final newTask = task.copyWith(id: docRef.id);
    
    await docRef.set(newTask.toMap());
    
    // Send notifications to assigned users
    for (String userId in task.assignedUsers) {
      await _sendNotification(
        userId,
        'New Task Assigned',
        'You have been assigned to: ${task.title}',
      );
    }
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    final task = Task.fromFirestore(taskDoc);

    // Create activity record
    final activity = TaskActivity(
      userId: userId,
      action: 'status_update',
      timestamp: DateTime.now(),
      changes: {'status': newStatus.toString()},
    );

    // Update task
    await _firestore.collection('tasks').doc(taskId).update({
      'status': newStatus.index,
      'updatedAt': DateTime.now().toIso8601String(),
      'activities': FieldValue.arrayUnion([activity.toMap()]),
    });

    // Notify task owner if the update is made by an assignee
    if (task.ownerId != userId) {
      await _sendNotification(
        task.ownerId,
        'Task Status Updated',
        'Task "${task.title}" status changed to ${newStatus.toString().split('.').last}',
      );
    }
  }

  // Share task with users
  Future<void> shareTask(String taskId, List<String> userIds) async {
    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    final task = Task.fromFirestore(taskDoc);

    await _firestore.collection('tasks').doc(taskId).update({
      'assignedUsers': FieldValue.arrayUnion(userIds),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Send notifications to newly assigned users
    for (String userId in userIds) {
      await _sendNotification(
        userId,
        'Task Shared With You',
        'You have been added to task: ${task.title}',
      );
    }
  }

  // Send notification to a user
  Future<void> _sendNotification(
    String userId,
    String title,
    String body,
  ) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final fcmToken = userDoc.data()?['fcmToken'];
    
    if (fcmToken != null) {
      await _messaging.sendMessage(
        to: fcmToken,
        data: {
          'title': title,
          'body': body,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      );
    }
  }

  // Update user's FCM token
  Future<void> updateFCMToken() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    }
  }

  // Get task details
  Future<Task?> getTaskDetails(String taskId) async {
    final doc = await _firestore.collection('tasks').doc(taskId).get();
    if (!doc.exists) return null;
    return Task.fromFirestore(doc);
  }

  // Get user details
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data();
  }
} 