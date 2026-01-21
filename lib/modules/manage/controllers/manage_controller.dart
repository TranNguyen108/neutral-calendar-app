import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/note.dart';
import '../../../core/models/diary.dart';
import '../../../core/services/storage_service.dart';

class ManageController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  final notes = <Note>[].obs;
  final diaries = <Diary>[].obs;
  final selectedCategory = Rx<String?>(null);
  final selectedMonth = DateTime.now().obs;

  List<String> get noteCategories {
    final categories = notes
        .where((note) => note.category != null)
        .map((note) => note.category!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  List<Note> get filteredNotes {
    if (selectedCategory.value == null) {
      return notes;
    }
    // Filter by favorites
    if (selectedCategory.value == '__favorites__') {
      return notes.where((note) => note.isFavorite).toList();
    }
    // Filter by category
    return notes
        .where((note) => note.category == selectedCategory.value)
        .toList();
  }

  List<Diary> get filteredDiaries {
    final month = selectedMonth.value.month;
    final year = selectedMonth.value.year;
    final filtered = diaries
        .where((diary) => diary.date.month == month && diary.date.year == year)
        .toList();

    // Sắp xếp: ghim trước, sau đó theo ngày giảm dần
    filtered.sort((a, b) {
      // Nếu một cái ghim một cái không, ghim lên trước
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      // Cùng trạng thái ghim, sắp xếp theo ngày
      return b.date.compareTo(a.date);
    });

    return filtered;
  }

  String get selectedMonthYear {
    return DateFormat('MMMM yyyy').format(selectedMonth.value);
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void loadData() {
    notes.value = _storage.getNotes();
    diaries.value = _storage.getDiaries();
  }

  void setCategory(String? category) {
    selectedCategory.value = category;
  }

  void previousMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
  }

  void nextMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
  }

  void setMonth(DateTime month) {
    selectedMonth.value = month;
  }

  Future<void> addNote(String title, String content, String category) async {
    final now = DateTime.now();
    final note = Note(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      category: category,
      createdAt: now,
      updatedAt: now,
    );
    await _storage.addNote(note);
    loadData();
  }

  Future<void> addDiary(String title, String content) async {
    final now = DateTime.now();
    final diary = Diary(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      date: selectedMonth.value,
      createdAt: now,
      updatedAt: now,
    );
    await _storage.addDiary(diary);
    loadData();
  }

  Future<void> deleteNote(String noteId) async {
    await _storage.deleteNote(noteId);
    loadData();
    Get.snackbar('success'.tr, 'note_deleted'.tr);
  }

  Future<void> toggleNoteFavorite(Note note) async {
    final updatedNote = note.copyWith(isFavorite: !note.isFavorite);
    final allNotes = _storage.getNotes();
    final index = allNotes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      allNotes[index] = updatedNote;
      await _storage.saveNotes(allNotes);
      loadData();
    }
  }

  Future<void> toggleDiaryPin(Diary diary) async {
    final updatedDiary = diary.copyWith(isPinned: !diary.isPinned);
    final allDiaries = _storage.getDiaries();
    final index = allDiaries.indexWhere((d) => d.id == diary.id);
    if (index >= 0) {
      allDiaries[index] = updatedDiary;
      await _storage.saveDiaries(allDiaries);
      loadData();
    }
  }

  Future<void> deleteDiary(String diaryId) async {
    await _storage.deleteDiary(diaryId);
    loadData();
    Get.snackbar('success'.tr, 'diary_deleted'.tr);
  }
}
