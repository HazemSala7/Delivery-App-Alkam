// NOTE: Firebase messaging is disabled in this build (see the commented-out
// firebase_* deps in pubspec.yaml) to keep the iOS build working. This is a
// no-op stub that preserves the original API so call sites keep compiling.
// Re-enable firebase_messaging and restore the real implementation (see git
// history of commit a852849 "fix some issues") when bringing Firebase back.
class DriverTopic {
  DriverTopic._();

  /// Topic names allow [a-zA-Z0-9-_.~%]; salesmanId is numeric so this is safe.
  static String topicFor(String salesmanId) => 'driver_$salesmanId';

  static Future<void> subscribe(String salesmanId) async {
    // no-op: Firebase messaging disabled
  }

  static Future<void> subscribeForCurrentUser() async {
    // no-op: Firebase messaging disabled
  }

  static Future<void> unsubscribeForCurrentUser() async {
    // no-op: Firebase messaging disabled
  }
}
