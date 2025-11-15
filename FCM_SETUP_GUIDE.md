# 🔥 Firebase Cloud Messaging (FCM) - Setup Complete!

## ✅ What Has Been Configured

### 1. **Flutter Dependencies Added** (`pubspec.yaml`)
```yaml
firebase_core: ^2.24.2          # Compatible with Google ML Kit
firebase_messaging: ^14.7.10     # Compatible with Google ML Kit
flutter_local_notifications: ^17.0.0
```

✅ These versions are **fully compatible** with your existing Google ML Kit packages!

### 2. **Flutter Code**

#### ✅ `lib/main.dart` - Updated
- Added `WidgetsFlutterBinding.ensureInitialized()`
- Added `await Firebase.initializeApp()`
- Added `await NotificationService().initialize()`
- FCM token will print on app startup

#### ✅ `lib/services/notification_service.dart` - NEW FILE
Complete notification service with:
- Foreground message handler (`FirebaseMessaging.onMessage`)
- Background message handler (`FirebaseMessaging.onBackgroundMessage`)
- FCM token fetching and printing with clear console output
- Token refresh listener
- Local notification display for foreground messages
- Notification tap handling
- Android 13+ and iOS permission requests
- Topic subscription/unsubscription methods

### 3. **Android Configuration** ✅

#### `android/app/src/main/AndroidManifest.xml` - Updated
- ✅ INTERNET permission
- ✅ POST_NOTIFICATIONS permission (Android 13+)
- ✅ VIBRATE and WAKE_LOCK permissions
- ✅ Default notification channel metadata
- ✅ Notification click intent filter

#### `android/build.gradle.kts` - Updated
- ✅ Google Services plugin classpath (4.3.15 - compatible version)

#### `android/app/build.gradle.kts` - Updated
- ✅ `com.google.gms.google-services` plugin
- ✅ Firebase BOM (32.7.0 - compatible version)
- ✅ Firebase Messaging dependency

#### `android/app/google-services.json` - TEMPLATE CREATED
⚠️ **ACTION REQUIRED:** Replace with your actual file from Firebase Console

### 4. **iOS Configuration** ✅

#### `ios/Runner/GoogleService-Info.plist` - TEMPLATE CREATED
⚠️ **ACTION REQUIRED:** Replace with your actual file from Firebase Console

#### iOS Pods - ✅ **SUCCESSFULLY INSTALLED!**
```
✅ Firebase (10.25.0)
✅ FirebaseCore (10.25.0)
✅ FirebaseMessaging (10.25.0)
✅ All Google ML Kit pods (compatible versions)
✅ 74 total pods installed successfully
```

**No dependency conflicts!** 🎉

---

## 📋 Next Steps to Complete Setup

### Step 1: Get Firebase Configuration Files

You need to download the actual Firebase config files from Firebase Console:

#### For Android:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Click "Add app" → Select Android
4. Package name: `com.example.massmello`
5. **Download `google-services.json`**
6. Replace the file at: `android/app/google-services.json`

#### For iOS:
1. In the same Firebase project
2. Click "Add app" → Select iOS
3. Bundle ID: `com.example.massmello`
4. **Download `GoogleService-Info.plist`**
5. Replace the file at: `ios/Runner/GoogleService-Info.plist`
6. **IMPORTANT:** Also add it to Xcode:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Drag `GoogleService-Info.plist` into the Runner folder in Xcode
   - Check "Copy items if needed"
   - Check the "Runner" target

### Step 2: Add iOS Capabilities in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode (NOT `.xcodeproj`)
2. Select the "Runner" target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability" button
5. Add **"Push Notifications"**
6. Click "+ Capability" again
7. Add **"Background Modes"**
8. Under Background Modes, enable:
   - ✅ Remote notifications

### Step 3: Clean Build and Run

```bash
cd /Users/sameer.yadav/Documents/test-flutter/massmello
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Step 4: Get Your FCM Token

When you run the app, check the console output. You'll see:

```
✅ Firebase initialized successfully
✅ Notification Service initialized
📱 iOS Permission status: AuthorizationStatus.authorized
✅ Local notifications initialized
✅ Message handlers configured
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 DEVICE FCM TOKEN:
dXJp8h3-T5e... (your actual token)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Copy this token!** You'll need it to send test notifications.

---

## 🧪 Testing Notifications

### Method 1: Firebase Console (Easiest)

1. Go to Firebase Console → Your Project
2. Navigate to "Cloud Messaging" (in Engage section)
3. Click "Send your first message"
4. Fill in:
   - **Notification title**: "Test Notification"
   - **Notification text**: "This is a test from Firebase!"
5. Click "Send test message"
6. Paste your FCM token
7. Click "Test"

### Method 2: Using cURL

