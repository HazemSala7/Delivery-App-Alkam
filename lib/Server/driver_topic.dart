import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-driver FCM topic so a targeted order push reaches *every* device the
/// driver is logged in on (Android + iPhone + tablets), and survives FCM token
/// rotation — without storing a list of tokens server-side.
///
/// Each device subscribes to `driver_<salesmanId>` on login / app start and
/// unsubscribes on logout. The backend sends the targeted notification to that
/// same topic.
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

  /// Subscribe using the salesmanId already stored in prefs (used on app start
  /// when the driver is already logged in).
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
