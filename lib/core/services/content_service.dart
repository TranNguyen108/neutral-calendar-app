import 'package:get/get.dart';
import '../models/event.dart';
import '../models/note.dart';
import '../models/diary.dart';
import 'storage_service.dart';

/// Service quản lý Events, Notes và Diary
class ContentService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();

  // Observable lists
  final events = <Event>[].obs;
  final notes = <Note>[].obs;
  final diaries = <Diary>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  // ========== EVENTS ==========

  Future<void> loadEvents() async {
    events.value = _storage.getEvents();
  }

  Future<void> saveEvent(Event event) async {
    final list = _storage.getEvents();
    final index = list.indexWhere((e) => e.id == event.id);
    if (index >= 0) {
      list[index] = event;
    } else {
      list.add(event);
    }
    await _storage.saveEvents(list);
    events.value = list;
  }

  Future<void> deleteEvent(String id) async {
    final list = _storage.getEvents();
    list.removeWhere((e) => e.id == id);
    await _storage.saveEvents(list);
    events.value = list;
  }

  List<Event> getEventsForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return events.where((e) {
      final eventDate = DateTime(e.date.year, e.date.month, e.date.day);
      return eventDate.isAtSameMomentAs(dateOnly);
    }).toList();
  }

  // ========== NOTES ==========

  Future<void> loadNotes() async {
    notes.value = _storage.getNotes();
  }

  Future<void> saveNote(Note note) async {
    final list = _storage.getNotes();
    final index = list.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      list[index] = note;
    } else {
      list.add(note);
    }
    await _storage.saveNotes(list);
    notes.value = list;
  }

  Future<void> deleteNote(String id) async {
    final list = _storage.getNotes();
    list.removeWhere((n) => n.id == id);
    await _storage.saveNotes(list);
    notes.value = list;
  }

  List<Note> getNotesByCategory(String? category) {
    if (category == null) return notes.toList();
    return notes.where((n) => n.category == category).toList();
  }

  List<Note> searchNotes(String query) {
    final lower = query.toLowerCase();
    return notes.where((n) {
      return n.title.toLowerCase().contains(lower) ||
          n.content.toLowerCase().contains(lower);
    }).toList();
  }

  // ========== DIARY ==========

  Future<void> loadDiaries() async {
    diaries.value = _storage.getDiaries();
  }

  Future<void> saveDiary(Diary diary) async {
    final list = _storage.getDiaries();
    final index = list.indexWhere((d) => d.id == diary.id);
    if (index >= 0) {
      list[index] = diary;
    } else {
      list.add(diary);
    }
    await _storage.saveDiaries(list);
    diaries.value = list;
  }

  Future<void> deleteDiary(String id) async {
    final list = _storage.getDiaries();
    list.removeWhere((d) => d.id == id);
    await _storage.saveDiaries(list);
    diaries.value = list;
  }

  Diary? getDiaryForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return diaries.firstWhereOrNull((d) {
      final diaryDate = DateTime(d.date.year, d.date.month, d.date.day);
      return diaryDate.isAtSameMomentAs(dateOnly);
    });
  }

  List<Diary> getDiariesInRange(DateTime start, DateTime end) {
    return diaries.where((d) {
      return d.date.isAfter(start.subtract(const Duration(days: 1))) &&
          d.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // ========== COMMON ==========

  Future<void> loadAll() async {
    await Future.wait([
      loadEvents(),
      loadNotes(),
      loadDiaries(),
    ]);
  }

  // Statistics
  int get totalEvents => events.length;
  int get totalNotes => notes.length;
  int get totalDiaries => diaries.length;

  List<Event> get upcomingEvents {
    final now = DateTime.now();
    return events.where((e) => e.date.isAfter(now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Diary> get recentDiaries {
    return diaries.toList()
      ..sort((a, b) => b.date.compareTo(a.date))
      ..take(10);
  }
}