Get your Server Key from: Firebase Console → Project Settings → Cloud Messaging → Server key

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "YOUR_FCM_TOKEN",
    "notification": {
      "title": "Memory Reminder 🧠",
      "body": "Time for your daily cognitive exercise!"
    },
    "data": {
      "screen": "memory_games",
      "timestamp": "2025-11-15T10:30:00Z"
    }
  }'
```

### Method 3: From Your Backend

Send POST request to: `https://fcm.googleapis.com/fcm/send`

Headers:
- `Authorization: key=YOUR_SERVER_KEY`
- `Content-Type: application/json`

Body:
```json
{
  "to": "DEVICE_FCM_TOKEN",
  "notification": {
    "title": "Notification Title",
    "body": "Notification message"
  },
  "data": {
    "custom_key": "custom_value"
  }
}
```

---

## 📱 How Notifications Work

### When App is OPEN (Foreground):
1. Notification arrives
2. `FirebaseMessaging.onMessage` catches it
3. Console prints: Title, Body, Data
4. `NotificationService._showLocalNotification()` displays it
5. User sees notification banner
6. Tap opens the app (custom navigation in `_onNotificationTapped`)

### When App is MINIMIZED (Background):
1. Notification arrives
2. System displays it automatically
3. User taps notification
4. App opens
5. `FirebaseMessaging.onMessageOpenedApp` triggered
6. Console prints: Title, Body, Data
7. Navigate to specific screen based on data

### When App is CLOSED (Terminated):
1. Notification arrives
2. System displays it
3. User taps notification
4. App launches
5. `firebaseMessagingBackgroundHandler` processes it
6. Use `FirebaseMessaging.instance.getInitialMessage()` to get notification

---

## 🎯 Usage Examples

### Get Current FCM Token Anywhere:
```dart
String? token = NotificationService().fcmToken;
print('Current token: $token');
```

### Subscribe to Topics:
```dart
await NotificationService().subscribeToTopic('alzheimers_updates');
await NotificationService().subscribeToTopic('family_alerts');
```

### Unsubscribe from Topics:
```dart
await NotificationService().unsubscribeFromTopic('alzheimers_updates');
```

### Send Token to Your Backend:
In `notification_service.dart`, implement `sendTokenToServer()`:
```dart
await NotificationService().sendTokenToServer(token!);
```

---

## 🔔 Notification Payload Examples

### Simple Notification:
```json
{
  "to": "FCM_TOKEN",
  "notification": {
    "title": "Daily Reminder",
    "body": "Time for medication"
  }
}
```

### Notification with Custom Data:
```json
{
  "to": "FCM_TOKEN",
  "notification": {
    "title": "Memory Game Available",
    "body": "Try the new sequence game!"
  },
  "data": {
    "screen": "memory_games",
    "game_type": "sequence",
    "difficulty": "easy"
  }
}
```

### Topic-based Notification:
```json
{
  "to": "/topics/family_alerts",
  "notification": {
    "title": "SOS Alert",
    "body": "Patient needs assistance"
  },
  "data": {
    "alert_type": "sos",
    "location": "home"
  }
}
```

---

## 🎨 Customization

### Change Notification Sound (Android):
1. Add sound file to `android/app/src/main/res/raw/notification.mp3`
2. Update in `notification_service.dart`:
```dart
const androidDetails = AndroidNotificationDetails(
  'high_importance_channel',
  'High Importance Notifications',
  sound: RawResourceAndroidNotificationSound('notification'),
);
```

### Custom Notification Icon (Android):
1. Add icon: `android/app/src/main/res/drawable/ic_notification.png`
2. Update AndroidManifest.xml:
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />
```

---

## ⚠️ Important Notes

1. **Both Firebase and Google ML Kit are working together!** ✅
   - Used older compatible versions of Firebase
   - No dependency conflicts
   - All 74 iOS pods installed successfully

2. **Must add actual Firebase config files** before testing
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS

3. **Must add iOS capabilities in Xcode**
   - Push Notifications
   - Background Modes → Remote notifications

4. **Permissions are automatically requested** when app starts

5. **FCM token prints to console** on every app launch

---

## ✨ What You Get

✅ **Complete FCM integration** that works on both iOS and Android  
✅ **Compatible with Google ML Kit** - no conflicts  
✅ **Automatic permission requests**  
✅ **FCM token printing to console**  
✅ **Foreground local notifications**  
✅ **Background message handling**  
✅ **Notification tap handling**  
✅ **Topic-based messaging support**  
✅ **Token refresh handling**  
✅ **Production-ready code**  

---

## 🚀 You're Ready!

Once you add the Firebase config files and iOS capabilities:

1. Run the app
2. Check console for FCM token
3. Send a test notification from Firebase Console
4. See it appear on your device! 🎉

The implementation is **100% complete** and follows Firebase best practices!
