import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/goal_provider.dart';
import '../models/goal.dart';
import 'create_goal_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hedefler ve Görevler'),
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateGoalScreen(),
                ),
              );
            },
            icon: const Icon(FlutterRemix.add_line),
            tooltip: 'Yeni Hedef',
          ),
        ],
      ),
      body: Consumer<GoalProvider>(
        builder: (context, goalProvider, _) {
          if (goalProvider.isLoading) {
            return _buildShimmerLoading(context);
          }

          final activeGoals = goalProvider.activeGoals;
          final completedGoals = goalProvider.completedGoals;

          if (activeGoals.isEmpty && completedGoals.isEmpty) {
            return _buildEmptyState(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activeGoals.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Aktif Hedefler', activeGoals.length),
                  const SizedBox(height: 16),
                  ...activeGoals.map((goal) => _buildGoalCard(context, goal, goalProvider)),
                  const SizedBox(height: 24),
                ],
                if (completedGoals.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Tamamlanan Hedefler', completedGoals.length),
                  const SizedBox(height: 16),
                  ...completedGoals.map((goal) => _buildGoalCard(context, goal, goalProvider, isCompleted: true)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    Goal goal,
    GoalProvider provider, {
    bool isCompleted = false,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    IconData categoryIcon;
    Color categoryColor;
    switch (goal.category) {
      case 'breathing':
        categoryIcon = FlutterRemix.lungs_line;
        categoryColor = Colors.blue;
        break;
      case 'meditation':
        categoryIcon = FlutterRemix.mental_health_line;
        categoryColor = Colors.purple;
        break;
      case 'journal':
        categoryIcon = FlutterRemix.book_open_line;
        categoryColor = Colors.green;
        break;
      case 'anxiety_tracking':
        categoryIcon = FlutterRemix.heart_line;
        categoryColor = Colors.red;
        break;
      default:
        categoryIcon = FlutterRemix.trophy_line;
        categoryColor = primaryColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCompleted ? 1 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(categoryIcon, color: categoryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Icon(
                    FlutterRemix.checkbox_circle_fill,
                    color: Colors.green,
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${goal.progress} / ${goal.target}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.green : primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: goal.progressPercentage,
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? Colors.green : primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  goal.type == 'daily' ? 'Günlük' : goal.type == 'weekly' ? 'Haftalık' : 'Aylık',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (!isCompleted) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => provider.deleteGoal(goal.id),
                    icon: const Icon(FlutterRemix.delete_bin_line, size: 16),
                    label: const Text('Sil'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FlutterRemix.trophy_line,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz hedef yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni bir hedef oluşturarak başlayabilirsin',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateGoalScreen(),
                ),
              );
            },
            icon: const Icon(FlutterRemix.add_line),
            label: const Text('İlk Hedefini Oluştur'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[850]!
          : Colors.grey[300]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]!
          : Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          3,
          (index) => Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

