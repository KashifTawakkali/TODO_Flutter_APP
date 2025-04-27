import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  pending,  // Default status for new tasks
  inProgress,
  onHold,
  completed
}

enum TaskCategory {
  all,
  personal,
  work,
  shopping,
  health,
  other
}

enum TaskPriority {
  low,
  medium,
  high
}

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final bool isCompleted;
  final TaskCategory category;
  final TaskPriority priority;
  final String ownerId;
  final String? assigneeId;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    this.isCompleted = false,
    required this.category,
    required this.priority,
    required this.ownerId,
    this.assigneeId,
    this.status = TaskStatus.pending,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    TaskCategory? category,
    TaskPriority? priority,
    String? ownerId,
    String? assigneeId,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      ownerId: ownerId ?? this.ownerId,
      assigneeId: assigneeId ?? this.assigneeId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'category': category.toString(),
      'priority': priority.toString(),
      'ownerId': ownerId,
      'assigneeId': assigneeId,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isCompleted: map['isCompleted'] ?? false,
      category: TaskCategory.values.firstWhere(
        (e) => e.toString() == map['category'],
        orElse: () => TaskCategory.other,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString() == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      ownerId: map['ownerId'] ?? '',
      assigneeId: map['assigneeId'],
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  factory Task.fromFirestore(DocumentSnapshot doc) {
    return Task.fromMap(doc.data() as Map<String, dynamic>);
  }
}

class TaskActivity {
  final String userId;
  final String action;
  final DateTime timestamp;
  final Map<String, dynamic>? changes;

  TaskActivity({
    required this.userId,
    required this.action,
    required this.timestamp,
    this.changes,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'changes': changes,
    };
  }

  factory TaskActivity.fromMap(Map<String, dynamic> map) {
    return TaskActivity(
      userId: map['userId'],
      action: map['action'],
      timestamp: DateTime.parse(map['timestamp']),
      changes: map['changes'],
    );
  }
} 