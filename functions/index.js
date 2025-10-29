const { onCall } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// ========================== CREATE PARTICIPANT ACCOUNT ==========================
exports.createParticipantAccount = onCall(
  { region: "asia-south1" },
  async (request) => {
    try {
      const { data, auth } = request;
      if (!auth) throw new Error("You must be logged in to create participants.");
      if (auth.token.role !== "admin") throw new Error("Only admins can create participants.");

      const { email, password, name, role, instituteId, year } = data;
      if (!email || !password || !role || !instituteId) {
        throw new Error("Email, password, role, and instituteId are required.");
      }

      // Create Firebase Auth User
      const userRecord = await admin.auth().createUser({
        email,
        password,
        displayName: name || email,
      });
      const uid = userRecord.uid;

      const participantsRef = admin
        .firestore()
        .collection("institutes")
        .doc(instituteId)
        .collection("participants");

      // Generate custom ID based on role (optional, purely cosmetic)
      const prefix = role === "alumni" ? "a" : role === "admin" ? "ad" : "s";
      const snapshot = await participantsRef.orderBy("customId", "desc").limit(1).get();

      let nextId = `${prefix}1`;
      if (!snapshot.empty) {
        const lastId = snapshot.docs[0].data().customId;
        const lastNum = parseInt(lastId?.replace(/\D/g, "")) || 0;
        nextId = `${prefix}${lastNum + 1}`;
      }

      const participantData = {
        uid,
        email,
        instituteId, // ✅ **FIX: Added instituteId**
        name: name || "",
        role,
        year: year || "",
        customId: nextId,
        isProfileComplete: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await participantsRef.doc(uid).set(participantData);

      // Create profile inside same institute
      await admin
        .firestore()
        .collection("institutes")
        .doc(instituteId)
        .collection("profiles")
        .doc(uid)
        .set({
          uid,
          email,
          instituteId, // ✅ **FIX: Added instituteId for consistency**
          name: name || "",
          role,
          isProfileComplete: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      // If admin role, assign admin claim
      if (role === "admin") {
        await admin.auth().setCustomUserClaims(uid, { role: "admin" });
      }

      return {
        success: true,
        uid,
        message: `✅ ${role} created successfully in ${instituteId}`,
      };
    } catch (error) {
      logger.error("Error creating participant:", error);
      throw new Error(error.message);
    }
  }
);

// ========================== ADD ADMIN ROLE TO EXISTING USER ==========================
exports.addAdminRole = onCall(
  { region: "asia-south1" },
  async (request) => {
    const { email, instituteId } = request.data;
    if (!email || !instituteId) throw new Error("Email and instituteId are required.");

    try {
      const user = await admin.auth().getUserByEmail(email);
      await admin.auth().setCustomUserClaims(user.uid, { role: "admin" });

      const participantsRef = admin
        .firestore()
        .collection("institutes")
        .doc(instituteId)
        .collection("participants");

      await participantsRef.doc(user.uid).set(
        {
          email: user.email,
          role: "admin",
          instituteId, // ✅ **FIX: Added instituteId here too**
          name: user.displayName || "Admin",
          isProfileComplete: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return { message: `✅ ${email} promoted to Admin in ${instituteId}` };
    } catch (error) {
      throw new Error(`Error setting admin role: ${error.message}`);
    }
  }
);