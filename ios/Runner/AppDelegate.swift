import UIKit
import Flutter
import GoogleMaps
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import uni_links2

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
  
  let gcmMessageIDKey = "gcm.message_id"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase
    FirebaseApp.configure()
    // Register for remote notifications
    registerForPushNotifications()
    // Set Messaging delegate
    Messaging.messaging().delegate = self

    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyC86lWEI5fMklifz509ZmHUyGpj1AuplUA")

    if let launchOptions = launchOptions,
       let userActivityDictionary = launchOptions[UIApplication.LaunchOptionsKey.userActivityDictionary] as? [String: Any],
       let userActivity = userActivityDictionary["UIApplicationLaunchOptionsUserActivityKey"] as? NSUserActivity,
       userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let incomingURL = userActivity.webpageURL {
        _ = handleIncomingURL(incomingURL)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if handleIncomingURL(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let incomingURL = userActivity.webpageURL {
      if handleIncomingURL(incomingURL) {
        return true
      }
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }

  private func handleIncomingURL(_ url: URL) -> Bool {
    guard let flutterViewController = window?.rootViewController as? FlutterViewController else {
      return false
    }

    let channel = FlutterMethodChannel(name: "co.j-food.perfect/uni_links",
                                       binaryMessenger: flutterViewController.binaryMessenger)
    channel.invokeMethod("onLink", arguments: url.absoluteString)
    return true
  }
  
  // MARK: - Push Notifications Setup

  func registerForPushNotifications() {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        print("Permission granted: \(granted)")
        guard granted else { return }
        self.getNotificationSettings()
      }
    } else {
      let settings = UIUserNotificationSettings(types: [.alert, .sound, .badge], categories: nil)
      UIApplication.shared.registerUserNotificationSettings(settings)
      UIApplication.shared.registerForRemoteNotifications()
    }
  }

  func getNotificationSettings() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      print("Notification settings: \(settings)")
      guard settings.authorizationStatus == .authorized else { return }
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }

  // MARK: - Firebase Messaging Delegate

  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
  }

  // MARK: - Handle Remote Notifications

  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    if let messageID = userInfo[gcmMessageIDKey] {
      print("Message ID: \(messageID)")
    }
    print(userInfo)
    Messaging.messaging().appDidReceiveMessage(userInfo)
    completionHandler(.newData)
  }

  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    if let messageID = userInfo[gcmMessageIDKey] {
      print("Message ID: \(messageID)")
    }
    print(userInfo)
    Messaging.messaging().appDidReceiveMessage(userInfo)
    completionHandler([.alert, .sound])
  }

  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    if let messageID = userInfo[gcmMessageIDKey] {
      print("Message ID: \(messageID)")
    }
    print(userInfo)
    Messaging.messaging().appDidReceiveMessage(userInfo)
    completionHandler()
  }

  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
    if let messageID = userInfo[gcmMessageIDKey] {
      print("Message ID: \(messageID)")
    }
    print(userInfo)
    Messaging.messaging().appDidReceiveMessage(userInfo)
  }
}
