const functions = require("firebase-functions");
const admin = require("firebase-admin");
const algoliasearch = require("algoliasearch"); // ✅ NEW: Import Algolia

admin.initializeApp();

// ✅ NEW: Initialize Algolia Client
const ALGOLIA_APP_ID = "BVW4RU2C7H"; // Replace with your actual App ID
const ALGOLIA_ADMIN_KEY = "5a131552acb9603a40afbed4ae6d6bf0"; // 🔐 Replace this safely
const ALGOLIA_INDEX_NAME = "users"; // You can customize this index name

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

    // ✅ NEW: Send data to Algolia (sync)
    await algoliaIndex.saveObject({
      objectID: uid, // Algolia requires this key
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
