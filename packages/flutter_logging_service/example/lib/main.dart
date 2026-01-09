import 'package:flutter/material.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging service FIRST (before any other services)
  await LoggingService.init(
    LoggingConfig(
      appName: 'LoggingExample',
      logFileName: 'example.log',
      crashLogFileName: 'example_crashes.log',
      // Optional: customize settings
      maxLogFileSize: 2 * 1024 * 1024, // 2MB
      maxLogFiles: 3,
      enableAggregation: true,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logging Service Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoggingExamplePage(),
    );
  }
}

class LoggingExamplePage extends StatefulWidget {
  const LoggingExamplePage({super.key});

  @override
  State<LoggingExamplePage> createState() => _LoggingExamplePageState();
}

class _LoggingExamplePageState extends State<LoggingExamplePage>
    with Loggable {
  String _logContent = '';
  String? _logFilePath;
  String? _crashLogFilePath;
  int _logFileSize = 0;
  int _crashLogFileSize = 0;

  @override
  void initState() {
    super.initState();
    _loadLogInfo();
  }

  Future<void> _loadLogInfo() async {
    try {
      _logFilePath = await LoggingService.getLogFilePath();
      _crashLogFilePath = await LoggingService.getCrashLogFilePath();
      _logFileSize = await LoggingService.getLogFileSize();
      _crashLogFileSize = await LoggingService.getCrashLogFileSize();
      setState(() {});
    } catch (e) {
      logError('Failed to load log info', error: e);
    }
  }

  Future<void> _loadLogContent() async {
    try {
      final content = await LoggingService.getLogContent(maxLines: 100);
      setState(() {
        _logContent = content;
      });
    } catch (e) {
      logError('Failed to load log content', error: e);
      setState(() {
        _logContent = 'Error: $e';
      });
    }
  }

  void _testLogging() {
    // Using Log helper (automatic component detection)
    Log.debug('This is a debug message');
    Log.info('This is an info message');
    Log.warning('This is a warning message');
    Log.error('This is an error message');
    Log.severe('This is a severe error message');

    // Using Loggable mixin (automatic component detection from class)
    logDebug('Debug from Loggable mixin');
    logInfo('Info from Loggable mixin');
    logWarning('Warning from Loggable mixin');
    logError('Error from Loggable mixin');
    logSevere('Severe error from Loggable mixin');

    // Using LoggingService directly (with explicit component)
    LoggingService.debug('Direct debug call', component: 'CustomComponent');
    LoggingService.info('Direct info call', component: 'CustomComponent');
    LoggingService.warning('Direct warning call', component: 'CustomComponent');
    LoggingService.error('Direct error call', component: 'CustomComponent');
    LoggingService.severe('Direct severe call', component: 'CustomComponent');

    // Test error logging with exception
    try {
      throw Exception('Test exception');
    } catch (e, stackTrace) {
      Log.error('Caught an exception', error: e, stackTrace: stackTrace);
    }

    // Test aggregation (multiple similar messages)
    for (int i = 0; i < 15; i++) {
      Log.info('Processing item $i');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test logs written! Check the log viewer below.'),
        duration: Duration(seconds: 2),
      ),
    );

    _loadLogInfo();
    _loadLogContent();
  }

  Future<void> _exportLogs() async {
    try {
      final path = await LoggingService.exportLogs();
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logs exported to: $path'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      logError('Failed to export logs', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _clearLogs() async {
    try {
      final cleared = await LoggingService.clearLogs();
      if (cleared && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logs cleared successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        _loadLogInfo();
        _loadLogContent();
      }
    } catch (e) {
      logError('Failed to clear logs', error: e);
    }
  }

  Future<void> _rotateLogs() async {
    try {
      final rotated = await LoggingService.rotateAndCleanupLogs();
      if (rotated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logs rotated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        _loadLogInfo();
        _loadLogContent();
      }
    } catch (e) {
      logError('Failed to rotate logs', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logging Service Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log File Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_logFilePath != null) ...[
                      Text('Main Log: $_logFilePath'),
                      Text('Size: ${(_logFileSize / 1024).toStringAsFixed(2)} KB'),
                    ],
                    if (_crashLogFilePath != null) ...[
                      const SizedBox(height: 4),
                      Text('Crash Log: $_crashLogFilePath'),
                      Text('Size: ${(_crashLogFileSize / 1024).toStringAsFixed(2)} KB'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _testLogging,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Test Logging'),
                ),
                ElevatedButton.icon(
                  onPressed: _loadLogContent,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Logs'),
                ),
                ElevatedButton.icon(
                  onPressed: _exportLogs,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Logs'),
                ),
                ElevatedButton.icon(
                  onPressed: _rotateLogs,
                  icon: const Icon(Icons.rotate_right),
                  label: const Text('Rotate Logs'),
                ),
                ElevatedButton.icon(
                  onPressed: _clearLogs,
                  icon: const Icon(Icons.delete),
                  label: const Text('Clear Logs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Log Content
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Log Content (last 100 lines)',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadLogContent,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _logContent.isEmpty
                              ? 'No log content. Click "Test Logging" to generate logs.'
                              : _logContent,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
