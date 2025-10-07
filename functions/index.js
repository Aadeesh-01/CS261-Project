const { onCall } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const algoliasearch = require("algoliasearch");

admin.initializeApp();

// Algolia setup
const ALGOLIA_APP_ID = "BVW4RU2C7H";
const ALGOLIA_ADMIN_KEY = "5a131552acb9603a40afbed4ae6d6bf0";
const ALGOLIA_USER_INDEX = "users";
const ALGOLIA_ALUMNI_INDEX = "alumni";

const algoliaClient = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
const userIndex = algoliaClient.initIndex(ALGOLIA_USER_INDEX);
const alumniIndex = algoliaClient.initIndex(ALGOLIA_ALUMNI_INDEX);

// ========================== CREATE ALUMNI ACCOUNT ==========================
exports.createAlumniAccount = onCall(
  { region: "asia-south1" },
  async (request) => {
    try {
      const { data, auth } = request;
      if (!auth) throw new Error("You must be logged in to create alumni.");
      if (auth.token.role !== "admin") throw new Error("Only admins can create alumni.");

      const { email, password, name, year } = data;
      if (!email || !password || !name) throw new Error("Email, password, and name are required.");

      const userRecord = await admin.auth().createUser({
        email,
        password,
        displayName: name,
      });

      const uid = userRecord.uid;

      // Generate alumniId
      const alumniRef = admin.firestore().collection("alumni");
      const snapshot = await alumniRef.orderBy("alumniId", "desc").limit(1).get();

      let nextId = "a1";
      if (!snapshot.empty) {
        const lastAlumniId = snapshot.docs[0].data().alumniId;
        const lastNum = parseInt(lastAlumniId?.substring(1)) || 0;
        nextId = `a${lastNum + 1}`;
      }

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
      await alumniIndex.saveObject({ objectID: uid, ...alumniData });

      // CREATE PROFILE DOCUMENT
      await admin.firestore().collection("profiles").doc(uid).set({
        uid,
        name,
        role: "alumni",
        isProfileComplete: false,
        email,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        uid,
        alumniId: nextId,
        message: "🎓 Alumni created successfully with profile.",
      };
    } catch (error) {
      logger.error("Error creating alumni:", error);
      throw new Error(error.message);
    }
  }
);

// ========================== CREATE USER ACCOUNT ==========================
exports.createUserAccount = onCall(
  { region: "asia-south1" },
  async (request) => {
    try {
      const { data, auth } = request;
      if (!auth) throw new Error("You must be logged in to create users.");
      if (auth.token.role !== "admin") throw new Error("Only admins can create users.");

      const { email, password, role } = data;
      if (!email || !password || !role) throw new Error("Email, password, and role are required.");

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
      await userIndex.saveObject({ objectID: uid, ...userData });

      // CREATE PROFILE DOCUMENT
      await admin.firestore().collection("profiles").doc(uid).set({
        uid,
        role,
        isProfileComplete: false,
        email,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        uid,
        userId: nextId,
        message: "✅ User created successfully with profile.",
      };
    } catch (error) {
      logger.error("Error creating user:", error);
      throw new Error(error.message);
    }
  }
);

// ========================== ADD ADMIN ROLE ==========================
exports.addAdminRole = onCall(
  { region: "asia-south1" },
  async (request) => {
    const { email } = request.data;
    if (!email) throw new Error("Email is required.");

    try {
      const user = await admin.auth().getUserByEmail(email);
      await admin.auth().setCustomUserClaims(user.uid, { role: "admin" });

      await admin.firestore().collection("admins").doc(user.uid).set({
        email: user.email,
        role: "admin",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Ensure profile exists for admin
      const profileRef = admin.firestore().collection("profiles").doc(user.uid);
      const profileDoc = await profileRef.get();
      if (!profileDoc.exists) {
        await profileRef.set({
          uid: user.uid,
          name: user.displayName || "Admin",
          role: "admin",
          isProfileComplete: true,
          email: user.email,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return { message: `✅ ${email} is now an admin with profile!` };
    } catch (error) {
      throw new Error(`Error setting admin role: ${error.message}`);
    }
  }
);
