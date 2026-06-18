const admin = require("firebase-admin");
const students = require("./students_firestore_ready.json");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function importStudents() {
  for (const student of students) {
    await db.collection("users").add(student);
    console.log(`Imported: ${student.name}`);
  }

  console.log("DONE IMPORT");
}

importStudents();
