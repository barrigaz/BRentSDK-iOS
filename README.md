# BRentSDK

[![Version](https://img.shields.io/cocoapods/v/BRentSDK.svg?style=flat)](http://cocoapods.org/pods/BRentSDK)


## Table of contents
- [Introduction](#introduction)
- [Requirements](#requirements)
- [Integration](#integration)

## Introduction
BRentSDK made for [barrigaz.app](https://barrigaz.app/) rent service.

In order for us to provide optimal support, we would kindly ask you to submit any issues to this github repo.

## Requirements
- iOS 12.0+
- [FacebookCore](https://github.com/facebook/facebook-ios-sdk)
- [Firebase](https://github.com/firebase/firebase-ios-sdk) (Analytics + Messaging)
- [AppsFlyerFramework](https://github.com/AppsFlyerSDK/AppsFlyerFramework)
- [SentrySDK](https://github.com/getsentry/sentry-cocoa)

## Integration

### iOS Swift projects integration

* Add Push Notification and Background Modes (Remote Fetch) Capabilities to your app.
* Add following lines to your target in Podfile

```ruby
  pod 'Firebase/Analytics'  
  pod 'Firebase/Messaging'
  pod 'FacebookCore'
  pod 'AppsFlyerFramework'
  pod 'Sentry'
  pod 'BRentSDK'
```

* Run `pod update`
* Add BRentSDK-Info.plist and GoogleService-Info.plist to your project. Make sure that  `Target Membership` property for them is set to your app's main target.
* Copy code from Info-addition.txt, open your Info.plist as source code and paste below last two lines. Info-addition.txt example: 

```xml
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>None</string>
			<key>CFBundleURLName</key>
			<string></string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>YOUR_CUSTOM_URL_SCHEME</string>
				<string>fb1234567890</string>
			</array>
		</dict>
	</array>
    <key>FacebookAdvertiserIDCollectionEnabled</key>
	<true/>
	<key>FacebookAppID</key>
	<string>1234567890</string>
	<key>FacebookAutoLogAppEventsEnabled</key>
	<true/>
	<key>FacebookDisplayName</key>
	<string>$(PRODUCT_NAME)</string>
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>
```

* Add BRentSDK initialization in AppDelegate's `application:didFinishLaunchingWithOptions`:

```swift
import FacebookCore
import FirebaseCore
import FirebaseAnalytics
import FirebaseMessaging
import AppsFlyerLib
import BRentSDK
import Sentry

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        BRentSDK.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Your initialization here
        
        // SplashScreen adding
		window?.rootViewController?.view.addSubview(SplashScreen.sharedWithOptions(tintColor: .green, hideNotification: .hideSplash))
		
		configureTrackers()
		
        return true
    }
```

* Implement delegate methods and other SDK's initialization code:

```swift
extension AppDelegate: BRentSDKDelegate {
    
    func issue(isError: Bool, message: String, extra: [String : Any]?) {
    	// warnings and errors handling
    	let event = Event(level: isError ? .error : .info)
        event.message = message
        event.extra = extra
        SentrySDK.capture(event: event)
    }
    
    func event(eventName: String, parameters: [String: Any]?) {
		// FacebookSDK events handling
		AppEvents.logEvent(AppEvents.Name(rawValue: eventName), parameters: parameters ?? [:])
    }
    
    func pause() {
    	// app pausing events handling like sound muting
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return BRentSDK.orientationMask
    }
    
    func configureTrackers() {
        configureFB()
        configureAF()
        configureFIR()
        configureSY()
    }
    
    func configureFIR() {
        
        FirebaseApp.configure()
        Analytics.logEvent("click", parameters: nil)
        
        Messaging.messaging().delegate = self
        // For iOS 10 display notification (sent via APNS)
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        
        UIApplication.shared.registerForRemoteNotifications()
        
    }
    
    func configureFB() {
        Settings.isAutoLogAppEventsEnabled = true
        AppLinkUtility.fetchDeferredAppLink(BRentSDK.handleFBLink)
    }
    
    func configureAF() {
        AppsFlyerTracker.shared().appsFlyerDevKey = BRentSDK.keys["AppsFlyer"]!
        AppsFlyerTracker.shared().appleAppID = BRentSDK.keys["StoreAppId"]!
        AppsFlyerTracker.shared().delegate = self
        
        #if DEBUG
        AppsFlyerTracker.shared().isDebug = true
        #endif
        BRentSDK.setAfid(afid: AppsFlyerTracker.shared().getAppsFlyerUID())
    }
    
    func configureSY() {
        SentrySDK.start { options in
            options.dsn = BRentSDK.keys["Sentry"]!
            #if DEBUG
            options.debug = true
            #endif
        }
    }
}
```

* Add AppsFlyer and FirebaseMessaging delegate methods to the bottom of AppDelegate:

```swift


extension AppDelegate: AppsFlyerTrackerDelegate {
    
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
        BRentSDK.handleAFLink(conversionInfo)
    }
    
    func onConversionDataFail(_ error: Error) {
        BRentSDK.handleAFLink([:])
    }
    
    // Reports app open from a Universal Link for iOS 9 or later
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerTracker.shared().continue(userActivity, restorationHandler: nil)
        return true
    }
    
    // Reports app open from deep link from apps which do not support Universal Links (Twitter) and for iOS8 and below
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        AppsFlyerTracker.shared().handleOpen(url, sourceApplication: sourceApplication, withAnnotation: annotation)
        return true
    }
    
    // Reports app open from deep link for iOS 10 or later
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AppsFlyerTracker.shared().handleOpen(url, options: options)
        return true
    }
}

// [START ios_10_message_handling]
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")
        
        // With swizzling disabled you must set the APNs token here.
        // Messaging.messaging().apnsToken = deviceToken
    }
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler()
    }
}
// [END ios_10_message_handling]


extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        BRentSDK.setPushToken(fcmToken)
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    // [END refresh_token]
    
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}
```
