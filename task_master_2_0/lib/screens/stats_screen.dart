import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:task_master_2_0/services/task_service.dart';
import 'package:task_master_2_0/models/task_model.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final TaskService _taskService = TaskService();
  bool _isLoading = true;
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _overdueTasks = 0;
  Map<String, int> _tasksByCategory = {};
  Map<String, int> _completionByDay = {};
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    // Get all tasks to calculate stats
    _taskService.getTasks().listen((tasks) {
      final now = DateTime.now();
      final Map<String, int> categoryCount = {};
      final Map<String, int> completionByDay = {};
      
      int completed = 0;
      int overdue = 0;
      
      // Process each task
      for (final task in tasks) {
        // Count by category
        final category = task.category.toString().split('.').last;
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        
        // Count completed
        if (task.isCompleted) {
          completed++;
          
          // Group by completion day for the last 7 days
          if (task.lastCompleted != null) {
            final dayKey = "${task.lastCompleted!.day}-${task.lastCompleted!.month}";
            completionByDay[dayKey] = (completionByDay[dayKey] ?? 0) + 1;
          }
        }
        
        // Count overdue
        if (!task.isCompleted && task.dueDate != null && task.dueDate!.isBefore(now)) {
          overdue++;
        }
      }
      
      setState(() {
        _totalTasks = tasks.length;
        _completedTasks = completed;
        _overdueTasks = overdue;
        _tasksByCategory = categoryCount;
        _completionByDay = completionByDay;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Statistics'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  
                  const SizedBox(height: 24),
                  Text(
                    'Tasks by Category',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: _buildCategorySections(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Text(
                    'Completion Rate',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildCompletionRateChart(),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard('Total Tasks', _totalTasks.toString(), Icons.list_alt),
        _buildStatCard('Completed', '$_completedTasks/$_totalTasks', Icons.check_circle_outline),
        _buildStatCard('Completion Rate', 
          _totalTasks > 0 ? '${(_completedTasks / _totalTasks * 100).toStringAsFixed(0)}%' : '0%', 
          Icons.trending_up),
        _buildStatCard('Overdue', _overdueTasks.toString(), Icons.warning_amber_outlined),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon) {
    final theme = Theme.of(context);
    
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  List<PieChartSectionData> _buildCategorySections() {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    
    final List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    
    _tasksByCategory.forEach((category, count) {
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: count.toDouble(),
          title: '$category\n$count',
          radius: 60,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
      colorIndex++;
    });
    
    return sections;
  }
  
  Widget _buildCompletionRateChart() {
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _buildCompletionBarGroups(),
      ),
    );
  }
  
  List<BarChartGroupData> _buildCompletionBarGroups() {
    final List<BarChartGroupData> barGroups = [];
    final theme = Theme.of(context);
    int index = 0;
    
    // Create 7 days of data
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayKey = "${date.day}-${date.month}";
      final count = _completionByDay[dayKey] ?? 0;
      
      barGroups.add(
        BarChartGroupData(
          x: index++,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: theme.colorScheme.primary,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
    
    return barGroups;
  }
}
