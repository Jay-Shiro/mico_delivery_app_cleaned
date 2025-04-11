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

func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
    guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
        print("Source type \(sourceType) not available.")
        return
    }

    let picker = UIImagePickerController()
    picker.sourceType = sourceType
    picker.allowsEditing = false

    if #available(iOS 13.0, *) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            // ✅ Prevent crash on iPad by setting up popoverPresentationController
            if let popoverController = picker.popoverPresentationController {
                popoverController.sourceView = rootVC.view
                popoverController.sourceRect = CGRect(x: rootVC.view.bounds.midX,
                                                      y: rootVC.view.bounds.midY,
                                                      width: 0,
                                                      height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            rootVC.present(picker, animated: true, completion: nil)
        } else {
            print("Failed to get root view controller.")
        }
    } else {
        // Fallback on earlier versions
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
