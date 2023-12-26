# Riparazioni 2

This is a (quick) rewrite of the original Riparazioni using SwiftUI (and Swift).
Some features are currently missing with respect the original Cocoa and XIB framework.

Differently from the original Riparazioni, this version does no longer use CoreData and a local sqlite database, but it connects to Firebase Firestore no-SQL database.

Follow the instructions on https://firebase.google.com/docs/firestore/quickstart#ios+ to create your project and download the `GoogleService-Info.plist` into the Xcode project to connect to your Firestore DB.
