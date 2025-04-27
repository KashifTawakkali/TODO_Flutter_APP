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
import 'package:todo_app/views/widgets/task_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _userName = '';
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUserData();
    // Load tasks when the screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskViewModel>().loadTasks('test_user_id');
    });
  }

  Future<void> _loadUserData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userData = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userData.exists) {
          setState(() {
            _userName = userData.data()?['displayName'] ?? currentUser.displayName ?? 'User';
            _isLoadingUser = false;
          });
        } else {
          setState(() {
            _userName = currentUser.displayName ?? 'User';
            _isLoadingUser = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _userName = 'User';
        _isLoadingUser = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Load more tasks when reaching the bottom
      context.read<TaskViewModel>().loadMoreTasks('test_user_id');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskViewModel>(
      builder: (context, taskViewModel, child) {
        final tasks = taskViewModel.tasks;
        return Scaffold(
          appBar: buildFullAppBar(
            context,
            userName: _isLoadingUser ? 'Loading...' : _userName,
            taskCount: tasks.length,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 15, left: 20, bottom: 15),
                child: Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CustomColors.TextSubHeader,
                  ),
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          return TaskItem(task: tasks[index]);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddTaskBottomSheet,
            elevation: 0,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
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

  Widget _buildEmptyState() {
    return Center(
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
    );
  }
} 