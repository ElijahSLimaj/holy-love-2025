/**
 * Migration script to add gender field to existing user profiles
 *
 * This script:
 * 1. Fetches all users from Firestore
 * 2. Infers gender from first names using common name lists
 * 3. Updates the user document, profileDetails subcollection, and searchIndex
 *
 * Usage:
 * 1. Download your Firebase service account key from Firebase Console
 * 2. Save it as 'serviceAccountKey.json' in the project root
 * 3. Run: node migrate_add_gender.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
// You need to download your service account key from Firebase Console
// Project Settings > Service Accounts > Generate new private key
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Common male first names
const maleNames = new Set([
  'james', 'john', 'robert', 'michael', 'david', 'william', 'richard', 'joseph', 'thomas', 'charles',
  'christopher', 'daniel', 'matthew', 'anthony', 'mark', 'donald', 'steven', 'paul', 'andrew', 'joshua',
  'kenneth', 'kevin', 'brian', 'george', 'timothy', 'ronald', 'edward', 'jason', 'jeffrey', 'ryan',
  'jacob', 'gary', 'nicholas', 'eric', 'jonathan', 'stephen', 'larry', 'justin', 'scott', 'brandon',
  'benjamin', 'samuel', 'raymond', 'gregory', 'frank', 'alexander', 'patrick', 'jack', 'dennis', 'jerry',
  'tyler', 'aaron', 'jose', 'adam', 'nathan', 'henry', 'douglas', 'zachary', 'peter', 'kyle',
  'noah', 'ethan', 'jeremy', 'walter', 'christian', 'keith', 'roger', 'terry', 'austin', 'sean',
  'gerald', 'carl', 'dylan', 'harold', 'jordan', 'jesse', 'bryan', 'lawrence', 'arthur', 'gabriel',
  'bruce', 'logan', 'albert', 'willie', 'alan', 'eugene', 'vincent', 'russell', 'elijah', 'randy',
  'philip', 'harry', 'wayne', 'howard', 'billy', 'steve', 'johnny', 'caleb', 'luke', 'connor',
  'isaac', 'evan', 'mason', 'liam', 'aiden', 'jackson', 'owen', 'carter', 'jayden', 'landon',
  'chase', 'hunter', 'cameron', 'cole', 'blake', 'alex', 'max', 'eli', 'ian', 'marcus',
  'adrian', 'antonio', 'miguel', 'carlos', 'luis', 'juan', 'francisco', 'javier', 'rafael', 'sergio',
  // Biblical/Christian names common in dating apps
  'nathaniel', 'ezekiel', 'jeremiah', 'isaiah', 'ezra', 'josiah', 'malachi', 'micah', 'silas', 'tobias',
  'abel', 'seth', 'jonah', 'levi', 'judah', 'asher', 'gideon', 'titus', 'simeon', 'zeke',
]);

// Common female first names
const femaleNames = new Set([
  'mary', 'patricia', 'jennifer', 'linda', 'elizabeth', 'barbara', 'susan', 'jessica', 'sarah', 'karen',
  'lisa', 'nancy', 'betty', 'margaret', 'sandra', 'ashley', 'kimberly', 'emily', 'donna', 'michelle',
  'dorothy', 'carol', 'amanda', 'melissa', 'deborah', 'stephanie', 'rebecca', 'sharon', 'laura', 'cynthia',
  'kathleen', 'amy', 'angela', 'shirley', 'anna', 'brenda', 'pamela', 'emma', 'nicole', 'helen',
  'samantha', 'katherine', 'christine', 'debra', 'rachel', 'carolyn', 'janet', 'catherine', 'maria', 'heather',
  'diane', 'ruth', 'julie', 'olivia', 'joyce', 'virginia', 'victoria', 'kelly', 'lauren', 'christina',
  'joan', 'evelyn', 'judith', 'megan', 'andrea', 'cheryl', 'hannah', 'jacqueline', 'martha', 'gloria',
  'teresa', 'ann', 'sara', 'madison', 'frances', 'kathryn', 'janice', 'jean', 'abigail', 'alice',
  'julia', 'judy', 'sophia', 'grace', 'denise', 'amber', 'doris', 'marilyn', 'danielle', 'beverly',
  'isabella', 'theresa', 'diana', 'natalie', 'brittany', 'charlotte', 'marie', 'kayla', 'alexis', 'lori',
  'ava', 'mia', 'chloe', 'zoe', 'lily', 'ella', 'harper', 'aria', 'scarlett', 'violet',
  'aurora', 'savannah', 'brooklyn', 'leah', 'stella', 'hazel', 'paisley', 'audrey', 'skylar', 'claire',
  'lucy', 'penelope', 'layla', 'riley', 'zoey', 'nora', 'elena', 'bella', 'maya', 'sophie',
  // Biblical/Christian names
  'ruth', 'esther', 'miriam', 'naomi', 'deborah', 'abigail', 'leah', 'rachel', 'rebecca', 'lydia',
  'priscilla', 'tabitha', 'eden', 'faith', 'hope', 'charity', 'joy', 'grace', 'mercy', 'serenity',
]);

/**
 * Infer gender from first name
 * @param {string} firstName
 * @returns {'male' | 'female' | null}
 */
