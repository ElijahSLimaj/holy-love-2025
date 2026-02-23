import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as https from "https";

// Initialize Firebase Admin
admin.initializeApp();

// ============================================
// IN-APP PURCHASE RECEIPT VALIDATION
// ============================================

interface ValidateReceiptRequest {
  userId: string;
  receipt: string;
  productId: string;
  platform: "ios" | "android";
}

/**
 * Validate in-app purchase receipts and update user premium status
 */
export const validateReceipt = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    res.status(405).json({valid: false, error: "Method not allowed"});
    return;
  }

  try {
    const {userId, receipt, productId, platform} = req.body as ValidateReceiptRequest;

    if (!userId || !receipt || !productId || !platform) {
      res.status(400).json({valid: false, error: "Missing required fields"});
      return;
    }

    let isValid = false;
    let expiresDate: Date | null = null;

    if (platform === "ios") {
      const result = await validateAppleReceipt(receipt);
      isValid = result.valid;
      expiresDate = result.expiresDate;
    } else if (platform === "android") {
      const result = await validateGoogleReceipt(receipt, productId);
      isValid = result.valid;
      expiresDate = result.expiresDate;
    }

    if (isValid) {
      // Update user's premium status in Firestore
      await admin.firestore().collection("user_stats").doc(userId).set(
        {
          isPremium: true,
          premiumProductId: productId,
          premiumExpiresAt: expiresDate ? admin.firestore.Timestamp.fromDate(expiresDate) : null,
          premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true}
      );

      console.log(`Premium status updated for user ${userId}, product: ${productId}`);
    }

    res.status(200).json({valid: isValid});
  } catch (error) {
    console.error("Receipt validation error:", error);
    res.status(500).json({valid: false, error: "Internal server error"});
  }
});

/**
 * Validate Apple App Store receipt
 */
async function validateAppleReceipt(
  receiptData: string
): Promise<{valid: boolean; expiresDate: Date | null}> {
  // Apple's verification endpoints
  const productionUrl = "https://buy.itunes.apple.com/verifyReceipt";
  const sandboxUrl = "https://sandbox.itunes.apple.com/verifyReceipt";

  // Get shared secret from environment (set via Firebase Functions config)
  // firebase functions:config:set apple.shared_secret="YOUR_SECRET"
  const sharedSecret = functions.config().apple?.shared_secret || "";

  const requestBody = JSON.stringify({
    "receipt-data": receiptData,
    "password": sharedSecret,
    "exclude-old-transactions": true,
  });

  // Try production first, fall back to sandbox if status is 21007
  let result = await makeAppleRequest(productionUrl, requestBody);

  if (result.status === 21007) {
    // Receipt is from sandbox, retry with sandbox URL
    result = await makeAppleRequest(sandboxUrl, requestBody);
  }

  if (result.status !== 0) {
    console.log(`Apple receipt validation failed with status: ${result.status}`);
    return {valid: false, expiresDate: null};
  }

  // Check for active subscription
  const latestReceiptInfo = (result.latest_receipt_info || []) as Array<Record<string, unknown>>;
  if (latestReceiptInfo.length === 0) {
    return {valid: false, expiresDate: null};
  }

  // Find the latest subscription
  const latestSubscription = latestReceiptInfo.reduce(
    (latest: Record<string, unknown>, current: Record<string, unknown>) => {
      const latestExpires = parseInt(latest.expires_date_ms as string || "0");
      const currentExpires = parseInt(current.expires_date_ms as string || "0");
      return currentExpires > latestExpires ? current : latest;
    }
  );

  const expiresMs = parseInt((latestSubscription as Record<string, unknown>).expires_date_ms as string || "0");
  const isActive = expiresMs > Date.now();

  return {
    valid: isActive,
    expiresDate: isActive ? new Date(expiresMs) : null,
  };
}

function makeAppleRequest(
  url: string,
  body: string
): Promise<Record<string, unknown>> {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      path: urlObj.pathname,
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(body),
      },
    };

    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => {
        data += chunk;
      });
      res.on("end", () => {
        try {
          resolve(JSON.parse(data));
        } catch {
          reject(new Error("Invalid JSON response from Apple"));
        }
      });
    });

    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

/**
 * Validate Google Play receipt
 */
async function validateGoogleReceipt(
  purchaseToken: string,
  productId: string
): Promise<{valid: boolean; expiresDate: Date | null}> {
  // For Google Play validation, you need to set up a service account
  // and use the Google Play Developer API
  //
  // This requires:
  // 1. Creating a service account in Google Cloud Console
  // 2. Enabling the Google Play Developer API
  // 3. Linking the service account to Play Console
  // 4. Storing the service account key in Firebase Functions config
  //
  // For now, we'll return a placeholder that trusts the client
  // TODO: Implement proper Google Play validation

  console.log(`Google Play validation for product ${productId}, token: ${purchaseToken.substring(0, 20)}...`);

  // TEMPORARY: Trust the client for now
  // In production, implement proper validation using googleapis
  return {valid: true, expiresDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)};
}

