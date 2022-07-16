import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_phone_auth_handler/src/type_definitions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

part 'auth_controller.dart';

class FirebasePhoneAuthHandler extends StatefulWidget {
  const FirebasePhoneAuthHandler({
    Key? key,
    required this.phoneNumber,
    required this.builder,
    this.onLoginSuccess,
    this.onLoginFailed,
    this.onError,
    this.onCodeSent,
    this.signOutOnSuccessfulVerification = false,
    this.linkWithExistingUser = false,
    this.autoRetrievalTimeOutDuration =
        FirebasePhoneAuthController.kAutoRetrievalTimeOutDuration,
    this.otpExpirationDuration =
        FirebasePhoneAuthController.kAutoRetrievalTimeOutDuration,
    this.recaptchaVerifierForWebProvider,
  }) : super(key: key);

  /// {@template phoneNumber}
  ///
  /// The phone number to which the OTP is to be sent.
  ///
  /// The phone number should also contain the country code.
  ///
  /// Example: +919876543210 where +91 is the country code and 9876543210 is the number.
  ///
  /// {@endtemplate}
  final String phoneNumber;

  /// {@template signOutOnSuccessfulVerification}
  ///
  /// If true, the user is signed out before the [onLoginSuccess]
  /// callback is fired when the OTP is verified successfully.
  ///
  /// Is useful when you only want to verify phone number,
  /// and not actually sign in the user.
  ///
  /// Defaults to false
  ///
  /// {@endtemplate}
  final bool signOutOnSuccessfulVerification;

  /// {@template onCodeSent}
  ///
  /// Callback called when the code is sent successfully to the phone number
  ///
  /// {@endtemplate}
  final VoidCallback? onCodeSent;

  /// {@template linkWithExistingUser}
  ///
  /// If true, links the generated credentials to an existing signed in user,
  /// and not creating new session.
  ///
  /// Internally, if true, this calls the linkWithCredential method instead of
  /// signInWithCredential.
  ///
  /// Make sure a user is signed in already, else an error is thrown.
  ///
  /// NOTE: Does not work on web platforms.
  ///
  /// Defaults to false
  ///
  /// {@endtemplate}
  final bool linkWithExistingUser;

  /// {@template onLoginSuccess}
  ///
  /// This callback is triggered when the phone number is verified and the user is
  /// signed in successfully. The function provides [UserCredential] which contains
  /// essential user information.
  ///
  /// The boolean provided is whether the OTP was auto verified or
  /// verified manually by calling [verifyOtp].
  ///
  /// True if auto verified and false is verified manually.
  ///
  /// {@endtemplate}
  final OnLoginSuccess? onLoginSuccess;

  /// {@template onLoginFailed}
  ///
  /// This callback is triggered if the phone verification fails. The callback provides
  /// [FirebaseAuthException] which contains information about the error.
  ///
  /// {@endtemplate}
  final OnLoginFailed? onLoginFailed;

  /// {@template onError}
  ///
  /// Called when a general error occurs.
  ///
  /// If the error is a [FirebaseAuthException], then [onLoginFailed] is called.
  ///
  /// {@endtemplate}
  final OnError? onError;

  /// {@template autoRetrievalTimeOutDuration}
  ///
  /// The maximum amount of time you are willing to wait for SMS
  /// auto-retrieval to be completed by the library.
  ///
  /// Maximum allowed value is 2 minutes.
  ///
  /// NOTE: The user can still use the OTP to sign in after
  /// [autoRetrievalTimeOutDuration] duration, but the device
  /// will not try to auto-fetch the OTP after this set duration.
  ///
  /// Defaults to [FirebasePhoneAuthController.kAutoRetrievalTimeOutDuration].
  ///
  /// {@endtemplate}
  final Duration autoRetrievalTimeOutDuration;

  /// {@template otpExpirationDuration}
  ///
  /// The OTP expiration duration, can be used to display a timer, and show
  /// a resend button, to resend the OTP.
  ///
  /// Firebase does not document if the OTP ever expires, or anything
  /// about it's validity. Hence, this can be used to show a timer, or force
  /// user to request a new otp after a set duration.
  ///
  /// Defaults to [FirebasePhoneAuthController.kAutoRetrievalTimeOutDuration].
  ///
  /// {@endtemplate}
  final Duration otpExpirationDuration;

  /// {@template recaptchaVerifierForWeb}
  ///
  /// Custom reCAPTCHA for web-based authentication.
  ///
  /// The boolean in the function is provided which can be used to check
  /// whether the platform is web or not.
  ///
  /// NOTE : Only pass a [RecaptchaVerifier] instance if you're on web, else an error occurs.
  ///
  /// {@endtemplate}
  final RecaptchaVerifier? Function(bool)? recaptchaVerifierForWebProvider;

  /// {@template builder}
  ///
  /// The widget returned by the `builder` is rendered on to the screen and
  /// builder is called every time a value changes i.e. either the timerCount or any
  /// other value.
  ///
  /// The builder provides a controller which can be used to render the UI based
  /// on the current state.
  ///
  /// {@endtemplate}
  final Widget Function(BuildContext, FirebasePhoneAuthController) builder;

  /// {@template signOut}
  ///
  /// Signs out the current user.
  ///
  /// {@endtemplate}
  static Future<void> signOut(BuildContext context) =>
      FirebasePhoneAuthController._of(context, listen: false).signOut();

  @override
  // ignore: library_private_types_in_public_api
  _FirebasePhoneAuthHandlerState createState() =>
      _FirebasePhoneAuthHandlerState();
}

class _FirebasePhoneAuthHandlerState extends State<FirebasePhoneAuthHandler> {
  @override
  void initState() {
    (() async {
      final con = FirebasePhoneAuthController._of(context, listen: false);

      RecaptchaVerifier? captcha;
      if (widget.recaptchaVerifierForWebProvider != null) {
        captcha = widget.recaptchaVerifierForWebProvider!(kIsWeb);
      }

      con._setData(
        phoneNumber: widget.phoneNumber,
        onLoginSuccess: widget.onLoginSuccess,
        onLoginFailed: widget.onLoginFailed,
        onError: widget.onError,
        autoRetrievalTimeOutDuration: widget.autoRetrievalTimeOutDuration,
        otpExpirationDuration: widget.otpExpirationDuration,
        onCodeSent: widget.onCodeSent,
        linkWithExistingUser: widget.linkWithExistingUser,
        signOutOnSuccessfulVerification: widget.signOutOnSuccessfulVerification,
        recaptchaVerifierForWeb: captcha,
      );

      await con.sendOTP();
    })();
    super.initState();
  }

  @override
  void dispose() {
    try {
      FirebasePhoneAuthController._of(context, listen: false).clear();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebasePhoneAuthController>(
      builder: (context, controller, _) => widget.builder(context, controller),
    );
  }
}
