import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/models/user.dart';
import 'package:todo_app/utils/colors.dart';

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
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskPriority>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: TaskPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag,
                          color: priority == TaskPriority.high
                              ? Colors.red
                              : priority == TaskPriority.medium
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(priority.toString().split('.').last),
                      ],
                    ),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedAssigneeId,
                decoration: const InputDecoration(
                  labelText: 'Assign to',
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _selectedDueDate == null
                      ? 'Set due date'
                      : 'Due: ${_selectedDueDate!.toString().split(' ')[0]}',
                ),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(widget.initialTask == null ? 'Add Task' : 'Update Task'),
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