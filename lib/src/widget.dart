import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_phone_auth_handler/src/service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FirebasePhoneAuthWidget extends StatefulWidget {
  const FirebasePhoneAuthWidget({
    required this.phoneNumber,
    required this.builder,
    this.onLoginFailed,
    this.onLoginSuccess,
    this.timeOutDuration = FirebasePhoneAuthService.TIME_OUT_DURATION,
  });

  /// {@macro phoneNumber}
  final String phoneNumber;

  /// {@macro onLoginSuccess}
  final FutureOr<void> Function(UserCredential)? onLoginSuccess;

  /// {@macro onLoginFailed}
  final FutureOr<void> Function(FirebaseAuthException)? onLoginFailed;

  /// {@macro timeOutDuration}
  final Duration timeOutDuration;

  /// {@macro builder}
  final Widget Function(FirebasePhoneAuthService) builder;

  @override
  _FirebasePhoneAuthWidgetState createState() =>
      _FirebasePhoneAuthWidgetState();
}

class _FirebasePhoneAuthWidgetState extends State<FirebasePhoneAuthWidget> {
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
