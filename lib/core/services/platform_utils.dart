// Conditional import for platform detection
export 'platform_utils_stub.dart'
    if (dart.library.io) 'platform_utils_native.dart'
    if (dart.library.html) 'platform_utils_web.dart';

