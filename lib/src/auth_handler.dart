import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_phone_auth_handler/src/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FirebasePhoneAuthHandler extends StatefulWidget {
  const FirebasePhoneAuthHandler({
    Key? key,
    required this.phoneNumber,
    required this.builder,
    this.onLoginFailed,
    this.onLoginSuccess,
    this.timeOutDuration = FirebasePhoneAuthService.TIME_OUT_DURATION,
  }) : super(key: key);

  /// {@template phoneNumber}
  /// The phone number to which the OTP is to be sent.
  ///
  /// The phone number should also contain the country code.
  ///
  /// Example: +919876543210 where +91 is the country code and 9876543210 is the number.
  /// {@endtemplate}
  final String phoneNumber;

  /// {@template onLoginSuccess}
  /// This callback is triggered when the phone number is verified and the user is
  /// signed in successfully. The function provides [UserCredential] which contains
  /// essential user information.
  ///
  /// The boolean provided is whether the OTP was auto verified or
  /// verified manually by calling [verifyOTP].
  ///
  /// True if auto verified and false is verified manually.
  /// {@endtemplate}
  final FutureOr<void> Function(UserCredential, bool)? onLoginSuccess;

  /// {@template onLoginFailed}
  /// This callback is triggered if the phone verification fails. The callback provides
  /// [FirebaseAuthException] which contains information about the error.
  /// {@endtemplate}
  final FutureOr<void> Function(FirebaseAuthException)? onLoginFailed;

  /// {@template timeOutDuration}
  /// The maximum amount of time you are willing to wait for SMS
  /// auto-retrieval to be completed by the library.
  ///
  /// Maximum allowed value is 2 minutes.
  ///
  /// Defaults to [FirebasePhoneAuthService.TIME_OUT_DURATION].
  /// {@endtemplate}
  final Duration timeOutDuration;

  /// {@template builder}
  /// The widget returned by the `builder` is rendered on to the screen and
  /// builder is called every time a value changes i.e. either the timerCount or any
  /// other value.
  /// {@endtemplate}
  final Widget Function(FirebasePhoneAuthService) builder;

  /// {@template signOut}
  /// Signs out the current user.
  /// {@endtemplate}
  static Future<void> signOut(BuildContext context) =>
      Provider.of<FirebasePhoneAuthService>(context, listen: false).signOut();

  @override
  _FirebasePhoneAuthHandlerState createState() =>
      _FirebasePhoneAuthHandlerState();
}

class _FirebasePhoneAuthHandlerState extends State<FirebasePhoneAuthHandler> {
  @override
  void initState() {
    (() async {
      final _con =
          Provider.of<FirebasePhoneAuthService>(context, listen: false);

      _con.setData(
        phoneNumber: this.widget.phoneNumber,
        onLoginSuccess: this.widget.onLoginSuccess,
        onLoginFailed: this.widget.onLoginFailed,
        timeOutDuration: this.widget.timeOutDuration,
      );

      await _con.sendOTP();
    })();
    super.initState();
  }

  @override
  void dispose() {
    Provider.of<FirebasePhoneAuthService>(context, listen: false).clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebasePhoneAuthService>(
      builder: (context, controller, child) => this.widget.builder(controller),
    );
  }
}
