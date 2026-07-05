const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Triggered whenever a new message document is created inside:
 *   chats/{chatId}/messages/{messageId}
 *
 * It reads the receiver's FCM token from Firestore and sends
 * a push notification via Firebase Cloud Messaging.
 */
exports.sendChatNotification = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const message = snap.data();

    // Only send notification for non-deleted messages
    if (!message || message.isDeleted === true) {
      console.log("Skipping notification: message is deleted or empty.");
      return null;
    }

    const senderId = message.senderId;
    const receiverId = message.receiverId;
    const messageText = message.text || "";
    const messageType = message.messageType || "text";

    if (!senderId || !receiverId) {
      console.log("Missing senderId or receiverId. Skipping.");
      return null;
    }

    // Don't send notification if sender == receiver (self-message)
    if (senderId === receiverId) {
      return null;
    }

    try {
      // 1. Fetch sender's name from Firestore
      const senderDoc = await admin
        .firestore()
        .collection("users")
        .doc(senderId)
        .get();

      const senderName = senderDoc.exists
        ? senderDoc.data().name || "Someone"
        : "Someone";

      // 2. Fetch receiver's FCM token from Firestore
      const receiverDoc = await admin
        .firestore()
        .collection("users")
        .doc(receiverId)
        .get();

      if (!receiverDoc.exists) {
        console.log(`Receiver ${receiverId} not found in Firestore.`);
        return null;
      }

      const receiverData = receiverDoc.data();
      const fcmToken = receiverData.fcmToken;

      if (!fcmToken) {
        console.log(
          `Receiver ${receiverId} has no FCM token. Cannot send notification.`
        );
        return null;
      }

      // 3. Build notification body based on message type
      let notificationBody = messageText;
      if (messageType === "image") {
        notificationBody = "📷 Aik image bheji";
      } else if (messageType === "video") {
        notificationBody = "🎥 Aik video bheji";
      } else if (messageType === "audio") {
        notificationBody = "🎤 Aik voice message bheja";
      } else if (messageType === "file") {
        notificationBody = "📎 Aik file bheji";
      } else if (!messageText || messageText.trim() === "") {
        notificationBody = "Naya message";
      }

      // 4. Build and send the FCM message
      const fcmPayload = {
        token: fcmToken,
        notification: {
          title: senderName,
          body: notificationBody,
        },
        data: {
          senderId: senderId,
          receiverId: receiverId,
          chatId: context.params.chatId,
          type: "chat_message",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "apnichat_high_importance_channel",
            priority: "high",
            defaultSound: true,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().send(fcmPayload);
      console.log(
        `✅ Notification sent to ${receiverId} (token: ${fcmToken.substring(
          0,
          20
        )}...). Response: ${response}`
      );
      return null;
    } catch (error) {
      console.error("❌ Error sending notification:", error);
      return null;
    }
  });
