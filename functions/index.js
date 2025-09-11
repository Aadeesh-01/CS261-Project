const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * A helper function to get the next sequential user ID (e.g., 's1', 's2').
 * This uses a transaction to prevent race conditions.
 * @param {admin.firestore.Transaction} transaction The Firestore transaction.
 * @returns {Promise<string>} The next user ID.
 */
const getNextUserId = async (transaction) => {
  const counterRef = admin.firestore().collection('metadata').doc('userCounter');
  const counterDoc = await transaction.get(counterRef);

  let nextCount = 1;
  if (counterDoc.exists) {
    nextCount = counterDoc.data().count + 1;
  }
  
  transaction.set(counterRef, { count: nextCount }, { merge: true });
  return `s${nextCount}`;
};

/**
 * Gives a user the 'admin' custom claim. Call this once for each admin.
 * @param {string} email - The email of the user to make an admin.
 */
exports.addAdminRole = functions.https.onCall(async (data, context) => {
  // Security check: Only an existing admin can make other users admins.
  if (context.auth.token.role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only an admin can add other admins.'
    );
  }

  const email = data.email;
  if (!email) {
    throw new functions.https.HttpsError('invalid-argument', 'The function must be called with an "email" argument.');
  }

  try {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().setCustomUserClaims(user.uid, { role: 'admin' });
    return { message: `Success! ${email} has been made an admin.` };
  } catch (error) {
    console.error("Error in addAdminRole:", error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});


/**
 * Creates a user account with a sequential ID (s1, s2...)
 * and sets their profile as incomplete.
 */
exports.createUserAccount = functions.https.onCall(async (data, context) => {
  // Security check: Ensure the user making the request is an admin.
  if (context.auth.token.role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'You must be an admin to create users.'
    );
  }

  const { email, password, name } = data;

  // Input validation
  if (!email || !password || !name) {
    throw new functions.https.HttpsError('invalid-argument', 'The function must be called with "email", "password", and "name" arguments.');
  }

  try {
    // Create the user in Firebase Authentication.
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: name,
    });

    // Use a transaction to safely get the next user ID and create the document.
    const db = admin.firestore();
    await db.runTransaction(async (transaction) => {
      const newUserId = await getNextUserId(transaction);
      const userDocRef = db.collection("users").doc(newUserId);

      // Create the user's profile document in Firestore.
      transaction.set(userDocRef, {
        uid: userRecord.uid, // Link to the Auth user
        name: name,
        email: email,
        role: "student", // Default role
        isProfileComplete: false, // Onboarding flag
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    return { message: `Successfully created user ${email}`, uid: userRecord.uid };
  } catch (error) {
    console.error("Error in createUserAccount:", error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

