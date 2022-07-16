# [FirebasePhoneAuthHandler](https://pub.dev/packages/firebase_phone_auth_handler) For Flutter
[![pub package](https://img.shields.io/pub/v/firebase_phone_auth_handler.svg)](https://pub.dev/packages/firebase_phone_auth_handler)
[![likes](https://badges.bar/firebase_phone_auth_handler/likes)](https://pub.dev/packages/firebase_phone_auth_handler/score)
[![popularity](https://badges.bar/firebase_phone_auth_handler/popularity)](https://pub.dev/packages/firebase_phone_auth_handler/score)
[![pub points](https://badges.bar/firebase_phone_auth_handler/pub%20points)](https://pub.dev/packages/firebase_phone_auth_handler/score)

* An easy-to-use firebase phone authentication package to easily send and verify OTP's with auto-fetch OTP support via SMS.
* Supports OTP on web out of the box.

## Screenshots
<img src="https://user-images.githubusercontent.com/56810766/166433323-39875cc4-440a-4556-9550-1b5ab4e8f310.gif" height=600/>&nbsp;&nbsp;<img src="https://user-images.githubusercontent.com/56810766/115599396-33876600-a2f9-11eb-9516-d0f189b88a53.jpeg" height=600/>&nbsp;&nbsp;<img src="https://user-images.githubusercontent.com/56810766/115599390-31bda280-a2f9-11eb-8990-d3df76d3aabc.jpg" height=600/>&nbsp;&nbsp;<img src="https://user-images.githubusercontent.com/56810766/166431851-228693fe-7430-4c66-baa2-65acc2db9db4.jpg" height=600/>&nbsp;&nbsp;<img src="https://user-images.githubusercontent.com/56810766/166431847-06aceb70-db87-4138-8146-e9c935a51cf2.jpg" height=600/>&nbsp;&nbsp;<img src="https://user-images.githubusercontent.com/56810766/166431849-28a4563d-2c59-4da7-b21a-355dc0b72448.jpg" height=600/>&nbsp;&nbsp;<img src="https://user-images.githubusercontent.com/56810766/166431854-f0f8ec50-a105-47ab-97a1-d12dbaf13ce8.jpg" height=600/>

## Getting Started
<b>Step 1</b>: Before you can add Firebase to your app, you need to create a Firebase project to connect to your application.
Visit [`Understand Firebase Projects`](https://firebase.google.com/docs/projects/learn-more) to learn more about Firebase projects.

<b>Step 2</b>: To use Firebase in your app, you need to register your app with your Firebase project.
Registering your app is often called "adding" your app to your project.

Also, register a web app if using on the web.
Follow on the screen instructions to initialize the project.

Add the latest version 'firebase-auth' CDN from [here](https://firebase.google.com/docs/web/setup#available-libraries).
(Tested on version 8.6.1)

<b> Step 3</b>: Add a Firebase configuration file and the SDK's. (google-services)

<b> Step 4</b>: When the basic setup is done, open the console and then the
project and head over to `Authentication` from the left drawer menu.

<b> Step 5</b>: Click on `Sign-in method` next to the `Users` tab and enable `Phone`.

<b> Step 6</b>: Follow the additional configuration steps for the platforms to avoid any errors.

<b> Step 7</b>: IMPORTANT: Do not forget to enable the [`Android Device Verification`](https://console.cloud.google.com/apis/library/androidcheck.googleapis.com)
service from Google Cloud Platform. (make sure the correct project is selected).

<b> Step 8</b>: Lastly, add [`firebase_core`](https://pub.dev/packages/firebase_core) as a dependency in your pubspec.yaml file.
and call `Firebase.initializeApp()` in the `main` method as shown:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(_MainApp());
}
```

## Usage

To use this plugin, add [`firebase_phone_auth_handler`](https://pub.dev/packages/firebase_phone_auth_handler) as a dependency in your pubspec.yaml file.

```yaml
  dependencies:
    flutter:
      sdk: flutter
    firebase_phone_auth_handler:
```

First and foremost, import the widget.
```dart
import 'package:firebase_phone_auth_handler/firebase_phone_auth_handler.dart';
```

Wrap the `MaterialApp` with `FirebasePhoneAuthProvider` to enable your application to support phone authentication like shown.
```dart
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

You can now add a [`FirebasePhoneAuthHandler`](https://github.com/rithik-dev/firebase_phone_auth_handler/blob/master/lib/firebase_phone_auth_handler.dart) widget to your widget tree and pass all the required parameters to get started.
```dart
FirebasePhoneAuthHandler(
    phoneNumber: "+919876543210",
    builder: (context, controller) {
        return SizedBox.shrink();
    },
),
```

The phone number is the number to which the OTP will be sent which should be formatted in the following way:

+919876543210 - where +91 is the country code and 9876543210 is the phone number.

The widget returned from the `builder` is rendered on the screen.
The builder exposes a `controller` which contains various variables and methods.

Callbacks such as `onLoginSuccess` or `onLoginFailed` can be passed to the widget.

`onLoginSuccess` is called whenever the otp was sent to the mobile successfully and
was either auto verified or verified manually by calling `verifyOTP` function in the
controller. The callback exposes `UserCredential` object which can be used to find
user UID and other stuff. The boolean provided is whether the OTP was auto verified or
verified manually be calling `verifyOTP`. True if auto verified and false is verified manually.

`onLoginFailed` is called if an error occurs while sending OTP or verifying the OTP
or any internal error occurs, callback is triggered exposing `FirebaseAuthException`
which can be used to handle the error.

`onCodeSent` is called when the OTP is successfully sent to the phone number.

```dart
FirebasePhoneAuthHandler(
    phoneNumber: "+919876543210",
    // If true, the user is signed out before the onLoginSuccess callback is fired when the OTP is verified successfully.
    signOutOnSuccessfulVerification: false,
    
    linkWithExistingUser: false,
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

To logout the current user(if any), simply call
```dart
await FirebasePhoneAuthHandler.signOut(context);
```

`controller.signOut()` can also be used to logout the current user if the functionality is needed in
the same screen as the widget itself (where `controller` is the variable passed in the callback from the builder method in the widget).

### Web (reCAPTCHA)

By default, the reCAPTCHA widget is a fully managed flow which provides security to your web application.
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

#### How I prefer using it usually
I usually have a phone number input field, which handles phone number input. Then pass the phone number
to the [`VerifyPhoneNumberScreen`](https://github.com/rithik-dev/firebase_phone_auth_handler/blob/master/example/lib/main.dart#L24)
widget from the example app.

```dart
// probably some ui or dialog to get the phone number
final phoneNumber = _getPhoneNumber();

// then call
void _verifyPhoneNumber() async {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => VerifyPhoneNumberScreen(phoneNumber: phoneNumber),
    ),
  );
}

/// route to home screen or somewhere in the onLoginSuccess callback for [VerifyPhoneNumberScreen] 
```

#### Sample Usage
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
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

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
    final bottomViewInsets = WidgetsBinding.instance.window.viewInsets.bottom;
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

See the [`example`](https://github.com/rithik-dev/firebase_phone_auth_handler/blob/master/example) directory for a complete sample app.

### Created & Maintained By `Rithik Bhandari`

* GitHub: [@rithik-dev](https://github.com/rithik-dev)
* LinkedIn: [@rithik-bhandari](https://www.linkedin.com/in/rithik-bhandari/)