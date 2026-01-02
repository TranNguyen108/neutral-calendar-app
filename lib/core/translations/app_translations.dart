import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          // Common
          'app_name': 'Neural Calendar',
          'ok': 'OK',
          'cancel': 'Cancel',
          'save': 'Save',
          'delete': 'Delete',
          'edit': 'Edit',
          'success': 'Success',
          'error': 'Error',

          // Bottom Navigation
          'nav_today': 'Today',
          'nav_calendar': 'Calendar',
          'nav_add': 'Add',
          'nav_focus': 'Focus',
          'nav_profile': 'Profile',

          // Today Screen
          'today_title': 'Today',
          'today_progress': "Today's Progress",
          'tasks_count': '@completed/@total tasks',
          'no_tasks_today': 'No tasks for today',
          'tap_add_task': 'Tap + to add a new task',
          'mark_done': 'Mark as Done',
          'mark_todo': 'Mark as Todo',
          'urgent_tasks': 'Urgent Tasks',
          'all_tasks': 'All Tasks',
          'overdue': 'OVERDUE',

          // Calendar Screen
          'calendar_title': 'Calendar',
          'no_tasks_day': 'No tasks for this day',

          // Add Task Screen
          'add_task': 'Add Task',
          'edit_task': 'Edit Task',
          'quick_add': 'Quick Add',
          'title_required': 'Title *',
          'enter_title': 'Enter task title',
          'date': 'Date',
          'start_time': 'Start Time',
          'end_time': 'End Time',
          'select_time': 'Select time',
          'priority': 'Priority',
          'high': 'High',
          'medium': 'Medium',
          'low': 'Low',
          'category': 'Category',
          'work': 'Work',
          'study': 'Study',
          'health': 'Health',
          'personal': 'Personal',
          'other': 'Other',
          'note': 'Note',
          'add_note': 'Add a note (optional)',
          'update_task': 'Update Task',
          'task_added': 'Task added',
          'task_updated': 'Task updated',
          'task_actions': 'Task Actions',
          'reschedule_tomorrow': 'Reschedule to Tomorrow',
          'delay_one_hour': 'Delay 1 Hour',
          'enter_title_error': 'Please enter a title',
          'enter_note': 'Enter note',
          'tomorrow': 'Tomorrow',
          '3_days_later': '3 Days',
          'this_sunday': 'Sunday',
          'choose_date': 'Choose',
          'add_category': 'Add',
          'add_new_category': 'New Category',
          'enter_category_name': 'Enter category name',
          'add': 'Add',

          // Task Detail
          'task_detail': 'Task Detail',
          'delete_task': 'Delete Task',
          'delete_confirm': 'Are you sure you want to delete this task?',
          'task_deleted': 'Task deleted',
          'status': 'Status',
          'created': 'Created',
          'last_updated': 'Last Updated',
          'task_completed': 'Task completed!',
          'task_marked_todo': 'Task marked as todo',

          // Focus Screen
          'focus_title': 'Focus Mode',
          'pomodoro_timer': 'Pomodoro Timer',
          'start': 'Start',
          'pause': 'Pause',
          'reset': 'Reset',
          'select_task': 'Select Task',
          'change_task': 'Change Task',
          'focus_completed': 'Pomodoro completed! Great work! 🎉',

          // Profile Screen
          'profile_title': 'Profile',
          'nc_user': 'Neural Calendar User',
          'settings': 'Settings',
          'dark_mode': 'Dark Mode',
          'toggle_theme': 'Toggle dark theme',
          'language': 'Language',
          'reports_analytics': 'Reports & Analytics',
          'view_statistics': 'View your statistics',
          'backup_restore': 'Backup & Restore',
          'manage_data': 'Manage your data',
          'data': 'Data',
          'clear_all_data': 'Clear All Data',
          'clear_warning': 'This action cannot be undone',
          'clear_confirm_title': 'Clear All Data?',
          'clear_confirm_msg':
              'This will delete all your tasks and settings. This action cannot be undone.',
          'all_data_cleared': 'All data cleared',
          'version': 'Neural Calendar v1.0.0',
          'select_language': 'Select Language',
          'language_changed': 'Language changed. Restart app to apply.',

          // Report Screen
          'report_title': 'Reports & Analytics',
          'today_stats': 'Today',
          'weekly_stats': 'This Week',
          'tasks_completed': 'Tasks',
          'minutes_focused': 'Minutes',
          'hours_focused': 'Hours',
          'week_completion_rate': 'Completion Rate',
          'insights': 'Insights',
          'top_category': 'Top Category',
          'most_productive_day': 'Best Day',
          'weekly_activity': 'Weekly Activity',
          'daily_streak': 'Day Streak',

          // Task Status
          'todo': 'TODO',
          'in_progress': 'IN PROGRESS',
          'done': 'DONE',

          // Search & Filter
          'search_tasks': 'Search tasks...',
          'clear_filters': 'Clear Filters',
          'no_results': 'No results found',

          // Recurrence
          'recurrence': 'Recurrence',
          'none': 'None',
          'daily': 'Daily',
          'weekly': 'Weekly',
          'monthly': 'Monthly',

          // Reminder
          'reminder': 'Reminder',
          'no_reminder': 'No Reminder',
          '5_min_before': '5 min before',
          '15_min_before': '15 min before',
          '30_min_before': '30 min before',
          '1_hour_before': '1 hour before',

          // Achievements
          'achievements': 'Achievements',
          'view_achievements': 'View your achievements',
          'achievement_unlocked': 'Achievement Unlocked!',
          'unlocked_on': 'Unlocked on',
          'achievement_streak_7_title': '7-Day Streak',
          'achievement_streak_7_desc': 'Complete tasks for 7 consecutive days',
          'achievement_tasks_100_title': '100 Tasks Master',
          'achievement_tasks_100_desc': 'Complete 100 tasks',
          'achievement_focus_10_title': 'Focus Champion',
          'achievement_focus_10_desc': 'Complete 10 focus sessions',
          'achievement_streak_30_title': '30-Day Warrior',
          'achievement_streak_30_desc':
              'Complete tasks for 30 consecutive days',
          'achievement_tasks_500_title': 'Task Legend',
          'achievement_tasks_500_desc': 'Complete 500 tasks',
          'achievement_focus_50h_title': 'Focus Master',
          'achievement_focus_50h_desc': 'Complete 50 hours of focus time',

          // Daily Summary
          'end_of_day_summary': 'End of Day Summary',
          'focus_time': 'Focus Time',
          'summary_excellent': 'Excellent work today! Keep it up! 🎉',
          'summary_good': 'Good progress today! 👍',
          'summary_keep_going': 'Every day is a new opportunity! 💪',
          'close': 'Close',
          'amazing': 'Amazing',
          'days': 'days',
          'streak_milestone': 'Streak milestone reached:',
          'streak_broken': 'Streak Broken',
          'motivational_title': 'Motivation',

          // Motivational Messages
          'motivational_msg_1': 'You are capable of amazing things!',
          'motivational_msg_2': 'Progress, not perfection.',
          'motivational_msg_3': 'Small steps lead to big results.',
          'motivational_msg_4': 'Believe in yourself!',
          'motivational_msg_5': 'You got this! 💪',
          'motivational_msg_6': 'Focus on what you can control.',
          'motivational_msg_7': 'Success is a journey, not a destination.',
          'motivational_msg_8': 'Make today count!',
          'motivational_low_productivity_1':
              'Every task completed is progress. Keep going!',
          'motivational_low_productivity_2':
              'You still have time to make today productive!',
          'motivational_low_productivity_3':
              'Small progress is still progress. Don\'t give up!',
          'motivational_streak_broken_1':
              'It\'s okay! Start a new streak today. 💪',
          'motivational_streak_broken_2':
              'Every champion has fallen. What matters is getting back up!',
          'motivational_streak_broken_3':
              'Fresh start! Let\'s build an even better streak!',
          'motivational_encouragement_1':
              'Take a moment to focus. You can do it!',
          'motivational_encouragement_2':
              'A little focus time goes a long way!',
          'motivational_encouragement_3': 'Time to get in the zone! 🎯',

          // Smart Suggestions
          'smart_suggestions': 'Smart Suggestions',
          'suggestion_overload_title': 'Too Many Tasks',
          'suggestion_overload_message':
              'You have a lot of tasks today. Consider rescheduling some.',
          'suggestion_reschedule_some': 'Reschedule Some',
          'suggestion_overdue_title': 'Overdue Tasks',
          'suggestion_overdue_message':
              'You have overdue tasks. Would you like to reschedule them?',
          'suggestion_reschedule': 'Reschedule',
          'suggestion_focus_title': 'Focus Time',
          'suggestion_focus_message':
              'You haven\'t done much focus work today. Start a session?',
          'suggestion_start_focus': 'Start Focus',
          'suggestion_break_title': 'Take a Break',
          'suggestion_break_message':
              'You\'ve been working for a while. Consider taking a break.',
          'suggestion_take_break': 'Got it',

          // Behavior Insights
          'insight_frequent_delays': 'Frequent Delays',
          'insight_frequent_delays_message':
              'You often delay tasks. Try setting more realistic times.',
          'insight_frequent_reschedules': 'Frequent Rescheduling',
          'insight_frequent_reschedules_message':
              'You reschedule tasks often. Plan buffer time for unexpected work.',
          'insight_low_task_completion': 'Low Task Completion',
          'insight_productive_hours': 'Your Productive Hours',
          'insight_productive_hours_message':
              'You\'re most productive during these hours. Schedule important tasks then.',
          'insight_low_focus_usage': 'Low Focus Usage',
          'insight_low_focus_usage_message':
              'Try using focus sessions to improve concentration.',
        },
        'vi_VN': {
          // Common
          'app_name': 'Lịch Thông Minh',
          'ok': 'Đồng ý',
          'cancel': 'Hủy',
          'save': 'Lưu',
          'delete': 'Xóa',
          'edit': 'Sửa',
          'success': 'Thành công',
          'error': 'Lỗi',

          // Bottom Navigation
          'nav_today': 'Hôm nay',
          'nav_calendar': 'Lịch',
          'nav_add': 'Thêm',
          'nav_focus': 'Tập trung',
          'nav_profile': 'Hồ sơ',

          // Today Screen
          'today_title': 'Hôm nay',
          'today_progress': 'Tiến độ hôm nay',
          'tasks_count': '@completed/@total việc',
          'no_tasks_today': 'Không có việc hôm nay',
          'tap_add_task': 'Nhấn + để thêm việc mới',
          'mark_done': 'Đánh dấu hoàn thành',
          'mark_todo': 'Đánh dấu chưa làm',
          'urgent_tasks': 'Việc cần làm ngay',
          'all_tasks': 'Tất cả công việc',
          'overdue': 'QUÁ HẠN',

          // Calendar Screen
          'calendar_title': 'Lịch',
          'no_tasks_day': 'Không có việc trong ngày này',

          // Add Task Screen
          'add_task': 'Thêm việc',
          'edit_task': 'Sửa việc',
          'quick_add': 'Thêm nhanh',
          'title_required': 'Tiêu đề *',
          'enter_title': 'Nhập tiêu đề công việc',
          'date': 'Ngày',
          'start_time': 'Thời gian bắt đầu',
          'end_time': 'Thời gian kết thúc',
          'select_time': 'Chọn thời gian',
          'priority': 'Độ ưu tiên',
          'high': 'Cao',
          'medium': 'Trung bình',
          'low': 'Thấp',
          'category': 'Danh mục',
          'work': 'Công việc',
          'study': 'Học tập',
          'health': 'Sức khỏe',
          'personal': 'Cá nhân',
          'other': 'Khác',
          'note': 'Ghi chú',
          'add_note': 'Thêm ghi chú (tùy chọn)',
          'update_task': 'Cập nhật',
          'task_added': 'Đã thêm việc',
          'task_updated': 'Đã cập nhật việc',
          'task_actions': 'Hành động',
          'reschedule_tomorrow': 'Lên lịch ngày mai',
          'delay_one_hour': 'Hoãn 1 giờ',
          'enter_title_error': 'Vui lòng nhập tiêu đề',
          'enter_note': 'Nhập ghi chú',
          'tomorrow': 'Ngày mai',
          '3_days_later': '3 Ngày',
          'this_sunday': 'Chủ nhật',
          'choose_date': 'Chọn',
          'add_category': 'Thêm',
          'add_new_category': 'Danh mục mới',
          'enter_category_name': 'Nhập tên danh mục',
          'add': 'Thêm',
          // Task Detail
          'task_detail': 'Chi tiết công việc',
          'delete_task': 'Xóa việc',
          'delete_confirm': 'Bạn có chắc muốn xóa việc này?',
          'task_deleted': 'Đã xóa việc',
          'status': 'Trạng thái',
          'created': 'Ngày tạo',
          'last_updated': 'Cập nhật lần cuối',
          'task_completed': 'Đã hoàn thành!',
          'task_marked_todo': 'Đã đánh dấu chưa làm',

          // Focus Screen
          'focus_title': 'Chế độ tập trung',
          'pomodoro_timer': 'Đồng hồ Pomodoro',
          'start': 'Bắt đầu',
          'pause': 'Tạm dừng',
          'reset': 'Đặt lại',
          'select_task': 'Chọn nhiệm vụ',
          'change_task': 'Đổi nhiệm vụ',
          'focus_completed': 'Hoàn thành Pomodoro! Tuyệt vời! 🎉',

          // Profile Screen
          'profile_title': 'Hồ sơ',
          'nc_user': 'Người dùng Lịch Thông Minh',
          'settings': 'Cài đặt',
          'dark_mode': 'Chế độ tối',
          'toggle_theme': 'Bật/tắt giao diện tối',
          'language': 'Ngôn ngữ',
          'reports_analytics': 'Báo cáo & Thống kê',
          'view_statistics': 'Xem thống kê của bạn',
          'backup_restore': 'Sao lưu & Khôi phục',
          'manage_data': 'Quản lý dữ liệu của bạn',
          'data': 'Dữ liệu',
          'clear_all_data': 'Xóa tất cả dữ liệu',
          'clear_warning': 'Hành động này không thể hoàn tác',
          'clear_confirm_title': 'Xóa tất cả dữ liệu?',
          'clear_confirm_msg':
              'Điều này sẽ xóa tất cả công việc và cài đặt của bạn. Hành động này không thể hoàn tác.',
          'all_data_cleared': 'Đã xóa tất cả dữ liệu',
          'version': 'Lịch Thông Minh v1.0.0',
          'select_language': 'Chọn ngôn ngữ',
          'language_changed':
              'Ngôn ngữ đã được thay đổi. Khởi động lại app để áp dụng.',

          // Report Screen
          'report_title': 'Báo cáo & Thống kê',
          'today_stats': 'Hôm nay',
          'weekly_stats': 'Tuần này',
          'tasks_completed': 'Công việc',
          'minutes_focused': 'Phút',
          'hours_focused': 'Giờ',
          'week_completion_rate': 'Tỉ lệ hoàn thành',
          'insights': 'Thông tin chi tiết',
          'top_category': 'Danh mục hàng đầu',
          'most_productive_day': 'Ngày hiệu quả nhất',
          'weekly_activity': 'Hoạt động trong tuần',
          'daily_streak': 'Chuỗi ngày',

          // Task Status
          'todo': 'CHƯA LÀM',
          'in_progress': 'ĐANG LÀM',
          'done': 'HOÀN THÀNH',

          // Search & Filter
          'search_tasks': 'Tìm kiếm công việc...',
          'clear_filters': 'Xóa bộ lọc',
          'no_results': 'Không tìm thấy kết quả',

          // Recurrence
          'recurrence': 'Lặp lại',
          'none': 'Không',
          'daily': 'Hàng ngày',
          'weekly': 'Hàng tuần',
          'monthly': 'Hàng tháng',

          // Reminder
          'reminder': 'Nhắc nhở',
          'no_reminder': 'Không nhắc',
          '5_min_before': '5 phút trước',
          '15_min_before': '15 phút trước',
          '30_min_before': '30 phút trước',
          '1_hour_before': '1 giờ trước',

          // Achievements
          'achievements': 'Thành tích',
          'view_achievements': 'Xem thành tích của bạn',
          'achievement_unlocked': 'Mở khóa thành tích!',
          'unlocked_on': 'Mở khóa vào',
          'achievement_streak_7_title': 'Chuỗi 7 ngày',
          'achievement_streak_7_desc':
              'Hoàn thành công việc trong 7 ngày liên tiếp',
          'achievement_tasks_100_title': 'Bậc thầy 100 việc',
          'achievement_tasks_100_desc': 'Hoàn thành 100 công việc',
          'achievement_focus_10_title': 'Nhà vô địch tập trung',
          'achievement_focus_10_desc': 'Hoàn thành 10 phiên tập trung',
          'achievement_streak_30_title': 'Chiến binh 30 ngày',
          'achievement_streak_30_desc':
              'Hoàn thành công việc trong 30 ngày liên tiếp',
          'achievement_tasks_500_title': 'Huyền thoại công việc',
          'achievement_tasks_500_desc': 'Hoàn thành 500 công việc',
          'achievement_focus_50h_title': 'Bậc thầy tập trung',
          'achievement_focus_50h_desc': 'Hoàn thành 50 giờ tập trung',

          // Daily Summary
          'end_of_day_summary': 'Tổng kết cuối ngày',
          'focus_time': 'Thời gian tập trung',
          'summary_excellent':
              'Công việc tuyệt vời hôm nay! Tiếp tục phát huy! 🎉',
          'summary_good': 'Tiến bộ tốt hôm nay! 👍',
          'summary_keep_going': 'Mỗi ngày là một cơ hội mới! 💪',
          'close': 'Đóng',
          'amazing': 'Tuyệt vời',
          'days': 'ngày',
          'streak_milestone': 'Đạt mốc chuỗi:',
          'streak_broken': 'Chuỗi đã gián đoạn',
          'motivational_title': 'Động lực',

          // Motivational Messages
          'motivational_msg_1': 'Bạn có khả năng làm những điều tuyệt vời!',
          'motivational_msg_2': 'Tiến bộ, không phải hoàn hảo.',
          'motivational_msg_3': 'Những bước nhỏ dẫn đến kết quả lớn.',
          'motivational_msg_4': 'Hãy tin vào bản thân!',
          'motivational_msg_5': 'Bạn làm được! 💪',
          'motivational_msg_6': 'Tập trung vào những gì bạn có thể kiểm soát.',
          'motivational_msg_7':
              'Thành công là hành trình, không phải đích đến.',
          'motivational_msg_8': 'Hãy tạo nên một ngày ý nghĩa!',
          'motivational_low_productivity_1':
              'Mỗi công việc hoàn thành là tiến bộ. Tiếp tục!',
          'motivational_low_productivity_2':
              'Bạn vẫn còn thời gian để làm ngày hôm nay hiệu quả!',
          'motivational_low_productivity_3':
              'Tiến bộ nhỏ vẫn là tiến bộ. Đừng bỏ cuộc!',
          'motivational_streak_broken_1':
              'Không sao! Bắt đầu chuỗi mới hôm nay. 💪',
          'motivational_streak_broken_2':
              'Mọi nhà vô địch đều từng ngã. Điều quan trọng là đứng dậy!',
          'motivational_streak_broken_3':
              'Khởi đầu mới! Hãy xây dựng chuỗi tốt hơn!',
          'motivational_encouragement_1':
              'Dành chút thời gian tập trung. Bạn làm được!',
          'motivational_encouragement_2':
              'Một chút thời gian tập trung sẽ tạo nên khác biệt!',
          'motivational_encouragement_3': 'Đã đến lúc vào trạng thái! 🎯',

          // Smart Suggestions
          'smart_suggestions': 'Gợi ý Thông minh',
          'suggestion_overload_title': 'Quá Nhiều Công việc',
          'suggestion_overload_message':
              'Bạn có quá nhiều công việc hôm nay. Xem xét lại lịch trình.',
          'suggestion_reschedule_some': 'Hoãn Một Số',
          'suggestion_overdue_title': 'Công việc Quá Hạn',
          'suggestion_overdue_message':
              'Bạn có công việc quá hạn. Muốn lên lịch lại?',
          'suggestion_reschedule': 'Lên Lịch Lại',
          'suggestion_focus_title': 'Thời Gian Tập Trung',
          'suggestion_focus_message':
              'Bạn chưa tập trung nhiều hôm nay. Bắt đầu phiên làm việc?',
          'suggestion_start_focus': 'Bắt Đầu',
          'suggestion_break_title': 'Nghỉ Ngơi',
          'suggestion_break_message':
              'Bạn đã làm việc lâu rồi. Hãy nghỉ ngơi chút.',
          'suggestion_take_break': 'Đồng ý',

          // Behavior Insights
          'insight_frequent_delays': 'Trì Hoãn Thường Xuyên',
          'insight_frequent_delays_message':
              'Bạn thường trì hoãn công việc. Thử đặt thời gian thực tế hơn.',
          'insight_frequent_reschedules': 'Lên Lịch Lại Thường Xuyên',
          'insight_frequent_reschedules_message':
              'Bạn thường xuyên lên lịch lại. Hãy dành thêm thời gian dự phòng.',
          'insight_low_task_completion': 'Hoàn Thành Ít',
          'insight_productive_hours': 'Giờ Làm Việc Hiệu Quả',
          'insight_productive_hours_message':
              'Bạn làm việc hiệu quả nhất vào các giờ này. Lên lịch công việc quan trọng.',
          'insight_low_focus_usage': 'Ít Sử Dụng Tính Năng Tập Trung',
          'insight_low_focus_usage_message':
              'Thử dùng phiên tập trung để cải thiện chú ý.',
        },
      };
}
