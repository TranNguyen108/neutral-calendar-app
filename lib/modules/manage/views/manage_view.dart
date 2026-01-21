import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manage_controller.dart';
import 'package:intl/intl.dart';
import '../../add_item/views/add_item_bottom_sheet.dart';
import '../../add_item/controllers/add_item_controller.dart';
import '../../../core/models/diary.dart';
import '../../../core/constants/mood_constants.dart';

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
      // Navigate to Note Editor Screen
      Get.toNamed('/note-editor');
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
                    _buildCategoryChip(
                        '⭐ Yêu thích', '__favorites__', Colors.red),
                    ...controller.noteCategories.map(
                      (cat) =>
                          _buildCategoryChip(cat, cat, _getCategoryColor(cat)),
                    ),
                  ],
                ),
              )),
        ),
        // Grid notes list
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
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final categoryColor = note.category != null
                    ? _getCategoryColor(note.category!)
                    : Colors.grey;
                return GestureDetector(
                  onTap: () {}, // Tắt popup khi click
                  child: Container(
                    decoration: BoxDecoration(
                      color: Get.isDarkMode ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: note.category != null
                            ? categoryColor.withValues(alpha: 0.3)
                            : (Get.isDarkMode
                                ? Colors.grey[700]!
                                : Colors.grey[300]!),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Get.isDarkMode
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                note.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Get.isDarkMode
                                      ? Colors.white
                                      : Colors.grey[900],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // Content
                              Expanded(
                                child: Text(
                                  note.content,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Get.isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Category tag
                              if (note.category != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        categoryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    note.category!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: categoryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Favorite button - top right
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: Icon(
                              note.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 20,
                            ),
                            color: note.isFavorite ? Colors.red : Colors.grey,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                controller.toggleNoteFavorite(note),
                          ),
                        ),
                        // Delete button - bottom right
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: Colors.red.shade400,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => controller.deleteNote(note.id),
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
      ],
    );
  }

  Widget _buildDiaryTab() {
    return Column(
      children: [
        // Horizontal month selector - fixed at top, responsive full width
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
            final selectedMonth = controller.selectedMonth.value;
            final now = DateTime.now();
            final currentMonth = DateTime(now.year, now.month);

            // Generate 24 tháng: 12 trước, tháng hiện tại, 11 sau
            final months = List.generate(24, (index) {
              return DateTime(
                currentMonth.year,
                currentMonth.month - 12 + index,
              );
            });

            // Tính toán scroll position để center tháng được chọn
            final selectedIndex = months.indexWhere((m) =>
                m.month == selectedMonth.month && m.year == selectedMonth.year);

            return LayoutBuilder(
              builder: (context, constraints) {
                // Mỗi tháng rộng 90px + 8px margin = 98px
                // Chỉ hiển thị khoảng 5 tháng trong viewport
                const itemWidth = 98.0;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  itemCount: months.length,
                  controller: selectedIndex >= 0
                      ? ScrollController(
                          initialScrollOffset: (selectedIndex - 2) * itemWidth)
                      : null,
                  itemBuilder: (context, index) {
                    final month = months[index];
                    final isSelected = month.month == selectedMonth.month &&
                        month.year == selectedMonth.year;
                    final isCurrent = month.month == currentMonth.month &&
                        month.year == currentMonth.year;

                    return GestureDetector(
                      onTap: () => controller.setMonth(month),
                      child: Container(
                        width: 90,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: isCurrent
                              ? LinearGradient(
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.green.shade600,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isCurrent
                              ? null
                              : isSelected
                                  ? (Get.isDarkMode
                                      ? Colors.blue.shade800
                                      : Colors.blue.shade100)
                                  : (Get.isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected && !isCurrent
                              ? Border.all(
                                  color: Colors.blue.shade400,
                                  width: 2,
                                )
                              : null,
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : isSelected
                                  ? [
                                      BoxShadow(
                                        color:
                                            Colors.blue.withValues(alpha: 0.2),
                                        blurRadius: 6,
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
                                color: isCurrent
                                    ? Colors.white
                                    : isSelected
                                        ? (Get.isDarkMode
                                            ? Colors.blue.shade300
                                            : Colors.blue.shade700)
                                        : (Get.isDarkMode
                                            ? Colors.grey[300]
                                            : Colors.grey[700]),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              month.year.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: isCurrent
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : isSelected
                                        ? (Get.isDarkMode
                                            ? Colors.blue.shade200
                                            : Colors.blue.shade600)
                                        : (Get.isDarkMode
                                            ? Colors.grey[500]
                                            : Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }),
        ),
        // Diary grid - scrollable
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

            // Tách diary thành 2 nhóm: đã ghim và chưa ghim
            final pinnedDiaries = diaries.where((d) => d.isPinned).toList();
            final unpinnedDiaries = diaries.where((d) => !d.isPinned).toList();

            return CustomScrollView(
              slivers: [
                // Khu vực diary đã ghim
                if (pinnedDiaries.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Icon(
                            Icons.push_pin,
                            size: 18,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Đã ghim (${pinnedDiaries.length})',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Get.isDarkMode
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final diary = pinnedDiaries[index];
                          return _buildDiaryCard(diary);
                        },
                        childCount: pinnedDiaries.length,
                      ),
                    ),
                  ),
                ],

                // Khu vực diary thường
                if (unpinnedDiaries.isNotEmpty) ...[
                  if (pinnedDiaries.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 18,
                              color: Get.isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Nhật ký (${unpinnedDiaries.length})',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Get.isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final diary = unpinnedDiaries[index];
                          return _buildDiaryCard(diary);
                        },
                        childCount: unpinnedDiaries.length,
                      ),
                    ),
                  ),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDiaryCard(Diary diary) {
    return GestureDetector(
      onTap: () => _editDiary(diary), // Click to edit diary
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: diary.backgroundColor ??
                  (Get.isDarkMode ? Colors.grey[850] : Colors.white),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date badge with mood emoji
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${diary.date.day}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM').format(diary.date),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mood emoji
                      Text(
                        MoodConstants.getEmojiForMood(diary.mood),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    diary.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Get.isDarkMode ? Colors.white : Colors.grey[900],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Content
                  if (diary.content.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        diary.content,
                        style: TextStyle(
                          fontSize: 13,
                          color: Get.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Time
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
          ),
          // Pin button - top right
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: () => controller.toggleDiaryPin(diary),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Get.isDarkMode
                      ? Colors.grey[800]?.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  diary.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 16,
                  color: diary.isPinned
                      ? Colors.green.shade600
                      : (Get.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ),
          ),
          // Delete button - bottom right
          Positioned(
            bottom: 8,
            right: 8,
            child: InkWell(
              onTap: () => controller.deleteDiary(diary.id),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Get.isDarkMode
                      ? Colors.grey[800]?.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Colors.red.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
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

  // Edit diary using popup dialog
  void _editDiary(Diary diary) {
    // Get or create AddItemController
    final addItemController = Get.isRegistered<AddItemController>()
        ? Get.find<AddItemController>()
        : Get.put(AddItemController());

    // Show edit dialog popup
    addItemController.showDiaryEditDialog(diary);
  }
}