/**
 * Webhook for App Store Server Notifications (subscription renewals, cancellations)
 */
export const appleSubscriptionWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method not allowed");
    return;
  }

  try {
    const notification = req.body;
    const notificationType = notification.notification_type;

    console.log(`Apple webhook received: ${notificationType}`);

    // Handle different notification types
    switch (notificationType) {
    case "DID_RENEW":
    case "INITIAL_BUY":
      // Subscription renewed or initially purchased
      await handleAppleSubscriptionActive(notification);
      break;

    case "CANCEL":
    case "DID_FAIL_TO_RENEW":
    case "EXPIRED":
      // Subscription ended
      await handleAppleSubscriptionEnded(notification);
      break;

    default:
      console.log(`Unhandled Apple notification type: ${notificationType}`);
    }

    res.status(200).send("OK");
  } catch (error) {
    console.error("Apple webhook error:", error);
    res.status(500).send("Error processing webhook");
  }
});

async function handleAppleSubscriptionActive(
  notification: Record<string, unknown>
): Promise<void> {
  const unifiedReceipt = notification.unified_receipt as Record<string, unknown>;
  const latestReceiptInfo =
    (unifiedReceipt?.latest_receipt_info as Array<Record<string, unknown>>) || [];

  if (latestReceiptInfo.length === 0) return;

  const latestTransaction = latestReceiptInfo[latestReceiptInfo.length - 1];
  const originalTransactionId = latestTransaction.original_transaction_id as string;

  // Find user by transaction ID
  const usersSnapshot = await admin.firestore()
    .collection("user_stats")
    .where("appleTransactionId", "==", originalTransactionId)
    .limit(1)
    .get();

  if (usersSnapshot.empty) {
    console.log(`No user found for transaction ${originalTransactionId}`);
    return;
  }

  const userId = usersSnapshot.docs[0].id;
  const expiresMs = parseInt(latestTransaction.expires_date_ms as string || "0");

  await admin.firestore().collection("user_stats").doc(userId).update({
    isPremium: true,
    premiumExpiresAt: admin.firestore.Timestamp.fromDate(new Date(expiresMs)),
    premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Subscription renewed for user ${userId}`);
}

async function handleAppleSubscriptionEnded(
  notification: Record<string, unknown>
): Promise<void> {
  const unifiedReceipt = notification.unified_receipt as Record<string, unknown>;
  const latestReceiptInfo =
    (unifiedReceipt?.latest_receipt_info as Array<Record<string, unknown>>) || [];

  if (latestReceiptInfo.length === 0) return;

  const latestTransaction = latestReceiptInfo[latestReceiptInfo.length - 1];
  const originalTransactionId = latestTransaction.original_transaction_id as string;

  // Find user by transaction ID
  const usersSnapshot = await admin.firestore()
    .collection("user_stats")
    .where("appleTransactionId", "==", originalTransactionId)
    .limit(1)
    .get();

  if (usersSnapshot.empty) {
    console.log(`No user found for transaction ${originalTransactionId}`);
    return;
  }

  const userId = usersSnapshot.docs[0].id;

  await admin.firestore().collection("user_stats").doc(userId).update({
    isPremium: false,
    premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Subscription ended for user ${userId}`);
}

// ============================================
// PUSH NOTIFICATIONS
// ============================================

/**
 * Send push notification when a new message is created
 */
export const sendMessageNotification = functions.firestore
  .document("conversations/{conversationId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    try {
      const message = snap.data();
      const receiverId = message.receiverId;
      const senderId = message.senderId;

      // Don't send notification for own messages
      if (senderId === receiverId) {
        return null;
      }

      // Get receiver's FCM tokens
      const tokensSnapshot = await admin.firestore()
        .collection("users")
        .doc(receiverId)
        .collection("fcmTokens")
        .get();

      if (tokensSnapshot.empty) {
        console.log(`No FCM tokens found for user: ${receiverId}`);
        return null;
      }

      const tokens = tokensSnapshot.docs.map((doc) => doc.data().token as string);

      // Get sender profile
      const senderDoc = await admin.firestore()
        .collection("users")
        .doc(senderId)
        .get();

      if (!senderDoc.exists) {
        console.log(`Sender profile not found: ${senderId}`);
        return null;
      }

      const sender = senderDoc.data()!;
      const senderName = `${sender.firstName} ${sender.lastName}`;

      // Prepare notification payload
      const messageText = message.text || "";
      const messagePreview = messageText.length > 100 ?
        messageText.substring(0, 100) + "..." :
        messageText;

      const payload = {
        notification: {
          title: `New message from ${senderName}`,
          body: messagePreview,
        },
        data: {
          type: "message",
          conversationId: context.params.conversationId,
          senderId: senderId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        android: {
          priority: "high" as const,
          notification: {
            channelId: "high_importance_channel",
            sound: "default",
          },
        },
      };

      // Send to all receiver's devices
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        ...payload,
      });

      console.log(`Message notification sent: ${response.successCount} success, ${response.failureCount} failure`);

      // Clean up invalid tokens
      if (response.failureCount > 0) {
        const failedTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(tokens[idx]);
          }
        });

        // Delete invalid tokens
        const batch = admin.firestore().batch();
        failedTokens.forEach((token) => {
          const tokenRef = admin.firestore()
            .collection("users")
            .doc(receiverId)
            .collection("fcmTokens")
            .doc(token);
          batch.delete(tokenRef);
        });
        await batch.commit();

        console.log(`Cleaned up ${failedTokens.length} invalid tokens`);
      }

      return null;
    } catch (error) {
      console.error("Error sending message notification:", error);
      return null;
    }
  });

