# FirebasePhoneAuthHandler For Flutter
[![pub package](https://img.shields.io/pub/v/firebase_phone_auth_handler.svg)](https://pub.dev/packages/firebase_phone_auth_handler)
[![likes](https://badges.bar/firebase_phone_auth_handler/likes)](https://pub.dev/packages/firebase_phone_auth_handler/score)
[![popularity](https://badges.bar/firebase_phone_auth_handler/popularity)](https://pub.dev/packages/firebase_phone_auth_handler/score)
[![pub points](https://badges.bar/firebase_phone_auth_handler/pub%20points)](https://pub.dev/packages/firebase_phone_auth_handler/score)

* An easy-to-use firebase phone authentication package to easily send and verify OTP's with auto-fetch OTP support via SMS.

## Screenshots
<img src="https://user-images.githubusercontent.com/56810766/115599399-341ffc80-a2f9-11eb-9410-ffd1a254caf6.jpeg" height=600/>&nbsp;&nbsp;<img src="https://user-images.githubusercontent.com/56810766/115599396-33876600-a2f9-11eb-9516-d0f189b88a53.jpeg" height=600/>&nbsp;&nbsp;<img src="https://user-images.githubusercontent.com/56810766/115599390-31bda280-a2f9-11eb-8990-d3df76d3aabc.jpg" height=600/>&nbsp;&nbsp;<img src="https://user-images.githubusercontent.com/56810766/115599398-33876600-a2f9-11eb-9a3a-61e073212c7b.jpeg" height=600/>

## Getting Started
<b>Step 1</b>: Before you can add Firebase to your app, you need to create a Firebase project to connect to your application.
Visit [`Understand Firebase Projects`](https://firebase.google.com/docs/projects/learn-more) to learn more about Firebase projects.

<b>Step 2</b>: To use Firebase in your app, you need to register your app with your Firebase project. Registering your app is often called "adding" your app to your project.

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
  runApp(MyApp());
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

Wrap the `MaterialApp` with `FirebasePhoneAuthSupporter` to enable your application to support phone authentication like shown.
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FirebasePhoneAuthSupporter(
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
    builder: (controller) {
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
user UID and other stuff.

`onLoginFailed` is called if an error occurs while sending OTP or verifying the OTP
or any internal error occurs, callback is triggered exposing `FirebaseAuthException`
which can be used to handle the error.

```dart
FirebasePhoneAuthHandler(
    phoneNumber: "+919876543210",
    builder: (controller) {
      return SizedBox.shrink();
    },
    onLoginSuccess: (userCredential) {
      print("Login success UID: ${userCredential.user?.uid}");
    },
    onLoginFailed: (authException) {
      print("An error occurred: ${authException.message}");
    },
),
```

To logout the current user(if any), simply call
```dart
await FirebasePhoneAuthHandler.signOut(context);
```

`controller.signOut()` can also be used to logout the current user if the functionality is needed in
the same screen as the widget itself (where `controller` is the variable passed in the callback from the builder method in the widget).

Sample Usage
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_phone_auth_handler/firebase_phone_auth_handler.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FirebasePhoneAuthSupporter(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  String? _enteredOTP;
  static const _phoneNumber = "+919876543210";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FirebasePhoneAuthHandler(
        phoneNumber: _phoneNumber,
        timeOutDuration: const Duration(seconds: 60),
        onLoginSuccess: (userCredential) async {
          print("Login Success UID: ${userCredential.user?.uid}");
        },
        onLoginFailed: (authException) {
          print("An error occurred: ${authException.message}");

          // handle error further if needed
        },
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Verification Code"),
              backgroundColor: Colors.black,
              actions: controller.codeSent
                  ? [
                      TextButton(
                        child: Text(
                          controller.timerIsActive
                              ? "${controller.timerCount.inSeconds}s"
                              : "RESEND",
                          style: TextStyle(color: Colors.blue, fontSize: 18),
                        ),
                        onPressed: controller.timerIsActive
                            ? null
                            : () async {
                                await controller.sendOTP();
                              },
                      ),
                      SizedBox(width: 5),
                    ]
                  : null,
            ),
            body: controller.codeSent
                ? ListView(
                    padding: EdgeInsets.all(20),
                    children: [
                      Text(
                        "We've sent an SMS with a verification code to $_phoneNumber",
                        style: TextStyle(
                          fontSize: 25,
                        ),
                      ),
                      SizedBox(height: 10),
                      Divider(),
                      AnimatedContainer(
                        duration: Duration(seconds: 1),
                        height: controller.timerIsActive ? null : 0,
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 50),
                            Text(
                              "Listening for OTP",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Divider(),
                            Text("OR", textAlign: TextAlign.center),
                            Divider(),
                          ],
                        ),
                      ),
                      Text(
                        "Enter Code Manually",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextField(
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                        onChanged: (String v) async {
                          _enteredOTP = v;
                          if (this._enteredOTP?.length == 6) {
                            final res =
                                await controller.verifyOTP(otp: _enteredOTP!);
                            // Incorrect OTP
                            if (!res)
                              print(
                                "Please enter the correct OTP sent to $_phoneNumber",
                              );
                          }
                        },
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 50),
                      Center(
                        child: Text(
                          "Sending OTP",
                          style: TextStyle(fontSize: 25),
                        ),
                      ),
                    ],
                  ),
            floatingActionButton: controller.codeSent
                ? FloatingActionButton(
                    backgroundColor: Theme.of(context).accentColor,
                    child: Icon(Icons.check),
                    onPressed: () async {
                      if (_enteredOTP == null || _enteredOTP?.length != 6) {
                        print("Please enter a valid 6 digit OTP");
                      } else {
                        final res =
                            await controller.verifyOTP(otp: _enteredOTP!);
                        // Incorrect OTP
                        if (!res)
                          print(
                            "Please enter the correct OTP sent to $_phoneNumber",
                          );
                      }
                    },
                  )
                : null,
          );
        },
      ),
    );
  }
}

```

### Created & Maintained By `Rithik Bhandari`

* GitHub: [@rithik-dev](https://github.com/rithik-dev)
* LinkedIn: [@rithik-bhandari](https://www.linkedin.com/in/rithik-bhandari/)