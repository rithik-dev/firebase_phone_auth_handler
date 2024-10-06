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
- **[🚀 Getting Started](#-getting-started)**
- **[🛠️ Platform-specific Setup](#%EF%B8%8F-platform-specific-setup)**  
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

2. Wrap the `MaterialApp` with `FirebasePhoneAuthProvider` to enable your application to support phone authentication.
```dart
import 'package:firebase_phone_auth_handler/firebase_phone_auth_handler.dart';

class _MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FirebasePhoneAuthProvider(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeScreen(),
      ),
    );
  }
}
```

4. Use [`FirebasePhoneAuthHandler`](https://github.com/rithik-dev/firebase_phone_auth_handler/blob/master/lib/firebase_phone_auth_handler.dart) widget in your widget tree and pass all the required parameters to get started.
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

5. To logout the current user(if any), call
```dart
await FirebasePhoneAuthHandler.signOut(context);

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
  State<VerifyPhoneNumberScreen> createState() =>
      _VerifyPhoneNumberScreenState();
}

class _VerifyPhoneNumberScreenState extends State<VerifyPhoneNumberScreen>
    with WidgetsBindingObserver {
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
    final bottomViewInsets = WidgetsBinding
        .instance.platformDispatcher.views.first.viewInsets.bottom;
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
            msg: autoVerified
                ? 'OTP was fetched automatically!'
                : 'OTP was verified manually!',
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
                      controller.isOtpExpired
                          ? 'Resend'
                          : '${controller.otpExpirationTimeLeft.inSeconds}s',
                      style: const TextStyle(color: Colors.blue, fontSize: 18),
                    ),
                  ),
                const SizedBox(width: 5),
              ],
            ),
            body: controller.isSendingCode
                ? Column(
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
                  )
                : ListView(
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
                          final verified =
                              await controller.verifyOtp(enteredOtp);
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
