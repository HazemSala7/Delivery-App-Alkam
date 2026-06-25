import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-driver FCM topic so a targeted order push reaches *every* device the
/// driver is logged in on, and survives FCM token rotation. The backend sends
/// the targeted notification to `driver_<salesmanId>` (= the users-table id).
class DriverTopic {
  DriverTopic._();

  /// Topic names allow [a-zA-Z0-9-_.~%]; salesmanId is numeric so this is safe.
  static String topicFor(String salesmanId) => 'driver_$salesmanId';

  static Future<void> subscribe(String salesmanId) async {
    final id = salesmanId.trim();
    if (id.isEmpty) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topicFor(id));
    } catch (_) {}
  }

  static Future<void> subscribeForCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await subscribe(prefs.getString('salesmanId') ?? '');
  }

  static Future<void> unsubscribeForCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = (prefs.getString('salesmanId') ?? '').trim();
    if (id.isEmpty) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topicFor(id));
    } catch (_) {}
  }
}
