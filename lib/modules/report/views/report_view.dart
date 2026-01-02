import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/report_controller.dart';

class ReportView extends GetView<ReportController> {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ReportController());

    return Scaffold(
      appBar: AppBar(
        title: Text('report_title'.tr),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.loadStatistics();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Daily Streak Card
                  _buildStreakCard(),
                  const SizedBox(height: 16),

                  // Today Stats
                  Text(
                    'today_stats'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.task_alt,
                          color: Colors.blue,
                          value:
                              '${controller.completedTasksToday}/${controller.totalTasksToday}',
                          label: 'tasks_completed'.tr,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.timer,
                          color: Colors.orange,
                          value: '${controller.totalFocusMinutesToday}',
                          label: 'minutes_focused'.tr,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildProgressBar(
                    'today_progress'.tr,
                    controller.todayCompletionRate,
                    Colors.blue,
                  ),

                  const SizedBox(height: 24),

                  // Weekly Stats
                  Text(
                    'weekly_stats'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.checklist,
                          color: Colors.green,
                          value:
                              '${controller.completedTasksWeek}/${controller.totalTasksWeek}',
                          label: 'tasks_completed'.tr,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.access_time,
                          color: Colors.purple,
                          value:
                              '${(controller.totalFocusMinutesWeek.value / 60).toStringAsFixed(1)}h',
                          label: 'hours_focused'.tr,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildProgressBar(
                    'week_completion_rate'.tr,
                    controller.weekCompletionRate,
                    Colors.green,
                  ),

                  const SizedBox(height: 24),

                  // Insights
                  Text(
                    'insights'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInsightCard(
                    icon: Icons.category,
                    title: 'top_category'.tr,
                    value: controller.topCategory,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _buildInsightCard(
                    icon: Icons.star,
                    title: 'most_productive_day'.tr,
                    value: '${controller.maxCompletionDay} tasks',
                    color: Colors.amber,
                  ),

                  const SizedBox(height: 24),

                  // Weekly Chart Placeholder
                  Text(
                    'weekly_activity'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildWeeklyChart(),
                ],
              )),
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.local_fire_department,
                    color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${controller.dailyStreak} ${controller.dailyStreak.value == 1 ? "day" : "days"}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    'daily_streak'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double percentage, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${percentage.toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: controller.weeklyCompletionByDay.entries.map((entry) {
                final maxValue = controller.maxCompletionDay > 0
                    ? controller.maxCompletionDay
                    : 1;
                final height =
                    (entry.value / maxValue * 100).clamp(20.0, 100.0);
                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
