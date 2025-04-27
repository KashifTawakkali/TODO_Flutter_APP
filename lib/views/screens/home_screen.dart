import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/viewmodels/task_view_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:todo_app/widgets/custom_app_bar.dart';
import 'package:todo_app/widgets/mock_images.dart';
import 'package:todo_app/utils/colors.dart';
import 'package:todo_app/views/screens/tasks_screen.dart';
import 'package:todo_app/views/screens/profile_screen.dart';
import 'package:todo_app/widgets/task_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  String sortBy = 'Date created';
  bool showDetails = false;
  TaskPriority selectedPriority = TaskPriority.medium;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load tasks when the screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskViewModel>().loadTasks('test_user_id');
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Load more tasks when reaching the bottom
      context.read<TaskViewModel>().loadMoreTasks('test_user_id');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _showAddTaskBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskForm(
        onSubmit: (task) {
          context.read<TaskViewModel>().createTask(task);
        },
      ),
    );
  }

  void _showShareTaskDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Share via Email'),
              onTap: () {
                Share.share(
                  'Check out this task: ${task.title}\n\nDescription: ${task.description}',
                  subject: 'Shared Task from Task Compass',
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share via Other Apps'),
              onTap: () {
                Share.share(
                  'Task: ${task.title}\nDescription: ${task.description}',
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskViewModel>(
      builder: (context, taskViewModel, child) {
        final tasks = taskViewModel.tasks;
        return Scaffold(
          appBar: buildFullAppBar(
            context,
            userName: "Brenda",
            taskCount: tasks.length,
          ),
          body: Container(
            width: MediaQuery.of(context).size.width,
            child: ListView(
              scrollDirection: Axis.vertical,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 15, left: 20, bottom: 15),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CustomColors.TextSubHeader,
                    ),
                  ),
                ),
                ...tasks.map((task) => _buildTaskItem(task, taskViewModel)).toList(),
                if (tasks.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: CustomColors.TextGrey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks for today',
                          style: TextStyle(
                            fontSize: 18,
                            color: CustomColors.TextHeaderGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddTaskBottomSheet,
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: MockImages.addTaskIcon(),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 10,
            selectedLabelStyle: const TextStyle(color: CustomColors.BlueDark),
            selectedItemColor: CustomColors.BlueDark,
            unselectedFontSize: 10,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt),
                label: 'Tasks',
              ),
            ],
            onTap: (index) {
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TasksScreen()),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(Task task, TaskViewModel taskViewModel) {
    Color categoryColor = _getCategoryColor(task.category);
    
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          CustomSlidableAction(
            onPressed: (_) => taskViewModel.deleteTask(task.id),
            backgroundColor: Colors.transparent,
            child: MockImages.deleteTaskIcon(),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
        padding: const EdgeInsets.fromLTRB(5, 13, 5, 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            GestureDetector(
              onTap: () => taskViewModel.updateTask(
                task.copyWith(isCompleted: !task.isCompleted),
              ),
              child: task.isCompleted
                  ? MockImages.checkedBox()
                  : MockImages.uncheckedBox(),
            ),
            Text(
              task.dueDate != null
                  ? '${task.dueDate!.hour.toString().padLeft(2, '0')}:${task.dueDate!.minute.toString().padLeft(2, '0')}'
                  : '--:--',
              style: TextStyle(color: CustomColors.TextGrey),
            ),
            Container(
              width: 180,
              child: Text(
                task.title,
                style: TextStyle(
                  color: task.isCompleted
                      ? CustomColors.TextGrey
                      : CustomColors.TextHeader,
                  fontWeight: task.isCompleted ? FontWeight.normal : FontWeight.w600,
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            MockImages.bellIcon(isActive: !task.isCompleted),
          ],
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            stops: const [0.015, 0.015],
            colors: [categoryColor, Colors.white],
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(5.0),
          ),
          boxShadow: const [
            BoxShadow(
              color: CustomColors.GreyBorder,
              blurRadius: 10.0,
              spreadRadius: 5.0,
              offset: Offset(0.0, 0.0),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.personal:
        return CustomColors.YellowIcon;
      case TaskCategory.work:
        return CustomColors.GreenIcon;
      case TaskCategory.shopping:
        return CustomColors.OrangeIcon;
      case TaskCategory.health:
        return CustomColors.BlueIcon;
      default:
        return CustomColors.PurpleIcon;
    }
  }

  Widget _buildPrioritySelector() {
    return DropdownButtonFormField<TaskPriority>(
      value: selectedPriority,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: [
        DropdownMenuItem(
          value: TaskPriority.high,
          child: Row(
            children: [
              Icon(Icons.flag, color: Colors.red[400]),
              const SizedBox(width: 8),
              const Text('High'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: TaskPriority.medium,
          child: Row(
            children: [
              Icon(Icons.flag, color: Colors.orange[400]),
              const SizedBox(width: 8),
              const Text('Medium'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: TaskPriority.low,
          child: Row(
            children: [
              Icon(Icons.flag, color: Colors.green[400]),
              const SizedBox(width: 8),
              const Text('Low'),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            selectedPriority = value;
          });
        }
      },
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search tasks...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      onChanged: (value) {
        // Implement search functionality
      },
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            selected: selectedCategory == 'All',
            label: const Text('All'),
            onSelected: (bool selected) {
              setState(() {
                selectedCategory = 'All';
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: selectedCategory == 'Work',
            label: const Text('Work'),
            onSelected: (bool selected) {
              setState(() {
                selectedCategory = 'Work';
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: selectedCategory == 'Personal',
            label: const Text('Personal'),
            onSelected: (bool selected) {
              setState(() {
                selectedCategory = 'Personal';
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: selectedCategory == 'Urgent',
            label: const Text('Urgent'),
            onSelected: (bool selected) {
              setState(() {
                selectedCategory = 'Urgent';
              });
            },
          ),
        ],
      ),
    );
  }
}

class CheckAnimation extends StatefulWidget {
  final bool isCompleted;
  final VoidCallback onTap;

  const CheckAnimation({
    Key? key,
    required this.isCompleted,
    required this.onTap,
  }) : super(key: key);

  @override
  _CheckAnimationState createState() => _CheckAnimationState();
}

class _CheckAnimationState extends State<CheckAnimation> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _isPressed ? Colors.green : Colors.grey,
          borderRadius: BorderRadius.circular(4),
        ),
        child: widget.isCompleted
            ? const Icon(Icons.check, color: Colors.white)
            : null,
      ),
    );
  }
} 