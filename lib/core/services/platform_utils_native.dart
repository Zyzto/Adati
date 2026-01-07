import 'dart:io' show Platform;

bool get isDesktop => Platform.isLinux || Platform.isWindows || Platform.isMacOS;
bool get isIOS => Platform.isIOS;
bool get isAndroid => Platform.isAndroid;
bool get isMobile => Platform.isAndroid || Platform.isIOS;

