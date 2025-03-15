import Flutter
import UIKit
import GoogleMaps
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Set notification delegate
    UNUserNotificationCenter.current().delegate = self

    // Provide Google Maps API Key
    GMSServices.provideAPIKey("AIzaSyAGpi5xRhCSbDFkoj25FlDkzGXDhILXRow")

    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}


// extension AppDelegate: UNUserNotificationCenterDelegate {
//   // Handle notifications when app is in foreground
//   func userNotificationCenter(
//     _ center: UNUserNotificationCenter,
//     willPresent notification: UNNotification,
//     withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
//   ) {
//     completionHandler([.alert, .badge, .sound])
//   }
// }