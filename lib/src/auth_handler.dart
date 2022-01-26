import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_phone_auth_handler/src/auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FirebasePhoneAuthHandler extends StatefulWidget {
  const FirebasePhoneAuthHandler({
    Key? key,
    required this.phoneNumber,
    required this.builder,
    this.onLoginFailed,
    this.onLoginSuccess,
    this.timeOutDuration = FirebasePhoneAuthService.kTimeOutDuration,
    this.recaptchaVerifierForWebProvider,
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
  /// Defaults to [FirebasePhoneAuthService.kTimeOutDuration].
  /// {@endtemplate}
  final Duration timeOutDuration;

  /// {@template recaptchaVerifierForWeb}
  /// Custom reCAPTCHA for web-based authentication.
  ///
  /// The boolean in the function is provided which can be used to check
  /// whether the platform is web or not.
  ///
  /// NOTE : Only pass a [RecaptchaVerifier] instance if you're on web, else an error occurs.
  /// {@endtemplate}
  final RecaptchaVerifier? Function(bool)? recaptchaVerifierForWebProvider;

  /// {@template builder}
  /// The widget returned by the `builder` is rendered on to the screen and
  /// builder is called every time a value changes i.e. either the timerCount or any
  /// other value.
  ///
  /// The builder provides a controller which can be used to render the UI based
  /// on the current state.
  /// {@endtemplate}
  final Widget Function(BuildContext, FirebasePhoneAuthService) builder;

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

      RecaptchaVerifier? _captcha;
      if (widget.recaptchaVerifierForWebProvider != null) {
        _captcha = widget.recaptchaVerifierForWebProvider!(kIsWeb);
      }

      _con.setData(
        phoneNumber: widget.phoneNumber,
        onLoginSuccess: widget.onLoginSuccess,
        onLoginFailed: widget.onLoginFailed,
        timeOutDuration: widget.timeOutDuration,
        recaptchaVerifierForWeb: _captcha,
      );

      await _con.sendOTP();
    })();
    super.initState();
  }

  @override
  void dispose() {
    try {
      Provider.of<FirebasePhoneAuthService>(context, listen: false).clear();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebasePhoneAuthService>(
      builder: (context, controller, _) => widget.builder(context, controller),
    );
  }
}
