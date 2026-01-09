# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2025-01-XX

### Added
- Initial release of flutter_logging_service package
- LoggingService with file persistence and log rotation
- LogHelper for convenient static logging with auto component detection
- LoggableMixin for automatic component detection in classes
- LoggingConfig for customizable configuration
- Support for log aggregation to reduce noise
- Separate crash log file for severe errors
- Cross-platform support (Android, iOS, Linux, macOS, Windows, Web)

### Features
- File-based logging with automatic rotation
- Configurable log file names and sizes
- Log level filtering (DEBUG, INFO, WARNING, ERROR, SEVERE)
- Automatic component name detection from stack traces
- Log export functionality
- Manual log rotation and cleanup
