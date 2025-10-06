// --- Imports ---
const { onCall } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const algoliasearch = require("algoliasearch");

admin.initializeApp();

// --- Algolia Config ---
const ALGOLIA_APP_ID = "BVW4RU2C7H";
const ALGOLIA_ADMIN_KEY = "5a131552acb9603a40afbed4ae6d6bf0";
const ALGOLIA_INDEX_NAME = "users";

const algoliaClient = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
const algoliaIndex = algoliaClient.initIndex(ALGOLIA_INDEX_NAME);

// --- GEN 2: Callable Function (create user) ---
exports.createUserAccount = onCall(
  { region: "asia-south1", invoker: "public" }, // 👈 optional settings
  async (request) => {
    try {
      const { data, auth } = request;

      if (!auth) {
        throw new Error("You must be logged in to create users.");
      }

      if (auth.token.role !== "admin") {
        throw new Error("Only admins can create users.");
      }

      const { email, password, role } = data;

      if (!email || !password || !role) {
        throw new Error("Email, password, and role are required.");
      }

      const userRecord = await admin.auth().createUser({ email, password });
      const uid = userRecord.uid;

      const usersRef = admin.firestore().collection("users");
      const snapshot = await usersRef.orderBy("userId", "desc").limit(1).get();

      let nextId = "s1";
      if (!snapshot.empty) {
        const lastUserId = snapshot.docs[0].data().userId;
        const lastNum = parseInt(lastUserId?.substring(1)) || 0;
        nextId = `s${lastNum + 1}`;
      }

      const userData = {
        uid,
        email,
        role,
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
        uid,
        userId: nextId,
        message: "✅ User created successfully",
      };
    } catch (error) {
      logger.error("Error creating user:", error);
      throw new Error(error.message);
    }
  }
);

// --- GEN 2: Firestore Trigger for new event ---
exports.sendEventNotification = onDocumentCreated(
  { document: "events/{eventId}", region: "asia-south1" },
  async (event) => {
    const eventData = event.data.data();
    const payload = {
      notification: {
        title: "🎉 New Event Added!",
        body: `Check out the new event: ${eventData.title}`,
        sound: "default",
      },
      data: {
        screen: "events_page",
        eventId: event.params.eventId,
      },
    };
    return admin.messaging().sendToTopic("all_users", payload);
  }
);

// --- GEN 2: Firestore Trigger for profile view ---
exports.sendProfileViewNotification = onDocumentCreated(
  { document: "users/{userId}/profileViews/{viewId}", region: "asia-south1" },
  async (event) => {
    const viewData = event.data.data();
    const profileOwnerId = event.params.userId;
    const userDoc = await admin.firestore().collection("users").doc(profileOwnerId).get();
    const fcmToken = userDoc.data().fcmToken;

    if (!fcmToken) {
      logger.info("User has no FCM token, skipping notification.");
      return;
    }

    const payload = {
      notification: {
        title: "👀 Someone Viewed Your Profile!",
        body: `${viewData.viewerName} just checked out your profile.`,
        sound: "default",
      },
      data: {
        screen: "profile_page",
        viewerId: viewData.viewerId,
      },
    };

    return admin.messaging().sendToDevice(fcmToken, payload);
  }
);

// --- GEN 2: Firestore Trigger for new post ---
exports.sendNewPostNotification = onDocumentCreated(
  { document: "posts/{postId}", region: "asia-south1" },
  async (event) => {
    const postData = event.data.data();

    if (!postData.content) {
      logger.info("Post has no content, skipping notification.");
      return;
    }

    const contentPreview =
      postData.content.length > 50
        ? postData.content.substring(0, 50) + "..."
        : postData.content;

    const payload = {
      notification: {
        title: `📰 New Post from ${postData.authorName || "an alumnus"}!`,
        body: contentPreview,
        sound: "default",
      },
      data: {
        screen: "posts_page",
        postId: event.params.postId,
      },
    };

    return admin.messaging().sendToTopic("all_users", payload);
  }
);
