import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/viewmodels/task_view_model.dart';
import 'package:todo_app/widgets/mock_images.dart';
import 'package:todo_app/utils/colors.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String selectedCategory = 'All';
  final ScrollController _scrollController = ScrollController();

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
      context.read<TaskViewModel>().loadMoreTasks('test_user_id');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskViewModel>(
      builder: (context, taskViewModel, child) {
        final tasks = taskViewModel.tasks;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'All Tasks',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // Implement search functionality
                },
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  // Implement filter functionality
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _buildCategoryFilter(),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  children: [
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
                              'No tasks found',
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
            ],
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

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip('All', TaskCategory.all),
          _buildCategoryChip('Work', TaskCategory.work),
          _buildCategoryChip('Personal', TaskCategory.personal),
          _buildCategoryChip('Shopping', TaskCategory.shopping),
          _buildCategoryChip('Health', TaskCategory.health),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, TaskCategory category) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: context.watch<TaskViewModel>().selectedCategory == category,
        label: Text(label),
        onSelected: (bool selected) {
          if (selected) {
            context.read<TaskViewModel>().setCategory(category);
          }
        },
      ),
    );
  }
} 