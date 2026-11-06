# Firebase Emulator Testing

The local Auth and Firestore emulators run on `127.0.0.1:9099` and
`127.0.0.1:8080`. Emulator tests use only the Firebase CLI demo project
`demo-aquaqueue`; scripts reject the production project ID and hard-code
loopback emulator endpoints.

## Run the integration tests

From the repository root, with Node.js and the Firebase CLI installed:

```powershell
$env:JAVA_HOME = '<path to JDK 21 or newer>'
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
npm run test:emulator
```

This starts Auth and Firestore, seeds one admin, two customers, and three
products, runs integration tests against the local emulators, and shuts them
down. Seed accounts use the local-only password `LocalOnly123!`; never use
these fixtures with a real Firebase project. Emulator-owner authorization is
used only to write fixture profiles with the admin role.

Run the existing Firestore rules suite separately with:

```powershell
npm run test:rules
```

To connect a debug Android app to the same emulators while the emulator process
is running, use:

```powershell
firebase emulators:start --only auth,firestore --project demo-aquaqueue
```

In another terminal:

```powershell
flutter run --dart-define=AQUAQUEUE_USE_FIREBASE_EMULATORS=true
```

The Android emulator reaches the host through `10.0.2.2`. The app refuses to
use emulator mode in non-debug builds and initializes Firebase with the
`demo-aquaqueue` project ID and dummy API/app identifiers when the emulator
flag is set. Normal builds continue to use the configured Firebase project.