function inferGender(firstName) {
  if (!firstName) return null;

  const normalizedName = firstName.toLowerCase().trim();

  if (maleNames.has(normalizedName)) {
    return 'male';
  }

  if (femaleNames.has(normalizedName)) {
    return 'female';
  }

  // Check for common endings (less reliable but helpful)
  if (normalizedName.endsWith('a') || normalizedName.endsWith('ie') || normalizedName.endsWith('lyn')) {
    return 'female';
  }

  return null;
}

/**
 * Main migration function
 */
async function migrateAddGender() {
  console.log('Starting gender migration...\n');

  const usersRef = db.collection('users');
  const snapshot = await usersRef.get();

  let updated = 0;
  let skipped = 0;
  let unknown = [];

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const userId = doc.id;
    const firstName = data.firstName;

    // Check if gender already exists
    if (data.gender) {
      console.log(`✓ ${firstName} (${userId.slice(0, 8)}...) - Already has gender: ${data.gender}`);
      skipped++;
      continue;
    }

    const inferredGender = inferGender(firstName);

    if (!inferredGender) {
      console.log(`? ${firstName} (${userId.slice(0, 8)}...) - Could not infer gender`);
      unknown.push({ userId, firstName });
      continue;
    }

    try {
      const batch = db.batch();

      // Update main user document
      const userRef = usersRef.doc(userId);
      batch.update(userRef, { gender: inferredGender });

      // Update profileDetails subcollection
      const detailsRef = usersRef.doc(userId).collection('profileDetails').doc('details');
      batch.set(detailsRef, { gender: inferredGender }, { merge: true });

      // Update searchIndex
      const searchIndexRef = db.collection('searchIndex').doc(userId);
      batch.set(searchIndexRef, { gender: inferredGender }, { merge: true });

      await batch.commit();

      console.log(`✓ ${firstName} (${userId.slice(0, 8)}...) - Set gender to: ${inferredGender}`);
      updated++;
    } catch (error) {
      console.error(`✗ Error updating ${firstName} (${userId}):`, error.message);
    }
  }

  console.log('\n--- Migration Summary ---');
  console.log(`Total users: ${snapshot.size}`);
  console.log(`Updated: ${updated}`);
  console.log(`Skipped (already had gender): ${skipped}`);
  console.log(`Unknown (needs manual review): ${unknown.length}`);

  if (unknown.length > 0) {
    console.log('\nUsers requiring manual gender assignment:');
    unknown.forEach(u => {
      console.log(`  - ${u.firstName} (${u.userId})`);
    });
    console.log('\nTo manually update these users, run:');
    console.log('  node migrate_add_gender.js --manual <userId> <gender>');
  }

  console.log('\nMigration complete!');
}

/**
 * Manually set gender for a specific user
 */
async function setGenderManually(userId, gender) {
  if (!['male', 'female'].includes(gender)) {
    console.error('Gender must be "male" or "female"');
    process.exit(1);
  }

  const batch = db.batch();

  // Update main user document
  const userRef = db.collection('users').doc(userId);
  batch.update(userRef, { gender });

  // Update profileDetails subcollection
  const detailsRef = db.collection('users').doc(userId).collection('profileDetails').doc('details');
  batch.set(detailsRef, { gender }, { merge: true });

  // Update searchIndex
  const searchIndexRef = db.collection('searchIndex').doc(userId);
  batch.set(searchIndexRef, { gender }, { merge: true });

  await batch.commit();

  console.log(`✓ Updated user ${userId} with gender: ${gender}`);
}

// Parse command line arguments
const args = process.argv.slice(2);

if (args[0] === '--manual' && args[1] && args[2]) {
  setGenderManually(args[1], args[2])
    .then(() => process.exit(0))
    .catch(err => {
      console.error('Error:', err);
      process.exit(1);
    });
} else {
  migrateAddGender()
    .then(() => process.exit(0))
    .catch(err => {
      console.error('Error:', err);
      process.exit(1);
    });
}
