# mycv_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase web setup

In the Firebase Console for `mycv-julio-2026`, enable **Authentication >
Sign-in method > Email/Password** and ensure the account exists under
**Authentication > Users**. Add the web app's hosting domain under
**Authentication > Settings > Authorized domains**.

When using the app through a GitHub Codespaces forwarded port, the port must be
reachable by the browser without redirecting requests to the GitHub sign-in
page. A private port can cause the browser's `manifest.json` request to fail
with a CORS error. Use an appropriately secured public port or deploy the app
to Firebase Hosting.

The VS Code **Flutter (web-server)** launch configuration connects directly to
the Firebase project configured in `lib/firebase_options.dart`.
