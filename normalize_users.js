const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function normalizeUsers() {
  const snapshot = await db.collection("users").get();

  for (const doc of snapshot.docs) {
    const data = doc.data();

    let department = data.department || "";
    let role = data.role || "";
    let className = data.className || data.class || "";

    // NORMALIZE DEPARTMENT
    const dept = department.toUpperCase();

    if (dept === "TKJ" || dept === "TJKT" || dept.includes("TEKNIK")) {
      department = "TJKT";
    }

    if (dept === "DKV" || dept === "MM") {
      department = "DKV";
    }

    if (dept === "MPLB") {
      department = "MPLB";
    }

    if (dept === "AKL") {
      department = "AKL";
    }

    // NORMALIZE ROLE
    role = role.toString().toLowerCase();

    if (role === "student" || role === "siswa" || role === "murid") {
      role = "student";
    }

    // FIX CLASSNAME
    className = className.replace(/-/g, " ").trim();

    await db.collection("users").doc(doc.id).update({
      department,
      role,
      className,
      class: className,
    });

    console.log(`UPDATED: ${data.name}`);
  }

  console.log("NORMALIZATION COMPLETE");
}

normalizeUsers();