/**
 * Send push notification when a new match is created
 */
export const sendMatchNotification = functions.firestore
  .document("matches/{matchId}")
  .onCreate(async (snap, context) => {
    try {
      const match = snap.data();
      const participants = match.participants as string[];

      if (participants.length !== 2) {
        console.log("Invalid match participants");
        return null;
      }

      const [user1Id, user2Id] = participants;

      // Send notification to both users
      await Promise.all([
        sendMatchNotificationToUser(user1Id, user2Id),
        sendMatchNotificationToUser(user2Id, user1Id),
      ]);

      return null;
    } catch (error) {
      console.error("Error sending match notification:", error);
      return null;
    }
  });

/**
 * Helper function to send match notification to a single user
 */
async function sendMatchNotificationToUser(
  userId: string,
  matchedUserId: string
): Promise<void> {
  try {
    // Get user's FCM tokens
    const tokensSnapshot = await admin.firestore()
      .collection("users")
      .doc(userId)
      .collection("fcmTokens")
      .get();

    if (tokensSnapshot.empty) {
      console.log(`No FCM tokens found for user: ${userId}`);
      return;
    }

    const tokens = tokensSnapshot.docs.map((doc) => doc.data().token as string);

    // Get matched user's profile
    const matchedUserDoc = await admin.firestore()
      .collection("users")
      .doc(matchedUserId)
      .get();

    if (!matchedUserDoc.exists) {
      console.log(`Matched user profile not found: ${matchedUserId}`);
      return;
    }

    const matchedUser = matchedUserDoc.data()!;
    const matchedUserName = `${matchedUser.firstName} ${matchedUser.lastName}`;

    // Prepare notification payload
    const payload = {
      notification: {
        title: "It's a Match! 💕",
        body: `You and ${matchedUserName} liked each other!`,
      },
      data: {
        type: "match",
        matchedUserId: matchedUserId,
        matchedUserName: matchedUserName,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      android: {
        priority: "high" as const,
        notification: {
          channelId: "high_importance_channel",
          sound: "default",
        },
      },
    };

    // Send to all user's devices
    const response = await admin.messaging().sendEachForMulticast({
      tokens: tokens,
      ...payload,
    });

    console.log(
      `Match notification sent to ${userId}: ${response.successCount} success, ${response.failureCount} failure`
    );

    // Clean up invalid tokens
    if (response.failureCount > 0) {
      const failedTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
        }
      });

      const batch = admin.firestore().batch();
      failedTokens.forEach((token) => {
        const tokenRef = admin.firestore()
          .collection("users")
          .doc(userId)
          .collection("fcmTokens")
          .doc(token);
        batch.delete(tokenRef);
      });
      await batch.commit();
    }
  } catch (error) {
    console.error(`Error sending match notification to ${userId}:`, error);
  }
}

/**
 * Send push notification for likes (when notification document is created)
 */
export const sendLikeNotification = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    try {
      const notification = snap.data();

      // Only send push for 'like' type notifications
      if (notification.type !== "like") {
        return null;
      }

      const userId = notification.userId;
      const likerName = notification.relatedUserName;

      // Get user's FCM tokens
      const tokensSnapshot = await admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("fcmTokens")
        .get();

      if (tokensSnapshot.empty) {
        console.log(`No FCM tokens found for user: ${userId}`);
        return null;
      }

      const tokens = tokensSnapshot.docs.map((doc) => doc.data().token as string);

      // Prepare notification payload
      const payload = {
        notification: {
          title: "Someone liked you! 💖",
          body: `${likerName} liked your profile`,
        },
        data: {
          type: "like",
          likerId: notification.relatedUserId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        android: {
          priority: "high" as const,
          notification: {
            channelId: "high_importance_channel",
            sound: "default",
          },
        },
      };

      // Send to all user's devices
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        ...payload,
      });

      console.log(`Like notification sent: ${response.successCount} success, ${response.failureCount} failure`);

      // Clean up invalid tokens
      if (response.failureCount > 0) {
        const failedTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(tokens[idx]);
          }
        });

        const batch = admin.firestore().batch();
        failedTokens.forEach((token) => {
          const tokenRef = admin.firestore()
            .collection("users")
            .doc(userId)
            .collection("fcmTokens")
            .doc(token);
          batch.delete(tokenRef);
        });
        await batch.commit();
      }

      return null;
    } catch (error) {
      console.error("Error sending like notification:", error);
      return null;
    }
  });
