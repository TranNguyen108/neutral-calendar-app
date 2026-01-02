import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/smart_suggestion_service.dart';

class SuggestionsCard extends StatelessWidget {
  final SmartSuggestionService _suggestionService = Get.find();

  SuggestionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestionService.getDailySuggestions();

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'smart_suggestions'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...suggestions.map((suggestion) => _buildSuggestionItem(
                context,
                suggestion,
              )),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(
    BuildContext context,
    SmartSuggestion suggestion,
  ) {
    return ListTile(
      leading: Icon(
        _getIconForType(suggestion.type),
        color: _getColorForPriority(suggestion.priority, context),
      ),
      title: Text(
        suggestion.title.tr,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(suggestion.message.tr),
      trailing: suggestion.actionLabel != null
          ? OutlinedButton(
              onPressed: () => _handleAction(suggestion),
              child: Text(suggestion.actionLabel!.tr),
            )
          : null,
    );
  }

  IconData _getIconForType(SuggestionType type) {
    switch (type) {
      case SuggestionType.reschedule:
        return Icons.calendar_today;
      case SuggestionType.focus:
        return Icons.timer;
      case SuggestionType.break_:
        return Icons.coffee;
      case SuggestionType.overloadWarning:
        return Icons.warning_amber;
    }
  }

  Color _getColorForPriority(
      SuggestionPriority priority, BuildContext context) {
    switch (priority) {
      case SuggestionPriority.high:
        return Colors.red;
      case SuggestionPriority.medium:
        return Colors.orange;
      case SuggestionPriority.low:
        return Theme.of(context).colorScheme.primary;
    }
  }

  void _handleAction(SmartSuggestion suggestion) {
    switch (suggestion.type) {
      case SuggestionType.reschedule:
        Get.snackbar('info'.tr, 'Long press on overdue tasks to reschedule');
        break;
      case SuggestionType.focus:
        Get.toNamed('/focus');
        break;
      case SuggestionType.break_:
        Get.snackbar('info'.tr, 'Take a 5 minute break!');
        break;
      case SuggestionType.overloadWarning:
        Get.snackbar('info'.tr, 'Consider rescheduling low-priority tasks');
        break;
    }
  }
}
