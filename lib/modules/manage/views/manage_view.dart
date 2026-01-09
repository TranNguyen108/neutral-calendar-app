import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manage_controller.dart';
import 'package:intl/intl.dart';
import '../../add_item/views/add_item_bottom_sheet.dart';

class ManageView extends GetView<ManageController> {
  const ManageView({super.key});

  // Helper function to get color for category
  Color _getCategoryColor(String category) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
    ];
    final index = category.hashCode % colors.length;
    return colors[index.abs()];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'nav_manage'.tr,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Get.isDarkMode ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Builder(
                builder: (context) {
                  final tabController = DefaultTabController.of(context);
                  return AnimatedBuilder(
                    animation: tabController,
                    builder: (context, child) {
                      final tabIndex = tabController.index;
                      return Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => tabController.animateTo(0),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: tabIndex == 0
                                      ? LinearGradient(
                                          colors: [
                                            Colors.blue.shade400,
                                            Colors.blue.shade600,
                                          ],
                                        )
                                      : null,
                                  color:
                                      tabIndex == 0 ? null : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: tabIndex == 0
                                      ? [
                                          BoxShadow(
                                            color: Colors.blue
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.note_outlined,
                                      size: 20,
                                      color: tabIndex == 0
                                          ? Colors.white
                                          : Get.isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'notes_tab'.tr,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: tabIndex == 0
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: tabIndex == 0
                                            ? Colors.white
                                            : Get.isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => tabController.animateTo(1),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: tabIndex == 1
                                      ? LinearGradient(
                                          colors: [
                                            Colors.green.shade400,
                                            Colors.green.shade600,
                                          ],
                                        )
                                      : null,
                                  color:
                                      tabIndex == 1 ? null : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: tabIndex == 1
                                      ? [
                                          BoxShadow(
                                            color: Colors.green
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.book_outlined,
                                      size: 20,
                                      color: tabIndex == 1
                                          ? Colors.white
                                          : Get.isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'diary_tab'.tr,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: tabIndex == 1
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: tabIndex == 1
                                            ? Colors.white
                                            : Get.isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildNotesTab(),
            _buildDiaryTab(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: tabController,
              builder: (context, child) {
                final tabIndex = tabController.index;
                return FloatingActionButton.extended(
                  onPressed: () => _showAddDialog(context, tabIndex),
                  icon: const Icon(Icons.add),
                  label: Text(tabIndex == 0 ? 'add_note'.tr : 'add_diary'.tr),
                  backgroundColor: tabIndex == 0 ? Colors.blue : Colors.green,
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, int tabIndex) {
    if (tabIndex == 0) {
      // Show note form from AddItemBottomSheet
      AddItemBottomSheet.showNoteForm();
    } else {
      // Show diary form from AddItemBottomSheet
      AddItemBottomSheet.showDiaryForm();
    }
  }

  Widget _buildNotesTab() {
    return Column(
      children: [
        // Category filter - compact design
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Get.isDarkMode ? Colors.grey[850] : Colors.grey[50],
            border: Border(
              bottom: BorderSide(
                color: Get.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('all'.tr, null, Colors.grey),
                    ...controller.noteCategories.map(
                      (cat) =>
                          _buildCategoryChip(cat, cat, _getCategoryColor(cat)),
                    ),
                  ],
                ),
              )),
        ),
        // Compact notes list
        Expanded(
          child: Obx(() {
            final notes = controller.filteredNotes;
            if (notes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.note_outlined,
                        size: 40,
                        color: Colors.blue.shade300,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'no_notes'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Get.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final categoryColor = note.category != null
                    ? _getCategoryColor(note.category!)
                    : Colors.grey;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Get.isDarkMode ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Get.isDarkMode
                            ? Colors.black.withValues(alpha: 0.2)
                            : categoryColor.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    dense: true,
                    onTap: () {}, // Tắt popup khi click
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    title: Text(
                      note.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Get.isDarkMode ? Colors.white : Colors.grey[900],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: note.content.isNotEmpty
                        ? Text(
                            note.content,
                            style: TextStyle(
                              fontSize: 13,
                              color: Get.isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (note.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              note.category!,
                              style: TextStyle(
                                fontSize: 11,
                                color: categoryColor.withValues(alpha: 1.0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: Colors.red.shade400,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => controller.deleteNote(note.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDiaryTab() {
    return Column(
      children: [
        // Horizontal scrollable month selector - 5 tháng cố định
        Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Get.isDarkMode ? Colors.grey[850]! : Colors.white,
                Get.isDarkMode
                    ? Colors.grey[900]!
                    : Colors.green.withValues(alpha: 0.05),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Get.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Obx(() {
            final currentMonth = controller.selectedMonth.value;
            // Generate 5 tháng: 2 trước, tháng hiện tại, 2 sau
            final months = List.generate(5, (index) {
              return DateTime(
                currentMonth.year,
                currentMonth.month - 2 + index,
              );
            });

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: months.length,
              itemBuilder: (context, index) {
                final month = months[index];
                final isSelected = month.month == currentMonth.month &&
                    month.year == currentMonth.year;
                return GestureDetector(
                  onTap: () => controller.setMonth(month),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected
                          ? null
                          : Get.isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMM').format(month),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : Get.isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          month.year.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.9)
                                : Get.isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
        // Diary list
        Expanded(
          child: Obx(() {
            final diaries = controller.filteredDiaries;
            if (diaries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.book_outlined,
                        size: 40,
                        color: Colors.green.shade300,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'no_diaries'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Get.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: diaries.length,
              itemBuilder: (context, index) {
                final diary = diaries[index];
                return GestureDetector(
                  onTap: () {}, // Tắt popup khi click
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Get.isDarkMode ? Colors.grey[850]! : Colors.white,
                          Get.isDarkMode
                              ? Colors.grey[900]!
                              : Colors.green.withValues(alpha: 0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Get.isDarkMode
                              ? Colors.black.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date badge
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${diary.date.day}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM').format(diary.date),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  diary.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Get.isDarkMode
                                        ? Colors.white
                                        : Colors.grey[900],
                                  ),
                                ),
                                if (diary.content.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    diary.content,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Get.isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (diary.showTime) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: Colors.green.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('HH:mm').format(diary.date),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: Colors.red.shade400,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => controller.deleteDiary(diary.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String? category, Color color) {
    return Obx(() {
      final isSelected = controller.selectedCategory.value == category;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: FilterChip(
          label: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => controller.setCategory(category),
          backgroundColor:
              Get.isDarkMode ? Colors.grey[800] : color.withValues(alpha: 0.1),
          selectedColor: color,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected
                ? Colors.white
                : (Get.isDarkMode
                    ? Colors.grey[300]
                    : color.withValues(alpha: 0.9)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          side: BorderSide(
            color: isSelected ? color : Colors.transparent,
            width: 1,
          ),
        ),
      );
    });
  }
}
