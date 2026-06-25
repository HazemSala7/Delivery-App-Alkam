import UIKit
import Flutter
// import GoogleMaps  // DISABLED for debugging
// import FirebaseCore  // DISABLED for debugging
// import FirebaseMessaging  // DISABLED for debugging
import UserNotifications
// import Firebase  // DISABLED for debugging

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  let gcmMessageIDKey = "gcm.message_id"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // DISABLED: Everything to test bare Flutter
    // GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Push Notifications Setup

  // DISABLED: Firebase - plugin disabled
  // func registerForPushNotifications() {
  //   if #available(iOS 10.0, *) {
  //     UNUserNotificationCenter.current().delegate = self
  //     UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
  //       print("Permission granted: \(granted)")
  //       guard granted else { return }
  //       self.getNotificationSettings()
  //     }
  //   } else {
  //     let settings = UIUserNotificationSettings(types: [.alert, .sound, .badge], categories: nil)
  //     UIApplication.shared.registerUserNotificationSettings(settings)
  //     UIApplication.shared.registerForRemoteNotifications()
  //   }
  // }

  // func getNotificationSettings() {
  //   UNUserNotificationCenter.current().getNotificationSettings { settings in
  //     print("Notification settings: \(settings)")
  //     guard settings.authorizationStatus == .authorized else { return }
  //     DispatchQueue.main.async {
  //       UIApplication.shared.registerForRemoteNotifications()
  //     }
  //   }
  // }

  // MARK: - Firebase Messaging Delegate

  // DISABLED: Firebase - plugin disabled
  // func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
  //   print("Firebase registration token: \(String(describing: fcmToken))")
  //   let dataDict: [String: String] = ["token": fcmToken ?? ""]
  //   NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
  // }

  // MARK: - Handle Remote Notifications

  // DISABLED: Firebase - plugin disabled
  // override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
  //   if let messageID = userInfo[gcmMessageIDKey] {
  //     print("Message ID: \(messageID)")
  //   }
  //   print(userInfo)
  //   Messaging.messaging().appDidReceiveMessage(userInfo)
  //   completionHandler(.newData)
  // }

  // @available(iOS 10.0, *)
  // override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
  //   let userInfo = notification.request.content.userInfo
  //   if let messageID = userInfo[gcmMessageIDKey] {
  //     print("Message ID: \(messageID)")
  //   }
  //   print(userInfo)
  //   Messaging.messaging().appDidReceiveMessage(userInfo)
  //   completionHandler([.alert, .sound])
  // }

  // @available(iOS 10.0, *)
  // override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
  //   let userInfo = response.notification.request.content.userInfo
  //   if let messageID = userInfo[gcmMessageIDKey] {
  //     print("Message ID: \(messageID)")
  //   }
  //   print(userInfo)
  //   Messaging.messaging().appDidReceiveMessage(userInfo)
  //   completionHandler()
  // }

  // override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
  //   if let messageID = userInfo[gcmMessageIDKey] {
  //     print("Message ID: \(messageID)")
  //   }
  //   print(userInfo)
  //   Messaging.messaging().appDidReceiveMessage(userInfo)
  // }
}
