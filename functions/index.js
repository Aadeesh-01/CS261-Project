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
const ALGOLIA_USER_INDEX = "users";
const ALGOLIA_ALUMNI_INDEX = "alumni";

const algoliaClient = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
const userIndex = algoliaClient.initIndex(ALGOLIA_USER_INDEX);
const alumniIndex = algoliaClient.initIndex(ALGOLIA_ALUMNI_INDEX);

// ===================================================================
// ✅ Callable Function: Create User Account (students)
// ===================================================================
exports.createUserAccount = onCall(
  { region: "asia-south1", invoker: "public" },
  async (request) => {
    try {
      const { data, auth } = request;

      if (!auth) throw new Error("You must be logged in to create users.");
      if (auth.token.role !== "admin")
        throw new Error("Only admins can create users.");

      const { email, password, role } = data;
      if (!email || !password || !role)
        throw new Error("Email, password, and role are required.");

      // Create Firebase Auth user
      const userRecord = await admin.auth().createUser({ email, password });
      const uid = userRecord.uid;

      // Generate sequential userId (s1, s2, ...)
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

      await userIndex.saveObject({
        objectID: uid,
        ...userData,
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

// ===================================================================
// ✅ Callable Function: Create Alumni Account
// ===================================================================
exports.createAlumniAccount = onCall(
  { region: "asia-south1", invoker: "public" },
  async (request) => {
    try {
      const { data, auth } = request;

      if (!auth) throw new Error("You must be logged in to create alumni.");
      if (auth.token.role !== "admin")
        throw new Error("Only admins can create alumni.");

      const { email, password, name, year } = data;
      if (!email || !password || !name)
        throw new Error("Email, password, and name are required.");

      // Create user in Firebase Auth
      const userRecord = await admin.auth().createUser({
        email,
        password,
        displayName: name,
      });

      const uid = userRecord.uid;

      // Generate sequential alumniId (a1, a2, ...)
      const alumniRef = admin.firestore().collection("alumni");
      const snapshot = await alumniRef.orderBy("alumniId", "desc").limit(1).get();

      let nextId = "a1";
      if (!snapshot.empty) {
        const lastAlumniId = snapshot.docs[0].data().alumniId;
        const lastNum = parseInt(lastAlumniId?.substring(1)) || 0;
        nextId = `a${lastNum + 1}`;
      }

      // Firestore data
      const alumniData = {
        uid,
        email,
        name,
        year: year || "",
        role: "alumni",
        alumniId: nextId,
        isProfileComplete: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await alumniRef.doc(uid).set(alumniData);

      await alumniIndex.saveObject({
        objectID: uid,
        ...alumniData,
      });

      return {
        success: true,
        uid,
        alumniId: nextId,
        message: "🎓 Alumni created successfully",
      };
    } catch (error) {
      logger.error("Error creating alumni:", error);
      throw new Error(error.message);
    }
  }
);

// ===================================================================
// 🔔 Firestore Triggers
// ===================================================================
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


// --- Make User Admin ---
exports.addAdminRole = onCall(
  { region: "asia-south1" },
  async (request) => {
    const { email } = request.data;

    if (!email) {
      throw new Error("Email is required.");
    }

    try {
      // Get user by email
      const user = await admin.auth().getUserByEmail(email);

      // Set custom claim 'role' = 'admin'
      await admin.auth().setCustomUserClaims(user.uid, { role: "admin" });

      // Optional: also mark it in Firestore for clarity
      await admin.firestore().collection("admins").doc(user.uid).set({
        email: user.email,
        role: "admin",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { message: `✅ ${email} is now an admin!` };
    } catch (error) {
      throw new Error(`Error setting admin role: ${error.message}`);
    }
  }
);
