import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_phone_auth_handler/src/auth_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Wrap the [MaterialApp] with [FirebasePhoneAuthProvider]
/// to enable your application to support phone authentication.
class FirebasePhoneAuthProvider extends StatelessWidget {
  const FirebasePhoneAuthProvider({
    super.key,
    required this.child,
    this.auth,
  });

  /// The child of the widget.
  final Widget child;

  /// The [FirebaseAuth] instance to use.
  final FirebaseAuth? auth;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FirebasePhoneAuthController>(
      create: (_) => FirebasePhoneAuthController(auth: auth),
      child: child,
    );
  }
}
