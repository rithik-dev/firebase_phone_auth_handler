import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_phone_auth_handler/firebase_phone_auth_handler.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(_MainApp());
}

class _MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FirebasePhoneAuthProvider(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: VerifyPhoneNumberScreen(phoneNumber: "+919876543210"),
      ),
    );
  }
}

// ignore: must_be_immutable
class VerifyPhoneNumberScreen extends StatelessWidget {
  final String phoneNumber;

  String? _enteredOTP;

  VerifyPhoneNumberScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  void _showSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FirebasePhoneAuthHandler(
        phoneNumber: phoneNumber,
        timeOutDuration: const Duration(seconds: 60),
        onLoginSuccess: (userCredential, autoVerified) async {
          _showSnackBar(
            context,
            'Phone number verified successfully!',
          );

          debugPrint(
            autoVerified
                ? "OTP was fetched automatically"
                : "OTP was verified manually",
          );

          debugPrint("Login Success UID: ${userCredential.user?.uid}");
        },
        onLoginFailed: (authException) {
          _showSnackBar(
            context,
            'Something went wrong (${authException.message})',
          );

          debugPrint(authException.message);
          // handle error further if needed
        },
        builder: (context, controller) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Verify Phone Number"),
              actions: [
                if (controller.codeSent)
                  TextButton(
                    child: Text(
                      controller.timerIsActive
                          ? "${controller.timerCount.inSeconds}s"
                          : "RESEND",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 18,
                      ),
                    ),
                    onPressed: controller.timerIsActive
                        ? null
                        : () async => await controller.sendOTP(),
                  ),
                const SizedBox(width: 5),
              ],
            ),
            body: controller.codeSent
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        "We've sent an SMS with a verification code to $phoneNumber",
                        style: const TextStyle(
                          fontSize: 25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      AnimatedContainer(
                        duration: const Duration(seconds: 1),
                        height: controller.timerIsActive ? null : 0,
                        child: Column(
                          children: const [
                            CircularProgressIndicator.adaptive(),
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
                      const Text(
                        "Enter OTP",
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
                          if (_enteredOTP?.length == 6) {
                            final isValidOTP = await controller.verifyOTP(
                              otp: _enteredOTP!,
                            );
                            // Incorrect OTP
                            if (!isValidOTP) {
                              _showSnackBar(
                                context,
                                "Please enter the correct OTP sent to $phoneNumber",
                              );
                            }
                          }
                        },
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator.adaptive(),
                      SizedBox(height: 50),
                      Center(
                        child: Text(
                          "Sending OTP",
                          style: TextStyle(fontSize: 25),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
