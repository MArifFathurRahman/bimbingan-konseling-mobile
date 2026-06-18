// BINUSA SAFESPACE - AUTH SEED SCRIPT
// =====================================
//
// Creates Firebase Auth accounts for existing Firestore student users.
//
// Prerequisites:
//   1. Node.js 18+
//   2. Firebase Admin SDK service account JSON
//      (Firebase Console > Settings > Service Accounts > Generate Key)
//   3. Install: npm install firebase-admin
//
// Usage:
//   $env:GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account.json"
//   node scripts/seed_auth.js
//
// What it does:
//   1. Reads all students from Firestore users collection
//   2. Skips users who already have authUid or are on the skip list
//   3. For each of the first 5 unmatched students:
//      a. Generates email from name
//      b. Creates Firebase Auth account with password "12345678"
//      c. Updates Firestore document with authUid field

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// === CONFIGURATION ===

const SKIP_NAMES = ['Alif Afriza']; // Already has auth
const PASSWORD = '12345678';
const MAX_ACCOUNTS = 5;

// Department allocation: at least 1 per department
const DEPARTMENTS = ['TJKT', 'DKV', 'MPLB', 'AKL'];

// === INITIALIZE ===

const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (!credPath) {
  console.error('ERROR: Set GOOGLE_APPLICATION_CREDENTIALS environment variable');
  console.error('Example:');
  console.error('  $env:GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account.json"');
  process.exit(1);
}

const absPath = path.resolve(credPath);
if (!fs.existsSync(absPath)) {
  console.error(`ERROR: Service account file not found at: ${absPath}`);
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});
const db = admin.firestore();
const auth = admin.auth();

// === HELPERS ===

function generateEmail(name) {
  // lowercase, remove special chars, remove spaces, append @student.com
  const clean = name
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '')
    .trim();
  return `${clean}@student.com`;
}

function selectStudents(students, count) {
  // Ensure at least 1 per department, then fill remaining
  const selected = [];
  const usedIds = new Set();

  // Pick 1 from each required department
  for (const dept of DEPARTMENTS) {
    const match = students.find(s => s.department === dept && !usedIds.has(s.id));
    if (match) {
      selected.push(match);
      usedIds.add(match.id);
    }
  }

  // Fill remaining slots from any department
  const remaining = students.filter(s => !usedIds.has(s.id));
  for (const s of remaining) {
    if (selected.length >= count) break;
    selected.push(s);
    usedIds.add(s.id);
  }

  return selected.slice(0, count);
}

// === MAIN ===

async function main() {
  console.log('=== BINUSA SAFESPACE AUTH SEED ===\n');

  // 1. Fetch all students from Firestore
  const snapshot = await db.collection('users')
    .where('role', '==', 'student')
    .get();

  const allStudents = [];
  snapshot.forEach(doc => {
    allStudents.push({ id: doc.id, ...doc.data() });
  });

  console.log(`Found ${allStudents.length} students in Firestore.\n`);

  // 2. Filter out already-connected or skipped users
  const available = allStudents.filter(s => {
    if (!s.name) return false;
    if (SKIP_NAMES.includes(s.name)) return false;
    if (s.authUid) return false; // Already has auth connection
    return true;
  });

  console.log(`Available after filtering: ${available.length} students\n`);

  if (available.length === 0) {
    console.log('No students available for auth creation. All are already connected or skipped.');
    process.exit(0);
  }

  // 3. Select students (department-distributed)
  const toCreate = selectStudents(available, MAX_ACCOUNTS);

  console.log('Creating auth accounts for:\n');

  const results = [];

  for (const student of toCreate) {
    const email = generateEmail(student.name);

    try {
      // Check if email already exists in Auth
      let existingUser = null;
      try {
        existingUser = await auth.getUserByEmail(email);
      } catch (_) {
        // Not found - good
      }

      if (existingUser) {
        // Check if this user already has a Firestore connection
        if (student.authUid) {
          console.log(`  SKIP ${student.name}: already connected (uid: ${student.authUid})`);
          continue;
        }
        // Email exists but no connection - update Firestore with existing uid
        await db.collection('users').doc(student.id).update({
          authUid: existingUser.uid,
        });
        console.log(`  LINK ${student.name}: ${email} (uid: ${existingUser.uid})`);
        results.push({ name: student.name, email, uid: existingUser.uid });
        continue;
      }

      // Create new Firebase Auth account
      const userRecord = await auth.createUser({
        email: email,
        password: PASSWORD,
        displayName: student.name,
        disabled: false,
      });

      // Update Firestore document with authUid
      await db.collection('users').doc(student.id).update({
        authUid: userRecord.uid,
      });

      console.log(`  CREATE ${student.name}: ${email} (uid: ${userRecord.uid})`);
      results.push({ name: student.name, email, uid: userRecord.uid });
    } catch (err) {
      console.error(`  ERROR ${student.name}: ${err.message}`);
    }
  }

  // === SUMMARY ===
  console.log('\n=== SUMMARY ===');
  console.log(`Total created/linked: ${results.length}`);
  console.log('');

  if (results.length > 0) {
    console.log('Login credentials:');
    console.log('Password: 12345678');
    console.log('');
    console.log('Email             | Student');
    console.log('-' .repeat(45));
    for (const r of results) {
      console.log(`${r.email.padEnd(18)} | ${r.name}`);
    }
  }

  console.log('\nDone.');
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
