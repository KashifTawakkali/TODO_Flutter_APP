import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/viewmodels/task_view_model.dart';
import 'package:todo_app/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:todo_app/utils/colors.dart';
import 'package:intl/intl.dart';

class TaskItem extends StatefulWidget {
  final Task task;

  const TaskItem({
    super.key,
    required this.task,
  });

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isExpanded = false;

  Future<String?> _getUserName(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        return user.displayName;
      }
    } catch (e) {
      debugPrint('Error getting user name: $e');
    }
    return null;
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.onHold:
        return 'On Hold';
      case TaskStatus.completed:
        return 'Completed';
      default:
        return 'Pending';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.onHold:
        return Colors.amber;
      case TaskStatus.completed:
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  void _updateTaskStatus(TaskStatus newStatus) {
    context.read<TaskViewModel>().updateTaskStatus(widget.task, newStatus);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final bool isOwner = currentUser?.uid == widget.task.ownerId;
    final bool isAssignee = currentUser?.uid == widget.task.assigneeId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(widget.task.status),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Column(
          children: [
            // Task Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.task.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(widget.task.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(widget.task.status),
                                style: TextStyle(
                                  color: _getStatusColor(widget.task.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (widget.task.dueDate != null) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM d, y').format(widget.task.dueDate!),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            // Expanded Details
            if (_isExpanded)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: FutureBuilder<List<String?>>(
                  future: Future.wait([
                    if (widget.task.ownerId != currentUser?.uid) _getUserName(widget.task.ownerId),
                    if (widget.task.assigneeId != null) _getUserName(widget.task.assigneeId!),
                  ]),
                  builder: (context, snapshot) {
                    String ownerName = widget.task.ownerId == currentUser?.uid ? 'You' : 
                      (snapshot.data != null && snapshot.data!.isNotEmpty ? snapshot.data![0] ?? 'Unknown' : 'Unknown');
                    String assigneeName = widget.task.assigneeId == currentUser?.uid ? 'You' : 
                      (snapshot.data != null && snapshot.data!.length > 1 ? snapshot.data![1] ?? 'Unassigned' : 'Unassigned');

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Description
                              if (widget.task.description.isNotEmpty) ...[
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(widget.task.description),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 16),
                              ],
                              // Assignment Info
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Created by',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(ownerName),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Assigned to',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(assigneeName),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              // Status Update
                              if (isOwner || isAssignee) ...[
                                const Text(
                                  'Update Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildStatusButton(TaskStatus.pending),
                                    const SizedBox(width: 8),
                                    _buildStatusButton(TaskStatus.inProgress),
                                    const SizedBox(width: 8),
                                    _buildStatusButton(TaskStatus.onHold),
                                    const SizedBox(width: 8),
                                    _buildStatusButton(TaskStatus.completed),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(TaskStatus status) {
    final isSelected = widget.task.status == status;
    return Expanded(
      child: InkWell(
        onTap: () => _updateTaskStatus(status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _getStatusColor(status) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getStatusColor(status),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                _getStatusIcon(status),
                color: isSelected ? Colors.white : _getStatusColor(status),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                _getStatusText(status),
                style: TextStyle(
                  color: isSelected ? Colors.white : _getStatusColor(status),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.schedule;
      case TaskStatus.inProgress:
        return Icons.play_circle_outline;
      case TaskStatus.onHold:
        return Icons.pause_circle_outline;
      case TaskStatus.completed:
        return Icons.check_circle_outline;
      default:
        return Icons.schedule;
    }
  }
} 