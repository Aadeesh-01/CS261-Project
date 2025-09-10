const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// This is our function. It creates a user in Auth and a profile in Firestore.
exports.createUserAccount = functions.https.onCall(async (data, context) => {
  // Simple check to make sure an authenticated user is making the request.
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be logged in to create a user."
    );
  }

  const { email, password, name } = data;

  // Create the user account in Firebase Authentication.
  const userRecord = await admin.auth().createUser({
    email: email,
    password: password,
    displayName: name,
  });

  // Create the user's profile document in Firestore.
  await admin.firestore().collection("users").doc(userRecord.uid).set({
    name: name,
    email: email,
    role: "student", // Assign a default role
  });

  return { message: `Successfully created user ${email}`, uid: userRecord.uid };
});