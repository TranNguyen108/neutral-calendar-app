# Quick Reference: Real-Time Mood Reflection

## Files Modified/Created

### 📝 New Files
1. `lib/core/models/daily_mood.dart` - DailyMood model
2. `MOOD_REFLECTION_IMPLEMENTATION.md` - Full documentation

### 🔧 Modified Files
1. `lib/core/constants/mood_constants.dart` - Added numeric scale & comparison
2. `lib/core/services/storage_service.dart` - Added daily mood storage
3. `lib/modules/add_item/controllers/add_item_controller.dart` - Added mood detection
4. `lib/modules/profile/controllers/mood_stats_controller.dart` - Prioritize daily mood

## Key Additions

### MoodConstants (mood_constants.dart)
```dart
// NEW: Convert mood to number (1-5)
static int getMoodNumericValue(String? mood)

// NEW: Calculate mood difference
static int getMoodDifference(String? mood1, String? mood2)

// NEW: Check if significant change (>= 2)
static bool isSignificantMoodChange(String? previousMood, String? newMood)
```

### StorageService (storage_service.dart)
```dart
// NEW: Daily mood CRUD
List<DailyMood> getDailyMoods()
DailyMood? getDailyMoodForDate(DateTime date)
Future<void> setDailyMood(DailyMood dailyMood)

// NEW: Prompt tracking
bool hasBeenPromptedToday()
Future<void> markPromptedToday()

// NEW: Helper
List<Diary> getDiariesForDate(DateTime date)
```

### AddItemController (add_item_controller.dart)
```dart
// NEW: Called after saving diary
Future<void> _checkAndPromptForDailyMood(Diary newDiary)

// NEW: Show non-blocking prompt
void _showDailyMoodPrompt(List<Diary> todayDiaries)

// NEW: Save user's choice or auto-fallback
Future<void> _saveDailyMood(String mood, {required bool isUserConfirmed})
Future<void> _saveDailyMoodAutomatic(List<Diary> todayDiaries)
```

### MoodStatsController (mood_stats_controller.dart)
```dart
// UPDATED: Prioritize daily mood
String? getMoodForDay(DateTime date) {
  // 1. Try daily mood first
  final dailyMood = _storage.getDailyMoodForDate(date);
  if (dailyMood != null) return dailyMood.mood;
  
  // 2. Fallback to diary mood
  final dayDiaries = getDiariesForDay(date);
  return dayDiaries.isNotEmpty ? dayDiaries.first.mood : null;
}
```

## User Flow

```
Create 1st diary → No prompt (only 1 diary)
         ↓
Create 2nd diary with different mood
         ↓
Mood difference >= 2? 
         ↓
    YES → Show prompt dialog
         ↓
User selects mood → Save as confirmed
         OR
User skips → Auto-save latest diary mood
         ↓
Mark prompted for today (no more prompts)
         ↓
Calendar/Stats use daily mood
```

## Testing Commands

```bash
# Check for errors
flutter analyze

# Run app
flutter run -d chrome

# Test flow:
# 1. Create diary with "Very Bad" mood
# 2. Create 2nd diary with "Very Happy" mood
# 3. Verify prompt appears
# 4. Select a mood or skip
# 5. Create 3rd diary → No prompt
```

## Storage Structure

```json
// Daily Moods
{
  "daily_moods": [
    {
      "id": "2026-01-21",
      "date": "2026-01-21T00:00:00.000",
      "mood": "good",
      "isUserConfirmed": true,
      "createdAt": "2026-01-21T14:30:00.000",
      "updatedAt": "2026-01-21T14:30:00.000"
    }
  ]
}

// Prompt State (one per day)
{
  "mood_prompt_shown_2026-01-21": true
}
```

## Mood Scale

| Mood       | Numeric | Emoji |
|------------|---------|-------|
| veryBad    | 1       | 😢    |
| bad        | 2       | 😕    |
| normal     | 3       | 😐    |
| good       | 4       | 🙂    |
| veryGood   | 5       | 😄    |

**Significant Change**: Difference >= 2
- Examples: veryBad → normal (3-1=2), normal → veryGood (5-3=2)

## Edge Cases

| Scenario                     | Behavior                        |
|------------------------------|---------------------------------|
| Only 1 diary today           | No prompt                       |
| Mood change < 2              | No prompt                       |
| Already prompted today       | No prompt                       |
| User dismisses dialog        | Auto-save (skip behavior)       |
| Storage fails                | Silent fail, logged             |
| No daily mood exists         | Fallback to diary mood          |

## Quick Fixes

### Prompt not showing?
Check:
1. Do you have 2+ diaries today?
2. Is mood difference >= 2?
3. Have you been prompted already today?

### Daily mood not saving?
Check:
1. Storage permissions
2. Console for errors
3. Logger output in storage_service.dart

### Old data not working?
- Should work automatically (backward compatible)
- Mood stats fall back to diary moods

## Future Enhancements

- [ ] Schedule prompt for end of day (8 PM)
- [ ] Edit daily mood in calendar long-press
- [ ] Weekly/monthly mood summaries
- [ ] Mood trend indicators (↑↓→)
- [ ] Privacy mode (disable auto-prompts)
- [ ] Export daily moods as CSV

## Performance

- **Storage**: ~73 KB per year of daily moods
- **Memory**: Minimal (loaded on-demand)
- **Computation**: O(n) where n = diaries per day (typically 1-10)
- **UI Impact**: None (prompt shown after save, async)

## Support

For detailed explanation, see: `MOOD_REFLECTION_IMPLEMENTATION.md`
