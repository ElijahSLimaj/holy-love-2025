# iOS Push Notifications - APNs Setup

## Upload APNs Authentication Key to Firebase

Without this step, iOS push notifications will NOT work.

### Steps:

1. Go to [Apple Developer Portal - Keys](https://developer.apple.com/account/resources/authkeys/list)
2. Click **+** to create a new key
3. Name it (e.g. "Holy Love APNs Key")
4. Check **Apple Push Notifications service (APNs)**
5. Click **Continue** then **Register**
6. Download the `.p8` file (you can only download it once!)
7. Note the **Key ID** shown on the page

### Upload to Firebase:

1. Go to [Firebase Console - Cloud Messaging Settings](https://console.firebase.google.com/project/holy-love-2025-07-11/settings/cloudmessaging)
2. Under your iOS app, click **Upload** next to APNs Authentication Key
3. Upload the `.p8` file
4. Enter the **Key ID** from step 6
5. Enter your **Team ID** (found in Apple Developer Portal under Membership)

### Verify:

- Run the app on a physical iOS device (simulators don't support push notifications)
- Check that the FCM token is saved in Firestore under `users/{userId}/fcmTokens`
- Send a test message from another account and confirm the notification appears
