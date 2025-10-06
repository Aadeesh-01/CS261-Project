const functions = require("firebase-functions");
const admin = require("firebase-admin");
const algoliasearch = require("algoliasearch");

admin.initializeApp();

const ALGOLIA_APP_ID = "BVW4RU2C7H";
const ALGOLIA_ADMIN_KEY = "5a131552acb9603a40afbed4ae6d6bf0";
const ALGOLIA_INDEX_NAME = "users";

const algoliaClient = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
const algoliaIndex = algoliaClient.initIndex(ALGOLIA_INDEX_NAME);

exports.createUserAccount = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be logged in to create users."
      );
    }

    if (context.auth.token.role !== "admin") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can create users."
      );
    }

    const { email, password, role } = data;

    if (!email || !password || !role) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Email, password, and role are required."
      );
    }

    const userRecord = await admin.auth().createUser({
      email,
      password,
    });

    const uid = userRecord.uid;
    const usersRef = admin.firestore().collection("users");

    const snapshot = await usersRef
      .orderBy("userId", "desc")
      .limit(1)
      .get();

    let nextId = "s1";
    if (!snapshot.empty) {
      const lastUserId = snapshot.docs[0].data().userId;
      const lastNum = parseInt(lastUserId?.substring(1)) || 0;
      nextId = `s${lastNum + 1}`;
    }

    const userData = {
      uid: uid,
      email: email,
      role: role,
      userId: nextId,
      isProfileComplete: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await usersRef.doc(uid).set(userData);

    await algoliaIndex.saveObject({
      objectID: uid,
      email,
      role,
      userId: nextId,
      isProfileComplete: false,
    });

    return {
      success: true,
      uid: uid,
      userId: nextId,
      message: "✅ User created successfully",
    };
  } catch (error) {
    console.error("Error creating user:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

exports.sendEventNotification = functions.firestore
  .document('events/{eventId}')
  .onCreate(async (snap, context) => {
    const eventData = snap.data();
    const payload = {
      notification: {
        title: '🎉 New Event Added!',
        body: `Check out the new event: ${eventData.title}`,
        sound: 'default'
      },
      data: {
        'screen': 'events_page',
        'eventId': context.params.eventId,
      }
    };
    return admin.messaging().sendToTopic('all_users', payload);
  });

exports.sendProfileViewNotification = functions.firestore
  .document('users/{userId}/profileViews/{viewId}')
  .onCreate(async (snap, context) => {
    const viewData = snap.data();
    const profileOwnerId = context.params.userId;
    const userDoc = await admin.firestore().collection('users').doc(profileOwnerId).get();
    const fcmToken = userDoc.data().fcmToken;

    if (!fcmToken) {
      console.log("User has no FCM token, can't send notification.");
      return;
    }

    const payload = {
      notification: {
        title: '👀 Someone Viewed Your Profile!',
        body: `${viewData.viewerName} just checked out your profile.`,
        sound: 'default'
      },
      data: {
        'screen': 'profile_page',
        'viewerId': viewData.viewerId,
      }
    };
    return admin.messaging().sendToDevice(fcmToken, payload);
  });

// --- NEW FUNCTION ADDED HERE ---
// Triggers when a new document is created in the 'posts' collection
exports.sendNewPostNotification = functions.firestore
  .document('posts/{postId}')
  .onCreate(async (snap, context) => {
    const postData = snap.data();

    // To prevent sending a notification for a post with no text content
    if (!postData.content) {
      console.log("Post has no content, skipping notification.");
      return;
    }

    // Creating a short preview of the post content
    const contentPreview = postData.content.length > 50
      ? postData.content.substring(0, 50) + '...'
      : postData.content;

    const payload = {
      notification: {
        title: `📰 New Post from ${postData.authorName || 'an alumnus'}!`,
        body: contentPreview,
        sound: 'default'
      },
      data: {
        'screen': 'posts_page', // Or a specific post page
        'postId': context.params.postId,
      }
    };

    // This sends the notification to all users subscribed to the 'all_users' topic
    return admin.messaging().sendToTopic('all_users', payload);
  });
