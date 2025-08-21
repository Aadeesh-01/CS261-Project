const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// --- Function 1: Add admin role ---
exports.addAdminRole = functions.https.onCall(async (data, context) => {
  // Only existing admins can call this function
  if (!context.auth?.token.admin) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only admins can add other admins."
    );
  }

  const email = data.email;
  if (!email) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Email is required."
    );
  }

  try {
    // 1. Fetch user
    const user = await admin.auth().getUserByEmail(email);

    // 2. Merge claims (instead of overwriting)
    const currentClaims = user.customClaims || {};
    await admin.auth().setCustomUserClaims(user.uid, {
      ...currentClaims,
      admin: true,
    });

    // 3. Revoke old tokens so new claim takes effect immediately on re-login
    await admin.auth().revokeRefreshTokens(user.uid);

    // 4. Update Firestore user doc (optional, but great for quick checks & audit)
    const userRef = admin.firestore().collection("users").doc(user.uid);
    await userRef.set(
      {
        role: "Admin",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { message: `✅ ${email} has been granted admin privileges.` };
  } catch (err) {
    console.error("Error assigning admin role:", err);
    throw new functions.https.HttpsError("internal", err.message);
  }
});

// --- Function 2: Create new user (admin-only) ---
exports.createNewUser = functions.https.onCall(async (data, context) => {
  if (!context.auth?.token.admin) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only admins can create new users."
    );
  }

  const { email, password } = data;
  if (!email || !password) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Must provide email and password."
    );
  }

  try {
    const userRecord = await admin.auth().createUser({ email, password });

    // Create Firestore doc right away for clarity
    await admin.firestore().collection("users").doc(userRecord.uid).set({
      uid: userRecord.uid,
      email: userRecord.email,
      role: "Student",
      institute: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      message: `✅ Created user ${userRecord.email}`,
      uid: userRecord.uid,
    };
  } catch (err) {
    throw new functions.https.HttpsError("internal", err.message);
  }
});

// --- Function 3: Auto-create Firestore user doc when Auth user created ---
exports.onAuthUserCreate = functions.auth.user().onCreate(async (user) => {
  const doc = {
    uid: user.uid,
    email: user.email || null,
    role: "Student", // default role
    institute: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const ref = admin.firestore().collection("users").doc(user.uid);
  await ref.set(doc, { merge: true });
});
