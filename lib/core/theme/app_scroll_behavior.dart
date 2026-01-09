import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

/// Custom scroll behavior that enables mouse drag support on desktop platforms.
///
/// By default, Flutter's [MaterialScrollBehavior] only allows drag gestures for
/// touch devices, stylus, and inverted stylus. It does not include mouse input,
/// which prevents users from dragging scrollable widgets (like PageView) with
/// a mouse on desktop platforms (Linux, Windows, macOS).
///
/// This custom behavior extends [MaterialScrollBehavior] and includes mouse and
/// trackpad in the allowed drag devices, enabling:
/// - Click and hold to drag PageView slides
/// - Mouse drag for all scrollable widgets
/// - Trackpad gestures support
///
/// This is applied globally to the app via [MaterialApp.scrollBehavior].
class AppScrollBehavior extends MaterialScrollBehavior with Loggable {
  AppScrollBehavior() {
    logDebug('AppScrollBehavior initialized');
  }

  @override
  Set<PointerDeviceKind> get dragDevices {
    logDebug('AppScrollBehavior.dragDevices accessed');
    return {
      PointerDeviceKind.touch,
      PointerDeviceKind.mouse,
      PointerDeviceKind.stylus,
      PointerDeviceKind.invertedStylus,
      PointerDeviceKind.trackpad,
    };
  }
}

