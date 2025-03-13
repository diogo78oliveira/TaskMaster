import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_master_2_0/models/task_model.dart';
import 'package:task_master_2_0/services/task_service.dart';
import 'package:task_master_2_0/services/auth_service.dart';
import 'package:task_master_2_0/screens/login_screen.dart';
import 'package:task_master_2_0/screens/calendar_screen.dart';
import 'package:task_master_2_0/widgets/animated_background.dart';
import 'package:task_master_2_0/main.dart';
import 'dart:ui';

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  String? _currentTaskId;
  bool _isEditing = false;
  bool _isSearching = false;
  String _searchQuery = '';
  int _currentTab = 0;
  bool _isLoading = true;
  List<TaskModel> _tasks = [];
  
  TaskCategory _selectedCategory = TaskCategory.other;
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDueDate;
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOut,
      )
    );
    
    _fabAnimationController.forward();
    
    // Search controller listener
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _loadTasks();
      });
    });
    
    // Load tasks
    _loadTasks();
  }
  
  void _loadTasks() {
    setState(() => _isLoading = true);
    
    Stream<List<TaskModel>> tasksStream;
    
    if (_isSearching && _searchQuery.isNotEmpty) {
      tasksStream = _taskService.searchTasks(_searchQuery);
    } else {
      switch (_currentTab) {
        case 0: // All tasks
          tasksStream = _taskService.getTasks();
          break;
        case 1: // Active tasks
          tasksStream = _taskService.getActiveTasks();
          break;
        case 2: // Completed tasks
          tasksStream = _taskService.getCompletedTasks();
          break;
        default:
          tasksStream = _taskService.getTasks();
      }
    }
    
    tasksStream.listen(
      (tasks) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      },
      onError: (error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tasks: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
    );
  }

  // Get date text color based on deadline proximity
  Color _getDateColor(DateTime dueDate, bool isOverdue, ThemeData theme) {
    if (isOverdue) return theme.colorScheme.error;
    
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    
    if (daysUntilDue == 0) { // Due today
      return Colors.red; // Red for today
    } else if (daysUntilDue <= 1) { // Tomorrow
      return Colors.deepOrange; // Orange for tomorrow
    } else if (daysUntilDue <= 2) { // 2 days
      return Colors.orange; // Orange-yellow for very soon
    } else if (daysUntilDue <= 4) { // 3-4 days
      return Colors.amber.shade800; // Amber for approaching
    } else if (daysUntilDue <= 7) { // 5-7 days
      return Colors.amber.shade700; // Light amber for this week
    } else if (daysUntilDue <= 14) { // 8-14 days
      return Colors.lightGreen; // Light green for next week
    } else {
      return theme.colorScheme.onSurfaceVariant; // Default color
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _currentTaskId = null;
    _isEditing = false;
    _selectedPriority = TaskPriority.medium;
    _selectedCategory = TaskCategory.other;
    _selectedDueDate = null;
  }

  void _setupEditTask(TaskModel task) {
    _titleController.text = task.title;
    _descriptionController.text = task.description ?? '';
    _currentTaskId = task.id;
    _isEditing = true;
    _selectedPriority = task.priority;
    _selectedCategory = task.category;
    _selectedDueDate = task.dueDate;
  }

  Future<void> _saveTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to create tasks')),
      );
      return;
    }

    try {
      if (_isEditing && _currentTaskId != null) {
        final existingTask = _tasks.firstWhere((task) => task.id == _currentTaskId);
            
        final updatedTask = existingTask.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _selectedPriority,
          category: _selectedCategory,
          dueDate: _selectedDueDate,
        );
        
        await _taskService.updateTask(updatedTask);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated')),
        );
      } else {
        final newTask = TaskModel(
          title: _titleController.text,
          description: _descriptionController.text,
          userId: currentUser.id!,
          priority: _selectedPriority,
          category: _selectedCategory,
          dueDate: _selectedDueDate,
        );
        
        await _taskService.addTask(newTask);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added')),
        );
      }
      
      _clearForm();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
  
  Future<bool> _deleteTask(TaskModel task) async {
    try {
      // Keep a copy for undo
      final taskCopy = task;
      
      // Delete from Firestore
      await _taskService.deleteTask(task);
      
      // Show undo option
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${task.title} deleted'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              // Re-add task to Firestore
              await _taskService.addTask(taskCopy);
            },
          ),
        ),
      );
      
      return true;
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting task: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return false;
    }
  }
  
  // Check if a task is overdue
  bool _isTaskOverdue(TaskModel task) {
    if (task.dueDate == null) return false;
    return !task.isCompleted && task.dueDate!.isBefore(DateTime.now());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // Animated background
          AnimatedBackground(theme: theme),
          
          // Main content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildCustomAppBar(theme),
                
                // Search field when searching is active
                if (_isSearching)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: Icon(Icons.search, 
                          color: theme.colorScheme.onSurfaceVariant),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear, 
                            color: theme.colorScheme.onSurfaceVariant),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                      ),
                      autofocus: true,
                    ),
                  ),
                
                _buildTabBar(theme),
                
                // Task list with loading state
                Expanded(
                  child: _isLoading 
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _tasks.isEmpty
                          ? _buildEmptyState(theme)
                          : _buildEnhancedTasksList(_tasks, theme),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: _showAddTaskModal,
              label: const Text('New Task'),
              icon: const Icon(Icons.add),
              elevation: 4,
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Build custom app bar with search, theme toggle, statistics and logout
  Widget _buildCustomAppBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TaskMaster',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _loadTasks();
                }
              });
            },
          ),
          // Add Calendar Button Here
          IconButton(
            icon: Icon(
              Icons.calendar_month,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () async {
              // Await for the result from calendar screen
              final selectedDate = await Navigator.push<DateTime>(
                context, 
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
              
              // If a date was selected in calendar and returned
              if (selectedDate != null) {
                setState(() {
                  _selectedDueDate = selectedDate;
                });
                // Optionally show add task form with the selected date
                _showAddTaskModal();
              }
            },
          ),
          // Statistics Button
          IconButton(
            icon: Icon(
              Icons.bar_chart,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              _showStatisticsPanel();
            },
          ),
          IconButton(
            icon: Icon(
              theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              MyApp.of(context).toggleTheme();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  // Build the tab bar with three tabs
  Widget _buildTabBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? Colors.white.withOpacity(0.7) 
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.brightness == Brightness.light
                    ? Colors.white.withOpacity(0.8)
                    : theme.colorScheme.outline.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildTabButton(0, 'All', theme),
                _buildTabButton(1, 'Active', theme),
                _buildTabButton(2, 'Completed', theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build tab button with selection indicator
  Widget _buildTabButton(int tabIndex, String label, ThemeData theme) {
    final isSelected = _currentTab == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentTab = tabIndex;
          });
          _loadTasks(); // Reload tasks when tab changes
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // Create empty state widget when no tasks are available
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light
                      ? Colors.white.withOpacity(0.7)
                      : theme.colorScheme.surface.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.brightness == Brightness.light 
                        ? Colors.white.withOpacity(0.9) 
                        : theme.colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No tasks yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a new task',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced task list with beautiful cards and animations - redesigned for cleaner look
  Widget _buildEnhancedTasksList(List<TaskModel> tasks, ThemeData theme) {
    return ListView.builder(
      itemCount: tasks.length,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isOverdue = _isTaskOverdue(task);
        final priorityColor = _getPriorityColor(task.priority);
        final categoryIcon = _getCategoryIcon(task.category);
        
        return _buildAnimatedTaskCard(
          index,
          Dismissible(
            key: Key('task_${task.id}'),
            background: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16),
              child: Icon(
                Icons.check_circle_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            secondaryBackground: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
                size: 24,
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                return await _deleteTask(task);
              } else {
                await _taskService.toggleTaskCompletion(task);
                return false;
              }
            },
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: theme.brightness == Brightness.light 
                          ? [
                              Colors.white.withOpacity(0.75),
                              Colors.white.withOpacity(0.65),
                            ] 
                          : [
                              theme.colorScheme.surface.withOpacity(0.75),
                              theme.colorScheme.surface.withOpacity(0.55),
                            ],
                      ),
                      border: Border.all(
                        color: isOverdue
                          ? theme.colorScheme.error.withOpacity(0.6)
                          : theme.brightness == Brightness.light
                              ? Colors.white.withOpacity(0.8)
                              : priorityColor.withOpacity(0.4),
                        width: isOverdue ? 2 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.brightness == Brightness.light 
                            ? Colors.grey.withOpacity(0.15)
                            : priorityColor.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 0.5,
                        )
                      ],
                    ),
                    child: InkWell(
                      onTap: () => _showTaskDetails(task, theme),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Checkbox that only responds to direct taps
                            Container(
                              width: 44,
                              alignment: Alignment.topCenter,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () {
                                    // Prevent multiple rapid clicks
                                    if (_isLoading) return;
                                    
                                    // Set a temporary loading state
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    
                                    // Toggle the task
                                    _taskService.toggleTaskCompletion(task).then((_) {
                                      // No need to manually reload - stream will handle it
                                    }).catchError((error) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error updating task: $error')),
                                      );
                                    }).whenComplete(() {
                                      // Ensure we're not stuck in loading state
                                      if (mounted) {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    });
                                  },
                                  child: Transform.scale(
                                    scale: 1.1,
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Checkbox(
                                          value: task.isCompleted,
                                          onChanged: (_isLoading) 
                                            ? null 
                                            : (bool? value) {
                                                setState(() {
                                                  _isLoading = true;
                                                });
                                                
                                                _taskService.toggleTaskCompletion(task)
                                                  .catchError((error) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Error updating task: $error')),
                                                    );
                                                  }).whenComplete(() {
                                                    if (mounted) {
                                                      setState(() {
                                                        _isLoading = false;
                                                      });
                                                    }
                                                  });
                                              },
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          side: BorderSide(
                                            color: theme.colorScheme.outline,
                                            width: 1.5,
                                          ),
                                          activeColor: theme.colorScheme.primary,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 10),
                            
                            // Content column with new layout
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Title at top
                                  Text(
                                    task.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                      color: task.isCompleted
                                          ? theme.colorScheme.onSurface.withOpacity(0.6)
                                          : theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  // Description below title if available
                                  if (task.description != null && task.description!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      task.description!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Category and date in one row at bottom (closer together)
                                  Row(
                                    children: [
                                      // Category icon and name
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(task.category).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              categoryIcon,
                                              size: 14,
                                              color: _getCategoryColor(task.category),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              // Capitalize first letter
                                              task.category.toString().split('.').last.capitalize(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: _getCategoryColor(task.category),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 12), // Smaller space between category and date
                                      
                                      // Due date if available with deadline-based coloring
                                      if (task.dueDate != null)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.event_outlined,
                                              size: 14,
                                              color: task.dueDate != null 
                                                ? _getDateColor(task.dueDate!, isOverdue, theme)
                                                : theme.colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatTaskDate(task.dueDate!),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: task.dueDate != null 
                                                  ? _getDateColor(task.dueDate!, isOverdue, theme)
                                                  : theme.colorScheme.onSurfaceVariant,
                                                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Actions
                            IconButton(
                              icon: Icon(Icons.more_vert, size: 20),
                              onPressed: () {
                                _showTaskActions(context, task, theme);
                              },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints.tightFor(width: 36, height: 36),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to get color based on task category
  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.personal:
        return Colors.blue;
      case TaskCategory.work:
        return Colors.orange;
      case TaskCategory.shopping:
        return Colors.green;
      case TaskCategory.health:
        return Colors.red;
      case TaskCategory.education:
        return Colors.purple;
      case TaskCategory.other:
      default:
        return Colors.grey;
    }
  }

  // Helper method to get color based on task priority
  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
      default:
        return Colors.green;
    }
  }

  // Get appropriate icon based on task category
  IconData _getCategoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.personal:
        return Icons.person;
      case TaskCategory.work:
        return Icons.work;
      case TaskCategory.shopping:
        return Icons.shopping_cart;
      case TaskCategory.health:
        return Icons.favorite;
      case TaskCategory.education:
        return Icons.school;
      case TaskCategory.other:
      default:
        return Icons.list_alt;
    }
  }

  // Show task details in a beautiful modal sheet
  void _showTaskDetails(TaskModel task, ThemeData theme) {
    final bool isOverdue = _isTaskOverdue(task);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with category and priority
                  Row(
                    children: [
                      // Category indicator
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(task.category),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        task.category.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      // Priority badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(task.priority).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          task.priority.toString().split('.').last.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getPriorityColor(task.priority),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Task title
                  Text(
                    task.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted
                          ? theme.colorScheme.onSurface.withOpacity(0.6)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  
                  // Due date if available
                  if (task.dueDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: isOverdue
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${DateFormat('MMMM d, yyyy').format(task.dueDate!)}',
                          style: TextStyle(
                            color: isOverdue
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isOverdue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'OVERDUE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  
                  // Description if available
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Description:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.description!,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Task status toggle
                  Row(
                    children: [
                      Text(
                        'Task Status:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        task.isCompleted ? 'Completed' : 'In Progress',
                        style: TextStyle(
                          color: task.isCompleted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: task.isCompleted,
                        onChanged: (value) async {
                          await _taskService.toggleTaskCompletion(task);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Edit button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditTaskModal(task);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('EDIT'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Delete button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _deleteTask(task);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.delete_outlined),
                          label: const Text('DELETE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.errorContainer,
                            foregroundColor: theme.colorScheme.error,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Show add task modal
  void _showAddTaskModal() {
    _clearForm();
    _showTaskForm();
  }

  // Show edit task modal
  void _showEditTaskModal(TaskModel task) {
    _setupEditTask(task);
    _showTaskForm();
  }

  // Beautiful task form with enhanced design
  void _showTaskForm() {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 
              24 + MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Beautiful header with animation
                  Row(
                    children: [
                      // Animated icon that changes based on category
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          key: ValueKey(_selectedCategory),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(_selectedCategory).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _getCategoryIcon(_selectedCategory),
                            color: _getCategoryColor(_selectedCategory),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Form title with lively animation
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Text(
                          _isEditing ? 'Edit Task' : 'Create New Task',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  // Title field with clean styling
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'What needs to be done?',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                    ),
                    autofocus: !_isEditing,
                  ),
                  const SizedBox(height: 20),
                  
                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Add details about your task (optional)',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  
                  // Category selector with beautiful icons
                  Text(
                    'Category',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: TaskCategory.values.map((category) {
                        final isSelected = _selectedCategory == category;
                        final categoryColor = _getCategoryColor(category);
                        final categoryIcon = _getCategoryIcon(category);
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                _selectedCategory = category;
                              });
                            },
                            borderRadius: BorderRadius.circular(50),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? categoryColor.withOpacity(0.2) 
                                    : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: isSelected 
                                      ? categoryColor 
                                      : theme.colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    categoryIcon,
                                    size: 20,
                                    color: categoryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category.toString().split('.').last.capitalize(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: categoryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Priority selector with beautiful chips
                  Text(
                    'Priority',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildPriorityChip(
                        TaskPriority.low,
                        'Low',
                        Colors.green,
                        setModalState,
                        theme,
                      ),
                      const SizedBox(width: 8),
                      _buildPriorityChip(
                        TaskPriority.medium,
                        'Medium',
                        Colors.orange,
                        setModalState,
                        theme,
                      ),
                      const SizedBox(width: 8),
                      _buildPriorityChip(
                        TaskPriority.high,
                        'High',
                        Colors.red,
                        setModalState,
                        theme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Due date picker
                  Text(
                    'Due Date',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setModalState(() {
                          _selectedDueDate = pickedDate;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDueDate != null
                                ? DateFormat('MMMM d, yyyy').format(_selectedDueDate!)
                                : 'Select a due date',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveTask,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _isEditing ? 'Update Task' : 'Create Task',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Elegant priority chip design
  Widget _buildPriorityChip(
    TaskPriority priority,
    String label,
    Color color,
    StateSetter setState,
    ThemeData theme,
  ) {
    final isSelected = _selectedPriority == priority;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPriority = priority;
          });
        },
        borderRadius: BorderRadius.circular(50),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            border: Border.all(
              color: isSelected ? color : theme.colorScheme.outline.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                priority == TaskPriority.low
                    ? Icons.keyboard_arrow_down
                    : priority == TaskPriority.medium
                        ? Icons.remove
                        : Icons.keyboard_arrow_up,
                size: 18,
                color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Format dates to be displayed in the task list
  String _formatTaskDate(DateTime date) {
    final now = DateTime.now();
    
    // Today
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    
    // Tomorrow
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    }
    
    // Within the next 7 days
    if (date.difference(now).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name
    }
    
    // Default format
    return DateFormat('MMM d').format(date);
  }
  
  // Animation for card appearance
  Widget _buildAnimatedTaskCard(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Show quick actions menu for a task
  void _showTaskActions(BuildContext context, TaskModel task, ThemeData theme) {
    // Instead of trying to position based on render objects, use a simpler approach
    // that works reliably with ListView items
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sheet handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Edit option
              ListTile(
                leading: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                title: const Text('Edit task'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditTaskModal(task);
                },
              ),
              
              // Toggle completion option
              ListTile(
                leading: Icon(
                  task.isCompleted ? Icons.radio_button_unchecked : Icons.check_circle_outline,
                  color: theme.colorScheme.secondary,
                ),
                title: Text(task.isCompleted ? 'Mark as incomplete' : 'Mark as complete'),
                onTap: () {
                  Navigator.pop(context);
                  _taskService.toggleTaskCompletion(task);
                },
              ),
              
              // Delete option
              ListTile(
                leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                title: const Text('Delete task'),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteTask(task);
                },
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // Simple stats display showing completed vs pending tasks, progress over time
  Widget _buildTaskStatistics() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Task Statistics", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard("Completed", _getCompletedTaskCount()),
                _buildStatCard("Pending", _getPendingTaskCount()),
                _buildStatCard("Overdue", _getOverdueTaskCount()),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Method to get the count of completed tasks
  int _getCompletedTaskCount() {
    return _tasks.where((task) => task.isCompleted).length;
  }

  // Method to get the count of pending tasks
  int _getPendingTaskCount() {
    return _tasks.where((task) => !task.isCompleted).length;
  }

  // Method to get the count of overdue tasks
  int _getOverdueTaskCount() {
    return _tasks.where((task) => _isTaskOverdue(task)).length;
  }

  // Helper method to build stat cards
  Widget _buildStatCard(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(label),
      ],
    );
  }

  void _showStatisticsPanel() {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.insert_chart_outlined,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Task Statistics',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Statistics cards
                _buildEnhancedStatistics(theme),
                
                const SizedBox(height: 24),
                
                // Optional: Add category distribution
                Text(
                  'Task Distribution',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCategoryDistribution(theme),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  // Enhanced statistics display
  Widget _buildEnhancedStatistics(ThemeData theme) {
    final completedCount = _getCompletedTaskCount();
    final pendingCount = _getPendingTaskCount();
    final overdueCount = _getOverdueTaskCount();
    final totalCount = _tasks.length;
    
    // Calculate completion percentage
    final completionPercentage = totalCount > 0 
        ? (completedCount / totalCount * 100).toInt()
        : 0;
        
    return Column(
      children: [
        // Progress indicator
        SizedBox(
          height: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalCount > 0 ? completedCount / totalCount : 0,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Statistic cards in a row
        Row(
          children: [
            _buildEnhancedStatCard(
              "Completed",
              completedCount,
              Icons.check_circle_outline,
              theme.colorScheme.primary,
              theme,
            ),
            const SizedBox(width: 8),
            _buildEnhancedStatCard(
              "Pending",
              pendingCount,
              Icons.hourglass_empty,
              theme.colorScheme.secondary,
              theme,
            ),
            const SizedBox(width: 8),
            _buildEnhancedStatCard(
              "Overdue",
              overdueCount,
              Icons.warning_amber_rounded,
              theme.colorScheme.error,
              theme,
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Completion rate card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Completion Rate',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedCount out of $totalCount tasks',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primaryContainer,
                ),
                child: Center(
                  child: Text(
                    '$completionPercentage%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Enhanced stat card with icon and better styling
  Widget _buildEnhancedStatCard(
    String label, 
    int count, 
    IconData icon, 
    Color color, 
    ThemeData theme
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build category distribution display
  Widget _buildCategoryDistribution(ThemeData theme) {
    // Count tasks by category
    Map<TaskCategory, int> categoryCounts = {};
    
    for (TaskCategory category in TaskCategory.values) {
      categoryCounts[category] = _tasks.where((task) => task.category == category).length;
    }
    
    return Column(
      children: categoryCounts.entries
          .where((entry) => entry.value > 0) // Only show categories with tasks
          .map((entry) {
            final category = entry.key;
            final count = entry.value;
            final percentage = (_tasks.isNotEmpty) 
                ? (count / _tasks.length * 100).toInt() 
                : 0;
                
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      size: 16,
                      color: _getCategoryColor(category),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category.toString().split('.').last.capitalize(),
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '$count tasks ($percentage%)',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _tasks.isNotEmpty ? count / _tasks.length : 0,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getCategoryColor(category),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(),
    );
  }
}