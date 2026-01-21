import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/mood_stats_controller.dart';
import '../../../core/constants/mood_constants.dart';
import '../../add_item/controllers/add_item_controller.dart';

class MoodStatsView extends GetView<MoodStatsController> {
  const MoodStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker Statistics'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Period selector
            _buildPeriodSelector(),

            // Date navigation
            _buildDateNavigation(),

            // Mood statistics
            _buildMoodStatistics(),

            const SizedBox(height: 20),

            // Calendar heatmap
            _buildCalendarHeatmap(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Obx(() => Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPeriodButton('This Month', 'month'),
              const SizedBox(width: 12),
              _buildPeriodButton('This Year', 'year'),
            ],
          ),
        ));
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = controller.selectedPeriod.value == period;
    return ElevatedButton(
      onPressed: () => controller.setPeriod(period),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget _buildDateNavigation() {
    return Obx(() {
      final isMonth = controller.selectedPeriod.value == 'month';
      final date = isMonth
          ? controller.selectedMonth.value
          : controller.selectedYear.value;
      final dateText = isMonth
          ? DateFormat('MMMM yyyy').format(date)
          : DateFormat('yyyy').format(date);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed:
                  isMonth ? controller.previousMonth : controller.previousYear,
            ),
            Text(
              dateText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: isMonth ? controller.nextMonth : controller.nextYear,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMoodStatistics() {
    return Obx(() => Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Get.isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mood Distribution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...MoodConstants.allMoods.map((mood) {
                final count = controller.moodCounts[mood] ?? 0;
                final total = controller.diaries.length;
                final percentage =
                    total > 0 ? (count / total * 100).toInt() : 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text(
                        MoodConstants.getEmojiForMood(mood),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              MoodConstants.getLabelForMood(mood),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: total > 0 ? count / total : 0,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  MoodConstants.getColorForMood(mood),
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$count ($percentage%)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ));
  }

  Widget _buildCalendarHeatmap() {
    return Obx(() {
      if (controller.selectedPeriod.value == 'year') {
        return _buildYearHeatmap();
      } else {
        return _buildMonthHeatmap();
      }
    });
  }

  Widget _buildMonthHeatmap() {
    return Obx(() {
      final month = controller.selectedMonth.value;
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);
      final daysInMonth = lastDay.day;

      // Calculate starting day of week (0 = Monday, 6 = Sunday)
      final startWeekday = firstDay.weekday - 1;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calendar View',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Weekday headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map((day) => SizedBox(
                        width: 40,
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Get.isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Calendar grid
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(startWeekday + daysInMonth, (index) {
                if (index < startWeekday) {
                  // Empty space before first day
                  return const SizedBox(width: 40, height: 40);
                }

                final day = index - startWeekday + 1;
                final date = DateTime(month.year, month.month, day);
                final mood = controller.getMoodForDay(date);
                final diaries = controller.getDiariesForDay(date);

                return GestureDetector(
                  onTap: () {
                    if (diaries.isNotEmpty) {
                      _showDiariesDialog(date, diaries);
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: mood != null
                          ? MoodConstants.getColorForMood(mood)
                          : (Get.isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: date.day == DateTime.now().day &&
                                date.month == DateTime.now().month &&
                                date.year == DateTime.now().year
                            ? Colors.blue
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontWeight: mood != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: mood != null
                                  ? Colors.black87
                                  : (Get.isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                            ),
                          ),
                        ),
                        if (diaries.length > 1)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Text(
                              '⋯',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Get.isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildYearHeatmap() {
    return Obx(() {
      final year = controller.selectedYear.value.year;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Year Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Grid table layout with months horizontal and days vertical
            _buildYearGridTable(year),
          ],
        ),
      );
    });
  }

  Widget _buildYearGridTable(int year) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate cell width based on available width
        // 13 columns total (1 day + 12 months)
        final availableWidth = constraints.maxWidth;
        final cellWidth = (availableWidth - 40) / 13; // 40px for padding
        final effectiveCellWidth = cellWidth.clamp(24.0, 50.0);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(
              color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              width: 0.5,
            ),
            defaultColumnWidth: FixedColumnWidth(effectiveCellWidth),
            children: [
              // Header row with month numbers
              TableRow(
                decoration: BoxDecoration(
                  color: Get.isDarkMode ? Colors.grey[850] : Colors.grey[100],
                ),
                children: [
                  // Empty cell for day column header
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Day',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Get.isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Month headers 1-12
                  ...List.generate(12, (index) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              Get.isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }),
                ],
              ),
              // Data rows for each day (1-31)
              ...List.generate(31, (dayIndex) {
                final day = dayIndex + 1;
                return TableRow(
                  children: [
                    // Day number column
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Get.isDarkMode
                            ? Colors.grey[850]
                            : Colors.grey[100],
                      ),
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color:
                              Get.isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Cells for each month (1-12)
                    ...List.generate(12, (monthIndex) {
                      final month = monthIndex + 1;
                      final daysInMonth = DateTime(year, month + 1, 0).day;

                      // If this day doesn't exist in this month, show empty
                      if (day > daysInMonth) {
                        return Container(
                          color: Get.isDarkMode
                              ? Colors.grey[900]
                              : Colors.grey[50],
                        );
                      }

                      final date = DateTime(year, month, day);
                      final mood = controller.getMoodForDay(date);
                      final diaries = controller.getDiariesForDay(date);

                      final isToday = date.day == DateTime.now().day &&
                          date.month == DateTime.now().month &&
                          date.year == DateTime.now().year;

                      Color cellColor;
                      if (mood != null) {
                        cellColor = MoodConstants.getColorForMood(mood)
                            .withOpacity(0.7);
                      } else {
                        cellColor = Get.isDarkMode
                            ? Colors.grey[800]!
                            : Colors.grey[200]!;
                      }

                      return GestureDetector(
                        onTap: diaries.isNotEmpty
                            ? () => _showDiariesDialog(date, diaries)
                            : null,
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: cellColor,
                            border: isToday
                                ? Border.all(color: Colors.blue, width: 2)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYearHeatmapGrid(int year) {
    // Start from first day of year
    final startDate = DateTime(year, 1, 1);
    // End at last day of year
    final endDate = DateTime(year, 12, 31);

    // Find the first Monday before or on startDate
    final firstMonday =
        startDate.subtract(Duration(days: (startDate.weekday - 1) % 7));

    // Calculate total weeks needed
    final totalDays = endDate.difference(firstMonday).inDays + 1;
    final totalWeeks = (totalDays / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weekday labels
        Row(
          children: [
            const SizedBox(width: 40), // Space for month labels
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                for (var day in ['Mon', '', 'Wed', '', 'Fri', '', 'Sun'])
                  SizedBox(
                    height: 12,
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 9,
                        color: Get.isDarkMode
                            ? Colors.grey[500]
                            : Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Month labels and heatmap
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month labels (vertical)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (monthIndex) {
                final month = monthIndex + 1;
                final monthStart = DateTime(year, month, 1);
                final weeksFromStart =
                    monthStart.difference(firstMonday).inDays ~/ 7;

                // Only show month label if it's the first week of the month or close to it
                final showLabel = weeksFromStart >= 0 &&
                    (monthIndex == 0 || DateTime(year, month, 1).day <= 7);

                return Container(
                  width: 35,
                  height: 12,
                  alignment: Alignment.centerRight,
                  child: showLabel
                      ? Text(
                          DateFormat('MMM').format(monthStart),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Get.isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                        )
                      : null,
                );
              }),
            ),
            const SizedBox(width: 5),
            // Heatmap grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(totalWeeks, (weekIndex) {
                return Column(
                  children: List.generate(7, (dayIndex) {
                    final date = firstMonday
                        .add(Duration(days: weekIndex * 7 + dayIndex));

                    // Check if date is in current year
                    final isInYear = date.year == year;
                    final mood =
                        isInYear ? controller.getMoodForDay(date) : null;
                    final diaries =
                        isInYear ? controller.getDiariesForDay(date) : [];

                    Color cellColor;
                    if (!isInYear) {
                      cellColor = Colors.transparent;
                    } else if (mood != null) {
                      cellColor = MoodConstants.getColorForMood(mood);
                    } else {
                      cellColor = Get.isDarkMode
                          ? Colors.grey[800]!
                          : Colors.grey[300]!;
                    }

                    return GestureDetector(
                      onTap: isInYear && diaries.isNotEmpty
                          ? () => _showDiariesDialog(date, diaries)
                          : null,
                      child: Container(
                        width: 11,
                        height: 11,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(2),
                          border: date.day == DateTime.now().day &&
                                  date.month == DateTime.now().month &&
                                  date.year == DateTime.now().year
                              ? Border.all(color: Colors.blue, width: 1.5)
                              : null,
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  void _showDiariesDialog(DateTime date, List diaries) {
    Get.dialog(
      AlertDialog(
        title: Text(DateFormat('MMM d, yyyy').format(date)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: diaries.length,
            itemBuilder: (context, index) {
              final diary = diaries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(
                    MoodConstants.getEmojiForMood(diary.mood),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    diary.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    diary.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Get.back(); // Close dialog
                    _editDiary(diary);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editDiary(diary) {
    // Get or create AddItemController
    final addItemController = Get.isRegistered<AddItemController>()
        ? Get.find<AddItemController>()
        : Get.put(AddItemController());

    // Show edit dialog popup
    addItemController.showDiaryEditDialog(diary);
  }
}
