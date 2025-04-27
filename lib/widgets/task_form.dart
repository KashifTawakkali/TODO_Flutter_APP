import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/models/user.dart';
import 'package:todo_app/utils/colors.dart';
import 'package:intl/intl.dart';

class TaskForm extends StatefulWidget {
  final Function(Task) onSubmit;
  final Task? initialTask;

  const TaskForm({
    Key? key,
    required this.onSubmit,
    this.initialTask,
  }) : super(key: key);

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskCategory _selectedCategory = TaskCategory.personal;
  String? _selectedAssigneeId;
  List<UserModel> _availableUsers = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialTask != null) {
      _titleController.text = widget.initialTask!.title;
      _descriptionController.text = widget.initialTask!.description;
      _selectedDueDate = widget.initialTask!.dueDate;
      _selectedPriority = widget.initialTask!.priority;
      _selectedCategory = widget.initialTask!.category;
      _selectedAssigneeId = widget.initialTask!.assigneeId;
    }
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        _availableUsers = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        _isLoadingUsers = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDueTime?.hour ?? 0,
          _selectedDueTime?.minute ?? 0,
        );
      });
      _selectTime(context);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedDueTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDueTime = picked;
        if (_selectedDueDate != null) {
          _selectedDueDate = DateTime(
            _selectedDueDate!.year,
            _selectedDueDate!.month,
            _selectedDueDate!.day,
            picked.hour,
            picked.minute,
          );
        }
      });
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red.shade400;
      case TaskPriority.medium:
        return Colors.orange.shade400;
      case TaskPriority.low:
        return Colors.green.shade400;
    }
  }

  IconData _getCategoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.personal:
        return Icons.person;
      case TaskCategory.work:
        return Icons.work;
      case TaskCategory.shopping:
        return Icons.shopping_bag;
      case TaskCategory.health:
        return Icons.favorite;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialTask == null ? 'Add New Task' : 'Edit Task',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'Enter task title',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter task description',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TaskCategory>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(
                          _getCategoryIcon(_selectedCategory),
                          color: Theme.of(context).primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: TaskCategory.values
                          .where((category) => category != TaskCategory.all)
                          .map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<TaskPriority>(
                      value: _selectedPriority,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        prefixIcon: Icon(
                          Icons.flag,
                          color: _getPriorityColor(_selectedPriority),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: TaskPriority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(priority.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPriority = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDueDate == null
                            ? 'Set Due Date & Time'
                            : 'Due: ${DateFormat('MMM d, y').format(_selectedDueDate!)} at ${_selectedDueTime?.format(context) ?? 'No time set'}',
                        style: TextStyle(
                          color: _selectedDueDate == null
                              ? Colors.grey[600]
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedAssigneeId,
                decoration: InputDecoration(
                  labelText: 'Assign to',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Unassigned'),
                  ),
                  ..._availableUsers.map((user) {
                    return DropdownMenuItem(
                      value: user.id,
                      child: Text(user.displayName),
                    );
                  }).toList(),
                ],
                onChanged: _isLoadingUsers
                    ? null
                    : (value) {
                        setState(() {
                          _selectedAssigneeId = value;
                        });
                      },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final task = Task(
                      id: widget.initialTask?.id ?? '',
                      title: _titleController.text,
                      description: _descriptionController.text,
                      category: _selectedCategory,
                      priority: _selectedPriority,
                      dueDate: _selectedDueDate,
                      ownerId: '',  // Will be set in TaskViewModel
                      assigneeId: _selectedAssigneeId,
                    );
                    widget.onSubmit(task);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  widget.initialTask == null ? 'Add Task' : 'Update Task',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 