# [FirebasePhoneAuthHandler](https://pub.dev/packages/firebase_phone_auth_handler) For Flutter
[![pub package](https://img.shields.io/pub/v/firebase_phone_auth_handler.svg)](https://pub.dev/packages/firebase_phone_auth_handler)
[![likes](https://img.shields.io/pub/likes/firebase_phone_auth_handler)](https://pub.dev/packages/firebase_phone_auth_handler/score)
[![popularity](https://img.shields.io/pub/popularity/firebase_phone_auth_handler)](https://pub.dev/packages/firebase_phone_auth_handler/score)
[![pub points](https://img.shields.io/pub/points/firebase_phone_auth_handler)](https://pub.dev/packages/firebase_phone_auth_handler/score)
[![code size](https://img.shields.io/github/languages/code-size/rithik-dev/firebase_phone_auth_handler)](https://github.com/rithik-dev/firebase_phone_auth_handler)
[![license MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

---

An easy-to-use firebase phone authentication package to easily send and verify OTP's with auto-fetch OTP support via SMS. Supports OTP on web out of the box.

---

# 🗂️ Table of Contents

- **[📷 Screenshots](#-screenshots)**
- **[✨ Features](#-features)**
- **[🛫 Migration Guides](#-migration-guides)**  
  - [Migration Guide from v1.x to v2.x+](#migration-guide-from-v1x-to-v2x)
- **[🚀 Getting Started](#-getting-started)**
- **[🛠️ Platform-specific Setup](#%EF%B8%8F-platform-specific-setup)**  
  - [Android](#android)
  - [iOS](#ios)
  - [Web](#web-recaptcha)
- **[❓ Usage](#-usage)**  
- **[🎯 Sample Usage](#-sample-usage)**
- **[👤 Collaborators](#-collaborators)**

---

# 📷 Screenshots

| Demo | Sending OTP | Auto Fetch OTP |
|-----------------------------------|-------------------------------------|-------------------------------------|
| <img src="https://user-images.githubusercontent.com/56810766/166433323-39875cc4-440a-4556-9550-1b5ab4e8f310.gif" height="500"> | <img src="https://user-images.githubusercontent.com/56810766/115599396-33876600-a2f9-11eb-9516-d0f189b88a53.jpeg" height="500"> | <img src="https://user-images.githubusercontent.com/56810766/115599390-31bda280-a2f9-11eb-8990-d3df76d3aabc.jpg" height="500"> |

---

# ✨ Features

- **Simple OTP Verification Process:** This package simplifies phone number authentication with Firebase, automatically managing OTP request and verification for you.
- **SMS Autofill Support:** Automatically fetches and enters the received OTP from the SMS, streamlining the user experience on Android.
- **Easy-to-use Callbacks:** You can define custom callbacks like `onLoginSuccess`, `onLoginFailed` etc., making the widget simple to use.
- **Configurable Resend OTP Timer:** You can easily configure the time interval for OTP resend requests, ensuring users don’t spam the request button.
- **Cross-Platform Support:** It provides full support for Android, iOS and Web, ensuring a consistent experience across platforms.
- **Widget-Based Approach:** The package integrates well with Flutter’s UI-driven architecture, offering a widget-based solution for handling phone authentication.
- **Seamless Integration:** The package can be easily integrated into any Flutter app, allowing quick and reliable phone authentication with Firebase.

---

# 🛫 Migration Guides

## Migration Guide from v1.x to v2.x+

### 1. `FirebasePhoneAuthProvider` was removed
`FirebasePhoneAuthHandler` now creates and owns the controller it passes to your `builder`,
so there is nothing to wrap your app with. The widget is gone — delete it from your tree:

```dart
// before
FirebasePhoneAuthProvider(
  child: MaterialApp(home: HomeScreen()),
)

// after
MaterialApp(home: HomeScreen())
```

The one capability this removes is reading the controller from a widget that is **not**
inside a handler, because there is no longer a single app-wide instance. Use the controller
passed to `builder`, or `context.watch<FirebasePhoneAuthController>()` from within it.

That single shared instance was also the source of several bugs: a verification session
could leak into the next screen, and two handlers mounted at the same time overwrote each
other's configuration. Each handler now gets a fresh controller, disposed when it unmounts.

### 2. `controller.clear()` was removed
It existed only to reset the shared app-wide controller between handlers. Since each handler
now disposes its own controller, there is nothing to reset. Calling it also left the
controller without a phone number and therefore unusable, so it was a footgun rather than a
useful reset. Delete the calls — unmounting the handler is the teardown.

### 3. `signOut()` no longer takes a `BuildContext`
It used to resolve the controller through the provider purely to reach
`FirebaseAuth.instance.signOut()`. Drop the argument:

```dart
// before
await FirebasePhoneAuthHandler.signOut(context);

// after
await FirebasePhoneAuthHandler.signOut();

// or, when using a secondary Firebase app
await FirebasePhoneAuthHandler.signOut(auth: myAuth);
```

### 4. `otpSendStatus` replaces the boolean pair as the source of truth
`codeSent` and `isSendingCode` remain as convenience shorthands, but they are now derived
from a new `OtpSendStatus` enum (`idle`, `sending`, `sent`, `failed`).

Two booleans could not express "nothing has happened yet" or "the last attempt failed" —
`isSendingCode` was literally defined as `!codeSent`, so a fresh controller reported that it
was sending. Any UI gated on it showed a "sending OTP" loader that never cleared when
`sendOtpOnInitialize` was `false`, or when a send failed. Switch on `otpSendStatus` where
that distinction matters:

```dart
body: switch (controller.otpSendStatus) {
  OtpSendStatus.idle || OtpSendStatus.failed => RetryButton(),
  OtpSendStatus.sending => Loader(),
  OtpSendStatus.sent => OtpEntryField(),
},
```

`codeSent` also changed from a settable field to a getter, so any code assigning to it
(`controller.codeSent = true`) no longer compiles. Such assignments always desynced the
controller from what had actually happened.

### 5. `sendOTP` now times out by default
Firebase does not guarantee that it calls back at all. When device verification cannot
complete — for example on Android with no SHA-1 registered — neither `codeSent` nor
`verificationFailed` ever fires, and the controller would sit in `sending` forever.

`sendOTP` now accepts `codeSendTimeout`, defaulting to 60 seconds. On timeout the status
becomes `OtpSendStatus.failed`, `onError` receives a `TimeoutException` explaining the likely
cause, and `sendOTP` returns `false`. Pass `null` for the old unbounded behaviour.

### 6. Minimum SDK versions raised
- Requires Dart 3.8 / Flutter 3.32 or newer, up from Dart 3.2 / Flutter 3.16.
- iOS apps need a deployment target of **15.0**, up from 13.0. `firebase_auth` 6 pulls in
  Firebase 12, whose `firebase-auth` and `firebase-core` packages require iOS 15. Without it
  the build fails with `Target Integrity (Xcode): The package product 'firebase-auth'
  requires minimum platform version 15.0`.
- Android needs Gradle 8.7 or newer (Flutter warns below 8.14). `minSdk` must be at least 23,
  which Flutter's own default of 24 already satisfies.

### 7. `firebase_auth` moved 5 → 6
This package re-exports `firebase_auth`, so its breaking changes reach your code directly.
See its [changelog](https://pub.dev/packages/firebase_auth/changelog) for the full list.

### 8. iOS setup gained a required step
Firebase phone auth needs a custom URL scheme registered in `Info.plist`, or the app
hard-crashes when it falls back to reCAPTCHA — which is always the case on the simulator.
This was always required by Firebase but was not documented here before. See
[Platform-Specific Setup → iOS](#ios).

### 9. New: pass a custom `FirebaseAuth` instance
`FirebasePhoneAuthHandler` accepts an `auth` parameter, defaulting to `FirebaseAuth.instance`.
Pass one explicitly to verify against a secondary `FirebaseApp`, or to inject a fake in tests:

```dart
FirebasePhoneAuthHandler(
  auth: FirebaseAuth.instanceFor(app: secondaryApp),
  phoneNumber: '+911234567890',
  builder: (context, controller) => ...,
);
```

Nothing to change unless you need this — the default behaves exactly as before.

For more details, refer to the [CHANGELOG](https://github.com/rithik-dev/firebase_phone_auth_handler/blob/master/CHANGELOG.md).

---

# 🚀 Getting Started

## Step 1: Create Firebase Project
Create a Firebase project. Learn more about Firebase projects [**here**](https://firebase.google.com/docs/projects/learn-more).

## Step 2: Register your apps and configure Firebase
Add your Android, iOS, Web apps to your Firebase project and configure the Firebase the apps by following the setup instructions for [Android](https://firebase.google.com/docs/flutter/setup?platform=android), [iOS](https://firebase.google.com/docs/flutter/setup?platform=ios) and [Web](https://firebase.google.com/docs/flutter/setup?platform=web) separately.

> [!IMPORTANT]
> Follow additional configration steps for Firebase Auth [here](https://firebase.google.com/docs/auth/flutter/start)

## Step 3: Enable Phone Authentication
Open the Firebase Console, go to the **Authentication** section in your project.
Select **Sign-in method** and enable **Phone**.

## Step 4: Enable Google Play Integrity API (Android Only)
For Android, enable the [`Google Play Integrity API`](https://console.cloud.google.com/apis/library/playintegrity.googleapis.com) from Google Cloud Platform.

## Step 5: Add firebase_core dependency
Add [`firebase_core`](https://pub.dev/packages/firebase_core) as a dependency in your pubspec.yaml file.
```yaml
dependencies:
  flutter:
    sdk: flutter

  firebase_core:
```

## Step 6: Initialize Firebase
Call `Firebase.initializeApp()` in the `main()` method as shown to intialize Firebase in your project.

```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}
```

---

# 🛠️ Platform-Specific Setup

## Android

### 1. Register your SHA certificate fingerprints (required)

Android verifies the device before sending an SMS, using Play Integrity. That check is tied to
the certificate your app is signed with, so Firebase needs your **SHA-1 and SHA-256**
fingerprints. Enabling the Play Integrity API (Step 4 above) is not sufficient on its own.

Get them with:

```bash
cd android && ./gradlew signingReport
```

Add both to **Firebase Console → Project settings → Your apps → Android → Add fingerprint**,
then **re-download `google-services.json`** and replace `android/app/google-services.json`.

> [!IMPORTANT]
> You need a fingerprint for **every** signing key you use: the debug keystore, your release
> keystore, and — if you use Play App Signing — the **App signing key certificate** shown
> under Play Console → Test and release → Setup → App signing. Google re-signs your upload
> with a different key, so phone auth can work locally and in internal testing yet fail for
> everyone once the app is live. That one is easy to miss.

### 2. What it looks like when this is missing

There is no clear error. The send simply never completes: neither `onCodeSent` nor
`onLoginFailed` fires, and the controller stays in `OtpSendStatus.sending`. In `logcat` you
will see the device-verification fallback failing:

```
E/zza: Failed to initialize reCAPTCHA config: No Recaptcha Enterprise siteKey
       configured for tenant/project *
```

Because Firebase never calls back, `sendOTP` would otherwise wait forever. It is bounded by
[`codeSendTimeout`](#-usage) (60 seconds by default), after which `otpSendStatus` becomes
`OtpSendStatus.failed` and `onError` receives a `TimeoutException`.

### 3. minSdk

`firebase_auth` requires **minSdk 23**. Flutter's own default (`flutter.minSdkVersion`) is
already 24, so this only matters if you have hardcoded a lower value in
`android/app/build.gradle`.

### Testing

Real device verification needs a real, non-emulated device and correct fingerprints. For
everything else, register a test number under **Firebase Console → Authentication →
Sign-in method → Phone → Phone numbers for testing**. Test numbers skip Play Integrity and
reCAPTCHA entirely, so they work on emulators and are the fastest way to tell a
configuration problem apart from a code problem.

---

## iOS

Two pieces of iOS setup are easy to miss, and neither fails in a way that points at the cause.

### 1. Register the custom URL scheme (required)

When APNs silent-push verification is unavailable — which is **always** the case on the
simulator — Firebase falls back to a reCAPTCHA web flow and returns to your app through a
custom URL scheme. If that scheme is not registered, the app **hard-crashes**:

```
FirebaseAuth/PhoneAuthProvider.swift:109: Fatal error: Please register custom URL
scheme app-1-1234567890-ios-abc123def456 in the app's Info.plist file.
```

The scheme is your `GOOGLE_APP_ID` from `GoogleService-Info.plist` with every `:` and `.`
replaced by `-`, prefixed with `app-`. Derive it rather than typing it out:

```bash
cd ios && echo "app-$(plutil -extract GOOGLE_APP_ID raw -o - Runner/GoogleService-Info.plist | tr ':.' '--')"
```

Add it to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>app-1-1234567890-ios-abc123def456</string>
    </array>
  </dict>
</array>
```

> **Note:** this is *not* the same as `REVERSED_CLIENT_ID`. That scheme is for Google
> Sign-In. Registering only `REVERSED_CLIENT_ID` will not stop the crash above.

If you re-run `flutterfire configure` and it changes which iOS app the project points at,
`GOOGLE_APP_ID` changes too and this scheme must be re-derived.

### 2. Deep linking

Firebase returns from the reCAPTCHA flow through the scheme above. `FirebaseAuth` consumes
that callback itself, but if Flutter's deep linking is enabled the engine **also** turns the
callback URL into a route name and pushes it, so your app navigates to a bogus route like
`/link?deep_link_id=...` on top of the OTP screen.

If your app does not use deep links, disable them in `ios/Runner/Info.plist`:

```xml
<key>FlutterDeepLinkingEnabled</key>
<false/>
```

If your app *does* need deep links, leave that enabled and ignore the callback in your
router instead:

```dart
if (name.startsWith('/link') && name.contains('deep_link_id')) {
  // Firebase auth reCAPTCHA callback, not a route this app owns.
  return null;
}
```

### 3. Minimum deployment target

`firebase_auth` 6 requires **iOS 15.0**. If `IPHONEOS_DEPLOYMENT_TARGET` is lower, the build
fails with `Target Integrity (Xcode): The package product 'firebase-auth' requires minimum
platform version 15.0`.

### Testing on the simulator

The simulator has no APNs, so every send takes the reCAPTCHA path. The most reliable way to
test is a test phone number: **Firebase Console → Authentication → Sign-in method → Phone →
Phone numbers for testing**. Those bypass APNs and reCAPTCHA entirely.

---

## Web (reCAPTCHA)

On Web, the reCAPTCHA widget is a fully managed flow which provides security to your web application.
The widget will render as an invisible widget when the sign-in flow is triggered. An "invisible"
widget will appear as a full-page modal on-top of your application like demonstrated below.

![reCAPTCHA1](https://user-images.githubusercontent.com/56810766/119164921-8da35480-ba7a-11eb-8169-eafd67bfdc12.png)

Although, a `RecaptchaVerifier` instance can be passed which can be used to manage the widget.

Use the function `recaptchaVerifierForWebProvider` in `FirebasePhoneAuthHandler` which gives a boolean
to check whether the current platform is Web or not.

`NOTE`: Do not pass a `RecaptchaVerifier` instance if the platform is not web, else an error occurs.

Example:
```dart
recaptchaVerifierForWebProvider: (isWeb) {
  if (isWeb) return RecaptchaVerifier();
},
```

It is however possible to display an inline widget which the user has to explicitly press to verify themselves.

![reCAPTCHA2](https://user-images.githubusercontent.com/56810766/119164930-8f6d1800-ba7a-11eb-9e3d-d58a50c959bd.png)

To add an inline widget, specify a DOM element ID to the container argument of the `RecaptchaVerifier` instance.
The element must exist and be empty otherwise an error will be thrown.
If no container argument is provided, the widget will be rendered as "invisible".

```dart
RecaptchaVerifier(
  container: 'recaptcha',
  size: RecaptchaVerifierSize.compact,
  theme: RecaptchaVerifierTheme.dark,
  onSuccess: () => print('reCAPTCHA Completed!'),
  onError: (FirebaseAuthException error) => print(error),
  onExpired: () => print('reCAPTCHA Expired!'),
),
```

If the reCAPTCHA badge does not disappear automatically after authentication is done,
try adding the following code in `onLoginSuccess` so that it disappears when the login process is done.

Firstly import `querySelector` from `dart:html`.
```dart
import 'dart:html' show querySelector;
```

Then add this in `onLoginSuccess` callback.
```dart
final captcha = querySelector('#__ff-recaptcha-container');
if (captcha != null) captcha.hidden = true;
```

If you want to completely disable the reCAPTCHA badge (typically appears on the bottom right),
add this CSS style in the `web/index.html` outside any other tag.

```html
<style>
  .grecaptcha-badge { visibility: hidden; }
</style>
```

---

# ❓ Usage

1. Add [`firebase_phone_auth_handler`](https://pub.dev/packages/firebase_phone_auth_handler) as a dependency in your pubspec.yaml file.
```yaml
dependencies:
  flutter:
    sdk: flutter

  firebase_phone_auth_handler:
```

2. Use [`FirebasePhoneAuthHandler`](https://github.com/rithik-dev/firebase_phone_auth_handler/blob/master/lib/firebase_phone_auth_handler.dart) widget in your widget tree and pass all the required parameters to get started.
```dart
FirebasePhoneAuthHandler(
  // required
  phoneNumber: "+919876543210",
  // If true, the user is signed out before the onLoginSuccess callback is fired when the OTP is verified successfully.
  signOutOnSuccessfulVerification: false,
  linkWithExistingUser: false,
  // required
  builder: (context, controller) {
    return SizedBox.shrink();
  },
  onLoginSuccess: (userCredential, autoVerified) {
    debugPrint("autoVerified: $autoVerified");
    debugPrint("Login success UID: ${userCredential.user?.uid}");
  },
  onLoginFailed: (authException, stackTrace) {
    debugPrint("An error occurred: ${authException.message}");
  },
  onError: (error, stackTrace) {},
),
```

3. To logout the current user(if any), call
```dart
await FirebasePhoneAuthHandler.signOut();

// OR

controller.signOut(); // can also be used to logout the current user.
```

---

# 🎯 Sample Usage

See the [example](https://github.com/rithik-dev/firebase_phone_auth_handler/blob/master/example) app for a complete app. Learn how to setup the example app for testing [here](https://github.com/rithik-dev/firebase_phone_auth_handler/blob/master/example/README.md).

Check out the full API reference of the widget [here](https://pub.dev/documentation/firebase_phone_auth_handler/latest/firebase_phone_auth_handler/FirebasePhoneAuthHandler-class.html).

```dart
import 'package:firebase_phone_auth_handler/firebase_phone_auth_handler.dart';
import 'package:flutter/material.dart';
import 'package:phone_auth_handler_demo/screens/home_screen.dart';
import 'package:phone_auth_handler_demo/utils/helpers.dart';
import 'package:phone_auth_handler_demo/widgets/custom_loader.dart';
import 'package:phone_auth_handler_demo/widgets/pin_input_field.dart';

class VerifyPhoneNumberScreen extends StatefulWidget {
  static const id = 'VerifyPhoneNumberScreen';

  final String phoneNumber;

  const VerifyPhoneNumberScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<VerifyPhoneNumberScreen> createState() => _VerifyPhoneNumberScreenState();
}

class _VerifyPhoneNumberScreenState extends State<VerifyPhoneNumberScreen> with WidgetsBindingObserver {
  bool isKeyboardVisible = false;

  late final ScrollController scrollController;

  @override
  void initState() {
    scrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomViewInsets = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    isKeyboardVisible = bottomViewInsets > 0;
  }

  // scroll to bottom of screen, when pin input field is in focus.
  Future<void> _scrollToBottomOnKeyboardOpen() async {
    while (!isKeyboardVisible) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    await Future.delayed(const Duration(milliseconds: 250));

    await scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FirebasePhoneAuthHandler(
        phoneNumber: widget.phoneNumber,
        signOutOnSuccessfulVerification: false,
        sendOtpOnInitialize: true,
        linkWithExistingUser: false,
        autoRetrievalTimeOutDuration: const Duration(seconds: 60),
        otpExpirationDuration: const Duration(seconds: 60),
        onCodeSent: () {
          log(VerifyPhoneNumberScreen.id, msg: 'OTP sent!');
        },
        onLoginSuccess: (userCredential, autoVerified) async {
          log(
            VerifyPhoneNumberScreen.id,
            msg: autoVerified ? 'OTP was fetched automatically!' : 'OTP was verified manually!',
          );

          showSnackBar('Phone number verified successfully!');

          log(
            VerifyPhoneNumberScreen.id,
            msg: 'Login Success UID: ${userCredential.user?.uid}',
          );

          Navigator.pushNamedAndRemoveUntil(
            context,
            HomeScreen.id,
            (route) => false,
          );
        },
        onLoginFailed: (authException, stackTrace) {
          log(
            VerifyPhoneNumberScreen.id,
            msg: authException.message,
            error: authException,
            stackTrace: stackTrace,
          );

          switch (authException.code) {
            case 'invalid-phone-number':
              // invalid phone number
              return showSnackBar('Invalid phone number!');
            case 'invalid-verification-code':
              // invalid otp entered
              return showSnackBar('The entered OTP is invalid!');
            // handle other error codes
            default:
              showSnackBar('Something went wrong!');
            // handle error further if needed
          }
        },
        onError: (error, stackTrace) {
          log(
            VerifyPhoneNumberScreen.id,
            error: error,
            stackTrace: stackTrace,
          );

          showSnackBar('An error occurred!');
        },
        builder: (context, controller) {
          return Scaffold(
            appBar: AppBar(
              leadingWidth: 0,
              leading: const SizedBox.shrink(),
              title: const Text('Verify Phone Number'),
              actions: [
                if (controller.codeSent)
                  TextButton(
                    onPressed: controller.isOtpExpired
                        ? () async {
                            log(VerifyPhoneNumberScreen.id, msg: 'Resend OTP');
                            await controller.sendOTP();
                          }
                        : null,
                    child: Text(
                      controller.isOtpExpired ? 'Resend' : '${controller.otpExpirationTimeLeft.inSeconds}s',
                      style: const TextStyle(color: Colors.blue, fontSize: 18),
                    ),
                  ),
                const SizedBox(width: 5),
              ],
            ),
            body: switch (controller.otpSendStatus) {
              // Nothing in flight: either the OTP was never requested, or the
              // last attempt failed. Both need an affordance to (re)send —
              // previously these states rendered a loader that never cleared.
              OtpSendStatus.idle || OtpSendStatus.failed => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.otpSendStatus == OtpSendStatus.failed
                          ? 'Could not send the OTP.'
                          : 'Tap below to send the OTP.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: controller.sendOTP,
                      child: Text(
                        controller.otpSendStatus == OtpSendStatus.failed ? 'Retry' : 'Send OTP',
                      ),
                    ),
                  ],
                ),
              ),
              OtpSendStatus.sending => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  CustomLoader(),
                  SizedBox(height: 50),
                  Center(
                    child: Text(
                      'Sending OTP',
                      style: TextStyle(fontSize: 25),
                    ),
                  ),
                ],
              ),
              OtpSendStatus.sent => ListView(
                padding: const EdgeInsets.all(20),
                controller: scrollController,
                children: [
                  Text(
                    "We've sent an SMS with a verification code to ${widget.phoneNumber}",
                    style: const TextStyle(fontSize: 25),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  if (controller.isListeningForOtpAutoRetrieve)
                    Column(
                      children: const [
                        CustomLoader(),
                        SizedBox(height: 50),
                        Text(
                          'Listening for OTP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 15),
                        Divider(),
                        Text('OR', textAlign: TextAlign.center),
                        Divider(),
                      ],
                    ),
                  const SizedBox(height: 15),
                  const Text(
                    'Enter OTP',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 15),
                  PinInputField(
                    length: 6,
                    onFocusChange: (hasFocus) async {
                      if (hasFocus) await _scrollToBottomOnKeyboardOpen();
                    },
                    onSubmit: (enteredOtp) async {
                      final verified = await controller.verifyOtp(enteredOtp);
                      if (verified) {
                        // number verify success
                        // will call onLoginSuccess handler
                      } else {
                        // phone verification failed
                        // will call onLoginFailed or onError callbacks with the error
                      }
                    },
                  ),
                ],
              ),
            },
          );
        },
      ),
    );
  }
}
```

---

# 👤 Collaborators


| Name | GitHub | Linkedin |
|-----------------------------------|-------------------------------------|-------------------------------------|
| Rithik Bhandari | [github/rithik-dev](https://github.com/rithik-dev) | [linkedin/rithik-bhandari](https://www.linkedin.com/in/rithik-bhandari) |
