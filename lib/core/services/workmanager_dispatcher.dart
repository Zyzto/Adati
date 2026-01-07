import 'package:workmanager/workmanager.dart';
import 'package:adati/core/services/reminder_checker.dart';
import 'package:adati/core/services/log_helper.dart';
import 'package:adati/features/habits/habit_repository.dart';
import 'package:adati/core/database/app_database.dart' as db;

/// WorkManager callback dispatcher
/// This is the entry point for background tasks scheduled by WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    Log.info('WorkManager task started: $task');
    
    try {
      // Initialize database and repository in background context
      // Note: This needs to be done in the background isolate
      // Use the same pattern as main.dart - create AppDatabase with default connection
      Log.debug('WorkManager: Initializing database and repository');
      final appDatabase = db.AppDatabase();
      final repository = HabitRepository(appDatabase);
      
      // Check for due reminders and show notifications
      Log.debug('WorkManager: Starting reminder check');
      await ReminderChecker.checkAndShowDueReminders(repository);
      Log.debug('WorkManager: Completed reminder check');
      
      Log.info('WorkManager task completed successfully: $task');
      return Future.value(true);
    } catch (e, stackTrace) {
      Log.error(
        'WorkManager task failed: $task',
        error: e,
        stackTrace: stackTrace,
      );
      return Future.value(false);
    }
  });
}
