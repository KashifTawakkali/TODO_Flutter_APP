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
        return 'Newly Created';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.onHold:
        return 'On Hold';
      case TaskStatus.completed:
        return 'Completed';
      default:
        return 'Newly Created';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.yellow.shade600;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.onHold:
        return Colors.orange;
      case TaskStatus.completed:
        return Colors.green;
      default:
        return Colors.yellow.shade600;
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: _isExpanded ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: _getStatusColor(widget.task.status).withOpacity(0.1),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          initiallyExpanded: _isExpanded,
          title: Text(
            widget.task.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.task.status).withOpacity(0.2),
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
            ],
          ),
          leading: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getStatusColor(widget.task.status),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(widget.task.status),
              color: Colors.white,
              size: 16,
            ),
          ),
          children: [
            FutureBuilder<List<String?>>(
              future: Future.wait([
                if (widget.task.ownerId != currentUser?.uid) _getUserName(widget.task.ownerId),
                if (widget.task.assigneeId != null) _getUserName(widget.task.assigneeId!),
              ]),
              builder: (context, snapshot) {
                String ownerName = widget.task.ownerId == currentUser?.uid ? 'You' : 
                  (snapshot.data != null && snapshot.data!.isNotEmpty ? snapshot.data![0] ?? 'Unknown' : 'Unknown');
                String assigneeName = widget.task.assigneeId == currentUser?.uid ? 'You' : 
                  (snapshot.data != null && snapshot.data!.length > 1 ? snapshot.data![1] ?? 'Unassigned' : 'Unassigned');

                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      
                      // Description
                      if (widget.task.description.isNotEmpty) ...[
                        _buildDetailRow(
                          'Description',
                          widget.task.description,
                          Icons.description,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Due Date
                      if (widget.task.dueDate != null)
                        _buildDetailRow(
                          'Due Date',
                          DateFormat('MMM d, y').format(widget.task.dueDate!),
                          Icons.calendar_today,
                        ),
                      const SizedBox(height: 16),

                      // Priority
                      _buildDetailRow(
                        'Priority',
                        widget.task.priority.toString().split('.').last,
                        Icons.flag,
                        color: _getPriorityColor(widget.task.priority),
                      ),
                      const SizedBox(height: 16),

                      // Assignment Info
                      _buildDetailRow(
                        'Created by',
                        ownerName,
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDetailRow(
                        'Assigned to',
                        assigneeName,
                        Icons.person,
                      ),
                      const SizedBox(height: 16),

                      // Status Dropdown
                      if (isOwner || isAssignee) ...[
                        const Text(
                          'Update Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getStatusColor(widget.task.status),
                              width: 1,
                            ),
                          ),
                          child: DropdownButton<TaskStatus>(
                            value: widget.task.status,
                            isExpanded: true,
                            underline: Container(),
                            onChanged: (TaskStatus? newStatus) {
                              if (newStatus != null) {
                                _updateTaskStatus(newStatus);
                              }
                            },
                            items: TaskStatus.values.map((TaskStatus status) {
                              return DropdownMenuItem<TaskStatus>(
                                value: status,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getStatusIcon(status),
                                      color: _getStatusColor(status),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_getStatusText(status)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: color ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.fiber_new;
      case TaskStatus.inProgress:
        return Icons.play_circle_outline;
      case TaskStatus.onHold:
        return Icons.pause_circle_outline;
      case TaskStatus.completed:
        return Icons.check_circle_outline;
      default:
        return Icons.fiber_new;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      default:
        return Colors.green;
    }
  }
} 